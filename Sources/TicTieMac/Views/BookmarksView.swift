#if canImport(SwiftUI)
import SwiftUI

/// Bookmark (PDF outline) management and page operations.
struct BookmarksView: View {
    @ObservedObject var model: AppModel
    @State private var hoveredIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Bookmarks & Pages", systemImage: "bookmark")

            HStack(spacing: 8) {
                pillButton("Bookmark Page", systemImage: "bookmark.fill") {
                    withAnimation(Theme.spring) { model.addBookmarkForCurrentPage() }
                }
                pillButton("Rotate", systemImage: "rotate.right") {
                    model.rotateCurrentPage()
                }
                .help("Rotate the current page 90° clockwise")
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation(Theme.spring) { model.autoBookmark() }
                } label: {
                    Label("Auto-Bookmark", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(!model.isDocumentOpen)
                .help("Scan page text and bookmark recognized forms using the template")

                Button { model.revealTemplate() } label: {
                    Label("Template", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .font(.caption)
                .help("Edit the auto-bookmark template (JSON)")
            }

            bookmarkList
        }
    }

    private func pillButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(!model.isDocumentOpen)
    }

    @ViewBuilder
    private var bookmarkList: some View {
        let bookmarks = model.bookmarks()
        if bookmarks.isEmpty {
            Text("No bookmarks yet.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(spacing: 2) {
                ForEach(Array(bookmarks.enumerated()), id: \.offset) { index, bm in
                    Button {
                        withAnimation(Theme.spring) { model.goToPage(bm.pageIndex) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.accent)
                            Text(bm.label)
                                .lineLimit(1)
                            Spacer()
                            Text("p.\(bm.pageIndex + 1)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.primary.opacity(hoveredIndex == index ? 0.08 : 0.0))
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(Theme.gentle) { hoveredIndex = hovering ? index : nil }
                    }
                }
            }
        }
    }
}
#endif
