import XCTest
@testable import TicTieCore

final class SignOffTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    func testPreparerRenderUppercasesInitials() {
        let s = SignOff(role: .preparer, initials: "jd", date: date(2026, 6, 10))
        let rendered = s.rendered(
            calendar: Calendar(identifier: .gregorian),
            locale: Locale(identifier: "en_US_POSIX")
        )
        XCTAssertEqual(rendered, "P: JD 06/10/26")
    }

    func testReviewerTag() {
        let s = SignOff(role: .reviewer, initials: "ab", date: date(2026, 1, 5))
        let rendered = s.rendered(
            calendar: Calendar(identifier: .gregorian),
            locale: Locale(identifier: "en_US_POSIX")
        )
        XCTAssertEqual(rendered, "R: AB 01/05/26")
    }

    func testRoleColors() {
        XCTAssertEqual(SignOff.Role.preparer.color, .blue)
        XCTAssertEqual(SignOff.Role.reviewer.color, .red)
    }
}

final class TickmarkTests: XCTestCase {

    func testDefaultPaletteIsNonEmptyAndUsesAllColors() {
        let palette = Tickmark.defaultPalette
        XCTAssertFalse(palette.isEmpty)
        let colors = Set(palette.map(\.color))
        XCTAssertEqual(colors, Set(AnnotationColor.allCases))
    }

    func testColorRGBInRange() {
        for color in AnnotationColor.allCases {
            let rgb = color.rgb
            for component in [rgb.red, rgb.green, rgb.blue] {
                XCTAssertTrue((0...1).contains(component))
            }
        }
    }
}
