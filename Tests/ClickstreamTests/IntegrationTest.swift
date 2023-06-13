//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import Clickstream
import Swifter
import XCTest

class IntegrationTest: XCTestCase {
    var analyticsPlugin: AWSClickstreamPlugin!
    var analyticsClient: AnalyticsClient!
    var eventRecorder: EventRecorder!
    var server: HttpServer!
    let testSuccessEndpoint = "http://localhost:8080/collect"
    let testFailEndpoint = "http://localhost:8080/collect/fail"
    let longSendEventInterval = 100_000

    override func setUp() async throws {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        server = HttpServer()
        server["/collect"] = { _ in
            HttpResponse.ok(.text("request success"))
        }
        server["/collect/fail"] = { _ in
            HttpResponse.badRequest(.text("request fail"))
        }
        try! server.start()
        analyticsPlugin = AWSClickstreamPlugin()
        let appId = JSONValue(stringLiteral: "testAppId" + String(describing: Date().millisecondsSince1970))
        await Amplify.reset()
        let plugins: [String: JSONValue] = [
            "awsClickstreamPlugin": [
                "appId": appId,
                "endpoint": "http://localhost:8080/collect",
                "isCompressEvents": false,
                "autoFlushEventsInterval": 10000,
                "isTrackAppExceptionEvents": false
            ]
        ]
        let analyticsConfiguration = AnalyticsCategoryConfiguration(plugins: plugins)
        let config = AmplifyConfiguration(analytics: analyticsConfiguration)
        do {
            try Amplify.add(plugin: analyticsPlugin)
            try Amplify.configure(config)
            analyticsClient = analyticsPlugin!.analyticsClient as? AnalyticsClient
            eventRecorder = await analyticsClient.eventRecorder as? EventRecorder
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
        analyticsPlugin.reset()
        server.stop()
        try eventRecorder.dbUtil.deleteAllEvents()
    }

    func testRecordOneEventSuccess() throws {
        ClickstreamAnalytics.recordEvent("userId", [
            "Channel": "SMS",
            "Successful": true,
            "Score": 90
        ])
        ClickstreamAnalytics.flushEvents()
        Thread.sleep(forTimeInterval: 0.2)
        let eventCount = try eventRecorder.dbUtil.getEventCount()
        XCTAssertEqual(0, eventCount)
    }

    func testRecordOneEventWithNameSuccess() throws {
        ClickstreamAnalytics.recordEvent("testEvent")
        ClickstreamAnalytics.flushEvents()
        Thread.sleep(forTimeInterval: 0.2)
        let eventCount = try eventRecorder.dbUtil.getEventCount()
        XCTAssertEqual(0, eventCount)
    }

    func testFlushEvents() throws {
        ClickstreamAnalytics.recordEvent("testEvent")
        ClickstreamAnalytics.flushEvents()
        Thread.sleep(forTimeInterval: 0.2)
        let eventCount = try eventRecorder.dbUtil.getEventCount()
        XCTAssertEqual(0, eventCount)
    }

    func testAddGlobalAttribute() throws {
        ClickstreamAnalytics.addGlobalAttributes([
            "channel": "AppStore",
            "level": 5.1,
            "class": 5,
            "isOpenNotification": true
        ])
        ClickstreamAnalytics.recordEvent("testEvent")
        Thread.sleep(forTimeInterval: 0.1)

        let testEvent = try getTestEvent()
        let eventAttribute = testEvent["attributes"] as! [String: Any]
        XCTAssertEqual("AppStore", eventAttribute["channel"] as! String)
        XCTAssertEqual(5.1, eventAttribute["level"] as! Double)
        XCTAssertEqual(5, eventAttribute["class"] as! Int)
        XCTAssertEqual(true, eventAttribute["isOpenNotification"] as! Bool)
    }

    func testDeleteGlobalAttribute() throws {
        ClickstreamAnalytics.addGlobalAttributes([
            "channel": "AppStore",
            "level": 5.1,
            "class": 5,
            "isOpenNotification": true
        ])
        ClickstreamAnalytics.deleteGlobalAttributes("channel")
        ClickstreamAnalytics.recordEvent("testEvent")
        Thread.sleep(forTimeInterval: 0.1)

        let testEvent = try getTestEvent()
        let eventAttribute = testEvent["attributes"] as! [String: Any]
        XCTAssertNil(eventAttribute["channel"])
        XCTAssertEqual(5.1, eventAttribute["level"] as! Double)
        XCTAssertEqual(5, eventAttribute["class"] as! Int)
        XCTAssertEqual(true, eventAttribute["isOpenNotification"] as! Bool)
    }

    func testAddUserAttribute() throws {
        ClickstreamAnalytics.setUserId("13232")
        ClickstreamAnalytics.addUserAttributes([
            "_user_age": 21,
            "isFirstOpen": true,
            "score": 85.2,
            "_user_name": "carl"
        ])
        Thread.sleep(forTimeInterval: 0.1)
        ClickstreamAnalytics.recordEvent("testEvent")
        Thread.sleep(forTimeInterval: 0.1)
        let testEvent = try getTestEvent()
        let userInfo = testEvent["user"] as! [String: Any]
        XCTAssertEqual(21, (userInfo["_user_age"] as! JsonObject)["value"] as! Int)
        XCTAssertEqual(true, (userInfo["isFirstOpen"] as! JsonObject)["value"] as! Bool)
        XCTAssertEqual(85.2, (userInfo["score"] as! JsonObject)["value"] as! Double)
        XCTAssertEqual("carl", (userInfo["_user_name"] as! JsonObject)["value"] as! String)
        XCTAssertEqual("13232", (userInfo[Event.ReservedAttribute.USER_ID] as! JsonObject)["value"] as! String)
    }

    func testSetUserIdString() throws {
        ClickstreamAnalytics.setUserId("12345")
        ClickstreamAnalytics.recordEvent("testEvent")
        Thread.sleep(forTimeInterval: 0.1)
        let testEvent = try getTestEvent()
        let userInfo = testEvent["user"] as! [String: Any]
        XCTAssertEqual("12345", (userInfo[Event.ReservedAttribute.USER_ID] as! JsonObject)["value"] as! String)
    }

    func testSetUserIdNil() throws {
        ClickstreamAnalytics.setUserId("12345")
        ClickstreamAnalytics.setUserId(nil)
        ClickstreamAnalytics.recordEvent("testEvent")
        Thread.sleep(forTimeInterval: 0.1)
        let testEvent = try getTestEvent()
        let userInfo = testEvent["user"] as! [String: Any]
        XCTAssertNil(userInfo[Event.ReservedAttribute.USER_ID])
    }

    func testProfileSetEvent() throws {
        ClickstreamAnalytics.setUserId("12345")
        Thread.sleep(forTimeInterval: 0.1)
        let eventArray = try eventRecorder.getBatchEvent().eventsJson.jsonArray()
        let profileSetEvent = eventArray[eventArray.count - 1]
        XCTAssertEqual(profileSetEvent["event_type"] as! String, Event.PresetEvent.PROFILE_SET)
        XCTAssertEqual(((profileSetEvent["user"] as! JsonObject)[Event.ReservedAttribute.USER_ID]
                as! JsonObject)["value"] as! String, "12345")
    }

    func testProfileSetEventWithAllAttributes() throws {
        ClickstreamAnalytics.addUserAttributes([
            "_user_age": 21,
            "isFirstOpen": true,
            "score": 85.2,
            "_user_name": "carl"
        ])
        Thread.sleep(forTimeInterval: 0.1)
        let eventArray = try eventRecorder.getBatchEvent().eventsJson.jsonArray()
        let profileSetEvent = eventArray[eventArray.count - 1]
        XCTAssertEqual(profileSetEvent["event_type"] as! String, Event.PresetEvent.PROFILE_SET)
        let user = (profileSetEvent["user"] as! JsonObject)
        XCTAssertEqual((user["_user_age"] as! JsonObject)["value"] as! Int, 21)
        XCTAssertEqual((user["isFirstOpen"] as! JsonObject)["value"] as! Bool, true)
        XCTAssertEqual((user["score"] as! JsonObject)["value"] as! Double, 85.2)
        XCTAssertEqual((user["_user_name"] as! JsonObject)["value"] as! String, "carl")
        XCTAssertNotNil(user[Event.ReservedAttribute.USER_FIRST_TOUCH_TIMESTAMP])
    }

    func testProfileSetTimestamp() throws {
        ClickstreamAnalytics.addUserAttributes([
            "_user_age": 21,
            "isFirstOpen": true,
            "score": 85.2,
            "_user_name": "carl"
        ])
        Thread.sleep(forTimeInterval: 0.1)
        let eventArray = try eventRecorder.getBatchEvent().eventsJson.jsonArray()
        let profileSetEvent = eventArray[eventArray.count - 1]
        XCTAssertEqual(profileSetEvent["event_type"] as! String, Event.PresetEvent.PROFILE_SET)
        let eventTime = profileSetEvent["timestamp"] as! Int64
        let user = (profileSetEvent["user"] as! JsonObject)
        let userAgeSetTime = (user["_user_age"] as! JsonObject)["set_timestamp"] as! Int64
        let isFirstOpenSetTime = (user["isFirstOpen"] as! JsonObject)["set_timestamp"] as! Int64
        let scoreSetTime = (user["score"] as! JsonObject)["set_timestamp"] as! Int64
        let userNameSetTime = (user["_user_name"] as! JsonObject)["set_timestamp"] as! Int64
        XCTAssertTrue(eventTime >= userAgeSetTime)
        XCTAssertTrue(eventTime >= isFirstOpenSetTime)
        XCTAssertTrue(eventTime >= scoreSetTime)
        XCTAssertTrue(eventTime >= userNameSetTime)
    }

    func testModifyEndpoint() throws {
        let configuration = try ClickstreamAnalytics.getClickstreamConfiguration()
        configuration.endpoint = testFailEndpoint
        ClickstreamAnalytics.recordEvent("testEvent")
        ClickstreamAnalytics.flushEvents()
        Thread.sleep(forTimeInterval: 0.2)
        let eventCount = try eventRecorder.dbUtil.getEventCount()
        XCTAssertNotEqual(0, eventCount)
    }

    func testModifyConfiguration() throws {
        let configuration = try ClickstreamAnalytics.getClickstreamConfiguration()
        configuration.isCompressEvents = true
        configuration.isLogEvents = true
        configuration.authCookie = "authCookie"
        ClickstreamAnalytics.recordEvent("testEvent")
        ClickstreamAnalytics.flushEvents()
        Thread.sleep(forTimeInterval: 0.2)
        let eventCount = try eventRecorder.dbUtil.getEventCount()
        XCTAssertEqual(0, eventCount)
    }

    // MARK: - Objc test

    func testRecordEventForObjc() throws {
        let attribute: NSDictionary = [
            "Channel": "SMS",
            "Successful": true,
            "Score": 90.1,
            "level": 5
        ]
        ClickstreamObjc.recordEvent("userId")
        ClickstreamObjc.recordEvent("testEvent", attribute)
        ClickstreamObjc.flushEvents()
        Thread.sleep(forTimeInterval: 0.2)
        let eventCount = try eventRecorder.dbUtil.getEventCount()
        XCTAssertEqual(0, eventCount)
    }

    func testGlobalAttributeForObjc() throws {
        let attribute: NSDictionary = [
            "Channel": "SMS",
            "Successful": true,
            "Score": 90.1,
            "level": 5
        ]
        ClickstreamObjc.addGlobalAttributes(attribute)
        ClickstreamObjc.deleteGlobalAttributes(["Channel"])
        Thread.sleep(forTimeInterval: 0.1)
        ClickstreamObjc.recordEvent("testEvent")
        Thread.sleep(forTimeInterval: 0.1)
        let testEvent = try getTestEvent()
        let eventAttribute = testEvent["attributes"] as! [String: Any]
        XCTAssertNil(eventAttribute["Channel"])
        XCTAssertEqual(5, eventAttribute["level"] as! Int)
        XCTAssertEqual(90.1, eventAttribute["Score"] as! Double)
        XCTAssertEqual(true, eventAttribute["Successful"] as! Bool)
    }

    func testUserAttributeForObjc() throws {
        ClickstreamObjc.setUserId("3231")
        let userAttribute: NSDictionary = [
            "_user_age": 21,
            "isFirstOpen": true,
            "score": 85.2,
            "_user_name": "carl"
        ]
        ClickstreamObjc.addUserAttributes(userAttribute)
        Thread.sleep(forTimeInterval: 0.1)
        ClickstreamObjc.recordEvent("testEvent")
        Thread.sleep(forTimeInterval: 0.1)
        let testEvent = try getTestEvent()
        let userInfo = testEvent["user"] as! [String: Any]
        XCTAssertEqual(21, (userInfo["_user_age"] as! JsonObject)["value"] as! Int)
        XCTAssertEqual(true, (userInfo["isFirstOpen"] as! JsonObject)["value"] as! Bool)
        XCTAssertEqual(85.2, (userInfo["score"] as! JsonObject)["value"] as! Double)
        XCTAssertEqual("carl", (userInfo["_user_name"] as! JsonObject)["value"] as! String)
        XCTAssertEqual("3231", (userInfo[Event.ReservedAttribute.USER_ID] as! JsonObject)["value"] as! String)
    }

    func testModifyConfigurationForObjc() throws {
        let configuration = try ClickstreamObjc.getClickstreamConfiguration()
        configuration.isCompressEvents = true
        configuration.authCookie = "authCookie"
        ClickstreamAnalytics.recordEvent("testEvent")
        ClickstreamAnalytics.flushEvents()
        Thread.sleep(forTimeInterval: 0.2)
        let eventCount = try eventRecorder.dbUtil.getEventCount()
        XCTAssertEqual(0, eventCount)
    }

    private func getTestEvent() throws -> [String: Any] {
        var testEvent: [String: Any] = JsonObject()
        let eventArray = try eventRecorder.getBatchEvent().eventsJson.jsonArray()
        for event in eventArray {
            if event["event_type"] as! String == "testEvent" {
                testEvent = event
                break
            }
        }
        return testEvent
    }
}
