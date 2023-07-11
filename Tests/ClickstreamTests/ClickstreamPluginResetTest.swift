//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Clickstream
import XCTest

class ClickstreamPluginResetTest: ClickstreamPluginTestBase {
    func testReset() {
        analyticsPlugin.reset(onComplete: {})
        XCTAssertNil(analyticsPlugin.clickstream)
        XCTAssertNil(analyticsPlugin.autoFlushEventsTimer)
        XCTAssertFalse(analyticsPlugin.isEnabled)
        XCTAssertNil(analyticsPlugin.networkMonitor)
    }
}
