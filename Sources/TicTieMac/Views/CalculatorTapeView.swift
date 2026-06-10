#if canImport(SwiftUI)
import SwiftUI
import TicTieCore

/// The adding-machine tape: enter amounts, build a running total, then stamp
/// the whole tape onto the workpaper.
struct CalculatorTapeView: View {
    @ObservedObject var model: AppModel
    @FocusState private var amountFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Calculator Tape", systemImage: "list.number")

            TextField("Tape label (optional)", text: $model.tapeLabel)
                .textFieldStyle(.roundedBorder)

            inputRow
            tapeList
            totalRow
            actionRow
        }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("Amount", text: $model.tapeInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .focused($amountFocused)
                .onSubmit { commit(model.enterTapeAmount) }

            circleButton("plus", color: .green) { commit(model.enterTapeAmount) }
            circleButton("minus", color: .red) { commit(model.subtractTapeAmount) }
        }
    }

    private func circleButton(_ symbol: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(color.gradient))
                .shadow(color: color.opacity(0.4), radius: 4, y: 2)
        }
        .buttonStyle(.pressable)
    }

    @ViewBuilder
    private var tapeList: some View {
        if model.tape.isEmpty {
            Text("No entries yet — type an amount and tap +.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(model.tape.entries.enumerated()), id: \.element.id) { index, entry in
                    HStack {
                        Image(systemName: entry.op == .add ? "plus" : "minus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(entry.op == .add ? Color.green : Color.red)
                            .frame(width: 14)
                        Spacer()
                        Text(AmountFormatter.string(from: entry.amount))
                            .font(.system(.callout, design: .monospaced))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(index % 2 == 1 ? Color.primary.opacity(0.035) : .clear)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
            )
            .frame(maxHeight: 180)
        }
    }

    private var totalRow: some View {
        HStack {
            Text("TOTAL")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.secondary)
                .tracking(1.2)
            Spacer()
            Text(AmountFormatter.string(from: model.tape.total))
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundStyle(model.tape.total < 0 ? Color.red : Color.primary)
                .contentTransition(.numericText())
                .animation(Theme.spring, value: model.tape.total)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: Theme.controlCorner, style: .continuous)
                .fill(Theme.accent.opacity(0.10))
        )
    }

    private var actionRow: some View {
        HStack {
            Button {
                withAnimation(Theme.spring) { model.selectTool(.tape) }
            } label: {
                Label("Stamp on Page", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .disabled(model.tape.isEmpty || !model.isDocumentOpen)

            Button(role: .destructive) {
                withAnimation(Theme.spring) { model.clearTape() }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(model.tape.isEmpty)
            .help("Clear the tape")
        }
    }

    /// Runs a tape mutation inside an animation and keeps focus for fast entry.
    private func commit(_ action: () -> Void) {
        withAnimation(Theme.spring) { action() }
        amountFocused = true
    }
}
#endif
