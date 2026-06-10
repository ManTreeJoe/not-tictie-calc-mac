import XCTest
@testable import TicTieCore

final class FormattingTests: XCTestCase {

    func testStringGroupsThousandsWithFixedFraction() {
        let s = AmountFormatter.string(from: Decimal(string: "1495.2")!)
        XCTAssertEqual(s, "1,495.20")
    }

    func testStringRoundsHalfUp() {
        let s = AmountFormatter.string(from: Decimal(string: "2.345")!)
        XCTAssertEqual(s, "2.35")
    }

    func testParsePlainNumber() {
        XCTAssertEqual(AmountFormatter.parse("1234.56"), Decimal(string: "1234.56"))
    }

    func testParseStripsGroupingAndCurrency() {
        XCTAssertEqual(AmountFormatter.parse("$1,234.56"), Decimal(string: "1234.56"))
    }

    func testParseAccountingNegativeParentheses() {
        XCTAssertEqual(AmountFormatter.parse("(75.25)"), Decimal(string: "-75.25"))
    }

    func testParseRejectsNonNumbers() {
        XCTAssertNil(AmountFormatter.parse(""))
        XCTAssertNil(AmountFormatter.parse("abc"))
        XCTAssertNil(AmountFormatter.parse("-"))
    }
}
