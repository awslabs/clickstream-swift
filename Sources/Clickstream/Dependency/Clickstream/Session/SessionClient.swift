//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol SessionClientBehaviour: AnyObject {
    var currentSession: Session { get }
    var analyticsClient: AnalyticsClientBehaviour? { get set }

    func startSession()
}

struct SessionClientConfiguration {
    let uniqueDeviceId: String
    let sessionBackgroundTimeout: TimeInterval
}

class SessionClient: SessionClientBehaviour {
    private var session: Session
    weak var analyticsClient: AnalyticsClientBehaviour?
    private let activityTracker: ActivityTrackerBehaviour
    private let configuration: SessionClientConfiguration
    private let sessionClientQueue = DispatchQueue(label: Constants.queue,
                                                   attributes: .concurrent)
    private let userDefaults: UserDefaultsBehaviour?
    init(activityTracker: ActivityTrackerBehaviour? = nil,
         configuration: SessionClientConfiguration,
         userDefaults: UserDefaultsBehaviour? = nil)
    {
        self.activityTracker = activityTracker ??
            ActivityTracker(backgroundTrackingTimeout: configuration.sessionBackgroundTimeout)
        self.configuration = configuration
        self.userDefaults = userDefaults
        self.session = Session.invalid
    }

    var currentSession: Session {
        if session == Session.invalid {
            startNewSession()
        }
        return session
    }

    func startSession() {
        guard analyticsClient != nil else {
            log.error("Clickstream Analytics is disabled.")
            return
        }

        activityTracker.beginActivityTracking { [weak self] newState in
            guard let self else { return }
            self.log.info("New state received: \(newState)")
            self.sessionClientQueue.sync(flags: .barrier) {
                self.respond(to: newState)
            }
        }

        sessionClientQueue.sync(flags: .barrier) {
            startNewSession()
        }
    }

    private func startNewSession() {
        session = Session(uniqueId: configuration.uniqueDeviceId)
        log.info("Session Started.")

        // Update Endpoint and record Session Start event
        Task {
            log.info("Firing Session Event: Start")
            record(eventType: Event.PresetEvent.SESSION_START)
        }
    }

    private func endSession() {
        session.stop()
        log.info("Session Stopped.")

        Task {
            log.info("Firing Session Event: Stop")
            record(eventType: Event.PresetEvent.SESSION_STOP)
        }
    }

    private func record(eventType: String) {
        guard let analyticsClient else {
            log.error("Clickstream Analytics is disabled.")
            return
        }

        let event = analyticsClient.createEvent(withEventType: eventType)
        Task {
            try? await analyticsClient.record(event)
        }
    }

    private func respond(to newState: ApplicationState) {
        switch newState {
        case .terminated:
            endSession()
        #if !os(macOS)
            case let .runningInBackground(isStale):
                if isStale {
                    endSession()
                }
        #endif
        default:
            break
        }
    }
}

// MARK: - ClickstreamLogger

extension SessionClient: ClickstreamLogger {}
extension SessionClient {
    enum Constants {
        static let queue = "software.aws.solution.Clickstream.SessionClientQueue"
    }
}

extension Session {
    static var invalid = Session(sessionId: "InvalidSessionId", startTime: Date(), stopTime: nil)
}
