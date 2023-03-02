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
}
