//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension AWSClickstreamPlugin {
    func identifyUser(userId: String, userProfile: AnalyticsUserProfile?) {
        if userId == Event.User.USER_ID_EMPTY {
            if let attributes = userProfile?.properties {
                for attribute in attributes {
                    analyticsClient.addUserAttribute(attribute.value, forKey: attribute.key)
                }
            }
        } else {
            if userId == Event.User.USER_ID_NIL {
                analyticsClient.updateUserId(nil)
            } else {
                analyticsClient.updateUserId(userId)
            }
        }
        analyticsClient.updateUserAttributes()
        Task {
            record(eventWithName: Event.PresetEvent.PROFILE_SET)
        }
    }

    func record(event: AnalyticsEvent) {
        guard let event = event as? BaseClickstreamEvent else {
            log.error("Event type does not match")
            return
        }
        if !isEnabled {
            log.warn("Cannot record events. Clickstream is disabled")
            return
        }

        let isValidEventName = analyticsClient.checkEventName(event.name)
        if isValidEventName {
            let clickstreamEvent = analyticsClient.createEvent(withEventType: event.name)
            if let attributes = event.attribute {
                clickstreamEvent.addAttribute(attributes)
            }

            Task {
                do {
                    try await analyticsClient.record(clickstreamEvent)
                } catch {
                    log.error("Record event error:\(error)")
                }
            }
        }
    }

    func record(eventWithName eventName: String) {
        let event = BaseClickstreamEvent(name: eventName)
        record(event: event)
    }

    func registerGlobalProperties(_ properties: AnalyticsProperties) {
        properties.forEach { key, value in
            analyticsClient.addGlobalAttribute(value, forKey: key)
        }
    }

    func unregisterGlobalProperties(_ keys: Set<String>?) {
        keys?.forEach { key in
            analyticsClient.removeGlobalAttribute(forKey: key)
        }
    }

    func flushEvents() {
        if !isEnabled {
            log.warn("Cannot flushEvents. Clickstream is disabled")
            return
        }
        // Do not attempt to submit events if we detect the device is offline, as it's gonna fail anyway
        guard networkMonitor.isOnline else {
            log.error("Device is offline, skipping submitting events to Clickstream server")
            return
        }
        analyticsClient.submitEvents(isBackgroundMode: false)
    }

    func getEscapeHatch() -> ClickstreamContext {
        clickstream
    }

    func enable() {
        if isEnabled { return }
        autoFlushEventsTimer?.resume()
        clickstream.isEnable = true
        isEnabled = true
    }

    func disable() {
        if !isEnabled { return }
        isEnabled = false
        clickstream.isEnable = false
        autoFlushEventsTimer?.suspend()
    }
}
