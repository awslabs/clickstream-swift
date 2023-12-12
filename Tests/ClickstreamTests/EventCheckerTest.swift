//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Clickstream
import XCTest

class EventCheckerTest: XCTestCase {
    func testIsValidEventType() {
        let noError = Event.ErrorCode.NO_ERROR
        XCTAssertFalse(EventChecker.checkEventType(eventType: "").errorCode == noError)
        XCTAssertTrue(EventChecker.checkEventType(eventType: "abc").errorCode == noError)
        XCTAssertFalse(EventChecker.checkEventType(eventType:
            "abcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcde1").errorCode == noError)
        XCTAssertFalse(EventChecker.checkEventType(eventType: "123").errorCode == noError)
        XCTAssertTrue(EventChecker.checkEventType(eventType: "AAA").errorCode == noError)
        XCTAssertTrue(EventChecker.checkEventType(eventType: "a_ab").errorCode == noError)
        XCTAssertTrue(EventChecker.checkEventType(eventType: "a_ab_1A").errorCode == noError)
        XCTAssertTrue(EventChecker.checkEventType(eventType: "add_to_cart").errorCode == noError)
        XCTAssertTrue(EventChecker.checkEventType(eventType: "Screen_view").errorCode == noError)
        XCTAssertFalse(EventChecker.checkEventType(eventType: "0abc").errorCode == noError)
        XCTAssertFalse(EventChecker.checkEventType(eventType: "9Abc").errorCode == noError)
        XCTAssertTrue(EventChecker.checkEventType(eventType: "A9bc").errorCode == noError)
    }
}
