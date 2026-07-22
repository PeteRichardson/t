//
//  Priority_tests.swift
//  t_tests
//

import XCTest
@testable import t

final class Priority_tests: XCTestCase {

    // MARK: - init?(name:) by case name

    func testInitName_everyCaseName_roundTrips() throws {
        for priority in Priority.allCases {
            let name = "\(priority)"
            XCTAssertEqual(Priority(name: name), priority, "name \"\(name)\" should resolve to \(priority)")
        }
    }

    // MARK: - init?(name:) by digit

    func testInitName_everyDigit_roundTrips() throws {
        for priority in Priority.allCases {
            let digit = "\(priority.rawValue)"
            XCTAssertEqual(Priority(name: digit), priority, "digit \"\(digit)\" should resolve to \(priority)")
        }
    }

    // MARK: - init?(name:) invalid input

    func testInitName_unknownName_returnsNil() throws {
        XCTAssertNil(Priority(name: "bogus"))
    }

    func testInitName_outOfRangeDigit_returnsNil() throws {
        XCTAssertNil(Priority(name: "42"))
    }

    func testInitName_emptyString_returnsNil() throws {
        XCTAssertNil(Priority(name: ""))
    }
}
