//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AnalyticsClientBehaviour {
    func addGlobalAttribute(_ attribute: AttributeValue, forKey key: String)
    func addUserAttribute(_ attribute: AttributeValue, forKey key: String)
    func removeGlobalAttribute(forKey key: String)
    func removeUserAttribute(forKey key: String)
    func updateUserId(_ id: String?)
    func updateUserAttributes()

    func createEvent(withEventType eventType: String) -> ClickstreamEvent
    func record(_ event: ClickstreamEvent) async throws
    func submitEvents(isBackgroundMode: Bool)
}

typealias SessionProvider = () -> Session?

class AnalyticsClient: AnalyticsClientBehaviour {
    private(set) var eventRecorder: AnalyticsEventRecording
    private let sessionProvider: SessionProvider
    private(set) lazy var globalAttributes: [String: AttributeValue] = [:]
    private(set) var userAttributes: [String: Any] = [:]
    private let clickstream: ClickstreamContext
    private(set) var userId: String?

    init(clickstream: ClickstreamContext,
         eventRecorder: AnalyticsEventRecording,
         sessionProvider: @escaping SessionProvider) throws
    {
        self.clickstream = clickstream
        self.eventRecorder = eventRecorder
        self.sessionProvider = sessionProvider
        self.userId = UserDefaultsUtil.getCurrentUserId(storage: clickstream.storage)
        self.userAttributes = UserDefaultsUtil.getUserAttributes(storage: clickstream.storage)
    }

    func addGlobalAttribute(_ attribute: AttributeValue, forKey key: String) {
        let eventError = Event.checkAttribute(currentNumber: globalAttributes.count, key: key, value: attribute)
        if eventError != nil {
            globalAttributes[eventError!.errorType] = eventError!.errorMessage
        } else {
            globalAttributes[key] = attribute
        }
    }

    func addUserAttribute(_ attribute: AttributeValue, forKey key: String) {
        let eventError = Event.checkUserAttribute(currentNumber: userAttributes.count, key: key, value: attribute)
        if eventError != nil {
            globalAttributes[eventError!.errorType] = eventError!.errorMessage
        } else {
            var userAttribute = JsonObject()
            if let attributeValue = attribute as? Double {
                userAttribute["value"] = Decimal(string: String(attributeValue))
            } else {
                userAttribute["value"] = attribute
            }
            userAttribute["set_timestamp"] = Date().millisecondsSince1970
            userAttributes[key] = userAttribute
        }
    }

    func removeGlobalAttribute(forKey key: String) {
        globalAttributes[key] = nil
    }

    func removeUserAttribute(forKey key: String) {
        userAttributes[key] = nil
    }

    func updateUserId(_ id: String?) {
        if userId != id {
            userId = id
            UserDefaultsUtil.saveCurrentUserId(storage: clickstream.storage, userId: userId)
            if let newUserId = id, !newUserId.isEmpty {
                userAttributes = JsonObject()
                let userInfo = UserDefaultsUtil.getNewUserInfo(storage: clickstream.storage, userId: newUserId)
                // swiftlint:disable force_cast
                clickstream.userUniqueId = userInfo["user_unique_id"] as! String
                let userFirstTouchTimestamp = userInfo["user_first_touch_timestamp"] as! Int64
                // swiftlint:enable force_cast
                addUserAttribute(userFirstTouchTimestamp, forKey: Event.ReservedAttribute.USER_FIRST_TOUCH_TIMESTAMP)
            }
            if id == nil {
                removeUserAttribute(forKey: Event.ReservedAttribute.USER_ID)
            } else {
                addUserAttribute(id!, forKey: Event.ReservedAttribute.USER_ID)
            }
        }
    }

    func updateUserAttributes() {
        UserDefaultsUtil.updateUserAttributes(storage: clickstream.storage, userAttributes: userAttributes)
    }

    // MARK: - Event recording

    func createEvent(withEventType eventType: String) -> ClickstreamEvent {
        let (isValid, errorType) = Event.isValidEventType(eventType: eventType)
        precondition(isValid, errorType)

        let event = ClickstreamEvent(eventType: eventType,
                                     appId: clickstream.configuration.appId,
                                     uniqueId: clickstream.userUniqueId,
                                     session: sessionProvider(),
                                     systemInfo: clickstream.systemInfo,
                                     netWorkType: clickstream.networkMonitor.netWorkType)
        return event
    }

    func record(_ event: ClickstreamEvent) async throws {
        for (key, attribute) in globalAttributes {
            event.addGlobalAttribute(attribute, forKey: key)
        }
        event.setUserAttribute(userAttributes)
        let objId = ObjectIdentifier(event)
        event.hashCode = objId.hashValue
        try eventRecorder.save(event)
    }

    func submitEvents(isBackgroundMode: Bool = false) {
        eventRecorder.submitEvents(isBackgroundMode: isBackgroundMode)
    }
}
