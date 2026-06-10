#if canImport(SwiftUI) && canImport(PDFKit) && canImport(AppKit)
import SwiftUI
import PDFKit
import AppKit
import UniformTypeIdentifiers
import TicTieCore

/// The placement tool currently armed. When a tool is active, the next click on
/// the PDF places the corresponding annotation.
enum Tool: Equatable {
    case none
    case tickmark
    case signOff(SignOff.Role)
    case tape
    case tie

    var help: String {
        switch self {
        case .none:               return "Select a tool, then click the page to place it."
        case .tickmark:           return "Click the page to stamp the selected tickmark."
        case .signOff(let role):  return "Click the page to add the \(role.displayName.lowercased()) sign-off."
        case .tape:               return "Click the page to stamp the calculator tape."
        case .tie:                return "Click the tie target first, then click where the reference marker goes."
        }
    }
}

/// Central observable state for the app. Owns the open document, the live
/// calculator tape, the active tool and all the placement actions wired up to
/// the PDF view.
@MainActor
final class AppModel: ObservableObject {

    // Document
    @Published private(set) var controller: PDFDocumentController?
    @Published var currentPageIndex: Int = 0
    @Published private(set) var documentTitle: String = "No document"
    @Published private(set) var hasUnsavedChanges = false

    // Tools
    @Published var tool: Tool = .none
    @Published var statusMessage: String = Tool.none.help

    // Tickmarks
    @Published var palette: [Tickmark] = Tickmark.defaultPalette
    @Published var selectedTickmarkID: UUID?
    @Published var activeColor: AnnotationColor = .red

    init() {
        loadLegend()
        loadTemplate()
    }

    // Calculator tape
    @Published var tape = CalculatorTape()
    @Published var tapeInput: String = ""
    @Published var tapeLabel: String = ""

    // Sign-offs
    @Published var preparerInitials: String = ""
    @Published var reviewerInitials: String = ""

    // Tie (cross-reference)
    private var pendingTieDestination: PDFDestination?

    // Auto-bookmarking
    var bookmarkTemplate: BookmarkTemplate = .default

    /// The PDFView injected by the representable, so the model can drive
    /// navigation and read the live document/undo manager.
    weak var pdfView: PDFView?

    var isDocumentOpen: Bool { controller != nil }

    var selectedTickmark: Tickmark? {
        palette.first { $0.id == selectedTickmarkID } ?? palette.first
    }

    // MARK: - Document lifecycle

    func open(url: URL) {
        guard let controller = PDFDocumentController(url: url) else {
            statusMessage = "Could not open \(url.lastPathComponent)."
            return
        }
        self.controller = controller
        self.documentTitle = url.lastPathComponent
        self.currentPageIndex = 0
        self.pdfView?.document = controller.document
        refreshUnsaved()
        statusMessage = "Opened \(url.lastPathComponent) — \(controller.pageCount) pages."
    }

    func save() {
        guard let controller else { return }
        let ok: Bool
        if controller.url != nil {
            ok = controller.save()
        } else {
            ok = saveAs()
        }
        statusMessage = ok ? "Saved \(documentTitle)." : "Save failed."
        refreshUnsaved()
    }

    @discardableResult
    func saveAs() -> Bool {
        guard let controller else { return false }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = documentTitle.replacingOccurrences(of: ".pdf", with: "") + "-annotated.pdf"
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        let ok = controller.save(to: url)
        refreshUnsaved()
        return ok
    }

    private func refreshUnsaved() {
        hasUnsavedChanges = controller?.hasUnsavedChanges ?? false
    }

    // MARK: - Navigation

    func goToPage(_ index: Int) {
        guard let controller, let page = controller.page(at: index) else { return }
        currentPageIndex = index
        pdfView?.go(to: page)
    }

    // MARK: - Tool selection

    func selectTool(_ newTool: Tool) {
        tool = newTool
        statusMessage = newTool.help
        if newTool != .tie { pendingTieDestination = nil }
    }

    // MARK: - Tickmark legend (shared, user-editable)

    /// User-editable legend file: `~/Library/Application Support/TicTie/tickmark-legend.json`.
    var legendURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("TicTie", isDirectory: true)
            .appendingPathComponent("tickmark-legend.json")
    }

    /// Loads the legend from disk, seeding it with the bundled default on first
    /// run. Falls back to the compiled-in palette on any error.
    func loadLegend() {
        let url = legendURL
        let fm = FileManager.default
        do {
            if !fm.fileExists(atPath: url.path) {
                try fm.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try TickmarkLegend.bundled().write(to: url)
            }
            palette = try TickmarkLegend.load(from: url).marks
        } catch {
            palette = Tickmark.defaultPalette
        }
        if let id = selectedTickmarkID, !palette.contains(where: { $0.id == id }) {
            selectedTickmarkID = nil
        }
    }

    func reloadLegend() {
        loadLegend()
        statusMessage = "Reloaded tickmark legend (\(palette.count) marks)."
    }

    /// Reveals the legend file in Finder so the user can edit it.
    func revealLegend() {
        if !FileManager.default.fileExists(atPath: legendURL.path) { loadLegend() }
        NSWorkspace.shared.activateFileViewerSelecting([legendURL])
    }

    // MARK: - Bookmark template (shared, user-editable)

    /// User-editable template file:
    /// `~/Library/Application Support/TicTie/bookmark-template.json`.
    var templateURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("TicTie", isDirectory: true)
            .appendingPathComponent("bookmark-template.json")
    }

    func loadTemplate() {
        let url = templateURL
        let fm = FileManager.default
        do {
            if !fm.fileExists(atPath: url.path) {
                try fm.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try BookmarkTemplate.bundled().write(to: url)
            }
            bookmarkTemplate = try BookmarkTemplate.load(from: url)
        } catch {
            bookmarkTemplate = .default
        }
    }

    func revealTemplate() {
        if !FileManager.default.fileExists(atPath: templateURL.path) { loadTemplate() }
        NSWorkspace.shared.activateFileViewerSelecting([templateURL])
    }

    /// Scans page text and adds bookmarks for every rule the template matches.
    func autoBookmark() {
        guard let controller else { return }
        loadTemplate() // pick up any edits the user just made
        let planned = BookmarkPlanner().plan(
            pageTexts: controller.pageTexts(),
            template: bookmarkTemplate
        )
        guard !planned.isEmpty else {
            statusMessage = "No “\(bookmarkTemplate.name)” template matches found in this document."
            return
        }
        for bm in planned {
            controller.addBookmark(label: bm.title, pageIndex: bm.pageIndex)
        }
        refreshUnsaved()
        objectWillChange.send()
        statusMessage = "Added \(planned.count) bookmark(s) from “\(bookmarkTemplate.name)”."
    }

    // MARK: - Tape actions

    func enterTapeAmount() {
        guard let amount = AmountFormatter.parse(tapeInput) else {
            statusMessage = "“\(tapeInput)” isn’t a number."
            return
        }
        tape.enter(amount)
        tapeInput = ""
    }

    func subtractTapeAmount() {
        guard let amount = AmountFormatter.parse(tapeInput) else {
            statusMessage = "“\(tapeInput)” isn’t a number."
            return
        }
        tape.subtract(amount)
        tapeInput = ""
    }

    func clearTape() {
        tape.clear()
        tape.label = ""
        tapeLabel = ""
    }

    // MARK: - Click placement

    /// Called by the PDF view when the user clicks while a tool is armed.
    func handleClick(on page: PDFPage, at point: CGPoint, pageIndex: Int) {
        guard let controller else { return }
        let undo = pdfView?.undoManager

        switch tool {
        case .none:
            return

        case .tickmark:
            guard var mark = selectedTickmark else { return }
            mark.color = activeColor
            controller.place(AnnotationFactory.tickmark(mark, at: point), on: page, undo: undo)
            statusMessage = "Stamped “\(mark.symbol)”."

        case .signOff(let role):
            let initials = role == .preparer ? preparerInitials : reviewerInitials
            guard !initials.trimmingCharacters(in: .whitespaces).isEmpty else {
                statusMessage = "Enter \(role.displayName.lowercased()) initials first."
                return
            }
            let signOff = SignOff(role: role, initials: initials)
            controller.place(AnnotationFactory.signOff(signOff, at: point), on: page, undo: undo)
            statusMessage = "Added \(role.displayName.lowercased()) sign-off."

        case .tape:
            guard !tape.isEmpty else {
                statusMessage = "The tape is empty — add some amounts first."
                return
            }
            tape.label = tapeLabel
            controller.place(AnnotationFactory.tape(tape.rendered(), at: point), on: page, undo: undo)
            statusMessage = "Stamped calculator tape (total \(AmountFormatter.string(from: tape.total)))."

        case .tie:
            handleTieClick(on: page, at: point)
        }

        refreshUnsaved()
        pdfView?.setNeedsDisplay(pdfView?.bounds ?? .zero)
    }

    private func handleTieClick(on page: PDFPage, at point: CGPoint) {
        guard let controller else { return }
        let undo = pdfView?.undoManager

        if pendingTieDestination == nil {
            // First click records the target the marker will jump to.
            pendingTieDestination = PDFDestination(page: page, at: point)
            statusMessage = "Tie target set. Now click where the reference marker should go."
        } else if let destination = pendingTieDestination {
            let targetPage = destination.page.flatMap { controller.document.index(for: $0) } ?? 0
            let label = "→ p.\(targetPage + 1)"
            let annotations = AnnotationFactory.tie(at: point, label: label, destination: destination)
            controller.place(annotations, on: page, undo: undo)
            pendingTieDestination = nil
            statusMessage = "Tie created to page \(targetPage + 1)."
        }
    }

    // MARK: - Page operations

    func rotateCurrentPage() {
        guard let controller else { return }
        controller.rotatePage(at: currentPageIndex, undo: pdfView?.undoManager)
        refreshUnsaved()
        pdfView?.layoutDocumentView()
        statusMessage = "Rotated page \(currentPageIndex + 1)."
    }

    func addBookmarkForCurrentPage() {
        guard let controller else { return }
        let label = "Page \(currentPageIndex + 1)"
        if controller.addBookmark(label: label, pageIndex: currentPageIndex) {
            refreshUnsaved()
            objectWillChange.send()
            statusMessage = "Bookmarked \(label)."
        }
    }

    func bookmarks() -> [(label: String, pageIndex: Int)] {
        controller?.bookmarks() ?? []
    }
}
#endif
