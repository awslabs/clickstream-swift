//
//  File.swift
//
//
//  Created by Zhu, Xiaowei on 2023/3/4.
//

import Amplify

public typealias ClickstreamAttribute = AnalyticsProperties
public typealias BaseClickstreamEvent = BasicAnalyticsEvent
public typealias AttributeValue = AnalyticsPropertyValue

public struct ClickstreamUserAttribute {
    public var userId: String?
    public var attribute: ClickstreamAttribute?
    public init(userId: String?, attribute: ClickstreamAttribute?) {
        self.userId = userId
        self.attribute = attribute
    }
}
