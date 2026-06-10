#if canImport(PDFKit) && canImport(AppKit)
import PDFKit
import AppKit
import TicTieCore

/// Builds `PDFAnnotation`s from the `TicTieCore` domain models. Keeping this in
/// one place means the placement code in the UI never has to know PDFKit's
/// annotation-construction details.
enum AnnotationFactory {

    static func nsColor(_ color: AnnotationColor, alpha: CGFloat = 1) -> NSColor {
        let rgb = color.rgb
        return NSColor(
            calibratedRed: rgb.red,
            green: rgb.green,
            blue: rgb.blue,
            alpha: alpha
        )
    }

    // MARK: - Tickmark

    /// A small, borderless free-text annotation that draws the tickmark glyph
    /// at the clicked point. The meaning is stored as the annotation contents
    /// so it surfaces in tooltips and PDF text search.
    static func tickmark(_ mark: Tickmark, at point: CGPoint) -> PDFAnnotation {
        let size = max(18.0, CGFloat(mark.symbol.count) * 11.0 + 8.0)
        let bounds = CGRect(
            x: point.x - size / 2,
            y: point.y - 9,
            width: size,
            height: 20
        )
        let annotation = PDFAnnotation(
            bounds: bounds,
            forType: .freeText,
            withProperties: nil
        )
        // `contents` is the drawn text *and* the searchable value; the meaning
        // lives in the tooltip so the glyph stays clean on the page.
        annotation.contents = mark.symbol
        annotation.color = .clear                     // no background fill
        annotation.fontColor = nsColor(mark.color)
        annotation.font = NSFont.boldSystemFont(ofSize: 14)
        annotation.alignment = .center
        return annotation
    }

    // MARK: - Calculator tape

    /// A bordered, monospaced free-text block containing the rendered tape.
    static func tape(_ rendered: String, at point: CGPoint) -> PDFAnnotation {
        let lines = rendered.split(separator: "\n", omittingEmptySubsequences: false)
        let widest = lines.map(\.count).max() ?? 12
        let charWidth: CGFloat = 7
        let lineHeight: CGFloat = 13
        let padding: CGFloat = 6
        let width = CGFloat(widest) * charWidth + padding * 2
        let height = CGFloat(lines.count) * lineHeight + padding * 2

        let bounds = CGRect(x: point.x, y: point.y - height, width: width, height: height)
        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        annotation.contents = rendered
        annotation.color = NSColor(calibratedWhite: 1.0, alpha: 0.92)
        annotation.fontColor = NSColor.black
        annotation.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        annotation.alignment = .left

        let border = PDFBorder()
        border.lineWidth = 0.75
        annotation.border = border
        return annotation
    }

    // MARK: - Sign-off

    static func signOff(_ signOff: SignOff, at point: CGPoint) -> PDFAnnotation {
        let text = signOff.rendered()
        let width = CGFloat(text.count) * 7.5 + 10
        let bounds = CGRect(x: point.x, y: point.y - 9, width: width, height: 20)
        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        annotation.contents = text
        annotation.color = .clear
        annotation.fontColor = nsColor(signOff.role.color)
        annotation.font = NSFont.boldSystemFont(ofSize: 11)
        annotation.alignment = .left
        return annotation
    }

    // MARK: - Cross-reference "tie"

    /// A link annotation at `point` that jumps to `destination` when clicked,
    /// plus a small visible marker so the tie is discoverable on the page.
    static func tie(
        at point: CGPoint,
        label: String,
        destination: PDFDestination,
        color: AnnotationColor = .blue
    ) -> [PDFAnnotation] {
        let markerWidth = max(20.0, CGFloat(label.count) * 7.5 + 6)
        let bounds = CGRect(x: point.x, y: point.y - 9, width: markerWidth, height: 18)

        let marker = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        marker.contents = label
        marker.color = .clear
        marker.fontColor = nsColor(color)
        marker.font = NSFont(name: "Menlo-BoldItalic", size: 11) ?? NSFont.boldSystemFont(ofSize: 11)
        marker.alignment = .center

        let link = PDFAnnotation(bounds: bounds, forType: .link, withProperties: nil)
        link.action = PDFActionGoTo(destination: destination)

        return [marker, link]
    }
}
#endif
