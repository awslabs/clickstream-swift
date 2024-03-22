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

    /// The method to record event with attributes and items
    /// - Parameters:
    ///   - eventName: the event name
    ///   - attributes: the event attributes which type is NSDictionary
    ///   - items: the event items which type is NSDictionary
    public static func recordEvent(_ eventName: String, _ attributes: NSDictionary, _ items: [NSDictionary] = []) {
        ClickstreamAnalytics.recordEvent(eventName, getAttributes(attributes), getItems(items))
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

    private static func getItems(_ items: [NSDictionary]) -> [ClickstreamAttribute] {
        var resultItems: [ClickstreamAttribute] = []
        for item in items {
            resultItems.append(getAttributes(item))
        }
        return resultItems
    }

    /// Disable the SDK
    public static func disable() {
        ClickstreamAnalytics.disable()
    }

    /// Enable the SDK
    public static func enable() {
        ClickstreamAnalytics.enable()
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

/// ClickstreamAnalytics preset events
@objcMembers public class EventName: NSObject {
    /// Preset event screen view
    public static let SCREEN_VIEW = "_screen_view"
}

/// ClickstreamANalytics preset attributes
@objcMembers public class Attr: NSObject {
    /// Preset attribute screen name
    public static let SCREEN_NAME = "_screen_name"
    /// Preset attribute screen unique id
    public static let SCREEN_UNIQUE_ID = "_screen_unique_id"
}

/// ClickstreamAnalytics preset item keys for objective-c
/// In addition to the item attributes defined below, you can add up to 10 custom attributes to an item.
@objcMembers public class ClickstreamItemKey: NSObject {
    /// The id of the item
    public static let ITEM_ID = "id"
    /// The name of the item
    public static let ITEM_NAME = "name"
    /// The location id of the item
    public static let LOCATION_ID = "location_id"
    /// The brand of the item
    public static let ITEM_BRAND = "brand"
    /// The currency of the item
    public static let CURRENCY = "currency"
    /// The price of the item
    public static let PRICE = "price"
    /// The quantity of the item
    public static let QUANTITY = "quantity"
    /// The creative name of the item
    public static let CREATIVE_NAME = "creative_name"
    /// The creative slot of the item
    public static let CREATIVE_SLOT = "creative_slot"
    /// The category of the item
    public static let ITEM_CATEGORY = "item_category"
    /// The category2 of the item
    public static let ITEM_CATEGORY2 = "item_category2"
    /// The category3 of the item
    public static let ITEM_CATEGORY3 = "item_category3"
    /// The category4 of the item
    public static let ITEM_CATEGORY4 = "item_category4"
    /// The category5 of the item
    public static let ITEM_CATEGORY5 = "item_category5"
}
