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
    @State private var hoveredID: UUID?

    private let columns = [GridItem(.adaptive(minimum: 54), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Tickmarks", systemImage: "checkmark.seal")

            colorRow

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(model.palette) { mark in
                    tickmarkButton(mark)
                }
            }

            footer
        }
    }

    private var colorRow: some View {
        HStack(spacing: 10) {
            ForEach(AnnotationColor.allCases) { color in
                let selected = model.activeColor == color
                Circle()
                    .fill(color.swiftUIColor.gradient)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().strokeBorder(.white.opacity(selected ? 0.9 : 0), lineWidth: 2)
                    )
                    .overlay(
                        Circle().strokeBorder(color.swiftUIColor.opacity(selected ? 1 : 0), lineWidth: 2)
                            .padding(-3)
                    )
                    .scaleEffect(selected ? 1.18 : 1)
                    .shadow(color: color.swiftUIColor.opacity(selected ? 0.5 : 0), radius: 5)
                    .contentShape(Circle())
                    .onTapGesture {
                        withAnimation(Theme.pop) { model.activeColor = color }
                    }
                    .help(color.displayName)
            }
            Spacer(minLength: 0)
        }
    }

    private func tickmarkButton(_ mark: Tickmark) -> some View {
        let selected = model.tool == .tickmark && model.selectedTickmarkID == mark.id
        let tint = selected ? model.activeColor : mark.color
        return Button {
            withAnimation(Theme.spring) {
                model.selectedTickmarkID = mark.id
                model.activeColor = mark.color
                model.selectTool(.tickmark)
            }
        } label: {
            Text(mark.symbol)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(selected ? .white : tint.swiftUIColor)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous)
                        .fill(selected ? AnyShapeStyle(tint.swiftUIColor.gradient)
                                       : AnyShapeStyle(Color.primary.opacity(hoveredID == mark.id ? 0.08 : 0.04)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous)
                        .strokeBorder(tint.swiftUIColor.opacity(selected ? 0 : 0.18), lineWidth: 1)
                )
                .shadow(color: tint.swiftUIColor.opacity(selected ? 0.35 : 0), radius: 6, y: 2)
                .scaleEffect(selected ? 1.05 : 1)
        }
        .buttonStyle(.pressable)
        .onHover { hovering in
            withAnimation(Theme.gentle) { hoveredID = hovering ? mark.id : nil }
        }
        .help(mark.meaning)
    }

    @ViewBuilder
    private var footer: some View {
        if let mark = model.selectedTickmark, model.tool == .tickmark {
            Text("\(mark.symbol)  ·  \(mark.meaning)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }

        HStack(spacing: 14) {
            Button {
                model.revealLegend()
            } label: {
                Label("Edit Legend", systemImage: "square.and.pencil")
            }
            Button {
                withAnimation(Theme.spring) { model.reloadLegend() }
            } label: {
                Label("Reload", systemImage: "arrow.clockwise")
            }
            Spacer()
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .font(.caption)
        .help("The legend is a shared JSON file the Acrobat plug-in uses too.")
    }
}
#endif
