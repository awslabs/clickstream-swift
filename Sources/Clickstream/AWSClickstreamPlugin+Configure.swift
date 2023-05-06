//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Network

public extension AWSClickstreamPlugin {
    /// called when sdk init.
    func configure(using configuration: Any?) throws {
        guard let config = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError(
                "Unable to decode configuration",
                "Make sure the plugin configuration is JSONValue"
            )
        }
        let pluginConfiguration = try AWSClickstreamConfiguration(config)
        try configure(using: pluginConfiguration)
    }

    /// Configure AWSClickstreamPlugin programatically using AWSClickstreamConfiguration
    func configure(using configuration: AWSClickstreamConfiguration) throws {
        let contextConfiguration = ClickstreamContextConfiguration(appId: configuration.appId,
                                                                   endpoint: configuration.endpoint,
                                                                   sendEventsInterval: configuration.sendEventsInterval,
                                                                   isTrackAppExceptionEvents:
                                                                   configuration.isTrackAppExceptionEvents,
                                                                   isCompressEvents: configuration.isCompressEvents)
        clickstream = try ClickstreamContext(with: contextConfiguration)

        let sessionClient = SessionClient(configuration: .init(uniqueDeviceId: clickstream.userUniqueId,
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
        analyticsClient = try AnalyticsClient(clickstream: clickstream,
                                              eventRecorder: eventRecorder,
                                              sessionProvider: sessionProvider)
        clickstream.analyticsClient = analyticsClient
        sessionClient.analyticsClient = analyticsClient
        let networkMonitor = NWPathMonitor()
        clickstream.networkMonitor = networkMonitor
        let autoRecordEventClient = AutoRecordEventClient(clickstream: clickstream)

        var autoFlushEventsTimer: DispatchSourceTimer?
        if configuration.sendEventsInterval != 0 {
            let timeInterval = TimeInterval(Double(configuration.sendEventsInterval) / 1_000)
            autoFlushEventsTimer = RepeatingTimer.createRepeatingTimer(
                timeInterval: timeInterval,
                eventHandler: { [weak self] in
                    self?.log.debug("AutoFlushTimer triggered, flushing events")
                    self?.flushEvents()
                }
            )
        }

        configure(
            autoFlushEventsTimer: autoFlushEventsTimer,
            networkMonitor: networkMonitor
        )
        sessionClient.startSession()
        log.debug("init the sdk success")
    }

    // MARK: Internal

    /// Internal configure method to set the properties of the plugin
    internal func configure(
        autoFlushEventsTimer: DispatchSourceTimer?,
        networkMonitor: NetworkMonitor
    ) {
        isEnabled = true
        self.autoFlushEventsTimer = autoFlushEventsTimer
        self.autoFlushEventsTimer?.resume()
        self.networkMonitor = networkMonitor
        self.networkMonitor.startMonitoring(
            using: DispatchQueue(
                label: "software.aws.solution.clickstream.AnalyticsPlugin.NetworkMonitor"
            )
        )
    }
}
