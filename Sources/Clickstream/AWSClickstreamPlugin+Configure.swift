//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension AWSClickstreamPlugin {
    /// called when sdk init.
    func configure(using configuration: Any?) throws {
        guard let config = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError(
                "Unable to decode configuration",
                "Make sure the plugin configuration is JSONValue"
            )
        }
        let pluginConfiguration = try AWSClickstreamConfiguration(config)
        try configure(using: pluginConfiguration)
    }

    /// Configure AWSClickstreamPlugin programatically using AWSClickstreamConfiguration
    func configure(using configuration: AWSClickstreamConfiguration) throws {}
}
