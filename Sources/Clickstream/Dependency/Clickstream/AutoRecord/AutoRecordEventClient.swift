//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class AutoRecordEventClient {
    private let clickstream: ClickstreamContext
    init(clickstream: ClickstreamContext) {
        self.clickstream = clickstream
        checkAppVersionUpdate(clickstream: clickstream)
        checkOSVersionUpdate(clickstream: clickstream)
    }

    func checkAppVersionUpdate(clickstream: ClickstreamContext) {
        let appVersion = UserDefaultsUtil.getAppVersion(storage: clickstream.storage)
        if appVersion != nil {
            let currentAppVersion = clickstream.systemInfo.appVersion
            if appVersion != currentAppVersion {
                let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.APP_UPDATE)
                event.addAttribute(appVersion!, forKey: Event.ReservedAttribute.PREVIOUS_APP_VERSION)
                recordEvent(event)
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
            }
        } else {
            UserDefaultsUtil.saveOSVersion(storage: clickstream.storage, osVersion: clickstream.systemInfo.osVersion)
        }
    }

    func recordEvent(_ event: ClickstreamEvent) {
        Task {
            try await clickstream.analyticsClient.record(event)
        }
    }
}
