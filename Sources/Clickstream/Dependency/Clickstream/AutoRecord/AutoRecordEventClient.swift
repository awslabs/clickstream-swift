//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class AutoRecordEventClient {
    private let clickstream: ClickstreamContext
    private var isEntrances = false
    private var isFirstOpen: Bool
    private var startEngageTimestamp: Int64!

    init(clickstream: ClickstreamContext) {
        self.clickstream = clickstream
        self.isFirstOpen = UserDefaultsUtil.getIsFirstOpen(storage: clickstream.storage)
    }

    func checkAppVersionUpdate(clickstream: ClickstreamContext) {
        let appVersion = UserDefaultsUtil.getAppVersion(storage: clickstream.storage)
        if appVersion != nil {
            let currentAppVersion = clickstream.systemInfo.appVersion
            if appVersion != currentAppVersion {
                let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.APP_UPDATE)
                event.addAttribute(appVersion!, forKey: Event.ReservedAttribute.PREVIOUS_APP_VERSION)
                recordEvent(event)
                UserDefaultsUtil.saveAppVersion(storage: clickstream.storage, appVersion: currentAppVersion!)
            }
        } else {
            UserDefaultsUtil.saveAppVersion(storage: clickstream.storage, appVersion: clickstream.systemInfo.appVersion)
        }
    }

    func checkOSVersionUpdate(clickstream: ClickstreamContext) {
        let osVersion = UserDefaultsUtil.getOSVersion(storage: clickstream.storage)
        if osVersion != nil {
            let currentOSVersion = clickstream.systemInfo.osVersion
            if osVersion != currentOSVersion {
                let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.OS_UPDATE)
                event.addAttribute(osVersion!, forKey: Event.ReservedAttribute.PREVIOUS_OS_VERSION)
                recordEvent(event)
                UserDefaultsUtil.saveOSVersion(storage: clickstream.storage, osVersion: currentOSVersion!)
            }
        } else {
            UserDefaultsUtil.saveOSVersion(storage: clickstream.storage, osVersion: clickstream.systemInfo.osVersion)
        }
    }

    func handleFirstOpen() {
        checkAppVersionUpdate(clickstream: clickstream)
        checkOSVersionUpdate(clickstream: clickstream)
        if isFirstOpen {
            let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.FIRST_OPEN)
            recordEvent(event)
            UserDefaultsUtil.saveIsFirstOpen(storage: clickstream.storage, isFirstOpen: "false")
            isFirstOpen = false
        }
    }

    func recordUserEngagement() {
        let engagementTime = Date().millisecondsSince1970 - startEngageTimestamp
        if engagementTime > Constants.minEngagementTime {
            let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.USER_ENGAGEMENT)
            event.addAttribute(engagementTime, forKey: Event.ReservedAttribute.ENGAGEMENT_TIMESTAMP)
            recordEvent(event)
        }
    }

    func updateEngageTimestamp() {
        startEngageTimestamp = Date().millisecondsSince1970
    }

    func recordSessionStartEvent() {
        let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.SESSION_START)
        recordEvent(event)
    }

    func setIsEntrances() {
        isEntrances = true
    }

    func recordEvent(_ event: ClickstreamEvent) {
        Task {
            try await clickstream.analyticsClient.record(event)
        }
    }
}

extension AutoRecordEventClient {
    enum Constants {
        static let minEngagementTime = 1000
    }
}
