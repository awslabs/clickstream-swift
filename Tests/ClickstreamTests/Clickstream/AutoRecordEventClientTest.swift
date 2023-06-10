//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Clickstream
import UIKit
import XCTest

class AutoRecordEventClientTest: XCTestCase {
    private var clickstream: ClickstreamContext!
    private var eventRecorder: MockEventRecorder!
    private var autoRecordEventClient: AutoRecordEventClient!
    let testAppId = "testAppId"
    let testEndpoint = "https://example.com/collect"

    override func setUp() async throws {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        let mockNetworkMonitor = MockNetworkMonitor()
        let contextConfiguration = ClickstreamContextConfiguration(appId: testAppId,
                                                                   endpoint: testEndpoint,
                                                                   sendEventsInterval: 10_000,
                                                                   isTrackAppExceptionEvents: false,
                                                                   isCompressEvents: false)
        clickstream = try ClickstreamContext(with: contextConfiguration)
        clickstream.networkMonitor = mockNetworkMonitor
        eventRecorder = MockEventRecorder()
        let analyticsClient = try AnalyticsClient(
            clickstream: clickstream,
            eventRecorder: eventRecorder,
            sessionProvider: { nil }
        )
        clickstream.analyticsClient = analyticsClient
        autoRecordEventClient = AutoRecordEventClient(clickstream: clickstream)
    }

    override func tearDown() {
        eventRecorder = nil
    }

    func testAppVersionUpdate() {
        autoRecordEventClient.checkAppVersionUpdate(clickstream: clickstream)
        XCTAssertNotNil(UserDefaultsUtil.getAppVersion(storage: clickstream.storage))
        clickstream.systemInfo.appVersion = "100.0.0"
        autoRecordEventClient.checkAppVersionUpdate(clickstream: clickstream)

        XCTAssertEqual("100.0.0", UserDefaultsUtil.getAppVersion(storage: clickstream.storage))
        XCTAssertTrue(eventRecorder.lastSavedEvent?.eventType == Event.PresetEvent.APP_UPDATE)
        XCTAssertNotNil(eventRecorder.lastSavedEvent?.attributes[Event.ReservedAttribute.PREVIOUS_APP_VERSION])

        autoRecordEventClient.checkAppVersionUpdate(clickstream: clickstream)
        XCTAssertNotNil(eventRecorder.saveCount == 1)
    }

    func testOSVersionUpdate() {
        autoRecordEventClient.checkOSVersionUpdate(clickstream: clickstream)
        XCTAssertNotNil(UserDefaultsUtil.getOSVersion(storage: clickstream.storage))
        clickstream.systemInfo.osVersion = "100.0.0"
        autoRecordEventClient.checkOSVersionUpdate(clickstream: clickstream)

        XCTAssertEqual("100.0.0", UserDefaultsUtil.getOSVersion(storage: clickstream.storage))
        XCTAssertTrue(eventRecorder.lastSavedEvent?.eventType == Event.PresetEvent.OS_UPDATE)
        XCTAssertNotNil(eventRecorder.lastSavedEvent?.attributes[Event.ReservedAttribute.PREVIOUS_OS_VERSION])

        autoRecordEventClient.checkOSVersionUpdate(clickstream: clickstream)
        XCTAssertNotNil(eventRecorder.saveCount == 1)
    }

    func testOneScreenView() {
        autoRecordEventClient.updateEngageTimestamp()
        autoRecordEventClient.setIsEntrances()
        let viewController = MockViewControllerA()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        XCTAssertTrue(viewController.viewDidAppearCalled)

        XCTAssertTrue(eventRecorder.saveCount == 1)
        XCTAssertTrue(eventRecorder.lastSavedEvent?.eventType == Event.PresetEvent.SCREEN_VIEW)
        XCTAssertNotNil(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.SCREEN_ID])
        XCTAssertNotNil(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.SCREEN_NAME])
        XCTAssertNotNil(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.ENGAGEMENT_TIMESTAMP])
        XCTAssertNil(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.PREVIOUS_SCREEN_ID])
        XCTAssertNil(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.PREVIOUS_SCREEN_NAME])
        XCTAssertTrue(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.ENTRANCES] as! Int == 1)
    }

    func testTwoScreenView() {
        autoRecordEventClient.updateEngageTimestamp()
        autoRecordEventClient.setIsEntrances()
        let viewControllerA = MockViewControllerA()
        let viewControllerB = MockViewControllerB()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewControllerA
        window.makeKeyAndVisible()
        window.rootViewController = viewControllerB
        window.makeKeyAndVisible()
        XCTAssertTrue(viewControllerA.viewDidAppearCalled)
        XCTAssertTrue(viewControllerB.viewDidAppearCalled)
        XCTAssertEqual(2, eventRecorder.saveCount)
        XCTAssertTrue(eventRecorder.lastSavedEvent!.eventType == Event.PresetEvent.SCREEN_VIEW)
        XCTAssertNotNil(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.SCREEN_ID])
        XCTAssertNotNil(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.SCREEN_NAME])
        XCTAssertNotNil(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.ENGAGEMENT_TIMESTAMP])
        XCTAssertNotNil(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.PREVIOUS_SCREEN_ID])
        XCTAssertNotNil(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.PREVIOUS_SCREEN_NAME])

        XCTAssertEqual(eventRecorder.savedEvents[0].attributes[Event.ReservedAttribute.SCREEN_NAME] as! String,
                       eventRecorder.savedEvents[1].attributes[Event.ReservedAttribute.PREVIOUS_SCREEN_NAME] as! String)

        XCTAssertEqual(eventRecorder.savedEvents[0].attributes[Event.ReservedAttribute.SCREEN_ID] as! String,
                       eventRecorder.savedEvents[1].attributes[Event.ReservedAttribute.PREVIOUS_SCREEN_ID] as! String)

        XCTAssertTrue(eventRecorder.lastSavedEvent!.attributes[Event.ReservedAttribute.ENTRANCES] as! Int == 0)
    }

    func testCloseRecordScreenView() {
        clickstream.configuration.isTrackScreenViewEvents = false
        autoRecordEventClient.updateEngageTimestamp()
        autoRecordEventClient.setIsEntrances()
        let viewController = MockViewControllerA()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        XCTAssertTrue(viewController.viewDidAppearCalled)
        XCTAssertTrue(eventRecorder.saveCount == 0)
    }
}
