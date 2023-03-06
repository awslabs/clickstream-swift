//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import Clickstream
import XCTest

class ClickstreamPluginTestBase: XCTestCase {
    var analyticsPlugin: AWSClickstreamPlugin!
    var mockNetworkMonitor: MockNetworkMonitor!
    let testAppId = "testAppId"
    let testEndpoint = "https://yourhost/collect"

    override func setUp() async throws {
        mockNetworkMonitor = MockNetworkMonitor()
        analyticsPlugin = AWSClickstreamPlugin()
        let contextConfiguration = ClickstreamContextConfiguration(appId: testAppId,
                                                                   endpoint: testEndpoint,
                                                                   sendEventsInterval: 10000,
                                                                   isTrackAppExceptionEvents: false,
                                                                   isCompressEvents: false)
        let clickstream = try ClickstreamContext(with: contextConfiguration)

        let sessionClient = SessionClient(configuration: .init(uniqueDeviceId: clickstream.uniqueId,
                                                               sessionBackgroundTimeout: TimeInterval(10)),
                                          userDefaults: clickstream.storage.userDefaults)
        clickstream.sessionClient = sessionClient
        let sessionProvider: () -> Session = { [weak sessionClient] in
            guard let sessionClient else {
                fatalError("SessionClient was deallocated")
            }
            return sessionClient.currentSession
        }

        let eventRecorder = try EventRecorder(clickstream: clickstream)
        let analyticsClient = try AnalyticsClient(clickstream: clickstream,
                                                  eventRecorder: eventRecorder,
                                                  sessionProvider: sessionProvider)
        analyticsPlugin.analyticsClient = analyticsClient
        clickstream.analyticsClient = analyticsClient
        sessionClient.analyticsClient = analyticsClient
        clickstream.networkMonitor = mockNetworkMonitor

        analyticsPlugin.configure(clickstream: clickstream,
                                  autoFlushEventsTimer: nil,
                                  networkMonitor: mockNetworkMonitor)
        sessionClient.startSession()

        await Amplify.reset()
        let config = AmplifyConfiguration()
        do {
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
        analyticsPlugin.reset()
    }
}
