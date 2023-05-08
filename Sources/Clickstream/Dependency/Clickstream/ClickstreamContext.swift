//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation
import Network

// MARK: - UserDefaultsBehaviour

protocol UserDefaultsBehaviour {
    func save(key: String, value: UserDefaultsBehaviourValue?)
    func removeObject(forKey key: String)
    func string(forKey key: String) -> String?
    func data(forKey key: String) -> Data?
    func object(forKey: String) -> Any?
}

protocol UserDefaultsBehaviourValue {}
extension String: UserDefaultsBehaviourValue {}
extension Data: UserDefaultsBehaviourValue {}
extension Dictionary: UserDefaultsBehaviourValue {}

extension UserDefaults: UserDefaultsBehaviour {
    func save(key: String, value: UserDefaultsBehaviourValue?) {
        set(value, forKey: key)
    }
}

// MARK: - ClickstreamContext

/// the configuration object contains the necessary and optional param which required to use clickstream
public struct ClickstreamContextConfiguration {
    // The clickstream appId
    var appId: String
    /// The clickstream endpoint
    var endpoint: String
    /// Time interval after which the events are automatically submitted to server
    private let sendEventsInterval: Int
    /// Whether to track app lifecycle events automatically
    var isTrackAppExceptionEvents: Bool
    /// Whether to track app exception events automatically
    var isTrackScreenViewEvents: Bool
    /// Whether to compress events
    var isCompressEvents: Bool
    /// Whether to log events json in terminal when debug
    var isLogEvents: Bool
    var authCookie: String?
    var sessionTimeoutDuration: Int64

    init(appId: String,
         endpoint: String,
         sendEventsInterval: Int,
         isTrackAppExceptionEvents: Bool = true,
         isTrackAppLifecycleEvents: Bool = true,
         isCompressEvents: Bool = true,
         isLogEvents: Bool = false,
         sessionTimeoutDuration: Int64 = 1800000)
    {
        self.appId = appId
        self.endpoint = endpoint
        self.sendEventsInterval = sendEventsInterval
        self.isTrackAppExceptionEvents = isTrackAppExceptionEvents
        self.isTrackScreenViewEvents = isTrackAppLifecycleEvents
        self.isCompressEvents = isCompressEvents
        self.isLogEvents = isLogEvents
        self.sessionTimeoutDuration = sessionTimeoutDuration
    }
}

struct ClickstreamContextStorage {
    let userDefaults: UserDefaultsBehaviour
}

public class ClickstreamContext {
    var sessionClient: SessionClientBehaviour!
    var analyticsClient: AnalyticsClientBehaviour!
    var networkMonitor: NetworkMonitor!
    let systemInfo: SystemInfo
    var configuration: ClickstreamContextConfiguration
    var userUniqueId: String
    let storage: ClickstreamContextStorage

    init(with configuration: ClickstreamContextConfiguration,
         userDefaults: UserDefaultsBehaviour = UserDefaults.standard) throws
    {
        self.storage = ClickstreamContextStorage(userDefaults: userDefaults)
        self.userUniqueId = UserDefaultsUtil.getCurrentUserUniqueId(storage: storage)
        self.systemInfo = SystemInfo(storage: storage)
        self.configuration = configuration
    }
}
