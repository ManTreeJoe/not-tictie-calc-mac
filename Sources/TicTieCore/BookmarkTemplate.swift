import Foundation

/// One rule in a bookmark template: a canonical bookmark `title` plus the
/// `keywords` that identify the page it belongs to (e.g. a tax form name).
public struct BookmarkRule: Codable, Equatable {
    public var title: String
    public var keywords: [String]

    public init(title: String, keywords: [String]) {
        self.title = title
        self.keywords = keywords
    }

    /// Case-insensitive: matches when the page text contains any keyword.
    public func matches(_ pageText: String) -> Bool {
        let hay = pageText.lowercased()
        return keywords.contains { kw in
            let needle = kw.lowercased()
            return !needle.isEmpty && hay.contains(needle)
        }
    }
}

/// A named, ordered set of rules used to auto-bookmark a workpaper, mirroring
/// TicTie Calculate's template-driven bookmarking of recognized tax forms.
public struct BookmarkTemplate: Codable, Equatable {
    public var name: String
    public var rules: [BookmarkRule]

    public init(name: String, rules: [BookmarkRule]) {
        self.name = name
        self.rules = rules
    }
}

/// A resolved bookmark: a `title` to place at a concrete `pageIndex`.
public struct PlannedBookmark: Equatable {
    public let title: String
    public let pageIndex: Int

    public init(title: String, pageIndex: Int) {
        self.title = title
        self.pageIndex = pageIndex
    }
}

/// Applies a `BookmarkTemplate` to the text of each page to produce an ordered
/// bookmark plan. Pure logic — the app extracts page text via PDFKit and feeds
/// it here, so this is fully unit-testable.
public struct BookmarkPlanner {
    public enum Mode {
        /// One bookmark per rule, at the first page that matches it
        /// (good for bookmarking the start of each form/section).
        case firstMatchPerRule
        /// A bookmark for every page that matches any rule.
        case everyMatch
    }

    public init() {}

    public func plan(
        pageTexts: [String],
        template: BookmarkTemplate,
        mode: Mode = .firstMatchPerRule
    ) -> [PlannedBookmark] {
        var collected: [(order: Int, bookmark: PlannedBookmark)] = []
        var order = 0

        switch mode {
        case .firstMatchPerRule:
            for rule in template.rules {
                if let idx = pageTexts.firstIndex(where: { rule.matches($0) }) {
                    collected.append((order, PlannedBookmark(title: rule.title, pageIndex: idx)))
                    order += 1
                }
            }
        case .everyMatch:
            for (idx, text) in pageTexts.enumerated() {
                for rule in template.rules where rule.matches(text) {
                    collected.append((order, PlannedBookmark(title: rule.title, pageIndex: idx)))
                    order += 1
                }
            }
        }

        // Bookmarks read best in page order; keep discovery order as the
        // tiebreak so the sort is deterministic (Swift's sort isn't stable).
        return collected
            .sorted { a, b in
                a.bookmark.pageIndex != b.bookmark.pageIndex
                    ? a.bookmark.pageIndex < b.bookmark.pageIndex
                    : a.order < b.order
            }
            .map { $0.bookmark }
    }
}

// MARK: - Defaults & I/O

public extension BookmarkTemplate {
    /// A realistic default template for individual (Form 1040) returns.
    static var `default`: BookmarkTemplate {
        BookmarkTemplate(name: "Form 1040 (default)", rules: [
            BookmarkRule(title: "Form 1040 — U.S. Individual Income Tax Return",
                         keywords: ["form 1040", "1040 u.s. individual"]),
            BookmarkRule(title: "Schedule A — Itemized Deductions",
                         keywords: ["schedule a", "itemized deductions"]),
            BookmarkRule(title: "Schedule B — Interest and Dividends",
                         keywords: ["schedule b", "interest and ordinary dividends"]),
            BookmarkRule(title: "Schedule C — Profit or Loss From Business",
                         keywords: ["schedule c", "profit or loss from business"]),
            BookmarkRule(title: "Schedule D — Capital Gains and Losses",
                         keywords: ["schedule d", "capital gains and losses"]),
            BookmarkRule(title: "Schedule E — Supplemental Income and Loss",
                         keywords: ["schedule e", "supplemental income and loss"]),
            BookmarkRule(title: "W-2 — Wage and Tax Statement",
                         keywords: ["w-2", "wage and tax statement"]),
            BookmarkRule(title: "1099-INT — Interest Income",
                         keywords: ["1099-int", "interest income"]),
            BookmarkRule(title: "1099-DIV — Dividends and Distributions",
                         keywords: ["1099-div", "dividends and distributions"]),
            BookmarkRule(title: "1099-NEC — Nonemployee Compensation",
                         keywords: ["1099-nec", "nonemployee compensation"]),
            BookmarkRule(title: "1098 — Mortgage Interest Statement",
                         keywords: ["form 1098", "mortgage interest statement"])
        ])
    }

    /// The template shipped as a package resource, falling back to `.default`.
    static func bundled() -> BookmarkTemplate {
        guard
            let url = Bundle.module.url(forResource: "bookmark-template", withExtension: "json"),
            let template = try? load(from: url)
        else {
            return .default
        }
        return template
    }

    static func load(from url: URL) throws -> BookmarkTemplate {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(BookmarkTemplate.self, from: data)
    }

    func write(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(self).write(to: url, options: .atomic)
    }
}
