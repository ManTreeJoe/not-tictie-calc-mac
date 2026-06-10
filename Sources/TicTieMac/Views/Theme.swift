#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import AppKit

/// The app's small design system — colors, gradients, radii and the shared
/// animation curves that give TicTie Mac its own clean, springy feel.
enum Theme {
    // Signature accent (cool indigo → violet).
    static let accent  = Color(red: 0.36, green: 0.42, blue: 0.96)
    static let accent2 = Color(red: 0.52, green: 0.32, blue: 0.93)

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accent2],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(nsColor: .underPageBackgroundColor),
                Color(nsColor: .underPageBackgroundColor).opacity(0.85)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    static let cardCorner: CGFloat = 16
    static let controlCorner: CGFloat = 10

    // Shared motion.
    static let spring: Animation = .spring(response: 0.34, dampingFraction: 0.82)
    static let pop: Animation = .spring(response: 0.28, dampingFraction: 0.6)
    static let gentle: Animation = .easeInOut(duration: 0.25)
}

/// Soft, material "card" container used throughout the inspector.
private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.07), radius: 7, x: 0, y: 3)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardModifier()) }
}

/// A button style that scales and dims slightly on press for tactile feedback.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Theme.pop, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

/// A clean section header (icon in an accent-tinted rounded square + title).
struct SectionHeader: View {
    let title: String
    let systemImage: String
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Theme.accent.opacity(0.14))
                )
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            Spacer(minLength: 0)
        }
    }
}
#endif
