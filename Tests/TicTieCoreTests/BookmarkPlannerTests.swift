import XCTest
@testable import TicTieCore

final class BookmarkPlannerTests: XCTestCase {

    private let template = BookmarkTemplate(name: "Test", rules: [
        BookmarkRule(title: "1040", keywords: ["form 1040"]),
        BookmarkRule(title: "Sch A", keywords: ["schedule a", "itemized deductions"]),
        BookmarkRule(title: "W-2", keywords: ["w-2", "wage and tax statement"])
    ])

    func testFirstMatchPerRuleReturnsPageOrder() {
        let pages = [
            "cover sheet",
            "Form 1040 U.S. Individual Income Tax Return",
            "Schedule A Itemized Deductions",
            "W-2 Wage and Tax Statement"
        ]
        let plan = BookmarkPlanner().plan(pageTexts: pages, template: template)
        XCTAssertEqual(plan, [
            PlannedBookmark(title: "1040", pageIndex: 1),
            PlannedBookmark(title: "Sch A", pageIndex: 2),
            PlannedBookmark(title: "W-2", pageIndex: 3)
        ])
    }

    func testCaseInsensitiveMatching() {
        let pages = ["...FORM 1040..."]
        let plan = BookmarkPlanner().plan(pageTexts: pages, template: template)
        XCTAssertEqual(plan.first?.title, "1040")
        XCTAssertEqual(plan.first?.pageIndex, 0)
    }

    func testFirstMatchTakesEarliestPage() {
        let pages = ["w-2 statement", "another w-2 wage and tax statement"]
        let plan = BookmarkPlanner().plan(pageTexts: pages, template: template)
        let w2 = plan.first { $0.title == "W-2" }
        XCTAssertEqual(w2?.pageIndex, 0)
    }

    func testEveryMatchBookmarksAllPages() {
        let pages = ["w-2 form", "form 1040", "w-2 form again"]
        let plan = BookmarkPlanner().plan(pageTexts: pages, template: template, mode: .everyMatch)
        XCTAssertEqual(plan, [
            PlannedBookmark(title: "W-2", pageIndex: 0),
            PlannedBookmark(title: "1040", pageIndex: 1),
            PlannedBookmark(title: "W-2", pageIndex: 2)
        ])
    }

    func testNoMatchesIsEmpty() {
        let plan = BookmarkPlanner().plan(pageTexts: ["nothing here"], template: template)
        XCTAssertTrue(plan.isEmpty)
    }

    func testTiesKeepRuleOrderOnSamePage() {
        // A single page matching two rules keeps template (discovery) order.
        let pages = ["form 1040 with itemized deductions on the same page"]
        let plan = BookmarkPlanner().plan(pageTexts: pages, template: template)
        XCTAssertEqual(plan.map(\.title), ["1040", "Sch A"])
        XCTAssertTrue(plan.allSatisfy { $0.pageIndex == 0 })
    }
}

final class BookmarkTemplateIOTests: XCTestCase {

    func testBundledMatchesDefault() {
        XCTAssertEqual(BookmarkTemplate.bundled(), BookmarkTemplate.default)
    }

    func testJSONRoundTrips() throws {
        let data = try JSONEncoder().encode(BookmarkTemplate.default)
        let decoded = try JSONDecoder().decode(BookmarkTemplate.self, from: data)
        XCTAssertEqual(decoded, BookmarkTemplate.default)
    }

    func testWriteThenLoad() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("tmpl-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        try BookmarkTemplate.default.write(to: url)
        XCTAssertEqual(try BookmarkTemplate.load(from: url), BookmarkTemplate.default)
    }
}
