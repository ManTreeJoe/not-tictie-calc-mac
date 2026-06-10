import Foundation

/// A serializable tickmark legend — the single source of truth shared between
/// the TicTie Mac app and the Acrobat plug-in. The app reads (and lets you
/// edit) a JSON copy of this; the Acrobat add-on is generated from the same
/// file via `AcrobatPlugin/generate-legend.sh`.
public struct TickmarkLegend: Codable, Equatable {

    /// A legend entry. Deliberately *without* an identity field so the JSON
    /// file stays clean and hand-editable; `marks` mints stable `Tickmark`s.
    public struct Entry: Codable, Equatable {
        public var symbol: String
        public var meaning: String
        public var color: AnnotationColor

        public init(symbol: String, meaning: String, color: AnnotationColor) {
            self.symbol = symbol
            self.meaning = meaning
            self.color = color
        }
    }

    public var tickmarks: [Entry]

    public init(tickmarks: [Entry]) {
        self.tickmarks = tickmarks
    }

    /// The legend as `Tickmark` domain models for the UI.
    public var marks: [Tickmark] {
        tickmarks.map { Tickmark(symbol: $0.symbol, meaning: $0.meaning, color: $0.color) }
    }

    // MARK: - Built-in defaults

    /// The compiled-in default legend (mirrors `Tickmark.defaultPalette`).
    public static var `default`: TickmarkLegend {
        TickmarkLegend(
            tickmarks: Tickmark.defaultPalette.map {
                Entry(symbol: $0.symbol, meaning: $0.meaning, color: $0.color)
            }
        )
    }

    /// The legend shipped as a package resource, falling back to `.default`.
    public static func bundled() -> TickmarkLegend {
        guard
            let url = Bundle.module.url(forResource: "tickmark-legend", withExtension: "json"),
            let legend = try? load(from: url)
        else {
            return .default
        }
        return legend
    }

    // MARK: - I/O

    public static func load(from url: URL) throws -> TickmarkLegend {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(TickmarkLegend.self, from: data)
    }

    public func write(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(self).write(to: url, options: .atomic)
    }
}
