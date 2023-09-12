//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Clickstream
import XCTest

class AnalyticsClientTest: XCTestCase {
    private var analyticsClient: AnalyticsClient!
    private var eventRecorder: MockEventRecorder!
    private var clickstream: ClickstreamContext!
    private var session: Session!
    let testAppId = "testAppId"
    let testEndpoint = "https://example.com/collect"

    override func setUp() async throws {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        let contextConfiguration = ClickstreamContextConfiguration(appId: testAppId,
                                                                   endpoint: testEndpoint,
                                                                   sendEventsInterval: 10_000,
                                                                   isTrackAppExceptionEvents: false,
                                                                   isCompressEvents: false)
        clickstream = try ClickstreamContext(with: contextConfiguration)
        clickstream.networkMonitor = MockNetworkMonitor()
        eventRecorder = MockEventRecorder()
        session = Session(uniqueId: "uniqueId", sessionIndex: 1)
        analyticsClient = try AnalyticsClient(
            clickstream: clickstream,
            eventRecorder: eventRecorder,
            sessionProvider: {
                self.session
            }
        )
    }

    override func tearDown() async throws {
        analyticsClient = nil
        session = nil
        eventRecorder = nil
    }

    // MARK: - testGlobalAttribute

    func testAddGlobalAttributeSuccess() {
        analyticsClient.addGlobalAttribute("appStore", forKey: "channel")
        let globalAttributeCount = analyticsClient.globalAttributes.count
        let attributeValue = analyticsClient.globalAttributes["channel"] as? String
        XCTAssertEqual(globalAttributeCount, 1)
        XCTAssertEqual(attributeValue, "appStore")
    }

    func testAddGlobalAttributeForExceedNameLength() {
        let exceedName = String(repeating: "a", count: 51)
        analyticsClient.addGlobalAttribute("value", forKey: exceedName)
        Thread.sleep(forTimeInterval: 0.02)
        XCTAssertEqual(Event.PresetEvent.CLICKSTREAM_ERROR, eventRecorder.lastSavedEvent?.eventType)
        XCTAssertEqual(Event.ErrorCode.ATTRIBUTE_NAME_LENGTH_EXCEED, eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_CODE) as! Int)
    }

    func testAddGlobalAttributeForInvalidName() {
        let invalidName = "1_goods_expose"
        analyticsClient.addGlobalAttribute("value", forKey: invalidName)
        Thread.sleep(forTimeInterval: 0.02)
        XCTAssertEqual(Event.PresetEvent.CLICKSTREAM_ERROR, eventRecorder.lastSavedEvent?.eventType)
        XCTAssertEqual(Event.ErrorCode.ATTRIBUTE_NAME_INVALID, eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_CODE) as! Int)

        let errorValue = eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_MESSAGE) as! String
        XCTAssertTrue(errorValue.contains(invalidName))
    }

    func testAddGlobalAttributeForExceedValueLength() {
        let exceedValue = String(repeating: "a", count: 1_025)
        analyticsClient.addGlobalAttribute(exceedValue, forKey: "name01")
        Thread.sleep(forTimeInterval: 0.02)
        XCTAssertEqual(Event.PresetEvent.CLICKSTREAM_ERROR, eventRecorder.lastSavedEvent?.eventType)
        XCTAssertEqual(Event.ErrorCode.ATTRIBUTE_VALUE_LENGTH_EXCEED, eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_CODE) as! Int)
        let errorValue = eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_MESSAGE) as! String
        XCTAssertTrue(errorValue.contains("name01"))
    }

    func testRemoveGlobalAttribute() {
        analyticsClient.addGlobalAttribute("value1", forKey: "name01")
        analyticsClient.addGlobalAttribute("value2", forKey: "name02")
        analyticsClient.removeGlobalAttribute(forKey: "name01")
        let value1 = analyticsClient.globalAttributes["name01"]
        let value2 = analyticsClient.globalAttributes["name02"]
        XCTAssertNil(value1)
        XCTAssertNotNil(value2)
    }

    func testRemoveNonExistingGlobalAttribute() {
        for i in 0 ..< 500 {
            analyticsClient.addGlobalAttribute("value", forKey: "name\(i)")
        }
        analyticsClient.removeGlobalAttribute(forKey: "name1000")
        let globalAttributeCount = analyticsClient.globalAttributes.count
        XCTAssertEqual(500, globalAttributeCount)
    }

    func testAddGlobalAttributeForSizeExceed() {
        for i in 0 ..< 501 {
            analyticsClient.addGlobalAttribute("value", forKey: "name\(i)")
        }
        Thread.sleep(forTimeInterval: 0.02)
        XCTAssertEqual(Event.PresetEvent.CLICKSTREAM_ERROR, eventRecorder.lastSavedEvent?.eventType)
        XCTAssertEqual(Event.ErrorCode.ATTRIBUTE_SIZE_EXCEED, eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_CODE) as! Int)
        let errorValue = eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_MESSAGE) as! String

        XCTAssertTrue(errorValue.contains("name500"))
    }

    func testAddGlobalAttributeSameNameMultiTimes() {
        for i in 0 ..< 500 {
            analyticsClient.addGlobalAttribute("value\(i)", forKey: "name")
        }
        Thread.sleep(forTimeInterval: 0.02)
        XCTAssertEqual(0, eventRecorder.saveCount)
        let globalAttributeCount = analyticsClient.globalAttributes.count
        XCTAssertEqual(1, globalAttributeCount)
    }

    // MARK: - testUserAttribute

    func testAddUserAttributeSuccess() {
        analyticsClient.addUserAttribute("appStore", forKey: "userChannel")
        let userAttributeCount = analyticsClient.userAttributes.count
        let attributeValue = (analyticsClient.userAttributes["userChannel"] as! JsonObject)["value"] as? String
        XCTAssertEqual(userAttributeCount, 2)
        XCTAssertEqual(attributeValue, "appStore")
    }

    func testAddUserAttributeForExceedNameLength() {
        let exceedName = String(repeating: "a", count: 51)
        analyticsClient.addUserAttribute("value", forKey: exceedName)

        Thread.sleep(forTimeInterval: 0.02)
        XCTAssertEqual(Event.PresetEvent.CLICKSTREAM_ERROR, eventRecorder.lastSavedEvent?.eventType)
        XCTAssertEqual(Event.ErrorCode.USER_ATTRIBUTE_NAME_LENGTH_EXCEED, eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_CODE) as! Int)
        let errorValue = eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_MESSAGE) as! String
        XCTAssertTrue(errorValue.contains(exceedName))
    }

    func testAddUserAttributeForInvalidName() {
        let invalidName = "1_goods_expose"
        analyticsClient.addUserAttribute("value", forKey: invalidName)

        Thread.sleep(forTimeInterval: 0.02)
        XCTAssertEqual(Event.PresetEvent.CLICKSTREAM_ERROR, eventRecorder.lastSavedEvent?.eventType)
        XCTAssertEqual(Event.ErrorCode.USER_ATTRIBUTE_NAME_INVALID, eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_CODE) as! Int)
        let errorValue = eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_MESSAGE) as! String
        XCTAssertTrue(errorValue.contains(invalidName))
    }

    func testAddUserAttributeForExceedValueLength() {
        let exceedValue = String(repeating: "a", count: 257)
        analyticsClient.addUserAttribute(exceedValue, forKey: "name01")

        Thread.sleep(forTimeInterval: 0.02)
        XCTAssertEqual(Event.PresetEvent.CLICKSTREAM_ERROR, eventRecorder.lastSavedEvent?.eventType)
        XCTAssertEqual(Event.ErrorCode.USER_ATTRIBUTE_VALUE_LENGTH_EXCEED, eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_CODE) as! Int)
        let errorValue = eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_MESSAGE) as! String
        XCTAssertTrue(errorValue.contains("name01"))
    }

    func testRemoveUserAttribute() {
        analyticsClient.addUserAttribute("value1", forKey: "name01")
        analyticsClient.addUserAttribute("value2", forKey: "name02")
        analyticsClient.removeUserAttribute(forKey: "name01")
        let value1 = analyticsClient.userAttributes["name01"]
        let value2 = analyticsClient.userAttributes["name02"]
        XCTAssertNil(value1)
        XCTAssertNotNil(value2)
    }

    func testRemoveNonExistingUserAttribute() {
        for i in 0 ..< 100 {
            analyticsClient.addUserAttribute("value", forKey: "name\(i)")
        }
        analyticsClient.removeUserAttribute(forKey: "name1000")
        let userAttributeCount = analyticsClient.userAttributes.count
        XCTAssertEqual(100, userAttributeCount)
    }

    func testAddUserAttributeForSizeExceed() {
        for i in 0 ..< 101 {
            analyticsClient.addUserAttribute("value", forKey: "name\(i)")
        }
        Thread.sleep(forTimeInterval: 0.02)
        XCTAssertEqual(Event.PresetEvent.CLICKSTREAM_ERROR, eventRecorder.lastSavedEvent?.eventType)
        XCTAssertEqual(Event.ErrorCode.USER_ATTRIBUTE_SIZE_EXCEED, eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_CODE) as! Int)
        let errorValue = eventRecorder.lastSavedEvent?.attribute(forKey: Event.ReservedAttribute.ERROR_MESSAGE) as! String
        XCTAssertTrue(errorValue.contains("attribute name"))
    }

    func testAddUserAttributeSameNameMultiTimes() {
        for i in 0 ..< 100 {
            analyticsClient.addUserAttribute("value\(i)", forKey: "name")
        }
        Thread.sleep(forTimeInterval: 0.02)
        XCTAssertEqual(0, eventRecorder.saveCount)
        let userAttributeCount = analyticsClient.userAttributes.count
        XCTAssertEqual(2, userAttributeCount)
    }

    func testInitialvalueInAnalyticsClient() {
        let userId = analyticsClient.userId
        let userUniqueId = clickstream.userUniqueId
        XCTAssertNil(userId)
        XCTAssertNotNil(userUniqueId)
        let userAttribute = analyticsClient.userAttributes
        XCTAssertTrue(userAttribute.keys.contains(Event.ReservedAttribute.USER_FIRST_TOUCH_TIMESTAMP))
    }

    func testUpdateSameUserIdTwice() {
        let userIdForA = "aaa"
        let userUniqueId = clickstream.userUniqueId
        analyticsClient.updateUserId(userIdForA)
        analyticsClient.addUserAttribute(12, forKey: "user_age")
        analyticsClient.updateUserId(userIdForA)
        let userAttribute = analyticsClient.userAttributes
        XCTAssertTrue(userAttribute.keys.contains("user_age"))
        XCTAssertEqual(userUniqueId, clickstream.userUniqueId)
    }

    func testUpdateDifferentUserId() {
        let userIdForA = "aaa"
        let userIdForB = "bbb"
        let userUniqueId = clickstream.userUniqueId
        analyticsClient.updateUserId(userIdForA)
        analyticsClient.addUserAttribute(12, forKey: "user_age")
        analyticsClient.updateUserId(userIdForB)
        let userAttribute = analyticsClient.userAttributes
        XCTAssertFalse(userAttribute.keys.contains("user_age"))
        XCTAssertNotEqual(userUniqueId, clickstream.userUniqueId)
    }

    func testChangeToOriginUserId() {
        let userIdForA = "aaa"
        let userIdForB = "bbb"
        let userUniqueId = clickstream.userUniqueId
        analyticsClient.updateUserId(userIdForA)
        analyticsClient.updateUserId(userIdForB)
        let userUniqueIdB = clickstream.userUniqueId
        analyticsClient.updateUserId(userIdForA)
        XCTAssertEqual(userUniqueId, clickstream.userUniqueId)
        analyticsClient.updateUserId(userIdForB)
        XCTAssertEqual(userUniqueIdB, clickstream.userUniqueId)
    }

    // MARK: - testEvent

    func testCreateEvent() {
        let eventType = "testEvent"
        let event = analyticsClient.createEvent(withEventType: eventType)!
        XCTAssertEqual(event.eventType, eventType)
    }

    func testRecordRecordEventWithGlobalAttribute() async {
        let event = analyticsClient.createEvent(withEventType: "testEvent")!
        XCTAssertTrue(event.attributes.isEmpty)

        analyticsClient.addGlobalAttribute("test_0", forKey: "attribute_0")
        analyticsClient.addGlobalAttribute(0, forKey: "metric_0")
        analyticsClient.addGlobalAttribute(1, forKey: "metric_1")

        do {
            try await analyticsClient.record(event)
            XCTAssertEqual(eventRecorder.saveCount, 1)
            guard let savedEvent = eventRecorder.lastSavedEvent else {
                XCTFail("Expected saved event")
                return
            }

            XCTAssertEqual(savedEvent.attributes.count, 3)
            XCTAssertEqual(savedEvent.attributes["attribute_0"] as? String, "test_0")
            XCTAssertEqual(savedEvent.attributes["metric_0"] as? Int, 0)
            XCTAssertEqual(savedEvent.attributes["metric_1"] as? Int, 1)

        } catch {
            XCTFail("Unexpected exception while attempting to record event")
        }
    }

    func testRecordRecordEventWithUserAttribute() async {
        let event = analyticsClient.createEvent(withEventType: "testEvent")!
        XCTAssertTrue(event.attributes.isEmpty)

        analyticsClient.addUserAttribute("test_0", forKey: "attribute_0")
        analyticsClient.addUserAttribute(0, forKey: "metric_0")
        analyticsClient.addUserAttribute(1, forKey: "metric_1")

        do {
            try await analyticsClient.record(event)
            XCTAssertEqual(eventRecorder.saveCount, 1)
            guard let savedEvent = eventRecorder.lastSavedEvent else {
                XCTFail("Expected saved event")
                return
            }

            XCTAssertEqual(savedEvent.userAttributes.count, 4)
            XCTAssertEqual((savedEvent.userAttributes["attribute_0"] as! JsonObject)["value"] as? String, "test_0")
            XCTAssertEqual((savedEvent.userAttributes["metric_0"] as! JsonObject)["value"] as? Int, 0)
            XCTAssertEqual((savedEvent.userAttributes["metric_1"] as! JsonObject)["value"] as? Int, 1)

        } catch {
            XCTFail("Unexpected exception while attempting to record event")
        }
    }

    func testSubmit() {
        analyticsClient.submitEvents()
        XCTAssertEqual(eventRecorder.submitCount, 1)
    }
}
