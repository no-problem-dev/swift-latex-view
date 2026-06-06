import SwiftUI
import DesignSystem
import LaTeXCore

/// A view that renders a LaTeX math expression.
///
/// Colors, sizing, and the math font come from the design-system
/// environment and the ``MathStyle`` in effect:
///
/// ```swift
/// LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)
///
/// // Inline, baseline-aligned with surrounding text:
/// HStack(alignment: .firstTextBaseline) {
///     Text("where")
///     LaTeXView(#"a \neq 0"#, mode: .inline)
///     Text("holds.")
/// }
/// ```
///
/// When the LaTeX source cannot be parsed — common with truncated LLM
/// output — the view falls back to showing the raw source in a
/// monospaced font with the style's error color.
public struct LaTeXView: View {

    public let expression: MathExpression

    @Environment(\.mathStyle) private var style
    @Environment(\.colorPalette) private var palette
    @Environment(\.spacingScale) private var spacing

    public init(_ expression: MathExpression) {
        self.expression = expression
    }

    public init(_ latex: String, mode: MathMode = .display) {
        self.expression = MathExpression(latex, mode: mode)
    }

    public var body: some View {
        if let rendered = renderedMath {
            switch expression.mode {
            case .display:
                mathImage(rendered)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(style.padding(spacing))
            case .inline:
                mathImage(rendered)
                    .alignmentGuide(.firstTextBaseline) { _ in rendered.size.height - rendered.descent }
                    .alignmentGuide(.lastTextBaseline) { _ in rendered.size.height - rendered.descent }
            }
        } else {
            fallback
        }
    }

    private var renderedMath: RenderedMath? {
        MathImageRenderer.render(
            latex: expression.latex,
            mode: expression.mode,
            fontFamily: style.fontFamily,
            fontSize: expression.mode == .display ? style.displayFontSize : style.inlineFontSize,
            color: style.textColor(palette)
        )
    }

    private func mathImage(_ rendered: RenderedMath) -> Image {
        #if canImport(UIKit)
        Image(uiImage: rendered.image)
        #elseif canImport(AppKit)
        Image(nsImage: rendered.image)
        #endif
    }

    private var fallback: some View {
        Text(expression.latex)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(style.errorColor(palette))
    }
}
