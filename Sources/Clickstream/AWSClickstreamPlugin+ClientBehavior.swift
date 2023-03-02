//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension AWSClickstreamPlugin {
    func identifyUser(userId: String, userProfile: AnalyticsUserProfile?) {}

    func record(event: AnalyticsEvent) {}

    func record(eventWithName eventName: String) {}

    func registerGlobalProperties(_ properties: AnalyticsProperties) {}

    func unregisterGlobalProperties(_ keys: Set<String>?) {}

    func flushEvents() {}

    func enable() {
        isEnabled = true
    }

    func disable() {
        isEnabled = false
    }
}
