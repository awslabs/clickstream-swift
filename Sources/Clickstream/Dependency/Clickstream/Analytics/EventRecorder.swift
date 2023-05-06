//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// AnalyticsEventRecording saves and submits clickstream events
protocol AnalyticsEventRecording {
    /// Saves a clickstream event to storage
    /// - Parameter event: A ClickstreamEvent
    func save(_ event: ClickstreamEvent) throws

    /// Submit locally stored events
    /// - Returns: A collection of events submitted to Clickstream
    func submitEvents() throws
}

/// An AnalyticsEventRecording implementation that stores and submits clickstream events
class EventRecorder: AnalyticsEventRecording {
    var clickstream: ClickstreamContext
    let dbUtil: ClickstreamDBProtocol
    private(set) var queue: OperationQueue

    init(clickstream: ClickstreamContext) throws {
        self.clickstream = clickstream
        let dbAdapter = try BaseDBAdapter(prefixPath: Constants.dbPathPrefix,
                                          databaseName: clickstream.configuration.appId)
        self.dbUtil = ClickstreamDBUtil(dbAdapter: dbAdapter)
        try dbUtil.createTable()
        self.queue = OperationQueue()
        queue.maxConcurrentOperationCount = Constants.maxConcurrentOperations
    }

    /// save an clickstream event to storage
    /// - Parameter event: A ClickstreamEvent
    func save(_ event: ClickstreamEvent) throws {
        let eventJson: String = event.toJson()
        if clickstream.configuration.isLogEvents {
            log.debug(eventJson)
        }
        let eventSize = eventJson.count
        let storageEvent = StorageEvent(eventJson: eventJson, eventSize: Int64(eventSize))
        try dbUtil.saveEvent(storageEvent)
    }

    /// submit an batch events, add the processEvent() as operation into queue
    func submitEvents() {
        if queue.operationCount < Constants.maxEventOperations {
            let operation = BlockOperation { [weak self] in
                _ = self?.processEvent()
            }
            queue.addOperation(operation)
        } else {
            log.error("submit events ignored, exceed the operation queue max limit")
        }
    }

    /// process an batch event and send the events to server
    func processEvent() -> Int {
        let startTime = Date().millisecondsSince1970
        var submissions = 0
        var totalEventSend = 0
        do {
            repeat {
                let batchEvent = try getBatchEvent()
                if batchEvent.eventCount == 0 {
                    break
                }
                let result = NetRequest.uploadEventWithURLSession(eventsJson: batchEvent.eventsJson,
                                                                  configuration: clickstream.configuration)
                if !result {
                    break
                }
                try dbUtil.deleteBatchEvents(lastEventId: batchEvent.lastEventId)
                log.debug("success send \(batchEvent.eventCount) event")
                totalEventSend += batchEvent.eventCount
                submissions += 1
            } while submissions < Constants.maxSubmissionsAllowed
            let costTime = String(describing: Date().millisecondsSince1970 - startTime)
            log.info("time of process event cost: \(costTime)s")
        } catch {
            log.error("Failed to send event:\(error)")
        }
        log.info("Submitte \(totalEventSend) events")
        return totalEventSend
    }

    func getBatchEvent() throws -> BatchEvent {
        var eventsJson = "["
        var eventCount = 0
        var lastEventId: Int64 = -1

        let events = try dbUtil.getEventsWith(limit: Constants.maxEventNumberOfBatch)
        for event in events {
            let eventJson = event.eventJson
            if eventsJson.count + eventJson.count > Constants.maxSubmissionSize {
                eventsJson.append("]")
                break
            } else if eventCount > 0 {
                eventsJson.append(",")
            }
            eventsJson.append(eventJson)
            lastEventId = event.id!
            eventCount += 1
        }
        if eventCount == events.count {
            eventsJson.append("]")
        }
        return BatchEvent(eventsJson: eventsJson, eventCount: eventCount, lastEventId: lastEventId)
    }
}

extension EventRecorder: ClickstreamLogger {}
extension EventRecorder {
    enum Constants {
        static let dbPathPrefix = "com/amazonaws/solution/Clickstream"

        static let maxConcurrentOperations = 1
        static let maxEventOperations = 1_000
        static let maxEventNumberOfBatch = 100
        static let maxSubmissionsAllowed = 3
        static let maxSubmissionSize = 512 * 1_024
        static let maxDbSize = 50 * 1_024 * 1_024
    }
}
