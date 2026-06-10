#if canImport(SwiftUI)
import SwiftUI
import TicTieCore

extension AnnotationColor {
    var swiftUIColor: Color {
        Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}

/// The tickmark palette: pick a color, pick a glyph, then click the page.
struct TickmarkPaletteView: View {
    @ObservedObject var model: AppModel

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Tickmarks", systemImage: "checkmark.seal")

            HStack(spacing: 8) {
                ForEach(AnnotationColor.allCases) { color in
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle().strokeBorder(
                                Color.primary.opacity(model.activeColor == color ? 0.9 : 0),
                                lineWidth: 2
                            )
                        )
                        .onTapGesture { model.activeColor = color }
                        .help(color.displayName)
                }
                Spacer()
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(model.palette) { mark in
                    Button {
                        model.selectedTickmarkID = mark.id
                        model.activeColor = mark.color
                        model.selectTool(.tickmark)
                    } label: {
                        Text(mark.symbol)
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 32)
                    }
                    .buttonStyle(.bordered)
                    .tint(isSelected(mark) ? model.activeColor.swiftUIColor : Color.gray)
                    .help(mark.meaning)
                }
            }

            if let mark = model.selectedTickmark, model.tool == .tickmark {
                Text("\(mark.symbol) — \(mark.meaning)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func isSelected(_ mark: Tickmark) -> Bool {
        model.tool == .tickmark && model.selectedTickmarkID == mark.id
    }
}

/// Small reusable section header used across the inspector panels.
struct SectionHeader: View {
    let title: String
    let systemImage: String
    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
    }
}
#endif
