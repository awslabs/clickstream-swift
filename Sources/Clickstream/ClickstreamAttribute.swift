//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public typealias ClickstreamAttribute = AnalyticsProperties
public typealias AttributeValue = AnalyticsPropertyValue
extension Int64: AnalyticsPropertyValue {}

public struct BaseClickstreamEvent: AnalyticsEvent {
    public var properties: AnalyticsProperties?

    /// The name of the event
    public var name: String

    /// Properties of the event
    public var attribute: ClickstreamAttribute?

    /// Initializer
    /// - Parameters:
    ///   - name: The name of the event
    ///   - attribute: Attribute of the event
    public init(name: String,
                attribute: ClickstreamAttribute? = nil)
    {
        self.name = name
        self.attribute = attribute
    }
}

public struct ClickstreamUserAttribute {
    public var attribute: ClickstreamAttribute?
    public init(attribute: ClickstreamAttribute?) {
        self.attribute = attribute
    }
}
