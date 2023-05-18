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
            userProfile?.properties?.forEach { key, value in
                Task {
                    await analyticsClient.addUserAttribute(value, forKey: key)
                }
            }
        } else {
            Task {
                if userId == Event.User.USER_ID_NIL {
                    await analyticsClient.updateUserId(nil)
                } else {
                    await analyticsClient.updateUserId(userId)
                }
            }
        }
        Task {
            await analyticsClient.updateUserAttributes()
        }
        record(eventWithName: Event.PresetEvent.PROFILE_SET)
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

    func record(eventWithName eventName: String) {
        let event = BaseClickstreamEvent(name: eventName)
        record(event: event)
    }

    func registerGlobalProperties(_ properties: AnalyticsProperties) {
        properties.forEach { key, value in
            Task {
                await analyticsClient.addGlobalAttribute(value, forKey: key)
            }
        }
    }

    func unregisterGlobalProperties(_ keys: Set<String>?) {
        keys?.forEach { key in
            Task {
                await analyticsClient.removeGlobalAttribute(forKey: key)
            }
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
        Task {
            try await analyticsClient.submitEvents()
        }
    }

    func getEscapeHatch() -> ClickstreamContext {
        clickstream
    }

    func enable() {
        isEnabled = true
    }

    func disable() {
        isEnabled = false
    }
}
