//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Network

protocol NetworkMonitor: AnyObject {
    var isOnline: Bool { get }
    var netWorkType: String { get }
    func startMonitoring(using queue: DispatchQueue)
    func stopMonitoring()
}

extension NWPathMonitor: NetworkMonitor {
    var isOnline: Bool {
        currentPath.status == .satisfied
    }

    var netWorkType: String {
        var type = "UNKNOWN"
        pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                type = "WIFI"
            } else if path.usesInterfaceType(.cellular) {
                type = "Mobile"
            } else {
                type = "UNKNOWN"
            }
        }
        return type
    }

    func startMonitoring(using queue: DispatchQueue) {
        start(queue: queue)
    }

    func stopMonitoring() {
        cancel()
    }
}
