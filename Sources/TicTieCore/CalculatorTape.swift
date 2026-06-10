import Foundation

/// A single line on the adding-machine tape.
public struct TapeEntry: Identifiable, Equatable, Codable {
    public enum Operation: String, Codable {
        case add
        case subtract

        public var symbol: String {
            switch self {
            case .add: return "+"
            case .subtract: return "-"
            }
        }
    }

    public let id: UUID
    /// Always stored as a positive magnitude; the sign is carried by `op`.
    public let amount: Decimal
    public let op: Operation

    public init(id: UUID = UUID(), amount: Decimal, op: Operation) {
        self.id = id
        // Normalise so callers can pass a signed value and we still record a
        // clean magnitude + operation.
        if amount < 0 {
            self.amount = -amount
            self.op = op == .add ? .subtract : .add
        } else {
            self.amount = amount
            self.op = op
        }
    }

    /// The signed contribution of this entry to the running total.
    public var signedAmount: Decimal {
        op == .add ? amount : -amount
    }
}

/// An adding-machine "tape": an ordered list of additions and subtractions
/// with a running total, mirroring the core of TicTie Calculate's on-PDF
/// calculator. Pure value logic — no UI, fully unit-testable.
public struct CalculatorTape: Equatable, Codable {

    /// Optional caption shown above the tape when stamped onto a workpaper.
    public var label: String
    public private(set) var entries: [TapeEntry]

    public init(label: String = "", entries: [TapeEntry] = []) {
        self.label = label
        self.entries = entries
    }

    // MARK: - Mutation

    @discardableResult
    public mutating func add(_ amount: Decimal) -> TapeEntry {
        let entry = TapeEntry(amount: amount, op: .add)
        entries.append(entry)
        return entry
    }

    @discardableResult
    public mutating func subtract(_ amount: Decimal) -> TapeEntry {
        let entry = TapeEntry(amount: amount, op: .subtract)
        entries.append(entry)
        return entry
    }

    /// Adds a signed amount, choosing the operation from its sign.
    @discardableResult
    public mutating func enter(_ signedAmount: Decimal) -> TapeEntry {
        signedAmount < 0 ? subtract(-signedAmount) : add(signedAmount)
    }

    public mutating func removeLast() {
        guard !entries.isEmpty else { return }
        entries.removeLast()
    }

    public mutating func remove(_ id: UUID) {
        entries.removeAll { $0.id == id }
    }

    public mutating func clear() {
        entries.removeAll()
    }

    // MARK: - Derived values

    public var total: Decimal {
        entries.reduce(Decimal(0)) { $0 + $1.signedAmount }
    }

    public var count: Int { entries.count }

    public var isEmpty: Bool { entries.isEmpty }

    /// Number of positive vs. negative lines — handy for the UI summary.
    public var creditCount: Int { entries.filter { $0.op == .add }.count }
    public var debitCount: Int { entries.filter { $0.op == .subtract }.count }

    // MARK: - Rendering

    /// Renders the tape as fixed-width text suitable for stamping onto a PDF,
    /// e.g.
    /// ```
    /// Cash receipts
    ///        1,250.00 +
    ///          320.50 +
    ///           75.25 -
    /// ----------------
    ///        1,495.25
    /// ```
    public func rendered(
        fractionDigits: Int = 2,
        width: Int = 16
    ) -> String {
        var lines: [String] = []
        if !label.isEmpty { lines.append(label) }

        for entry in entries {
            let value = AmountFormatter.string(
                from: entry.amount,
                fractionDigits: fractionDigits
            )
            let padded = value.leftPadded(to: width)
            lines.append("\(padded) \(entry.op.symbol)")
        }

        lines.append(String(repeating: "-", count: width))
        let totalString = AmountFormatter.string(
            from: total,
            fractionDigits: fractionDigits
        )
        lines.append(totalString.leftPadded(to: width))
        return lines.joined(separator: "\n")
    }
}

private extension String {
    func leftPadded(to width: Int) -> String {
        count >= width ? self : String(repeating: " ", count: width - count) + self
    }
}
