//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

public final class AWSClickstreamPlugin: AnalyticsCategoryPlugin {
    /// Automatically flushes the events that have been recorded on an interval
    var autoFlushEventsTimer: DispatchSourceTimer?
    
    /// An observer to monitor connectivity changes
    var networkMonitor: NetworkMonitor!
    
    /// Specifies whether the plugin is enabled
    var isEnabled: Bool!
    
    /// The configuration file plugin key of clickstream plugin
    public var key: PluginKey {
        "awsClickstreamPlugin"
    }
    
    /// Instantiates an instance of the AWSClickstreamPlugin
    public init() {}
}
