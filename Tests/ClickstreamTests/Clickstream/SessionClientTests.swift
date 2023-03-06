//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Clickstream
import XCTest

class SessionClientTests: XCTestCase {
    private var client: SessionClient!

    private var activityTracker: MockActivityTracker!
    private var analyticsClient: MockAnalyticsClient!
    private var sessionTimeout: TimeInterval = 5

    override func setUp() {
        activityTracker = MockActivityTracker()
        analyticsClient = MockAnalyticsClient()
        createNewSessionClient()
    }

    override func tearDown() {
        activityTracker = nil
        analyticsClient = nil
        client = nil
    }

    func createNewSessionClient() {
        client = SessionClient(activityTracker: activityTracker,
                               configuration: SessionClientConfiguration(
                                   uniqueDeviceId: "deviceId",
                                   sessionBackgroundTimeout: sessionTimeout))
        client.analyticsClient = analyticsClient
    }

    func resetCounters() async {
        await analyticsClient.resetCounters()
        activityTracker.resetCounters()
    }

    func testCurrentSession_withoutStoredSession_shouldStartNewSession() async {
        let currentSession = client.currentSession
        XCTAssertFalse(currentSession.isPaused)
        XCTAssertNil(currentSession.stopTime)
        XCTAssertEqual(activityTracker.beginActivityTrackingCount, 0)
        await analyticsClient.setRecordExpectation(expectation(description: "Start event for new session"))
        await waitForExpectations(timeout: 1)
        let createEventCount = await analyticsClient.createEventCount
        XCTAssertEqual(createEventCount, 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 1)
    }

    func teststartSession_shouldRecordStartEvent() async {
        await resetCounters()

        await analyticsClient.setRecordExpectation(expectation(description: "Start event for new session"))
        client.startSession()
        await waitForExpectations(timeout: 1)
        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 1)
        guard let event = await analyticsClient.lastRecordedEvent else {
            XCTFail("Expected recorded event")
            return
        }
        XCTAssertEqual(event.eventType, Event.PresetEvent.SESSION_START)
    }

    #if !os(macOS)

        func testApplicationMovedToBackground_stale_shouldRecordStopEvent_andSubmit() async {
            client.startSession()
            await analyticsClient.setRecordExpectation(expectation(description: "Start event for new session"))
            await waitForExpectations(timeout: 1)

            await resetCounters()

            activityTracker.callback?(.runningInBackground(isStale: true))
            await analyticsClient.setRecordExpectation(expectation(description: "Stop event for current session"))
            await waitForExpectations(timeout: 1)

            let createCount = await analyticsClient.createEventCount
            XCTAssertEqual(createCount, 1)
            let recordCount = await analyticsClient.recordCount
            XCTAssertEqual(recordCount, 1)

            guard let event = await analyticsClient.lastRecordedEvent else {
                XCTFail("Expected recorded event")
                return
            }
            XCTAssertEqual(event.eventType, Event.PresetEvent.SESSION_STOP)
        }

        func testApplicationMovedToForeground_withNonPausedSession_shouldDoNothing() async {
            client.startSession()
            await analyticsClient.setRecordExpectation(expectation(description: "Start event for new session"))
            await waitForExpectations(timeout: 1)

            await resetCounters()
            activityTracker.callback?(.runningInForeground)
            let createCount = await analyticsClient.createEventCount
            XCTAssertEqual(createCount, 0)
            let recordCount = await analyticsClient.recordCount
            XCTAssertEqual(recordCount, 0)
            let event = await analyticsClient.lastRecordedEvent
            XCTAssertNil(event)
        }
    #endif
    func testApplicationTerminated_shouldRecordStopEvent() async {
        client.startSession()
        await analyticsClient.setRecordExpectation(expectation(description: "Start event for new session"))
        await waitForExpectations(timeout: 1)

        await resetCounters()
        await analyticsClient.setRecordExpectation(expectation(description: "Stop event for current session"))
        activityTracker.callback?(.terminated)
        await waitForExpectations(timeout: 1)

        let createCount = await analyticsClient.createEventCount
        XCTAssertEqual(createCount, 1)
        let recordCount = await analyticsClient.recordCount
        XCTAssertEqual(recordCount, 1)
        guard let event = await analyticsClient.lastRecordedEvent else {
            XCTFail("Expected recorded event")
            return
        }
        XCTAssertEqual(event.eventType, Event.PresetEvent.SESSION_STOP)
        let submitCount = await analyticsClient.submitEventsCount
        XCTAssertEqual(submitCount, 0)
    }
}
