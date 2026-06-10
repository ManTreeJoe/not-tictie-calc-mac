import XCTest
@testable import TicTieCore

final class TickmarkLegendTests: XCTestCase {

    func testBundledLegendMatchesDefaultPalette() {
        let bundled = TickmarkLegend.bundled()
        XCTAssertEqual(bundled.marks.map(\.symbol), Tickmark.defaultPalette.map(\.symbol))
        XCTAssertEqual(bundled.marks.map(\.color), Tickmark.defaultPalette.map(\.color))
        XCTAssertEqual(bundled.marks.map(\.meaning), Tickmark.defaultPalette.map(\.meaning))
    }

    func testJSONRoundTrips() throws {
        let legend = TickmarkLegend.default
        let data = try JSONEncoder().encode(legend)
        let decoded = try JSONDecoder().decode(TickmarkLegend.self, from: data)
        XCTAssertEqual(legend, decoded)
    }

    func testDecodesHandWrittenJSON() throws {
        let json = """
        { "tickmarks": [ { "symbol": "✓", "meaning": "ok", "color": "green" } ] }
        """
        let legend = try JSONDecoder().decode(TickmarkLegend.self, from: Data(json.utf8))
        XCTAssertEqual(legend.tickmarks.count, 1)
        XCTAssertEqual(legend.marks.first?.color, .green)
        XCTAssertEqual(legend.marks.first?.symbol, "✓")
    }

    func testWriteThenLoadFromDisk() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("legend-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        try TickmarkLegend.default.write(to: url)
        let loaded = try TickmarkLegend.load(from: url)
        XCTAssertEqual(loaded, .default)
    }
}
