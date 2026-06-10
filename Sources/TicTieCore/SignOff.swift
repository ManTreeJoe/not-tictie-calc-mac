import Foundation

/// A preparer or reviewer page sign-off, stamped as `"P: JD 06/10/26"`.
public struct SignOff: Identifiable, Equatable, Codable {
    public enum Role: String, CaseIterable, Codable, Identifiable {
        case preparer
        case reviewer

        public var id: String { rawValue }

        /// Short tag placed in front of the initials.
        public var tag: String {
            switch self {
            case .preparer: return "P"
            case .reviewer: return "R"
            }
        }

        public var displayName: String { rawValue.capitalized }

        public var color: AnnotationColor {
            switch self {
            case .preparer: return .blue
            case .reviewer: return .red
            }
        }
    }

    public let id: UUID
    public var role: Role
    public var initials: String
    public var date: Date

    public init(
        id: UUID = UUID(),
        role: Role,
        initials: String,
        date: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.initials = initials
        self.date = date
    }

    /// The stamped text, e.g. `"P: JD 06/10/26"`.
    public func rendered(
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateFormat = "MM/dd/yy"
        let cleanInitials = initials
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        return "\(role.tag): \(cleanInitials) \(formatter.string(from: date))"
    }
}
