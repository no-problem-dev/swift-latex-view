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
                ScrollableDisplayMath(image: mathImage(rendered), padding: style.padding(spacing))
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

/// Display math wider than the container scrolls horizontally instead of
/// expanding the surrounding layout — the SwiftUI counterpart of KaTeX's
/// `overflow-x: auto`. Math that fits stays centered, with bounce disabled
/// so the scroll view is inert.
private struct ScrollableDisplayMath: View {
    let image: Image
    let padding: CGFloat

    @State private var containerWidth: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            image
                .padding(padding)
                .frame(minWidth: containerWidth, alignment: .center)
        }
        .scrollBounceBehavior(.basedOnSize, axes: [.horizontal])
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            containerWidth = width
        }
    }
}

// MARK: - Inline Text API

extension LaTeXView {

    /// Renders inline math as a `Text` segment for text concatenation.
    ///
    /// Use this when math must participate in a larger `Text` composition
    /// (e.g. a Markdown paragraph built from concatenated segments), where
    /// a `View` cannot be embedded. The image is baseline-aligned with the
    /// surrounding text via its typeset descent.
    ///
    /// - Parameters:
    ///   - latex: The LaTeX source without delimiters.
    ///   - fontFamily: The math font. Defaults to Latin Modern.
    ///   - fontSize: The point size; should match the surrounding text.
    ///   - color: The text color. Color resolution from a design-system
    ///     palette is the caller's responsibility.
    /// - Returns: A `Text` segment, or `nil` if the LaTeX fails to parse.
    @MainActor
    public static func inlineText(
        _ latex: String,
        fontFamily: MathFontFamily = .latinModern,
        fontSize: CGFloat = 17,
        color: Color
    ) -> Text? {
        guard let rendered = MathImageRenderer.render(
            latex: latex,
            mode: .inline,
            fontFamily: fontFamily,
            fontSize: fontSize,
            color: color
        ) else {
            return nil
        }
        #if canImport(UIKit)
        let image = Image(uiImage: rendered.image)
        #elseif canImport(AppKit)
        let image = Image(nsImage: rendered.image)
        #endif
        return Text(image).baselineOffset(-rendered.descent)
    }
}
