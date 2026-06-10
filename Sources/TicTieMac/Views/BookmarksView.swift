#if canImport(SwiftUI)
import SwiftUI

/// Bookmark (PDF outline) management and page operations.
struct BookmarksView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Bookmarks & Pages", systemImage: "bookmark")

            HStack {
                Button {
                    model.addBookmarkForCurrentPage()
                } label: {
                    Label("Bookmark Page", systemImage: "bookmark.fill")
                }
                .disabled(!model.isDocumentOpen)

                Button {
                    model.rotateCurrentPage()
                } label: {
                    Label("Rotate", systemImage: "rotate.right")
                }
                .disabled(!model.isDocumentOpen)
                .help("Rotate the current page 90° clockwise")
            }

            let bookmarks = model.bookmarks()
            if bookmarks.isEmpty {
                Text("No bookmarks yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(bookmarks.enumerated()), id: \.offset) { _, bm in
                        Button {
                            model.goToPage(bm.pageIndex)
                        } label: {
                            HStack {
                                Image(systemName: "bookmark")
                                Text(bm.label)
                                Spacer()
                                Text("p.\(bm.pageIndex + 1)")
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                    }
                }
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}
#endif
