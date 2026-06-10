import Foundation

/// Number formatting helpers shared by the tape engine and the UI.
///
/// Accountants expect grouped thousands and a fixed number of decimal
/// places on a calculator tape, so the defaults mirror an adding machine.
public enum AmountFormatter {

    /// A grouped, fixed-fraction formatter (e.g. `1,495.25`).
    public static func string(
        from amount: Decimal,
        fractionDigits: Int = 2,
        grouping: Bool = true
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = grouping
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.roundingMode = .halfUp
        return formatter.string(from: amount as NSDecimalNumber)
            ?? "\(amount)"
    }

    /// Parses free-form user input (allowing grouping separators, a leading
    /// currency symbol, parentheses for negatives, and surrounding spaces)
    /// into a `Decimal`. Returns `nil` when the text is not a number.
    public static func parse(_ text: String) -> Decimal? {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Accounting-style negatives: (123.45) == -123.45
        var negative = false
        if trimmed.hasPrefix("(") && trimmed.hasSuffix(")") {
            negative = true
            trimmed.removeFirst()
            trimmed.removeLast()
        }

        // Strip everything that is not a digit, separator or sign.
        let allowed = Set("0123456789.,-")
        trimmed = String(trimmed.filter { allowed.contains($0) })
        trimmed = trimmed.replacingOccurrences(of: ",", with: "")
        guard !trimmed.isEmpty, trimmed != "-" else { return nil }

        guard let value = Decimal(string: trimmed) else { return nil }
        return negative ? -value : value
    }
}
