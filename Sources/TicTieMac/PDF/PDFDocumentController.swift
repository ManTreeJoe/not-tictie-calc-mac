#if canImport(PDFKit) && canImport(AppKit)
import PDFKit
import AppKit
import TicTieCore

/// Thin wrapper around a `PDFDocument` that exposes the workpaper operations
/// the app needs: stamping annotations, rotating pages, managing bookmarks and
/// saving. Annotation placement is intentionally undo-friendly — every mutation
/// records an inverse on the supplied `UndoManager` when one is provided.
final class PDFDocumentController {

    let document: PDFDocument
    let url: URL?
    private(set) var hasUnsavedChanges = false

    init(document: PDFDocument, url: URL?) {
        self.document = document
        self.url = url
    }

    convenience init?(url: URL) {
        guard let doc = PDFDocument(url: url) else { return nil }
        self.init(document: doc, url: url)
    }

    var pageCount: Int { document.pageCount }

    func page(at index: Int) -> PDFPage? {
        guard index >= 0, index < document.pageCount else { return nil }
        return document.page(at: index)
    }

    // MARK: - Annotation placement

    func place(_ annotation: PDFAnnotation, on page: PDFPage, undo: UndoManager? = nil) {
        page.addAnnotation(annotation)
        hasUnsavedChanges = true
        undo?.registerUndo(withTarget: self) { controller in
            controller.remove(annotation, from: page, undo: undo)
        }
        undo?.setActionName("Add Annotation")
    }

    func place(_ annotations: [PDFAnnotation], on page: PDFPage, undo: UndoManager? = nil) {
        annotations.forEach { place($0, on: page, undo: undo) }
    }

    func remove(_ annotation: PDFAnnotation, from page: PDFPage, undo: UndoManager? = nil) {
        page.removeAnnotation(annotation)
        hasUnsavedChanges = true
        undo?.registerUndo(withTarget: self) { controller in
            controller.place(annotation, on: page, undo: undo)
        }
    }

    // MARK: - Page rotation

    /// Rotates a page 90° clockwise (TicTie's "single-click rotate").
    func rotatePage(at index: Int, by degrees: Int = 90, undo: UndoManager? = nil) {
        guard let page = page(at: index) else { return }
        page.rotation = normalizedRotation(page.rotation + degrees)
        hasUnsavedChanges = true
        undo?.registerUndo(withTarget: self) { controller in
            controller.rotatePage(at: index, by: -degrees, undo: undo)
        }
        undo?.setActionName("Rotate Page")
    }

    private func normalizedRotation(_ value: Int) -> Int {
        let r = value % 360
        return r < 0 ? r + 360 : r
    }

    // MARK: - Bookmarks (PDF outline)

    /// Adds a top-level outline entry pointing at the top of `pageIndex`.
    @discardableResult
    func addBookmark(label: String, pageIndex: Int) -> Bool {
        guard let page = page(at: pageIndex) else { return false }
        let root = document.outlineRoot ?? {
            let newRoot = PDFOutline()
            document.outlineRoot = newRoot
            return newRoot
        }()

        let bounds = page.bounds(for: .mediaBox)
        let destination = PDFDestination(page: page, at: CGPoint(x: 0, y: bounds.height))
        let entry = PDFOutline()
        entry.label = label
        entry.destination = destination
        root.insertChild(entry, at: root.numberOfChildren)
        hasUnsavedChanges = true
        return true
    }

    /// Extracted text of every page, for template-driven auto-bookmarking.
    func pageTexts() -> [String] {
        var texts: [String] = []
        texts.reserveCapacity(document.pageCount)
        for i in 0..<document.pageCount {
            texts.append(document.page(at: i)?.string ?? "")
        }
        return texts
    }

    /// Flat list of top-level bookmarks as `(label, pageIndex)`.
    func bookmarks() -> [(label: String, pageIndex: Int)] {
        guard let root = document.outlineRoot else { return [] }
        var result: [(String, Int)] = []
        for i in 0..<root.numberOfChildren {
            guard let child = root.child(at: i) else { continue }
            let label = child.label ?? "Untitled"
            let pageIndex = child.destination?.page.flatMap { document.index(for: $0) } ?? 0
            result.append((label, pageIndex))
        }
        return result
    }

    // MARK: - Saving

    @discardableResult
    func save() -> Bool {
        guard let url else { return false }
        return save(to: url)
    }

    @discardableResult
    func save(to destination: URL) -> Bool {
        let ok = document.write(to: destination)
        if ok { hasUnsavedChanges = false }
        return ok
    }
}
#endif
