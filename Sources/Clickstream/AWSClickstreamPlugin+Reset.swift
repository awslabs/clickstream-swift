//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension AWSClickstreamPlugin {
    func reset() async {
        if autoFlushEventsTimer != nil {
            autoFlushEventsTimer?.setEventHandler {}
            autoFlushEventsTimer?.cancel()
            autoFlushEventsTimer = nil
        }

        if isEnabled != nil {
            isEnabled = nil
        }

        if networkMonitor != nil {
            networkMonitor.stopMonitoring()
            networkMonitor = nil
        }
    }
}
