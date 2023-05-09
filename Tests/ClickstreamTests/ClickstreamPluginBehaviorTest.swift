//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import Clickstream
import XCTest

class ClickstreamPluginBehaviorTest: ClickstreamPluginTestBase {
    var analyticsClient: MockAnalyticsClient!
    let testAttribute: ClickstreamAttribute = [
        "isSuccess": true,
        "userName": "carl",
        "userAge": 12,
        "score": 85.5,
    ]

    override func setUp() async throws {
        try await super.setUp()
        analyticsClient = MockAnalyticsClient()
        analyticsPlugin.analyticsClient = analyticsClient
    }

    func testIdentifyUser() async {
        let userProfile = AnalyticsUserProfile(location: nil, properties: [
            "user_age": 22,
            "user_name": "carl",
        ])
        let expectation = expectation(description: "Identify user")
        await analyticsClient.setAddUserAttributeExpectation(expectation, count: 2)
        analyticsPlugin.identifyUser(userId: Event.User.USER_ID_EMPTY, userProfile: userProfile)
        await fulfillment(of: [expectation], timeout: 1)
        let addCount = await analyticsClient.addUserAttributeCount
        XCTAssertEqual(2, addCount)
    }

    func testUpdateUserAttributes() async {
        let userProfile = AnalyticsUserProfile(location: nil, properties: [
            "user_age": 22,
            "user_name": "carl",
        ])
        let expectation = expectation(description: "Identify user")
        await analyticsClient.setUpdateUserAttributesExpectation(expectation, count: 1)
        analyticsPlugin.identifyUser(userId: Event.User.USER_ID_EMPTY, userProfile: userProfile)
        await fulfillment(of: [expectation], timeout: 1)
        let updateCount = await analyticsClient.updateUserAttributeCount
        XCTAssertEqual(1, updateCount)
    }

    func testIdentifyUserForSetUserId() async {
        let expectation = expectation(description: "Identify user set user id not nil")
        await analyticsClient.setUpdateUserIdExpectation(expectation, count: 1)
        analyticsPlugin.identifyUser(userId: "13231", userProfile: nil)
        await fulfillment(of: [expectation], timeout: 1)
        let updateCount = await analyticsClient.updateUserIdCount
        XCTAssertEqual(1, updateCount)
    }

    func testIdentifyUserForNilUserId() async {
        let expectation = expectation(description: "Identify user set user id not nil")
        await analyticsClient.setUpdateUserIdExpectation(expectation, count: 1)
        analyticsPlugin.identifyUser(userId: Event.User.USER_ID_NIL, userProfile: nil)
        await fulfillment(of: [expectation], timeout: 1)
        let updateCount = await analyticsClient.updateUserIdCount
        XCTAssertEqual(1, updateCount)
    }

    func testUpdateUserAttributesForUserIdUpdate() async {
        let expectation = expectation(description: "Identify user")
        await analyticsClient.setUpdateUserAttributesExpectation(expectation, count: 1)
        analyticsPlugin.identifyUser(userId: "13231", userProfile: nil)
        await fulfillment(of: [expectation], timeout: 1)
        let updateCount = await analyticsClient.updateUserAttributeCount
        XCTAssertEqual(1, updateCount)
    }

    func testRecordEvent() async {
        let expectation = expectation(description: "record event")
        await analyticsClient.setRecordExpectation(expectation)
        let event = BaseClickstreamEvent(name: "testEvent", attribute: testAttribute)
        analyticsPlugin.record(event: event)
        await fulfillment(of: [expectation], timeout: 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(1, recordCount)
    }

    func testRecordEventWhenIsEnableFalse() async {
        analyticsPlugin.isEnabled = false
        let event = BaseClickstreamEvent(name: "testName", attribute: testAttribute)
        analyticsPlugin.record(event: event)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(0, recordCount)
    }

    func testRecordEventWithName() async {
        let expectation = expectation(description: "record event")
        await analyticsClient.setRecordExpectation(expectation)
        analyticsPlugin.record(eventWithName: "testEvent")
        await fulfillment(of: [expectation], timeout: 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(1, recordCount)
    }

    func testRecordEventWithNameWhenIsEnableFalse() async {
        analyticsPlugin.isEnabled = false
        analyticsPlugin.record(eventWithName: "testEvent")
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(0, recordCount)
    }

    func testRegisterGlobalAttribute() async {
        let expectation = expectation(description: "add global attribute")
        await analyticsClient.setAddGlobalAttributeExpectation(expectation, count: 4)
        analyticsPlugin.registerGlobalProperties(testAttribute)
        await fulfillment(of: [expectation], timeout: 1)
        let addGlobalAttributeCallCount = await analyticsClient.addGlobalAttributeCalls.count
        XCTAssertEqual(addGlobalAttributeCallCount, testAttribute.count)
    }

    func testUnregisterGlobalAttribute() async {
        let expectation = expectation(description: "add global attribute")
        await analyticsClient.setRemoveGlobalAttributeExpectation(expectation, count: 4)
        analyticsPlugin.unregisterGlobalProperties(Set<String>(testAttribute.keys))
        await fulfillment(of: [expectation], timeout: 1)
        let removeGlobalAttributeCallCount = await analyticsClient.removeGlobalAttributeCalls.count
        XCTAssertEqual(removeGlobalAttributeCallCount, testAttribute.count)
    }

    func testFlushEvent() async {
        let expectation = expectation(description: "flush event")
        await analyticsClient.setSubmitEventsExpectation(expectation, count: 1)
        analyticsPlugin.flushEvents()
        await fulfillment(of: [expectation], timeout: 1)
        let submitEventsCount = await analyticsClient.submitEventsCount
        XCTAssertEqual(1, submitEventsCount)
    }

    func testFlushEventWhenIsEnableFalse() async {
        analyticsPlugin.isEnabled = false
        analyticsPlugin.flushEvents()
        let submitEventsCount = await analyticsClient.submitEventsCount
        XCTAssertEqual(0, submitEventsCount)
    }

    func testFlushEventWhenNetworkIsOffline() async {
        mockNetworkMonitor.isOnline = false
        analyticsPlugin.flushEvents()
        let submitEventsCount = await analyticsClient.submitEventsCount
        XCTAssertEqual(0, submitEventsCount)
    }

    func testEnable() {
        analyticsPlugin.enable()
        XCTAssertTrue(analyticsPlugin.isEnabled)
    }

    func testDisable() {
        analyticsPlugin.disable()
        XCTAssertFalse(analyticsPlugin.isEnabled)
    }
}
