#if canImport(SwiftUI) && canImport(PDFKit) && canImport(AppKit)
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        NavigationSplitView {
            inspector
                .frame(minWidth: 280, idealWidth: 320)
        } detail: {
            detail
        }
        .navigationTitle(model.documentTitle)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { statusBar }
    }

    // MARK: - Inspector (sidebar)

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TickmarkPaletteView(model: model)
                Divider()
                CalculatorTapeView(model: model)
                Divider()
                SignOffView(model: model)
                Divider()
                crossReferenceSection
                Divider()
                BookmarksView(model: model)
            }
            .padding(16)
        }
    }

    private var crossReferenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Cross-reference (Tie)", systemImage: "link")
            Button {
                model.selectTool(.tie)
            } label: {
                Label("Create Tie", systemImage: "link.badge.plus")
            }
            .buttonStyle(.bordered)
            .tint(model.tool == .tie ? Color.accentColor : Color.gray)
            .disabled(!model.isDocumentOpen)
            Text("Links a marker on one page to a target elsewhere in the document.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Detail (PDF)

    @ViewBuilder
    private var detail: some View {
        if model.isDocumentOpen {
            PDFViewerView(model: model)
                .background(Color(nsColor: .underPageBackgroundColor))
        } else {
            VStack(spacing: 14) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text("Open a PDF workpaper to begin")
                    .font(.title3)
                Button {
                    openDocument()
                } label: {
                    Label("Open PDF…", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { openDocument() } label: {
                Label("Open", systemImage: "folder")
            }
            Button { model.save() } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(!model.isDocumentOpen)
        }

        ToolbarItemGroup(placement: .principal) {
            if model.tool != .none {
                Button {
                    model.selectTool(.none)
                } label: {
                    Label("Done Placing", systemImage: "cursorarrow")
                }
                .help("Stop placing and return to normal selection")
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button { model.rotateCurrentPage() } label: {
                Label("Rotate", systemImage: "rotate.right")
            }
            .disabled(!model.isDocumentOpen)
        }
    }

    // MARK: - Status bar

    private var statusBar: some View {
        HStack(spacing: 8) {
            if model.tool != .none {
                Circle().fill(Color.accentColor).frame(width: 8, height: 8)
            }
            Text(model.statusMessage)
                .font(.callout)
                .lineLimit(1)
            Spacer()
            if model.isDocumentOpen {
                Text("Page \(model.currentPageIndex + 1) of \(model.controller?.pageCount ?? 0)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if model.hasUnsavedChanges {
                    Text("• Unsaved")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Actions

    private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            model.open(url: url)
        }
    }
}
#endif
