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
        var type = NetWorkType.UnKnow
        pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                type = NetWorkType.Wifi
            } else if path.usesInterfaceType(.cellular) {
                type = NetWorkType.Mobile
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

enum NetWorkType {
    static let Wifi = "WIFI"
    static let UnKnow = "UNKNOWN"
    static let Mobile = "Mobile"
}
