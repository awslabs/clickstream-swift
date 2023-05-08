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
        session = Session(uniqueId: "uniqueId",sessionIndex: 1)
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

    func testAddGlobalAttributeSuccess() async {
        await analyticsClient.addGlobalAttribute("appStore", forKey: "channel")
        let globalAttributeCount = await analyticsClient.globalAttributes.count
        let attributeValue = await analyticsClient.globalAttributes["channel"] as? String
        XCTAssertEqual(globalAttributeCount, 1)
        XCTAssertEqual(attributeValue, "appStore")
    }

    func testAddGlobalAttributeForExceedNameLength() async {
        let exceedName = String(repeating: "a", count: 51)
        await analyticsClient.addGlobalAttribute("value", forKey: exceedName)
        let errorValue = await analyticsClient.globalAttributes["_error_name_length_exceed"] as? String
        XCTAssertNotNil(errorValue)
        XCTAssertTrue(errorValue!.contains(exceedName))
    }

    func testAddGlobalAttributeForInvalidName() async {
        let invalidName = "1_goods_expose"
        await analyticsClient.addGlobalAttribute("value", forKey: invalidName)
        let errorValue = await analyticsClient.globalAttributes["_error_name_invalid"] as? String
        XCTAssertNotNil(errorValue)
        XCTAssertTrue(errorValue!.contains(invalidName))
    }

    func testAddGlobalAttributeForExceedValueLength() async {
        let exceedValue = String(repeating: "a", count: 1_025)
        await analyticsClient.addGlobalAttribute(exceedValue, forKey: "name01")
        let errorValue = await analyticsClient.globalAttributes["_error_value_length_exceed"] as? String
        XCTAssertNotNil(errorValue)
        XCTAssertTrue(errorValue!.contains("name01"))
        XCTAssertTrue(errorValue!.contains("attribute value:"))
    }

    func testRemoveGlobalAttribute() async {
        await analyticsClient.addGlobalAttribute("value1", forKey: "name01")
        await analyticsClient.addGlobalAttribute("value2", forKey: "name02")
        await analyticsClient.removeGlobalAttribute(forKey: "name01")
        let value1 = await analyticsClient.globalAttributes["name01"]
        let value2 = await analyticsClient.globalAttributes["name02"]
        XCTAssertNil(value1)
        XCTAssertNotNil(value2)
    }

    func testRemoveNonExistingGlobalAttribute() async {
        for i in 0 ..< 500 {
            await analyticsClient.addGlobalAttribute("value", forKey: "name\(i)")
        }
        await analyticsClient.removeGlobalAttribute(forKey: "name1000")
        let globalAttributeCount = await analyticsClient.globalAttributes.count
        XCTAssertEqual(500, globalAttributeCount)
    }

    func testAddGlobalAttributeForSizeExceed() async {
        for i in 0 ..< 501 {
            await analyticsClient.addGlobalAttribute("value", forKey: "name\(i)")
        }
        let sizeExceedValue = await analyticsClient.globalAttributes["_error_attribute_size_exceed"] as? String
        XCTAssertNotNil(sizeExceedValue)
        XCTAssertTrue(sizeExceedValue!.contains("name500"))
    }

    func testAddGlobalAttributeSameNameMultiTimes() async {
        for i in 0 ..< 500 {
            await analyticsClient.addGlobalAttribute("value\(i)", forKey: "name")
        }
        let sizeExceedValue = await analyticsClient.globalAttributes["_error_attribute_size_exceed"]
        XCTAssertNil(sizeExceedValue)
        let globalAttributeCount = await analyticsClient.globalAttributes.count
        XCTAssertEqual(1, globalAttributeCount)
    }

    // MARK: - testUserAttribute

    func testAddUserAttributeSuccess() async {
        await analyticsClient.addUserAttribute("appStore", forKey: "userChannel")
        let userAttributeCount = await analyticsClient.userAttributes.count
        let attributeValue = await (analyticsClient.userAttributes["userChannel"] as! JsonObject)["value"] as? String
        XCTAssertEqual(userAttributeCount, 2)
        XCTAssertEqual(attributeValue, "appStore")
    }

    func testAddUserAttributeForExceedNameLength() async {
        let exceedName = String(repeating: "a", count: 51)
        await analyticsClient.addUserAttribute("value", forKey: exceedName)
        let errorValue = await analyticsClient.globalAttributes["_error_name_length_exceed"] as? String
        XCTAssertNotNil(errorValue)
        XCTAssertTrue(errorValue!.contains(exceedName))
    }

    func testAddUserAttributeForInvalidName() async {
        let invalidName = "1_goods_expose"
        await analyticsClient.addUserAttribute("value", forKey: invalidName)
        let errorValue = await analyticsClient.globalAttributes["_error_name_invalid"] as? String
        XCTAssertNotNil(errorValue)
        XCTAssertTrue(errorValue!.contains(invalidName))
    }

    func testAddUserAttributeForExceedValueLength() async {
        let exceedValue = String(repeating: "a", count: 257)
        await analyticsClient.addUserAttribute(exceedValue, forKey: "name01")
        let errorValue = await analyticsClient.globalAttributes["_error_value_length_exceed"] as? String
        XCTAssertNotNil(errorValue)
        XCTAssertTrue(errorValue!.contains("name01"))
        XCTAssertTrue(errorValue!.contains("attribute value:"))
    }

    func testRemoveUserAttribute() async {
        await analyticsClient.addUserAttribute("value1", forKey: "name01")
        await analyticsClient.addUserAttribute("value2", forKey: "name02")
        await analyticsClient.removeUserAttribute(forKey: "name01")
        let value1 = await analyticsClient.userAttributes["name01"]
        let value2 = await analyticsClient.userAttributes["name02"]
        XCTAssertNil(value1)
        XCTAssertNotNil(value2)
    }

    func testRemoveNonExistingUserAttribute() async {
        for i in 0 ..< 100 {
            await analyticsClient.addUserAttribute("value", forKey: "name\(i)")
        }
        await analyticsClient.removeUserAttribute(forKey: "name1000")
        let userAttributeCount = await analyticsClient.userAttributes.count
        XCTAssertEqual(100, userAttributeCount)
    }

    func testAddUserAttributeForSizeExceed() async {
        for i in 0 ..< 101 {
            await analyticsClient.addUserAttribute("value", forKey: "name\(i)")
        }
        let sizeExceedValue = await analyticsClient.globalAttributes["_error_attribute_size_exceed"] as? String
        XCTAssertNotNil(sizeExceedValue)
        XCTAssertTrue(sizeExceedValue!.contains("name100"))
    }

    func testAddUserAttributeSameNameMultiTimes() async {
        for i in 0 ..< 100 {
            await analyticsClient.addUserAttribute("value\(i)", forKey: "name")
        }
        let sizeExceedValue = await analyticsClient.globalAttributes["_error_attribute_size_exceed"]
        XCTAssertNil(sizeExceedValue)
        let userAttributeCount = await analyticsClient.userAttributes.count
        XCTAssertEqual(2, userAttributeCount)
    }

    func testInitialvalueInAnalyticsClient() async {
        let userId = await analyticsClient.userId
        let userUniqueId = clickstream.userUniqueId
        XCTAssertNil(userId)
        XCTAssertNotNil(userUniqueId)
        let userAttribute = await analyticsClient.userAttributes
        XCTAssertTrue(userAttribute.keys.contains(Event.ReservedAttribute.USER_FIRST_TOUCH_TIMESTAMP))
    }

    func testUpdateSameUserIdTwice() async {
        let userIdForA = "aaa"
        let userUniqueId = clickstream.userUniqueId
        await analyticsClient.updateUserId(userIdForA)
        await analyticsClient.addUserAttribute(12, forKey: "user_age")
        await analyticsClient.updateUserId(userIdForA)
        let userAttribute = await analyticsClient.userAttributes
        XCTAssertTrue(userAttribute.keys.contains("user_age"))
        XCTAssertEqual(userUniqueId, clickstream.userUniqueId)
    }

    func testUpdateDifferentUserId() async {
        let userIdForA = "aaa"
        let userIdForB = "bbb"
        let userUniqueId = clickstream.userUniqueId
        await analyticsClient.updateUserId(userIdForA)
        await analyticsClient.addUserAttribute(12, forKey: "user_age")
        await analyticsClient.updateUserId(userIdForB)
        let userAttribute = await analyticsClient.userAttributes
        XCTAssertFalse(userAttribute.keys.contains("user_age"))
        XCTAssertNotEqual(userUniqueId, clickstream.userUniqueId)
    }

    func testChangeToOriginUserId() async {
        let userIdForA = "aaa"
        let userIdForB = "bbb"
        let userUniqueId = clickstream.userUniqueId
        await analyticsClient.updateUserId(userIdForA)
        await analyticsClient.updateUserId(userIdForB)
        let userUniqueIdB = clickstream.userUniqueId
        await analyticsClient.updateUserId(userIdForA)
        XCTAssertEqual(userUniqueId, clickstream.userUniqueId)
        await analyticsClient.updateUserId(userIdForB)
        XCTAssertEqual(userUniqueIdB, clickstream.userUniqueId)
    }

    // MARK: - testEvent

    func testCreateEvent() {
        let eventType = "testEvent"
        let event = analyticsClient.createEvent(withEventType: eventType)
        XCTAssertEqual(event.eventType, eventType)
    }

    func testRecordRecordEventWithGlobalAttribute() async {
        let event = analyticsClient.createEvent(withEventType: "testEvent")
        XCTAssertTrue(event.attributes.isEmpty)

        await analyticsClient.addGlobalAttribute("test_0", forKey: "attribute_0")
        await analyticsClient.addGlobalAttribute(0, forKey: "metric_0")
        await analyticsClient.addGlobalAttribute(1, forKey: "metric_1")

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
        let event = analyticsClient.createEvent(withEventType: "testEvent")
        XCTAssertTrue(event.attributes.isEmpty)

        await analyticsClient.addUserAttribute("test_0", forKey: "attribute_0")
        await analyticsClient.addUserAttribute(0, forKey: "metric_0")
        await analyticsClient.addUserAttribute(1, forKey: "metric_1")

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

    func testSubmit() async {
        do {
            try await analyticsClient.submitEvents()
            XCTAssertEqual(eventRecorder.submitCount, 1)
        } catch {
            XCTFail("Unexpected exception while attempting to submit events")
        }
    }
}
