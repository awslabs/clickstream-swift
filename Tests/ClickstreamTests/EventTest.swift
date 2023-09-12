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
        let noError = Event.ErrorCode.NO_ERROR
        XCTAssertFalse(Event.checkEventType(eventType: "").errorCode == noError)
        XCTAssertTrue(Event.checkEventType(eventType: "abc").errorCode == noError)
        XCTAssertFalse(Event.checkEventType(eventType: "abcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcde1").errorCode == noError)
        XCTAssertFalse(Event.checkEventType(eventType: "123").errorCode == noError)
        XCTAssertTrue(Event.checkEventType(eventType: "AAA").errorCode == noError)
        XCTAssertTrue(Event.checkEventType(eventType: "a_ab").errorCode == noError)
        XCTAssertTrue(Event.checkEventType(eventType: "a_ab_1A").errorCode == noError)
        XCTAssertTrue(Event.checkEventType(eventType: "add_to_cart").errorCode == noError)
        XCTAssertTrue(Event.checkEventType(eventType: "Screen_view").errorCode == noError)
        XCTAssertFalse(Event.checkEventType(eventType: "0abc").errorCode == noError)
        XCTAssertFalse(Event.checkEventType(eventType: "9Abc").errorCode == noError)
        XCTAssertTrue(Event.checkEventType(eventType: "A9bc").errorCode == noError)
    }
}
