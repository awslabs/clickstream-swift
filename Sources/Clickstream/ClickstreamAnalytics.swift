//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public enum ClickstreamAnalytics {
    /// Init ClickstreamAnalytics
    public static func initSDK() throws {
        try Amplify.add(plugin: AWSClickstreamPlugin())
        try Amplify.configure()
    }

    /// Use this method to record Event.
    /// - Parameter event: ClickstreamEvent to record
    public static func recordEvent(event: AnalyticsEvent) {
        Amplify.Analytics.record(event: event)
    }

    /// Use this method to record Event.
    /// - Parameter eventName: the event name
    public static func recordEvent(eventName: String) {
        Amplify.Analytics.record(eventWithName: eventName)
    }

    /// Use this method to send events immediately.
    public static func flushEvents() {
        Amplify.Analytics.flushEvents()
    }

    /// Add global attributes
    /// - Parameter attributes: the global attributes to add
    public static func addGlobalAttributes(attributes: ClickstreamAttribute) {
        Amplify.Analytics.registerGlobalProperties(attributes)
    }

    /// Delete global attributes
    /// - Parameter attributes: the global attributes to delete
    public static func deleteGlobalAttributes(attributes: String...) {
        Amplify.Analytics.unregisterGlobalProperties(attributes)
    }

    /// Add user attributes
    /// - Parameter attributes: the user attributes to add
    public static func addUserAttributes(userAttributes: ClickstreamUserAttribute) {
        let userProfile = AnalyticsUserProfile(location: nil, properties: userAttributes.attribute)
        Amplify.Analytics.identifyUser(userId: Event.User.USER_ID_EMPTY,
                                       userProfile: userProfile)
    }

    /// Set user id for login and logout
    /// - Parameter userId: current userId, nil for logout
    public static func setUserId(userId: String?) {
        if userId == nil {
            Amplify.Analytics.identifyUser(userId: Event.User.USER_ID_NIL)
        } else {
            Amplify.Analytics.identifyUser(userId: userId!)
        }
    }

    /// Get clickstream configuration, please config it after initialize.
    /// - Returns: ClickstreamContextConfiguration: current userId, nil for logout
    public static func getClickStreamConfiguration() throws -> ClickstreamContextConfiguration? {
        let plugin = try Amplify.Analytics.getPlugin(for: "awsClickstreamPlugin")
        return (plugin as? AWSClickstreamPlugin)?.getEscapeHatch()
    }
}
