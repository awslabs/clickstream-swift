//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import Clickstream
import XCTest

class ClickstreamPluginConfigurationTest: XCTestCase {
    let appId: JSONValue = "myAppId"
    let testAppId = "myAppId"
    let endpoint: JSONValue = "https://yourhost.com/collect"
    let testEndpoint = "https://yourhost.com/collect"
    let sendEventsInterval: JSONValue = 15000
    let testSendEventsInterval = 15000

    func testConfigureSuccessWithDefaultValue() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, appId),
            (AWSClickstreamConfiguration.endpointKey, endpoint)
        )

        do {
            let config = try AWSClickstreamConfiguration(configJson)
            XCTAssertNotNil(config)
            XCTAssertEqual(config.appId, testAppId)
            XCTAssertEqual(config.endpoint, testEndpoint)
            XCTAssertEqual(config.sendEventsInterval, AWSClickstreamConfiguration.defaultSendEventsInterval)
            XCTAssertEqual(config.isTrackAppExceptionEvents, AWSClickstreamConfiguration.defaulTrackAppException)
            XCTAssertEqual(config.isCompressEvents, AWSClickstreamConfiguration.defaulCompressEvents)
        } catch {
            XCTFail("Failed to instantiate clicstream plugin configuration")
        }
    }

    func testConfigFailWithInvalidConfigJson() {
        let configJson: JSONValue = ""
        let errString = "Configuration was not a dictionary literal"
        assertInitPluginError(errString: errString, configJson: configJson)
    }

    func testConfigureWithNoAppId() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.endpointKey, endpoint)
        )
        let errString = "appId is missing"
        assertInitPluginError(errString: errString, configJson: configJson)
    }

    func testConfigureWithInvalidAppId() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, true),
            (AWSClickstreamConfiguration.endpointKey, endpoint)
        )
        let errString = "appId is not a string"
        assertInitPluginError(errString: errString, configJson: configJson)
    }

    func testConfigureWithEmptyStringAppId() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, ""),
            (AWSClickstreamConfiguration.endpointKey, endpoint)
        )
        let errString = "appId is specified but is empty"
        assertInitPluginError(errString: errString, configJson: configJson)
    }

    func testConfigureWithNoEndpoint() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, appId)
        )
        let errString = "endpoint is missing"
        assertInitPluginError(errString: errString, configJson: configJson)
    }

    func testConfigureWithInvalidEndpoint() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, appId),
            (AWSClickstreamConfiguration.endpointKey, 123)
        )
        let errString = "endpoint is not a string"
        assertInitPluginError(errString: errString, configJson: configJson)
    }

    func testConfigureWithEmptyStringEndpoint() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, appId),
            (AWSClickstreamConfiguration.endpointKey, "")
        )
        let errString = "endpoint is specified but is empty"
        assertInitPluginError(errString: errString, configJson: configJson)
    }

    func testConfigureSuccessWithCustomSendEventsInterval() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, appId),
            (AWSClickstreamConfiguration.endpointKey, endpoint),
            (AWSClickstreamConfiguration.sendEventsIntervalKey, sendEventsInterval)
        )
        do {
            let config = try AWSClickstreamConfiguration(configJson)
            XCTAssertNotNil(config)
            XCTAssertEqual(config.appId, testAppId)
            XCTAssertEqual(config.endpoint, testEndpoint)
            XCTAssertEqual(config.sendEventsInterval, testSendEventsInterval)
            XCTAssertEqual(config.isTrackAppExceptionEvents, AWSClickstreamConfiguration.defaulTrackAppException)
            XCTAssertEqual(config.isCompressEvents, AWSClickstreamConfiguration.defaulCompressEvents)
        } catch {
            XCTFail("Failed to instantiate clicstream plugin configuration")
        }
    }

    func testConfigureErrorWithNegativeSendEventsInterval() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, appId),
            (AWSClickstreamConfiguration.endpointKey, endpoint),
            (AWSClickstreamConfiguration.sendEventsIntervalKey, -100)
        )
        let errString = "sendEventsInterval is less than 0"
        assertInitPluginError(errString: errString, configJson: configJson)
    }

    func testConfigureErrorWithInvalidSendEventsInterval() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, appId),
            (AWSClickstreamConfiguration.endpointKey, endpoint),
            (AWSClickstreamConfiguration.sendEventsIntervalKey, "100")
        )
        let errString = "sendEventsInterval is not a number"
        assertInitPluginError(errString: errString, configJson: configJson)
    }

    func testConfigureSuccessWithNotTrackAppException() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, appId),
            (AWSClickstreamConfiguration.endpointKey, endpoint),
            (AWSClickstreamConfiguration.trackAppExceptionKey, false)
        )
        do {
            let config = try AWSClickstreamConfiguration(configJson)
            XCTAssertNotNil(config)
            XCTAssertEqual(config.appId, testAppId)
            XCTAssertEqual(config.endpoint, testEndpoint)
            XCTAssertEqual(config.sendEventsInterval, AWSClickstreamConfiguration.defaultSendEventsInterval)
            XCTAssertEqual(config.isTrackAppExceptionEvents, false)
            XCTAssertEqual(config.isCompressEvents, AWSClickstreamConfiguration.defaulCompressEvents)
        } catch {
            XCTFail("Failed to instantiate clicstream plugin configuration")
        }
    }

    func testConfigureErrorWithInvalidTrackAppExceptionValue() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, appId),
            (AWSClickstreamConfiguration.endpointKey, endpoint),
            (AWSClickstreamConfiguration.trackAppExceptionKey, 10)
        )
        let errString = "isTrackAppException is not a boolean value"
        assertInitPluginError(errString: errString, configJson: configJson)
    }

    func testConfigureSuccessWithNotCompressEvents() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, appId),
            (AWSClickstreamConfiguration.endpointKey, endpoint),
            (AWSClickstreamConfiguration.isCompressEventsKey, false)
        )
        do {
            let config = try AWSClickstreamConfiguration(configJson)
            XCTAssertNotNil(config)
            XCTAssertEqual(config.appId, testAppId)
            XCTAssertEqual(config.endpoint, testEndpoint)
            XCTAssertEqual(config.sendEventsInterval, AWSClickstreamConfiguration.defaultSendEventsInterval)
            XCTAssertEqual(config.isCompressEvents, false)
        } catch {
            XCTFail("Failed to instantiate clicstream plugin configuration")
        }
    }

    func testConfigureErrorWithInvalidCompressEventsValue() {
        let configJson = JSONValue(
            dictionaryLiteral:
            (AWSClickstreamConfiguration.appIdKey, appId),
            (AWSClickstreamConfiguration.endpointKey, endpoint),
            (AWSClickstreamConfiguration.isCompressEventsKey, "10")
        )
        let errString = "isCompressEvents is not a boolean value"
        assertInitPluginError(errString: errString, configJson: configJson)
    }

    func assertInitPluginError(errString: String, configJson: JSONValue) {
        XCTAssertThrowsError(try AWSClickstreamConfiguration(configJson)) { error in
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
            XCTAssertEqual(errorDescription, errString)
        }
    }
}
