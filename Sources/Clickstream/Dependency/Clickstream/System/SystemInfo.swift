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
    var idfv: String! = ""
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
    init() {
        #if canImport(UIKit)
            idfv = UIDevice.current.identifierForVendor?.uuidString ?? ""
            idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            model = UIDevice.current.name

            osVersion = UIDevice.current.systemVersion
            screenWidth = Int(UIScreen.main.bounds.size.width * UIScreen.main.scale)
            screenHeight = Int(UIScreen.main.bounds.size.height * UIScreen.main.scale)
            let infoDictionary = Bundle.main.infoDictionary
            appTitle = (infoDictionary?["CFBundleName"] ?? "") as? String
            appVersion = (infoDictionary?["CFBundleShortVersionString"] ?? "") as? String
            appPackgeName = (infoDictionary?["CFBundleIdentifier"] ?? "") as? String
        #endif
        platform = "iOS"
        make = "apple"
        brand = "apple"
        carrier = Self.getCarrier()
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
