//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Clickstream
import XCTest

class EventTest: XCTestCase {
    func testIsValidEventType() {
        XCTAssertFalse(Event.isValidEventType(eventType: "").0)
        XCTAssertTrue(Event.isValidEventType(eventType: "abc").0)
        XCTAssertFalse(Event.isValidEventType(eventType: "abcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcde1").0)
        XCTAssertFalse(Event.isValidEventType(eventType: "123").0)
        XCTAssertTrue(Event.isValidEventType(eventType: "AAA").0)
        XCTAssertTrue(Event.isValidEventType(eventType: "a_ab").0)
        XCTAssertTrue(Event.isValidEventType(eventType: "a_ab_1A").0)
        XCTAssertTrue(Event.isValidEventType(eventType: "add_to_cart").0)
        XCTAssertTrue(Event.isValidEventType(eventType: "Screen_view").0)
        XCTAssertFalse(Event.isValidEventType(eventType: "0abc").0)
        XCTAssertFalse(Event.isValidEventType(eventType: "9Abc").0)
        XCTAssertTrue(Event.isValidEventType(eventType: "A9bc").0)
    }
}
