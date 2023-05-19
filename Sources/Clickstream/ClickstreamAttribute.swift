//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// the attribute for Clickstream which support String, Int, Int64, Double and Bool
public typealias ClickstreamAttribute = AnalyticsProperties

typealias AttributeValue = AnalyticsPropertyValue
extension Int64: AnalyticsPropertyValue {}

struct BaseClickstreamEvent: AnalyticsEvent {
    var properties: AnalyticsProperties?

    /// The name of the event
    var name: String

    /// Properties of the event
    var attribute: ClickstreamAttribute?

    /// Initializer
    /// - Parameters:
    ///   - name: The name of the event
    ///   - attribute: Attribute of the event
    init(name: String,
         attribute: ClickstreamAttribute? = nil)
    {
        self.name = name
        self.attribute = attribute
    }
}
