//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol AnalyticsClientBehaviour: Actor {
    func addGlobalAttribute(_ attribute: AttributeValue, forKey key: String)
    func addUserAttribute(_ attribute: AttributeValue, forKey key: String)
    func removeGlobalAttribute(forKey key: String)
    func removeUserAttribute(forKey key: String)

    nonisolated func createEvent(withEventType eventType: String) -> ClickstreamEvent
    func record(_ event: ClickstreamEvent) async throws
    func submitEvents() throws
}

typealias SessionProvider = () -> Session

actor AnalyticsClient: AnalyticsClientBehaviour {
    private(set) var eventRecorder: AnalyticsEventRecording
    private let sessionProvider: SessionProvider
    private(set) lazy var globalAttributes: [String: AttributeValue] = [:]
    private(set) lazy var userAttributes: [String: AttributeValue] = [:]
    private let clickstream: ClickstreamContext

    init(clickstream: ClickstreamContext,
         eventRecorder: AnalyticsEventRecording,
         sessionProvider: @escaping SessionProvider) throws
    {
        self.clickstream = clickstream
        self.eventRecorder = eventRecorder
        self.sessionProvider = sessionProvider
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
            userAttributes[eventError!.errorType] = eventError!.errorMessage
        } else {
            userAttributes[key] = attribute
        }
    }

    func removeGlobalAttribute(forKey key: String) {
        globalAttributes[key] = nil
    }

    func removeUserAttribute(forKey key: String) {
        userAttributes[key] = nil
    }

    // MARK: - Event recording

    nonisolated func createEvent(withEventType eventType: String) -> ClickstreamEvent {
        let (isValid, errorType) = Event.isValidEventType(eventType: eventType)
        precondition(isValid, errorType)

        let event = ClickstreamEvent(eventType: eventType,
                                     appId: clickstream.configuration.appId,
                                     uniqueId: clickstream.uniqueId,
                                     session: sessionProvider(),
                                     systemInfo: clickstream.systemInfo,
                                     netWorkType: clickstream.networkMonitor.netWorkType)
        return event
    }

    func record(_ event: ClickstreamEvent) async throws {
        for (key, attribute) in globalAttributes {
            event.addGlobalAttribute(attribute, forKey: key)
        }
        for (key, attribute) in userAttributes {
            event.addUserAttribute(attribute, forKey: key)
        }
        let objId = ObjectIdentifier(event)
        event.hashCode = objId.hashValue
        try eventRecorder.save(event)
    }

    func submitEvents() throws {
        try eventRecorder.submitEvents()
    }
}
