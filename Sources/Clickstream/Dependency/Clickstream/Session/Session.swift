//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class Session: Codable {
    let sessionId: String
    let startTime: Date
    private(set) var stopTime: Date?

    init(uniqueId: String) {
        self.sessionId = Self.generateSessionId(uniqueId: uniqueId)
        self.startTime = Date()
        self.stopTime = nil
    }

    init(sessionId: String, startTime: Date, stopTime: Date?) {
        self.sessionId = sessionId
        self.startTime = startTime
        self.stopTime = stopTime
    }

    var isPaused: Bool {
        stopTime != nil
    }

    var duration: Date.Timestamp {
        let endTime = stopTime ?? Date()
        return endTime.millisecondsSince1970 - startTime.millisecondsSince1970
    }

    func stop() {
        guard stopTime == nil else { return }
        stopTime = Date()
    }

    func pause() {
        guard !isPaused else { return }
        stopTime = Date()
    }

    func resume() {
        stopTime = nil
    }

    private static func generateSessionId(uniqueId: String) -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: Constants.defaultTimezone)
        dateFormatter.locale = Locale(identifier: Constants.defaultLocale)

        // Timestamp: Day
        dateFormatter.dateFormat = Constants.dateFormat
        let timestampDay = dateFormatter.string(from: now)

        // Timestamp: Time
        dateFormatter.dateFormat = Constants.timeFormat
        let timestampTime = dateFormatter.string(from: now)

        let uniqueIdKey = uniqueId.padding(toLength: Constants.maxUniqueIdLength,
                                           withPad: Constants.paddingChar,
                                           startingAt: 0)

        // Create Session ID formatted as <UniqueID> - <Day> - <Time>
        return "\(uniqueIdKey)-\(timestampDay)-\(timestampTime)"
    }
}

// MARK: - Equatable

extension Session: Equatable {
    static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.sessionId == rhs.sessionId
            && lhs.startTime == rhs.startTime
            && lhs.stopTime == rhs.stopTime
    }
}

extension Session {
    enum Constants {
        static let maxUniqueIdLength = 8
        static let paddingChar = "_"
        static let defaultTimezone = "GMT"
        static let defaultLocale = "en_US"
        static let dateFormat = "yyyyMMdd"
        static let timeFormat = "HHmmssSSS"
    }
}
