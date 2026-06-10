#if canImport(SwiftUI)
import SwiftUI
import TicTieCore

/// Preparer / reviewer page sign-offs.
struct SignOffView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Sign-offs", systemImage: "signature")

            row(role: .preparer, initials: $model.preparerInitials)
            row(role: .reviewer, initials: $model.reviewerInitials)
        }
    }

    @ViewBuilder
    private func row(role: SignOff.Role, initials: Binding<String>) -> some View {
        HStack(spacing: 6) {
            TextField("\(role.displayName) initials", text: initials)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 120)
            Button {
                model.selectTool(.signOff(role))
            } label: {
                Label(role.displayName, systemImage: "hand.point.up.left")
            }
            .buttonStyle(.bordered)
            .tint(role.color.swiftUIColor)
            .disabled(!model.isDocumentOpen)
        }
    }
}
#endif
