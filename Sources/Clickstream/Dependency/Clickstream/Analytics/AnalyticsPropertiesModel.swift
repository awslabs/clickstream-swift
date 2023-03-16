//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol AnalyticsPropertiesModel {
    func addAttribute(_ attribute: AttributeValue, forKey key: String)
}

extension AnalyticsPropertiesModel {
    func addAttribute(_ properties: [String: AttributeValue]) {
        for (key, value) in properties {
            addAttribute(value, forKey: key)
        }
    }
}
