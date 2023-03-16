//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Clickstream

class MockEventRecorder: AnalyticsEventRecording {
    var saveCount = 0
    var lastSavedEvent: ClickstreamEvent?

    func save(_ event: ClickstreamEvent) throws {
        saveCount += 1
        lastSavedEvent = event
    }

    var submitCount = 0
    func submitEvents() {
        submitCount += 1
    }
}
