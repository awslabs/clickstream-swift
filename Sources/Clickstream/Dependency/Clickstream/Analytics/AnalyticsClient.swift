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

    func checkEventName(_ eventName: String) -> Bool
    func createEvent(withEventType eventType: String) -> ClickstreamEvent
    func record(_ event: ClickstreamEvent) throws
    func submitEvents(isBackgroundMode: Bool)
}

typealias SessionProvider = () -> Session?

class AnalyticsClient: AnalyticsClientBehaviour {
    private(set) var eventRecorder: AnalyticsEventRecording
    private let sessionProvider: SessionProvider
    private(set) lazy var globalAttributes: [String: AttributeValue] = [:]
    private(set) var allUserAttributes: [String: Any] = [:]
    private(set) var simpleUserAttributes: [String: Any] = [:]
    private let clickstream: ClickstreamContext
    private(set) var userId: String?
    var autoRecordClient: AutoRecordEventClient?

    init(clickstream: ClickstreamContext,
         eventRecorder: AnalyticsEventRecording,
         sessionProvider: @escaping SessionProvider) throws
    {
        self.clickstream = clickstream
        self.eventRecorder = eventRecorder
        self.sessionProvider = sessionProvider
        self.userId = UserDefaultsUtil.getCurrentUserId(storage: clickstream.storage)
        self.allUserAttributes = UserDefaultsUtil.getUserAttributes(storage: clickstream.storage)
        self.simpleUserAttributes = getSimpleUserAttributes()
        self.autoRecordClient = (clickstream.sessionClient as? SessionClient)?.autoRecordClient
    }

    func addGlobalAttribute(_ attribute: AttributeValue, forKey key: String) {
        let eventError = EventChecker.checkAttribute(
            currentNumber: globalAttributes.count,
            key: key,
            value: attribute)
        if eventError.errorCode > 0 {
            recordEventError(eventError)
        } else {
            globalAttributes[key] = attribute
        }
    }

    func addUserAttribute(_ attribute: AttributeValue, forKey key: String) {
        let eventError = EventChecker.checkUserAttribute(currentNumber: allUserAttributes.count,
                                                         key: key,
                                                         value: attribute)
        if eventError.errorCode > 0 {
            recordEventError(eventError)
        } else {
            var userAttribute = JsonObject()
            if let attributeValue = attribute as? Double {
                userAttribute["value"] = Decimal(string: String(attributeValue))
            } else {
                userAttribute["value"] = attribute
            }
            userAttribute["set_timestamp"] = Date().millisecondsSince1970
            allUserAttributes[key] = userAttribute
        }
    }

    func removeGlobalAttribute(forKey key: String) {
        globalAttributes[key] = nil
    }

    func removeUserAttribute(forKey key: String) {
        allUserAttributes[key] = nil
    }

    func updateUserId(_ id: String?) {
        if userId != id {
            userId = id
            UserDefaultsUtil.saveCurrentUserId(storage: clickstream.storage, userId: userId)
            if let newUserId = id, !newUserId.isEmpty {
                allUserAttributes = JsonObject()
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
            simpleUserAttributes = getSimpleUserAttributes()
        }
    }

    func updateUserAttributes() {
        UserDefaultsUtil.updateUserAttributes(storage: clickstream.storage, userAttributes: allUserAttributes)
    }

    // MARK: - Event recording

    func createEvent(withEventType eventType: String) -> ClickstreamEvent {
        let event = ClickstreamEvent(eventType: eventType,
                                     appId: clickstream.configuration.appId,
                                     uniqueId: clickstream.userUniqueId,
                                     session: sessionProvider(),
                                     systemInfo: clickstream.systemInfo,
                                     netWorkType: clickstream.networkMonitor.netWorkType)
        return event
    }

    func checkEventName(_ eventName: String) -> Bool {
        let eventError = EventChecker.checkEventType(eventType: eventName)
        if eventError.errorCode > 0 {
            recordEventError(eventError)
            return false
        }
        return true
    }

    func record(_ event: ClickstreamEvent) throws {
        for (key, attribute) in globalAttributes {
            event.addGlobalAttribute(attribute, forKey: key)
        }
        if let autoRecordClient {
            if autoRecordClient.lastScreenName != nil {
                event.addGlobalAttribute(autoRecordClient.lastScreenName!,
                                         forKey: Event.ReservedAttribute.SCREEN_NAME)
            }
            if autoRecordClient.lastScreenUniqueId != nil {
                event.addGlobalAttribute(autoRecordClient.lastScreenUniqueId!,
                                         forKey: Event.ReservedAttribute.SCREEN_UNIQUEID)
            }
        }
        if event.eventType == Event.PresetEvent.PROFILE_SET {
            event.setUserAttribute(allUserAttributes)
        } else {
            event.setUserAttribute(simpleUserAttributes)
        }
        try eventRecorder.save(event)
    }

    func recordEventError(_ eventError: EventChecker.EventError) {
        Task {
            do {
                let event = createEvent(withEventType: Event.PresetEvent.CLICKSTREAM_ERROR)
                event.addAttribute(eventError.errorCode, forKey: Event.ReservedAttribute.ERROR_CODE)
                event.addAttribute(eventError.errorMessage, forKey: Event.ReservedAttribute.ERROR_MESSAGE)
                try record(event)
            } catch {
                log.error("Failed to record event with error:\(error)")
            }
        }
    }

    func submitEvents(isBackgroundMode: Bool = false) {
        eventRecorder.submitEvents(isBackgroundMode: isBackgroundMode)
    }

    func getSimpleUserAttributes() -> [String: Any] {
        simpleUserAttributes = [:]
        simpleUserAttributes[Event.ReservedAttribute.USER_FIRST_TOUCH_TIMESTAMP]
            = allUserAttributes[Event.ReservedAttribute.USER_FIRST_TOUCH_TIMESTAMP]
        if allUserAttributes.keys.contains(Event.ReservedAttribute.USER_ID) {
            simpleUserAttributes[Event.ReservedAttribute.USER_ID]
                = allUserAttributes[Event.ReservedAttribute.USER_ID]
        }
        return simpleUserAttributes
    }
}

extension AnalyticsClient: ClickstreamLogger {}
