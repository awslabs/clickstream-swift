//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// AnalyticsEventRecording saves and submits clickstream events
protocol AnalyticsEventRecording {
    /// Saves a clickstream event to storage
    /// - Parameter event: A ClickstreamEvent
    func save(_ event: ClickstreamEvent) throws

    /// Submit locally stored events
    /// - Returns: A collection of events submitted to Clickstream
    func submitEvents() async throws -> [ClickstreamEvent]
}

/// An AnalyticsEventRecording implementation that stores and submits clickstream events
class EventRecorder: AnalyticsEventRecording {
    let clickstream: ClickstreamContext
    init(clickstream: ClickstreamContext) throws {
        self.clickstream = clickstream
    }

    /// save an clickstream event to storage
    /// - Parameter event: A ClickstreamEvent
    func save(_ event: ClickstreamEvent) throws {
        let eventJson: String = event.toJson()
        log.debug(eventJson)
    }

    /// submit an batch events
    func submitEvents() async throws -> [ClickstreamEvent] {
        []
    }
}

extension EventRecorder: DefaultLogger {}
