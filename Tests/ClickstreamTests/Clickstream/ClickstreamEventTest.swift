//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Clickstream
import Foundation
import XCTest
class ClickstreamEventTest: XCTestCase {
    let testAppId = "testAppId"
    var clickstreamEvent: ClickstreamEvent!
    override func setUp() {
        clickstreamEvent = ClickstreamEvent(eventType: "testEvent",
                                            appId: testAppId,
                                            uniqueId: UUID().uuidString,
                                            session: Session(uniqueId: UUID().uuidString),
                                            systemInfo: SystemInfo(),
                                            netWorkType: NetWorkType.Wifi)
    }

    override func tearDown() {
        clickstreamEvent = nil
    }

    func testAddAttributeSuccess() {
        clickstreamEvent.addAttribute(133_232_123, forKey: "GoodsId")
        clickstreamEvent.addAttribute("iPhone 14", forKey: "GoodsName")
        clickstreamEvent.addAttribute(true, forKey: "isNewGoods")
        XCTAssertEqual(133_232_123, clickstreamEvent.attribute(forKey: "GoodsId") as! Int)
        XCTAssertEqual("iPhone 14", clickstreamEvent.attribute(forKey: "GoodsName") as! String)
        XCTAssertEqual(true, clickstreamEvent.attribute(forKey: "isNewGoods") as! Bool)
    }

    func testAddAttributeErrorForInvalidKey() {
        clickstreamEvent.addAttribute(133_232_123, forKey: "1GoodsId")
        XCTAssertNil(clickstreamEvent.attribute(forKey: "isNewGoods"))
        let erroValueString = clickstreamEvent.attribute(forKey: Event.ErrorType.ATTRIBUTE_NAME_INVALID) as! String
        XCTAssertNotNil(erroValueString)
        XCTAssertTrue(erroValueString.contains("1GoodsId"))
    }

    func testAddAttributeErrorForExceedMaxLenthOfKey() {
        let longAttributeKey = String(repeating: "a", count: 51)
        clickstreamEvent.addAttribute("testValue", forKey: longAttributeKey)
        XCTAssertNil(clickstreamEvent.attribute(forKey: "longAttributeKey"))
        let erroValueString = clickstreamEvent.attribute(forKey: Event.ErrorType.ATTRIBUTE_NAME_LENGTH_EXCEED) as! String
        XCTAssertNotNil(erroValueString)
        XCTAssertTrue(erroValueString.contains(longAttributeKey))
    }

    func testAddAttributeErrorForExceedMaxLenthOfValue() {
        let longAttributeValue = String(repeating: "a", count: 1_025)
        clickstreamEvent.addAttribute(longAttributeValue, forKey: "testKey")
        XCTAssertNil(clickstreamEvent.attribute(forKey: "testKey"))
        let erroValueString = clickstreamEvent.attribute(forKey: Event.ErrorType.ATTRIBUTE_VALUE_LENGTH_EXCEED) as! String
        XCTAssertNotNil(erroValueString)
        XCTAssertTrue(erroValueString.contains("testKey"))
    }

    func testEventEqualsFail() {
        let event1 = clickstreamEvent
        let event2 = ClickstreamEvent(eventType: "testEvent",
                                      appId: testAppId,
                                      uniqueId: UUID().uuidString,
                                      session: Session(uniqueId: UUID().uuidString),
                                      systemInfo: SystemInfo(),
                                      netWorkType: NetWorkType.Wifi)
        XCTAssertFalse(event1 == event2)
    }
}
