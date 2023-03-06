//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

private typealias Limit = Event.Limit
private typealias JsonObject = [String: Any]

class ClickstreamEvent: AnalyticsPropertiesModel {
    var hashCode: Int!
    let eventId: String
    let appId: String
    let uniqueId: String
    let eventType: String
    let timestamp: Date.Timestamp
    let session: Session
    private(set) lazy var attributes: [String: AttributeValue] = [:]
    private(set) lazy var userAttributes: [String: AttributeValue] = [:]
    let systemInfo: SystemInfo
    let netWorkType: String
    
    init(eventId: String = UUID().uuidString,
         eventType: String,
         appId: String,
         uniqueId: String,
         timestamp: Date.Timestamp = Date().millisecondsSince1970,
         session: Session,
         systemInfo: SystemInfo,
         netWorkType: String)
    {
        self.eventId = eventId
        self.appId = appId
        self.uniqueId = uniqueId
        self.eventType = eventType
        self.timestamp = timestamp
        self.session = session
        self.systemInfo = systemInfo
        self.netWorkType = netWorkType
    }
    
    func addAttribute(_ attribute: AttributeValue, forKey key: String) {
        let eventError = Event.checkAttribute(currentNumber: attributes.count, key: key, value: attribute)
        if eventError != nil {
            attributes[eventError!.errorType] = eventError!.errorMessage
        } else {
            attributes[key] = attribute
        }
    }
    
    func addGlobalAttribute(_ attribute: AttributeValue, forKey key: String) {
        attributes[key] = attribute
    }
    
    func addUserAttribute(_ attribute: AttributeValue, forKey key: String) {
        userAttributes[key] = attribute
    }
    
    func attribute(forKey key: String) -> AttributeValue? {
        attributes[key]
    }
    
    private func trimmedKey(_ string: String) -> String {
        if string.count > Limit.MAX_LENGTH_OF_NAME {
            log.warn("The \(string) key has been trimmed to a length of \(Limit.MAX_LENGTH_OF_NAME) characters")
        }
        return String(string.prefix(Limit.MAX_LENGTH_OF_NAME))
    }
    
    private func trimmedValue(_ string: String, forKey key: String) -> String {
        if string.count > Limit.MAX_LENGTH_OF_VALUE {
            log.warn("The value for key \(key) has been trimmed to a length of \(Limit.MAX_LENGTH_OF_VALUE) characters")
        }
        return String(string.prefix(Limit.MAX_LENGTH_OF_VALUE))
    }
    
    func toJson() -> String {
        var event = JsonObject()
        event["hashCode"] = String(format: "%08X", hashCode)
        event["unique_id"] = uniqueId
        event["event_type"] = eventType
        event["event_id"] = eventId
        event["app_id"] = appId
        event["timestamp"] = timestamp
        event["device_id"] = systemInfo.idfv
        event["device_unique_id"] = systemInfo.idfa
        event["platform"] = systemInfo.platform
        event["os_version"] = systemInfo.osVersion
        event["make"] = systemInfo.make
        event["brand"] = systemInfo.brand
        event["model"] = systemInfo.model
        event["locale"] = String(describing: Locale.current)
        event["carrier"] = systemInfo.carrier
        event["network_type"] = netWorkType
        event["screen_height"] = systemInfo.screenHeight
        event["screen_width"] = systemInfo.screenWidth
        event["zone_offset"] = TimeZone.current.secondsFromGMT() * 1000
        event["system_language"] = Locale.current.languageCode ?? "UNKNOWN"
        event["country_code"] = Locale.current.regionCode ?? "UNKNOWN"
        event["sdk_version"] = PackageInfo.version
        event["sdk_name"] = "aws-solution-clickstream-sdk"
        event["app_version"] = systemInfo.appVersion
        event["app_package_name"] = systemInfo.appPackgeName
        event["app_title"] = systemInfo.appTitle
        event["user"] = getAttributeObject(from: userAttributes)
        event["attributes"] = getAttributeObject(from: attributes)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: event, options: [.sortedKeys])
            return String(data: jsonData, encoding: .utf8)!
        } catch {
            log.error("Error serializing dictionary to JSON: \(error.localizedDescription)")
        }
        return ""
    }
    
    private func getAttributeObject(from dictionary: AnalyticsProperties) -> JsonObject {
        var attribute = JsonObject()
        if dictionary.isEmpty {
            return attribute
        }
        for (key, value) in dictionary.sorted(by: { $0.key < $1.key }) {
            if let value = value as? Double {
                attribute[key] = Decimal(string: String(value))
            } else {
                attribute[key] = value
            }
        }
        return attribute
    }
}

// MARK: - DefaultLogger

extension ClickstreamEvent: DefaultLogger {}
