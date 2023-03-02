//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Clickstream
import XCTest

class ClickstreamAnalyticsTest: XCTestCase {
    func testThrowMissingConfigureFileWhenInitSDK() throws {
        do {
            try ClickstreamAnalytics.initSDK()
            XCTFail("Should have thrown a invalidAmplifyConfigurationFile error, if no configuration file is specified")
        } catch {
            guard case ConfigurationError.invalidAmplifyConfigurationFile = error else {
                XCTFail("Should have thrown a invalidAmplifyConfigurationFile error")
                return
            }
        }
    }
}
