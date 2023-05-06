//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if canImport(UIKit)
    import UIKit
#endif
import AdSupport
import CoreTelephony

class SystemInfo {
    var deviceId: String! = ""
    var idfa: String! = ""
    let platform: String
    var osVersion: String! = ""
    let make: String
    var model: String! = ""
    let brand: String
    let carrier: String
    var screenHeight: Int!
    var screenWidth: Int!
    var appVersion: String! = ""
    var appPackgeName: String! = ""
    var appTitle: String! = ""
    init(storage: ClickstreamContextStorage) {
        #if canImport(UIKit)
            self.deviceId = UserDefaultsUtil.getDeviceId(storage: storage)
            self.idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            self.model = UIDevice.current.name
            self.osVersion = UIDevice.current.systemVersion
            self.screenWidth = Int(UIScreen.main.bounds.size.width * UIScreen.main.scale)
            self.screenHeight = Int(UIScreen.main.bounds.size.height * UIScreen.main.scale)
            let infoDictionary = Bundle.main.infoDictionary
            self.appTitle = (infoDictionary?["CFBundleName"] ?? "") as? String
            self.appVersion = (infoDictionary?["CFBundleShortVersionString"] ?? "") as? String
            self.appPackgeName = (infoDictionary?["CFBundleIdentifier"] ?? "") as? String
        #endif
        self.platform = "iOS"
        self.make = "apple"
        self.brand = "apple"
        self.carrier = Self.getCarrier()
    }

    private static func getCarrier() -> String {
        #if canImport(UIKit)
            let networkInfo = CTTelephonyNetworkInfo()
            if let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value {
                return carrier.carrierName ?? "UNKNOWN"
            } else {
                return "UNKNOWN"
            }
        #else
            return "UNKNOWN"
        #endif
    }
}
