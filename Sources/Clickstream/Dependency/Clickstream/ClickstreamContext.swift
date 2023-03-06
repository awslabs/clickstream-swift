//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Network
@_spi(KeychainStore) import AWSPluginsCore

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
    var sendEventsInterval: Int
    /// Whether to track app lifecycle events automatically
    var isTrackAppExceptionEvents: Bool
    /// Whether to track app exception events automatically
    var isTrackAppLifecycleEvents: Bool
    /// Whether to compress events
    var isCompressEvents: Bool
    /// Whether to log events json in terminal when debug
    var isLogEvents: Bool

    init(appId: String,
         endpoint: String,
         sendEventsInterval: Int,
         isTrackAppExceptionEvents: Bool = true,
         isTrackAppLifecycleEvents: Bool = true,
         isCompressEvents: Bool,
         isLogEvents: Bool = false)
    {
        self.appId = appId
        self.endpoint = endpoint
        self.sendEventsInterval = sendEventsInterval
        self.isTrackAppExceptionEvents = isTrackAppExceptionEvents
        self.isTrackAppLifecycleEvents = isTrackAppLifecycleEvents
        self.isCompressEvents = isCompressEvents
        self.isLogEvents = isLogEvents
    }
}

struct ClickstreamContextStorage {
    let userDefaults: UserDefaultsBehaviour
    let keychainStore: KeychainStoreBehavior
}

class ClickstreamContext {
    var sessionClient: SessionClientBehaviour!
    var analyticsClient: AnalyticsClientBehaviour!
    var networkMonitor: NetworkMonitor!
    let systemInfo: SystemInfo
    let configuration: ClickstreamContextConfiguration
    let uniqueId: String
    let storage: ClickstreamContextStorage

    init(with configuration: ClickstreamContextConfiguration,
         userDefaults: UserDefaultsBehaviour = UserDefaults.standard,
         keychainStore: KeychainStoreBehavior = KeychainStore(service: ClickstreamContext.Constants.keychain)) throws
    {
        storage = ClickstreamContextStorage(userDefaults: userDefaults, keychainStore: keychainStore)
        uniqueId = Self.getUniqueId(storage: storage)
        systemInfo = SystemInfo()
        self.configuration = configuration
    }

    private static func getUniqueId(storage: ClickstreamContextStorage) -> String {
        if let deviceUniqueId = try? storage.keychainStore._getString(Constants.uniqueIdKey) {
            return deviceUniqueId
        }
        let newUniqueId = UUID().uuidString
        do {
            try storage.keychainStore._set(newUniqueId, key: Constants.uniqueIdKey)
            log.verbose("Created new Clickstream UniqueId and saved it to Keychain: \(newUniqueId)")
        } catch {
            log.error("Failed to save UniqueId in Keychain")
        }
        return newUniqueId
    }
}

// MARK: - extensions

extension ClickstreamContext: DefaultLogger {}

extension ClickstreamContext {
    enum Constants {
        static let keychain = "com.amazonaws.solution.clickstream.Keychain"
        static let uniqueIdKey = "com.amazonaws.solution.clickstream.UniqueIdKey"
    }
}
