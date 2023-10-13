//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// ClickstreamAnalytics api for swift
public enum ClickstreamAnalytics {
    /// Init ClickstreamAnalytics
    public static func initSDK() throws {
        try Amplify.add(plugin: AWSClickstreamPlugin())
        try Amplify.configure()
    }

    /// Use this method to record event
    /// - Parameter eventName: the event name
    public static func recordEvent(_ eventName: String) {
        Amplify.Analytics.record(eventWithName: eventName)
    }

    /// The method to record event with ClickstreamAttribute
    /// - Parameters:
    ///   - eventName: the event name
    ///   - attributes: the event attributes
    public static func recordEvent(_ eventName: String,
                                   _ attributes: ClickstreamAttribute,
                                   _ items: [ClickstreamAttribute] = [])
    {
        let event = BaseClickstreamEvent(name: eventName, attribute: attributes, items: items)
        Amplify.Analytics.record(event: event)
    }

    /// Use this method to send events immediately
    public static func flushEvents() {
        Amplify.Analytics.flushEvents()
    }

    /// Add global attributes
    /// - Parameter attributes: the global attributes to add
    public static func addGlobalAttributes(_ attributes: ClickstreamAttribute) {
        Amplify.Analytics.registerGlobalProperties(attributes)
    }

    /// Delete global attributes
    /// - Parameter attributes: the global attributes names to delete
    public static func deleteGlobalAttributes(_ attributes: String...) {
        Amplify.Analytics.unregisterGlobalProperties(attributes)
    }

    /// Add user attributes
    /// - Parameter attributes: the user attributes to add
    public static func addUserAttributes(_ attributes: ClickstreamAttribute) {
        let userProfile = AnalyticsUserProfile(location: nil, properties: attributes)
        Amplify.Analytics.identifyUser(userId: Event.User.USER_ID_EMPTY,
                                       userProfile: userProfile)
    }

    /// Set user id for login and logout
    /// - Parameter userId: current userId, nil for logout
    public static func setUserId(_ userId: String?) {
        if userId == nil {
            Amplify.Analytics.identifyUser(userId: Event.User.USER_ID_NIL)
        } else {
            Amplify.Analytics.identifyUser(userId: userId!)
        }
    }

    /// Get Clickstream configuration, please config it after initialize sdk
    /// - Returns: ClickstreamContextConfiguration to modify the configuration of clickstream sdk
    public static func getClickstreamConfiguration() throws -> ClickstreamContextConfiguration {
        let plugin = try Amplify.Analytics.getPlugin(for: "awsClickstreamPlugin")
        // swiftlint:disable force_cast
        return (plugin as! AWSClickstreamPlugin).getEscapeHatch().configuration
        // swiftlint:enable force_cast
    }

    /// ClickstreamAnalytics item attributes
    public enum Item {
        static let ITEM_ID = "id"
        static let ITEM_NAME = "name"
        static let LOCATION_ID = "location_id"
        static let ITEM_BRAND = "brand"
        static let CURRENCY = "currency"
        static let PRICE = "price"
        static let QUANTITY = "quantity"
        static let CREATIVE_NAME = "creative_name"
        static let CREATIVE_SLOT = "creative_slot"
        static let ITEM_CATEGORY = "item_category"
        static let ITEM_CATEGORY2 = "item_category2"
        static let ITEM_CATEGORY3 = "item_category3"
        static let ITEM_CATEGORY4 = "item_category4"
        static let ITEM_CATEGORY5 = "item_category5"
    }
}
