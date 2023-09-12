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
    private var lastEngageTime: Int64 = 0
    private var lastScreenName: String?
    private var lastScreenPath: String?
    private var lastScreenUniqueId: String?
    private var lastScreenStartTimestamp: Int64 = 0

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

    func onViewDidAppear(screenName: String, screenPath: String, screenHashValue: String) {
        if !isSameScreen(screenName, screenPath, screenHashValue) {
            recordUserEngagement()
            recordScreenView(screenName, screenPath, screenHashValue)
        }
    }

    func recordScreenView(_ screenName: String, _ screenPath: String, _ screenUniqueId: String) {
        if !clickstream.configuration.isTrackScreenViewEvents {
            return
        }
        let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.SCREEN_VIEW)!
        let eventTimestamp = event.timestamp
        event.addAttribute(screenName, forKey: Event.ReservedAttribute.SCREEN_NAME)
        event.addAttribute(screenPath, forKey: Event.ReservedAttribute.SCREEN_ID)
        event.addAttribute(screenUniqueId, forKey: Event.ReservedAttribute.SCREEN_UNIQUEID)
        if lastScreenName != nil, lastScreenPath != nil, lastScreenUniqueId != nil {
            event.addAttribute(lastScreenName!, forKey: Event.ReservedAttribute.PREVIOUS_SCREEN_NAME)
            event.addAttribute(lastScreenPath!, forKey: Event.ReservedAttribute.PREVIOUS_SCREEN_ID)
            event.addAttribute(lastScreenUniqueId!, forKey: Event.ReservedAttribute.PREVIOUS_SCREEN_UNIQUEID)
        }
        let previousTimestamp = getPreviousScreenViewTimestamp()
        if previousTimestamp > 0 {
            event.addAttribute(previousTimestamp, forKey: Event.ReservedAttribute.PREVIOUS_TIMESTAMP)
        }
        event.addAttribute(isEntrances ? 1 : 0, forKey: Event.ReservedAttribute.ENTRANCES)
        if lastEngageTime > 0 {
            event.addAttribute(lastEngageTime, forKey: Event.ReservedAttribute.ENGAGEMENT_TIMESTAMP)
        }
        recordEvent(event)

        isEntrances = false
        lastScreenName = screenName
        lastScreenPath = screenPath
        lastScreenUniqueId = screenUniqueId
        lastScreenStartTimestamp = eventTimestamp
        UserDefaultsUtil.savePreviousScreenViewTimestamp(storage: clickstream.storage, timestamp: eventTimestamp)
    }

    func recordUserEngagement() {
        if lastScreenStartTimestamp == 0 { return }
        lastEngageTime = Date().millisecondsSince1970 - lastScreenStartTimestamp
        if clickstream.configuration.isTrackUserEngagementEvents, lastEngageTime > Constants.minEngagementTime {
            let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.USER_ENGAGEMENT)!
            event.addAttribute(lastEngageTime, forKey: Event.ReservedAttribute.ENGAGEMENT_TIMESTAMP)
            if lastScreenName != nil, lastScreenPath != nil, lastScreenUniqueId != nil {
                event.addAttribute(lastScreenName!, forKey: Event.ReservedAttribute.SCREEN_NAME)
                event.addAttribute(lastScreenPath!, forKey: Event.ReservedAttribute.SCREEN_ID)
                event.addAttribute(lastScreenUniqueId!, forKey: Event.ReservedAttribute.SCREEN_UNIQUEID)
            }
            recordEvent(event)
        }
    }

    func updateLastScreenStartTimestamp() {
        lastScreenStartTimestamp = Date().millisecondsSince1970
    }

    func getPreviousScreenViewTimestamp() -> Int64 {
        if lastScreenStartTimestamp > 0 {
            return lastScreenStartTimestamp
        } else {
            return UserDefaultsUtil.getPreviousScreenViewTimestamp(storage: clickstream.storage)
        }
    }

    func isSameScreen(_ screenName: String, _ screenPath: String, _ screenUniqueId: String) -> Bool {
        lastScreenName != nil
            && lastScreenPath != nil
            && screenName == lastScreenName
            && screenPath == lastScreenPath
            && screenUniqueId == lastScreenUniqueId
    }

    func checkAppVersionUpdate(clickstream: ClickstreamContext) {
        let appVersion = UserDefaultsUtil.getAppVersion(storage: clickstream.storage)
        if appVersion != nil {
            let currentAppVersion = clickstream.systemInfo.appVersion
            if appVersion != currentAppVersion {
                let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.APP_UPDATE)!
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
                let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.OS_UPDATE)!
                event.addAttribute(osVersion!, forKey: Event.ReservedAttribute.PREVIOUS_OS_VERSION)
                recordEvent(event)
                UserDefaultsUtil.saveOSVersion(storage: clickstream.storage, osVersion: currentOSVersion!)
            }
        } else {
            UserDefaultsUtil.saveOSVersion(storage: clickstream.storage, osVersion: clickstream.systemInfo.osVersion)
        }
    }

    func handleAppStart() {
        if isFirstTime {
            checkAppVersionUpdate(clickstream: clickstream)
            checkOSVersionUpdate(clickstream: clickstream)
        }
        if isFirstOpen {
            let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.FIRST_OPEN)!
            recordEvent(event)
            UserDefaultsUtil.saveIsFirstOpen(storage: clickstream.storage, isFirstOpen: "false")
            isFirstOpen = false
        }
        let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.APP_START)!
        event.addAttribute(isFirstTime, forKey: Event.ReservedAttribute.IS_FIRST_TIME)
        if lastScreenName != nil, lastScreenPath != nil {
            event.addAttribute(lastScreenName!, forKey: Event.ReservedAttribute.SCREEN_NAME)
            event.addAttribute(lastScreenPath!, forKey: Event.ReservedAttribute.SCREEN_ID)
        }
        recordEvent(event)
        isFirstTime = false
    }

    func recordAppEnd() {
        let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.APP_END)!
        if lastScreenName != nil, lastScreenPath != nil, lastScreenUniqueId != nil {
            event.addAttribute(lastScreenName!, forKey: Event.ReservedAttribute.SCREEN_NAME)
            event.addAttribute(lastScreenPath!, forKey: Event.ReservedAttribute.SCREEN_ID)
            event.addAttribute(lastScreenUniqueId!, forKey: Event.ReservedAttribute.SCREEN_UNIQUEID)
        }
        recordEvent(event)
    }

    func recordSessionStartEvent() {
        let event = clickstream.analyticsClient.createEvent(withEventType: Event.PresetEvent.SESSION_START)!
        recordEvent(event)
    }

    func setIsEntrances() {
        isEntrances = true
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
                log.error("Failed to record event with error:\(error)")
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
