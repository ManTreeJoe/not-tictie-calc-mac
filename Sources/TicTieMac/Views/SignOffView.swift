#if canImport(SwiftUI)
import SwiftUI
import TicTieCore

/// Preparer / reviewer page sign-offs.
struct SignOffView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Sign-offs", systemImage: "signature")
            row(role: .preparer, initials: $model.preparerInitials)
            row(role: .reviewer, initials: $model.reviewerInitials)
        }
    }

    @ViewBuilder
    private func row(role: SignOff.Role, initials: Binding<String>) -> some View {
        let armed = model.tool == .signOff(role)
        HStack(spacing: 8) {
            TextField("\(role.displayName) initials", text: initials)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 130)

            Button {
                withAnimation(Theme.spring) { model.selectTool(.signOff(role)) }
            } label: {
                Label(role.displayName, systemImage: armed ? "hand.point.up.left.fill" : "hand.point.up.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(armed ? role.color.swiftUIColor : Color.secondary.opacity(0.5))
            .disabled(!model.isDocumentOpen)
        }
    }
}
#endif
