//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Clickstream
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
}
