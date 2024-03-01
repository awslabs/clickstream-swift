//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Clickstream
import XCTest

class SessionClientTests: XCTestCase {
    private var sessionClient: SessionClient!
    private var eventRecorder: MockEventRecorder!
    private var activityTracker: MockActivityTracker!
    var mockNetworkMonitor: MockNetworkMonitor!
    private var analyticsClient: AnalyticsClient!
    private var clickstream: ClickstreamContext!
    let testAppId = "testAppId"
    let testEndpoint = "https://example.com/collect"

    override func setUp() async throws {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        activityTracker = MockActivityTracker()
        mockNetworkMonitor = MockNetworkMonitor()
        let contextConfiguration = ClickstreamContextConfiguration(appId: testAppId,
                                                                   endpoint: testEndpoint,
                                                                   sendEventsInterval: 10_000,
                                                                   isTrackAppExceptionEvents: false,
                                                                   isCompressEvents: false)
        clickstream = try ClickstreamContext(with: contextConfiguration)
        clickstream.networkMonitor = mockNetworkMonitor
        sessionClient = SessionClient(activityTracker: activityTracker, clickstream: clickstream)
        clickstream.sessionClient = sessionClient

        eventRecorder = MockEventRecorder()

        let sessionProvider: () -> Session? = { [weak sessionClient] in
            guard let sessionClient else {
                fatalError("SessionClient was deallocated")
            }
            return sessionClient.getCurrentSession()
        }

        analyticsClient = try AnalyticsClient(
            clickstream: clickstream,
            eventRecorder: eventRecorder,
            sessionProvider: sessionProvider
        )
        clickstream.analyticsClient = analyticsClient
    }

    override func tearDown() {
        activityTracker = nil
        sessionClient = nil
        eventRecorder = nil
        activityTracker?.resetCounters()
    }

    func testGetCurrentSession() {
        let session = Session.getCurrentSession(clickstream: clickstream)
        XCTAssertTrue(session.isNewSession)
        XCTAssertTrue(session.sessionIndex == 1)
        XCTAssertNotNil(session.sessionId)
        XCTAssertNotNil(session.startTime)
    }

    func testRunningInForeground() {
        XCTAssertTrue(sessionClient.getCurrentSession() == nil)
        activityTracker.callback?(.runningInForeground)
        let session = sessionClient.getCurrentSession()!
        XCTAssertTrue(session.isNewSession)
        XCTAssertTrue(session.sessionIndex == 1)
        XCTAssertNotNil(session.sessionId)
        XCTAssertNotNil(session.startTime)

        Thread.sleep(forTimeInterval: 0.1)
        let events = eventRecorder.savedEvents
        XCTAssertEqual(3, events.count)
        XCTAssertEqual(Event.PresetEvent.FIRST_OPEN, events[0].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_START, events[1].eventType)
        XCTAssertEqual(Event.PresetEvent.SESSION_START, events[2].eventType)
    }

    func testGoBackground() {
        XCTAssertTrue(sessionClient.getCurrentSession() == nil)
        activityTracker.callback?(.runningInForeground)
        Thread.sleep(forTimeInterval: 0.1)
        activityTracker.callback?(.runningInBackground)
        let session = sessionClient.getCurrentSession()!
        XCTAssertTrue(session.pauseTime != nil)
        let storedSession = UserDefaultsUtil.getSession(storage: clickstream.storage)
        XCTAssertTrue(storedSession != nil)

        let events = eventRecorder.savedEvents
        XCTAssertEqual(4, events.count)
        XCTAssertEqual(Event.PresetEvent.FIRST_OPEN, events[0].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_START, events[1].eventType)
        XCTAssertEqual(Event.PresetEvent.SESSION_START, events[2].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_END, events[3].eventType)
        XCTAssertNil(events[3].attributes[Event.ReservedAttribute.SCREEN_ID])
        XCTAssertNil(events[3].attributes[Event.ReservedAttribute.SCREEN_NAME])
    }

    func testGoBackgroundWithUserEngagement() {
        activityTracker.callback?(.runningInForeground)
        let viewControllerA = MockViewControllerA()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewControllerA
        window.makeKeyAndVisible()

        sessionClient.autoRecordClient.updateLastScreenStartTimestamp(Date().millisecondsSince1970 - 1_100)
        activityTracker.callback?(.runningInBackground)

        let session = sessionClient.getCurrentSession()!
        XCTAssertTrue(session.pauseTime != nil)
        let storedSession = UserDefaultsUtil.getSession(storage: clickstream.storage)
        XCTAssertTrue(storedSession != nil)
        Thread.sleep(forTimeInterval: 0.1)
        let events = eventRecorder.savedEvents
        XCTAssertEqual(6, events.count)
        XCTAssertEqual(Event.PresetEvent.FIRST_OPEN, events[0].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_START, events[1].eventType)
        XCTAssertEqual(Event.PresetEvent.SESSION_START, events[2].eventType)
        XCTAssertEqual(Event.PresetEvent.SCREEN_VIEW, events[3].eventType)
        XCTAssertEqual(Event.PresetEvent.USER_ENGAGEMENT, events[4].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_END, events[5].eventType)
        XCTAssertNotNil(events[5].attributes[Event.ReservedAttribute.SCREEN_NAME])
        XCTAssertNotNil(events[5].attributes[Event.ReservedAttribute.SCREEN_UNIQUEID])
    }

    func testReturnToForeground() {
        activityTracker.callback?(.runningInForeground)
        let session1 = sessionClient.getCurrentSession()!
        XCTAssertTrue(session1.isNewSession)
        activityTracker.callback?(.runningInBackground)
        activityTracker.callback?(.runningInForeground)
        let session2 = sessionClient.getCurrentSession()!
        XCTAssertTrue(session1.sessionId == session2.sessionId)
        XCTAssertFalse(session2.isNewSession)
    }

    func testReturnToForegroundWithSessionTimeout() {
        clickstream.configuration.sessionTimeoutDuration = 0
        activityTracker.callback?(.runningInForeground)
        let session1 = sessionClient.getCurrentSession()!
        XCTAssertTrue(session1.isNewSession)
        activityTracker.callback?(.runningInBackground)
        activityTracker.callback?(.runningInForeground)
        let session2 = sessionClient.getCurrentSession()!
        XCTAssertTrue(session1.sessionIndex != session2.sessionIndex)
        XCTAssertTrue(session2.isNewSession)
        XCTAssertTrue(session2.sessionIndex == 2)

        Thread.sleep(forTimeInterval: 0.1)
        let events = eventRecorder.savedEvents
        XCTAssertEqual(6, events.count)
        XCTAssertEqual(Event.PresetEvent.FIRST_OPEN, events[0].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_START, events[1].eventType)
        XCTAssertEqual(Event.PresetEvent.SESSION_START, events[2].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_END, events[3].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_START, events[4].eventType)
        XCTAssertEqual(Event.PresetEvent.SESSION_START, events[5].eventType)
    }

    func testReturnToForegroundWithScreenView() {
        activityTracker.callback?(.runningInForeground)
        let viewController = MockViewControllerA()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        activityTracker.callback?(.runningInBackground)
        activityTracker.callback?(.runningInForeground)
        Thread.sleep(forTimeInterval: 0.1)
        let events = eventRecorder.savedEvents
        XCTAssertEqual(6, events.count)
        XCTAssertEqual(Event.PresetEvent.FIRST_OPEN, events[0].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_START, events[1].eventType)
        XCTAssertTrue(events[1].attributes[Event.ReservedAttribute.IS_FIRST_TIME] as! Bool)

        XCTAssertEqual(Event.PresetEvent.SESSION_START, events[2].eventType)
        XCTAssertEqual(Event.PresetEvent.SCREEN_VIEW, events[3].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_END, events[4].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_START, events[5].eventType)
        let appStartEvent = events[5]
        XCTAssertNotNil(appStartEvent.attributes[Event.ReservedAttribute.SCREEN_NAME])
        XCTAssertFalse(appStartEvent.attributes[Event.ReservedAttribute.IS_FIRST_TIME] as! Bool)
    }
    
    func testReopenAppAfterSessionTimeoutWillRecordScreenView() {
        clickstream.configuration.sessionTimeoutDuration = 0
        activityTracker.callback?(.runningInForeground)
        let viewController = MockViewControllerA()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        activityTracker.callback?(.runningInBackground)
        activityTracker.callback?(.runningInForeground)
        Thread.sleep(forTimeInterval: 0.1)
        let events = eventRecorder.savedEvents
        XCTAssertEqual(8, events.count)
        XCTAssertEqual(Event.PresetEvent.FIRST_OPEN, events[0].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_START, events[1].eventType)
        XCTAssertEqual(Event.PresetEvent.SESSION_START, events[2].eventType)
        XCTAssertEqual(Event.PresetEvent.SCREEN_VIEW, events[3].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_END, events[4].eventType)
        XCTAssertEqual(Event.PresetEvent.APP_START, events[5].eventType)
        XCTAssertEqual(Event.PresetEvent.SESSION_START, events[6].eventType)
        
        XCTAssertEqual(Event.PresetEvent.SCREEN_VIEW, events[7].eventType)
        XCTAssertNotNil(events[7].attributes[Event.ReservedAttribute.SCREEN_NAME])
        XCTAssertNotNil(events[7].attributes[Event.ReservedAttribute.SCREEN_ID])
        XCTAssertNotNil(events[7].attributes[Event.ReservedAttribute.SCREEN_UNIQUEID])
        XCTAssertNil(events[7].attributes[Event.ReservedAttribute.PREVIOUS_SCREEN_NAME])
        XCTAssertNil(events[7].attributes[Event.ReservedAttribute.PREVIOUS_SCREEN_ID])
        XCTAssertNil(events[7].attributes[Event.ReservedAttribute.PREVIOUS_SCREEN_UNIQUEID])
        XCTAssertEqual(1, events[7].attributes[Event.ReservedAttribute.ENTRANCES] as! Int)
    }

    func testLastScreenStartTimeStampUpdatedAfterReturnToForeground() {
        activityTracker.callback?(.runningInForeground)
        let viewController = MockViewControllerA()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        activityTracker.callback?(.runningInBackground)
        sessionClient.autoRecordClient.updateLastScreenStartTimestamp(Date().millisecondsSince1970 - 1_100)
        activityTracker.callback?(.runningInForeground)
        XCTAssertTrue(Date().millisecondsSince1970 - sessionClient.autoRecordClient.lastScreenStartTimestamp < 200)
    }

    func testDisableSDKWillNotRecordSessionEvents() {
        clickstream.isEnable = false
        activityTracker.callback?(.runningInForeground)
        Thread.sleep(forTimeInterval: 0.1)
        let events = eventRecorder.savedEvents
        XCTAssertEqual(0, events.count)
    }
}
