#if canImport(SwiftUI)
import SwiftUI
import TicTieCore

/// The adding-machine tape: enter amounts, build a running total, then stamp
/// the whole tape onto the workpaper.
struct CalculatorTapeView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Calculator Tape", systemImage: "list.number")

            TextField("Tape label (optional)", text: $model.tapeLabel)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 6) {
                TextField("Amount", text: $model.tapeInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { model.enterTapeAmount() }
                Button("+") { model.enterTapeAmount() }
                    .help("Add to the tape")
                Button("−") { model.subtractTapeAmount() }
                    .help("Subtract from the tape")
            }

            tapeList

            HStack {
                Text("Total")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(AmountFormatter.string(from: model.tape.total))
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundStyle(model.tape.total < 0 ? Color.red : Color.primary)
            }
            .padding(.vertical, 2)

            HStack {
                Button {
                    model.selectTool(.tape)
                } label: {
                    Label("Stamp on Page", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.tape.isEmpty || !model.isDocumentOpen)

                Spacer()

                Button(role: .destructive) { model.clearTape() } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(model.tape.isEmpty)
            }
        }
    }

    @ViewBuilder
    private var tapeList: some View {
        if model.tape.isEmpty {
            Text("No entries yet.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
        } else {
            VStack(spacing: 0) {
                ForEach(model.tape.entries) { entry in
                    HStack {
                        Text(entry.op.symbol)
                            .foregroundStyle(entry.op == .add ? Color.green : Color.red)
                            .frame(width: 14)
                        Spacer()
                        Text(AmountFormatter.string(from: entry.amount))
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                }
            }
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(maxHeight: 160)
        }
    }
}
#endif
