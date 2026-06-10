#if canImport(SwiftUI) && canImport(PDFKit) && canImport(AppKit)
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        NavigationSplitView {
            inspector
                .frame(minWidth: 300, idealWidth: 340)
                .background(.background)
        } detail: {
            detail
        }
        .navigationTitle(model.documentTitle)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom, spacing: 0) { statusBar }
    }

    // MARK: - Inspector (sidebar)

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let badge = model.toolBadge {
                    toolChip(badge)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }

                TickmarkPaletteView(model: model).cardStyle()
                CalculatorTapeView(model: model).cardStyle()
                SignOffView(model: model).cardStyle()
                crossReferenceCard.cardStyle()
                BookmarksView(model: model).cardStyle()
            }
            .padding(16)
            .animation(Theme.spring, value: model.toolBadge?.label)
        }
        .scrollContentBackground(.hidden)
    }

    private var header: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.accentGradient)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                )
                .shadow(color: Theme.accent.opacity(0.4), radius: 6, y: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text("TicTie")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                Text("Workpaper annotation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func toolChip(_ badge: (label: String, systemImage: String)) -> some View {
        HStack(spacing: 8) {
            Image(systemName: badge.systemImage)
                .symbolEffect(.pulse, options: .repeating)
            Text(badge.label)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Spacer(minLength: 4)
            Button {
                withAnimation(Theme.spring) { model.selectTool(.none) }
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(Theme.accentGradient))
        .shadow(color: Theme.accent.opacity(0.35), radius: 8, y: 3)
    }

    private var crossReferenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Cross-reference (Tie)", systemImage: "link")
            Button {
                withAnimation(Theme.spring) { model.selectTool(.tie) }
            } label: {
                Label("Create Tie", systemImage: "link.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(model.tool == .tie ? Theme.accent : Color.secondary.opacity(0.5))
            .disabled(!model.isDocumentOpen)
            Text("Links a marker on one page to a target elsewhere in the document.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Detail (PDF)

    @ViewBuilder
    private var detail: some View {
        ZStack {
            Theme.canvasGradient.ignoresSafeArea()
            if model.isDocumentOpen {
                PDFViewerView(model: model)
                    .transition(.opacity)
            } else {
                EmptyStateView { openDocument() }
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(Theme.gentle, value: model.isDocumentOpen)
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
                    withAnimation(Theme.spring) { model.selectTool(.none) }
                } label: {
                    Label("Done Placing", systemImage: "cursorarrow")
                }
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
                Circle().fill(Theme.accentGradient).frame(width: 8, height: 8)
                    .transition(.scale)
            }
            Text(model.statusMessage)
                .font(.callout)
                .lineLimit(1)
                .contentTransition(.opacity)
            Spacer()
            if model.isDocumentOpen {
                Text("Page \(model.currentPageIndex + 1) of \(model.controller?.pageCount ?? 0)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                if model.hasUnsavedChanges {
                    Label("Unsaved", systemImage: "circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.bar)
        .overlay(Divider(), alignment: .top)
        .animation(Theme.gentle, value: model.statusMessage)
        .animation(Theme.spring, value: model.hasUnsavedChanges)
    }

    // MARK: - Actions

    private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            withAnimation(Theme.gentle) { model.open(url: url) }
        }
    }
}

/// A polished, gently animated placeholder shown before a PDF is opened.
private struct EmptyStateView: View {
    var onOpen: () -> Void
    @State private var float = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .blur(radius: 4)
                Image(systemName: "doc.richtext")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.accentGradient)
            }
            .offset(y: float ? -7 : 7)
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: float)

            VStack(spacing: 6) {
                Text("Open a PDF workpaper to begin")
                    .font(.title2.weight(.semibold))
                Text("Stamp tickmarks, run calculator tapes, tie cross-references and sign off.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            Button(action: onOpen) {
                Label("Open PDF…", systemImage: "folder")
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .controlSize(.large)
        }
        .padding(40)
        .onAppear { float = true }
    }
}
#endif
