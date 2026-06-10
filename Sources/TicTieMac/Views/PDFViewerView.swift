#if canImport(SwiftUI) && canImport(PDFKit) && canImport(AppKit)
import SwiftUI
import PDFKit
import AppKit

/// A `PDFView` subclass that, when a placement tool is armed, intercepts the
/// click and reports the page + page-space point instead of selecting text.
final class PlacementPDFView: PDFView {
    var isPlacementActive: @MainActor () -> Bool = { false }
    var onPlacementClick: @MainActor (PDFPage, CGPoint, Int) -> Void = { _, _, _ in }

    override func mouseDown(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        guard isPlacementActive(), let page = page(for: viewPoint, nearest: true) else {
            super.mouseDown(with: event)
            return
        }
        let pagePoint = convert(viewPoint, to: page)
        let index = document?.index(for: page) ?? 0
        onPlacementClick(page, pagePoint, index)
    }

    /// A crosshair cursor while a placement tool is active makes the mode obvious.
    override func resetCursorRects() {
        if isPlacementActive() {
            addCursorRect(bounds, cursor: .crosshair)
        } else {
            super.resetCursorRects()
        }
    }
}

/// SwiftUI bridge for the PDF view.
struct PDFViewerView: NSViewRepresentable {
    @ObservedObject var model: AppModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeNSView(context: Context) -> PlacementPDFView {
        let view = PlacementPDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displaysPageBreaks = true
        view.backgroundColor = NSColor.windowBackgroundColor

        view.isPlacementActive = { [weak model] in
            guard let model else { return false }
            return model.tool != .none
        }
        view.onPlacementClick = { [weak model] page, point, index in
            model?.handleClick(on: page, at: point, pageIndex: index)
        }

        model.pdfView = view
        if let document = model.controller?.document {
            view.document = document
        }

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: view
        )
        return view
    }

    func updateNSView(_ nsView: PlacementPDFView, context: Context) {
        if nsView.document !== model.controller?.document {
            nsView.document = model.controller?.document
        }
        // Refresh the cursor when the tool changes.
        nsView.window?.invalidateCursorRects(for: nsView)
    }

    final class Coordinator: NSObject {
        let model: AppModel
        init(model: AppModel) { self.model = model }

        @objc func pageChanged(_ note: Notification) {
            guard let view = note.object as? PDFView,
                  let page = view.currentPage,
                  let index = view.document?.index(for: page) else { return }
            Task { @MainActor in
                if model.currentPageIndex != index {
                    model.currentPageIndex = index
                }
            }
        }
    }
}
#endif
