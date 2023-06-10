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

/// The configuration object for clickstream, modify the params after sdk initialize
@objcMembers public class ClickstreamContextConfiguration: NSObject {
    /// The clickstream appId
    public var appId: String
    /// The clickstream endpoint
    public var endpoint: String
    /// Time interval after which the events are automatically submitted to server
    private let sendEventsInterval: Int
    /// Whether to track app exception events automatically
    public var isTrackAppExceptionEvents: Bool
    /// Whether to track app scren view events automatically
    public var isTrackScreenViewEvents: Bool
    /// Whether to compress events when send to server
    public var isCompressEvents: Bool
    /// Whether to log events json in console when debug
    public var isLogEvents: Bool
    /// The auth cookie for request
    public var authCookie: String?
    /// The session timeout calculated the duration from last app in background, defalut is 1800000ms
    public var sessionTimeoutDuration: Int64

    init(appId: String,
         endpoint: String,
         sendEventsInterval: Int,
         isTrackAppExceptionEvents: Bool = true,
         isTrackScreenViewEvents: Bool = true,
         isCompressEvents: Bool = true,
         isLogEvents: Bool = false,
         sessionTimeoutDuration: Int64 = 1_800_000)
    {
        self.appId = appId
        self.endpoint = endpoint
        self.sendEventsInterval = sendEventsInterval
        self.isTrackAppExceptionEvents = isTrackAppExceptionEvents
        self.isTrackScreenViewEvents = isTrackScreenViewEvents
        self.isCompressEvents = isCompressEvents
        self.isLogEvents = isLogEvents
        self.sessionTimeoutDuration = sessionTimeoutDuration
    }
}

struct ClickstreamContextStorage {
    let userDefaults: UserDefaultsBehaviour
}

class ClickstreamContext {
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
