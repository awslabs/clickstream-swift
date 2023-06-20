//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(UIKit)
    import UIKit
#endif
import Foundation

class AutoRecordEventClient {
    private let clickstream: ClickstreamContext
    private var isEntrances = false
    private var isFirstOpen: Bool
    private var isFirstTime = true
    private var startEngageTimestamp: Int64!
    private var lastScreenName: String?
    private var lastScreenPath: String?
    private var lastScreenStartTime: Int64?

    init(clickstream: ClickstreamContext) {
        self.clickstream = clickstream
        self.isFirstOpen = UserDefaultsUtil.getIsFirstOpen(storage: clickstream.storage)
        if clickstream.configuration.isTrackScreenViewEvents {
            #if canImport(UIKit)
                UIViewController.swizzle(viewDidAppear: onViewDidAppear)
            #endif
        }
        if clickstream.configuration.isTrackAppExceptionEvents {
            setupExceptionHandler()
        }
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

    func handleAppStart() {
        checkAppVersionUpdate(clickstream: clickstream)
        checkOSVersionUpdate(clickstream: clickstream)
        if isFirstOpen {
            let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.FIRST_OPEN)
            recordEvent(event)
            UserDefaultsUtil.saveIsFirstOpen(storage: clickstream.storage, isFirstOpen: "false")
            isFirstOpen = false
        }
        let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.APP_START)
        event.addAttribute(isFirstTime, forKey: Event.ReservedAttribute.IS_FIRST_TIME)
        if lastScreenName != nil, lastScreenPath != nil {
            event.addAttribute(lastScreenName!, forKey: Event.ReservedAttribute.SCREEN_NAME)
            event.addAttribute(lastScreenPath!, forKey: Event.ReservedAttribute.SCREEN_ID)
        }
        recordEvent(event)
        isFirstTime = false
    }

    func recordUserEngagement() {
        let engagementTime = Date().millisecondsSince1970 - startEngageTimestamp
        if engagementTime > Constants.minEngagementTime {
            let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.USER_ENGAGEMENT)
            event.addAttribute(engagementTime, forKey: Event.ReservedAttribute.ENGAGEMENT_TIMESTAMP)
            if lastScreenName != nil, lastScreenPath != nil {
                event.addAttribute(lastScreenName!, forKey: Event.ReservedAttribute.SCREEN_NAME)
                event.addAttribute(lastScreenPath!, forKey: Event.ReservedAttribute.SCREEN_ID)
            }
            recordEvent(event)
        }
        clickstream.analyticsClient.submitEvents(inBackgroundMode: true)
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

    func onViewDidAppear(screenName: String, screenPath: String) {
        if !clickstream.configuration.isTrackScreenViewEvents {
            return
        }
        let currentTimestamp = Date().millisecondsSince1970
        let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.SCREEN_VIEW)
        event.addAttribute(screenName, forKey: Event.ReservedAttribute.SCREEN_NAME)
        event.addAttribute(screenPath, forKey: Event.ReservedAttribute.SCREEN_ID)
        if lastScreenName != nil, lastScreenPath != nil {
            event.addAttribute(lastScreenName!, forKey: Event.ReservedAttribute.PREVIOUS_SCREEN_NAME)
            event.addAttribute(lastScreenPath!, forKey: Event.ReservedAttribute.PREVIOUS_SCREEN_ID)
        }
        event.addAttribute(isEntrances ? 1 : 0, forKey: Event.ReservedAttribute.ENTRANCES)
        if !isEntrances, lastScreenStartTime != nil {
            event.addAttribute(currentTimestamp - lastScreenStartTime!,
                               forKey: Event.ReservedAttribute.ENGAGEMENT_TIMESTAMP)
        }
        recordEvent(event)

        isEntrances = false
        lastScreenName = screenName
        lastScreenPath = screenPath
        lastScreenStartTime = currentTimestamp
    }

    func setupExceptionHandler() {
        NSSetUncaughtExceptionHandler { exception in
            AutoRecordEventClient.handleException(exception)
        }
    }

    static func handleException(_ exception: NSException) {
        let name = exception.name.rawValue
        let reason = exception.reason ?? ""
        let stackTrace = exception.callStackSymbols.joined(separator: "\n")
        let attribute: ClickstreamAttribute = [
            Event.ReservedAttribute.EXCEPTION_NAME: name,
            Event.ReservedAttribute.EXCEPTION_REASON: reason,
            Event.ReservedAttribute.EXCEPTION_STACK: stackTrace
        ]
        ClickstreamAnalytics.recordEvent(Event.PresetEvent.APP_EXCEPTION, attribute)
        Thread.sleep(forTimeInterval: 0.2)
        log.info("Recorded an app exception event, error name:\(name)")
    }

    func recordEvent(_ event: ClickstreamEvent) {
        Task {
            do {
                try await clickstream.analyticsClient.record(event)
            } catch {
                log.error("Record event error:\(error)")
            }
        }
    }
}

extension AutoRecordEventClient {
    enum Constants {
        static let minEngagementTime = 1_000
    }
}

extension AutoRecordEventClient: ClickstreamLogger {}
