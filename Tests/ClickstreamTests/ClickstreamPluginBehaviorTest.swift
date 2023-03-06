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
    let testProperty: ClickstreamAttribute = [
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
        await analyticsClient.setAddUserAttributeExpectation(expectation(description: "Identify user"), count: 3)
        analyticsPlugin.identifyUser(userId: "testUserId", userProfile: userProfile)
        await waitForExpectations(timeout: 1)
        let addCount = await analyticsClient.addUserAttributeCount
        XCTAssertEqual(3, addCount)
    }

    func testIdentifyUserForNilUserId() async {
        await analyticsClient.setRemoveUserAttributeExpectation(expectation(description: "Identify user set user id nil"), count: 1)
        analyticsPlugin.identifyUser(userId: Event.User.USER_ID_NIL, userProfile: nil)
        await waitForExpectations(timeout: 1)
        let addCount = await analyticsClient.removeUserAttributeCount
        XCTAssertEqual(1, addCount)
    }

    func testRecordEvent() async {
        await analyticsClient.setRecordExpectation(expectation(description: "record event"))
        let event = BaseClickstreamEvent(name: "testEvent", properties: testProperty)
        analyticsPlugin.record(event: event)
        await waitForExpectations(timeout: 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(1, recordCount)
    }

    func testRecordEventWhenIsEnableFalse() async {
        analyticsPlugin.isEnabled = false
        let event = BaseClickstreamEvent(name: "testName", properties: testProperty)
        analyticsPlugin.record(event: event)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(0, recordCount)
    }

    func testRecordEventWithName() async {
        await analyticsClient.setRecordExpectation(expectation(description: "record event"))
        analyticsPlugin.record(eventWithName: "testEvent")
        await waitForExpectations(timeout: 1)
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
        await analyticsClient.setAddGlobalAttributeExpectation(expectation(description: "add global attribute"), count: 4)
        analyticsPlugin.registerGlobalProperties(testProperty)
        await waitForExpectations(timeout: 1)
        let addGlobalAttributeCallCount = await analyticsClient.addGlobalAttributeCalls.count
        XCTAssertEqual(addGlobalAttributeCallCount, testProperty.count)
    }

    func testUnregisterGlobalAttribute() async {
        await analyticsClient.setRemoveGlobalAttributeExpectation(expectation(description: "add global attribute"), count: 4)
        analyticsPlugin.unregisterGlobalProperties(Set<String>(testProperty.keys))
        await waitForExpectations(timeout: 1)
        let removeGlobalAttributeCallCount = await analyticsClient.removeGlobalAttributeCalls.count
        XCTAssertEqual(removeGlobalAttributeCallCount, testProperty.count)
    }

    func testFlushEvent() async {
        await analyticsClient.setSubmitEventsExpectation(expectation(description: "flush event"), count: 1)
        analyticsPlugin.flushEvents()
        await waitForExpectations(timeout: 1)
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
