//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// ClickstreamAnalytics api for objective-c
@objcMembers public class ClickstreamObjc: NSObject {
    
    /// Hide the constructor
    @nonobjc
    override private init() {
        super.init()
    }

    /// Init the Clickstream sdk
    public static func initSDK() throws {
        try ClickstreamAnalytics.initSDK()
    }

    /// Use this method to record event
    /// - Parameter eventName: the event name
    public static func recordEvent(_ eventName: String) {
        ClickstreamAnalytics.recordEvent(eventName)
    }

    /// The method to record event with attributes
    /// - Parameters:
    ///   - eventName: the event name
    ///   - attributes: the event attributes which type is NSDictionary
    public static func recordEvent(_ eventName: String, _ attributes: NSDictionary) {
        ClickstreamAnalytics.recordEvent(eventName, getAttributes(attributes))
    }

    /// Use this method to send events immediately
    public static func flushEvents() {
        ClickstreamAnalytics.flushEvents()
    }

    /// Add global attributes
    /// - Parameter attributes: the global attributes to add
    public static func addGlobalAttributes(_ attributes: NSDictionary) {
        ClickstreamAnalytics.addGlobalAttributes(getAttributes(attributes))
    }

    /// Delete global attributes
    /// - Parameter attributes: the global attributes names to delete
    public static func deleteGlobalAttributes(_ attributes: [String]) {
        for attribute in attributes {
            ClickstreamAnalytics.deleteGlobalAttributes(attribute)
        }
    }

    /// Add user attributes
    /// - Parameter attributes: the user attributes to add
    public static func addUserAttributes(_ attributes: NSDictionary) {
        ClickstreamAnalytics.addUserAttributes(getAttributes(attributes))
    }

    /// Set user id for login and logout
    /// - Parameter userId: current userId, nil for logout
    public static func setUserId(_ userId: String?) {
        ClickstreamAnalytics.setUserId(userId)
    }

    /// Get Clickstream configuration, please config it after initialize sdk
    /// - Returns: ClickstreamContextConfiguration to modify the configuration of clickstream sdk
    public static func getClickstreamConfiguration() throws -> ClickstreamContextConfiguration {
        try ClickstreamAnalytics.getClickstreamConfiguration()
    }

    private static func getAttributes(_ attributes: NSDictionary) -> ClickstreamAttribute {
        var result: ClickstreamAttribute = [:]
        for case let (key as String, value) in attributes {
            if value is String {
                result[key] = value as? String
            } else if value is Bool {
                if let boolValue = value as? Bool {
                    result[key] = boolValue ? true : false
                }
            } else if value is Int {
                result[key] = value as? Int
            } else if value is Double {
                result[key] = value as? Double
            }
        }
        return result
    }
}
