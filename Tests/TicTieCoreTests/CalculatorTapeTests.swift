import XCTest
@testable import TicTieCore

final class CalculatorTapeTests: XCTestCase {

    func testRunningTotalAddsAndSubtracts() {
        var tape = CalculatorTape()
        tape.add(Decimal(string: "1250.00")!)
        tape.add(Decimal(string: "320.50")!)
        tape.subtract(Decimal(string: "75.25")!)
        XCTAssertEqual(tape.total, Decimal(string: "1495.25"))
        XCTAssertEqual(tape.count, 3)
        XCTAssertEqual(tape.creditCount, 2)
        XCTAssertEqual(tape.debitCount, 1)
    }

    func testEnterChoosesOperationFromSign() {
        var tape = CalculatorTape()
        tape.enter(Decimal(100))
        tape.enter(Decimal(-40))
        XCTAssertEqual(tape.total, Decimal(60))
        XCTAssertEqual(tape.entries.last?.op, .subtract)
    }

    func testEntryNormalisesNegativeMagnitude() {
        // Passing a negative amount with `.add` should flip to a subtract.
        let entry = TapeEntry(amount: Decimal(-30), op: .add)
        XCTAssertEqual(entry.amount, Decimal(30))
        XCTAssertEqual(entry.op, .subtract)
        XCTAssertEqual(entry.signedAmount, Decimal(-30))
    }

    func testRemoveLastAndClear() {
        var tape = CalculatorTape()
        tape.add(Decimal(10))
        tape.add(Decimal(20))
        tape.removeLast()
        XCTAssertEqual(tape.total, Decimal(10))
        tape.clear()
        XCTAssertTrue(tape.isEmpty)
        XCTAssertEqual(tape.total, Decimal(0))
    }

    func testRemoveByID() {
        var tape = CalculatorTape()
        let first = tape.add(Decimal(10))
        tape.add(Decimal(5))
        tape.remove(first.id)
        XCTAssertEqual(tape.total, Decimal(5))
    }

    func testRenderedTapeHasLabelEntriesAndTotal() {
        var tape = CalculatorTape(label: "Cash receipts")
        tape.add(Decimal(string: "1250")!)
        tape.subtract(Decimal(string: "75.25")!)
        let text = tape.rendered()
        let lines = text.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.first, "Cash receipts")
        XCTAssertTrue(lines.contains { $0.hasSuffix("+") })
        XCTAssertTrue(lines.contains { $0.hasSuffix("-") })
        XCTAssertTrue(lines.contains { $0.contains("-----") })
        XCTAssertTrue(text.contains("1,174.75"))
    }

    func testEmptyTapeRendersZeroTotal() {
        let tape = CalculatorTape()
        XCTAssertTrue(tape.rendered().contains("0.00"))
    }
}
