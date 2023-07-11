//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSClickstreamPlugin {
    func reset(onComplete: @escaping BasicClosure) {
        if clickstream != nil {
            clickstream = nil
        }

        if autoFlushEventsTimer != nil {
            autoFlushEventsTimer?.setEventHandler {}
            autoFlushEventsTimer?.cancel()
            autoFlushEventsTimer = nil
        }

        if isEnabled != nil {
            isEnabled = false
        }

        if networkMonitor != nil {
            networkMonitor.stopMonitoring()
            networkMonitor = nil
        }
        onComplete()
    }
}
