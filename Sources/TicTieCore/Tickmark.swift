import Foundation

/// The three annotation colors offered by TicTie Calculate. Stored as RGB
/// components (0...1) so `TicTieCore` stays free of any UI framework; the app
/// layer maps these to `NSColor` / SwiftUI `Color`.
public enum AnnotationColor: String, CaseIterable, Codable, Identifiable {
    case red
    case green
    case blue

    public var id: String { rawValue }

    public var rgb: (red: Double, green: Double, blue: Double) {
        switch self {
        case .red:   return (0.85, 0.18, 0.18)
        case .green: return (0.13, 0.55, 0.27)
        case .blue:  return (0.15, 0.39, 0.84)
        }
    }

    public var displayName: String { rawValue.capitalized }
}

/// A tickmark the preparer can stamp onto a workpaper. Each has a short glyph
/// (rendered as text so it works with any font) and a meaning used as the
/// annotation's tooltip / search text.
public struct Tickmark: Identifiable, Equatable, Codable {
    public let id: UUID
    public var symbol: String
    public var meaning: String
    public var color: AnnotationColor

    public init(
        id: UUID = UUID(),
        symbol: String,
        meaning: String,
        color: AnnotationColor = .red
    ) {
        self.id = id
        self.symbol = symbol
        self.meaning = meaning
        self.color = color
    }
}

public extension Tickmark {
    /// The standard tickmark palette tax preparers reach for first. These
    /// mirror the conventional audit / tax tickmark legend.
    static let defaultPalette: [Tickmark] = [
        Tickmark(symbol: "✓", meaning: "Verified / agreed",            color: .green),
        Tickmark(symbol: "F", meaning: "Footed (column adds)",         color: .blue),
        Tickmark(symbol: "C", meaning: "Cross-footed",                 color: .blue),
        Tickmark(symbol: "T", meaning: "Traced / tied to support",     color: .green),
        Tickmark(symbol: "A", meaning: "Agreed to prior year",         color: .green),
        Tickmark(symbol: "PY", meaning: "Per prior-year workpaper",    color: .blue),
        Tickmark(symbol: "R", meaning: "Recomputed",                   color: .green),
        Tickmark(symbol: "N/A", meaning: "Not applicable",             color: .red),
        Tickmark(symbol: "?", meaning: "Open item — follow up",        color: .red),
        Tickmark(symbol: "X", meaning: "Exception / discrepancy",      color: .red)
    ]
}
