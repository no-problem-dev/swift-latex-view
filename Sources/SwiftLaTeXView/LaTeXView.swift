import SwiftUI
import DesignSystem
import LaTeXCore

/// A SwiftUI view that typesets LaTeX math.
///
/// Color, size, and math font are read from the surrounding DesignSystem environment and the
/// ``MathStyle`` in effect, so math follows the app's theme without being configured at each site.
///
/// ```swift
/// LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)
///
/// // Inline math — aligned to the surrounding text baseline:
/// HStack(alignment: .firstTextBaseline) {
///     Text("where")
///     LaTeXView(#"a \neq 0"#, mode: .inline)
///     Text("holds.")
/// }
/// ```
///
/// Source that cannot be parsed — a truncated LLM response, say — falls back to showing the source
/// the engine was given, in a monospaced font tinted with the style's error color. There is no
/// crash and no empty view, but the view itself keeps no error: call `MathExpression.validate()`
/// first if the caller needs to know why.
public struct LaTeXView: View {

    /// The expression to typeset, kept verbatim — nothing is parsed until the body is evaluated.
    public let expression: MathExpression

    @Environment(\.mathStyle) private var style
    @Environment(\.colorPalette) private var palette
    @Environment(\.spacingScale) private var spacing

    /// Creates a view for an expression you already hold.
    ///
    /// This is the initializer to use after splitting prose with `MathSegmenter`, which hands
    /// back `MathExpression` values with their delimiters already stripped.
    ///
    /// - Parameter expression: The expression to typeset.
    public init(_ expression: MathExpression) {
        self.expression = expression
    }

    /// Creates a view from a LaTeX string.
    ///
    /// - Parameters:
    ///   - latex: LaTeX source **without** delimiters, for example `#"\frac{1}{2}"#`.
    ///     Leaving the delimiters in — `"$\frac{1}{2}$"` — typesets them as literal characters.
    ///   - mode: The layout mode. Defaults to `MathMode.display`.
    public init(_ latex: String, mode: MathMode = .display) {
        self.expression = MathExpression(latex, mode: mode)
    }

    public var body: some View {
        switch renderedMath {
        case .success(let rendered):
            switch expression.mode {
            case .display:
                ScrollableDisplayMath(image: mathImage(rendered), padding: style.padding(spacing))
            case .inline:
                mathImage(rendered)
                    .alignmentGuide(.firstTextBaseline) { _ in rendered.size.height - rendered.descent }
                    .alignmentGuide(.lastTextBaseline) { _ in rendered.size.height - rendered.descent }
            }
        case .failure(let failure):
            fallback(failure)
        }
    }

    private var renderedMath: Result<RenderedMath, MathRenderFailure> {
        do {
            return .success(try MathImageRenderer.render(
                latex: expression.latex,
                mode: expression.mode,
                fontFamily: style.fontFamily,
                fontSize: expression.mode == .display ? style.displayFontSize : style.inlineFontSize,
                color: style.textColor(palette)
            ))
        } catch {
            return .failure(error)
        }
    }

    private func mathImage(_ rendered: RenderedMath) -> Image {
        #if canImport(UIKit)
        Image(uiImage: rendered.image)
        #elseif canImport(AppKit)
        Image(nsImage: rendered.image)
        #endif
    }

    private func fallback(_ failure: MathRenderFailure) -> some View {
        Text(failure.source)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(style.errorColor(palette))
    }
}

/// Lets display math that is wider than its container scroll horizontally, instead of forcing the
/// surrounding layout to grow — the equivalent of KaTeX's `overflow-x: auto`.
///
/// Math that does fit stays centered, and bounce is switched off so the scroll view sits still
/// rather than rubber-banding under a formula that has nowhere to go.
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

    /// Typesets inline math as a `Text` segment so it can be concatenated with other text.
    ///
    /// Reach for this where a `View` cannot go — inside a `Text` composition built by joining
    /// segments, such as a rendered Markdown paragraph. The typeset descent is applied as a
    /// baseline offset so the formula sits on the same line as the words around it.
    ///
    /// Unlike the ``LaTeXView`` initializers this method reads nothing from the environment:
    /// neither ``SwiftUICore/EnvironmentValues/mathStyle`` nor the color palette. Pass
    /// `fontFamily`, `fontSize`, and `color` that match the surrounding text, or the math will
    /// visibly disagree with it.
    ///
    /// - Parameters:
    ///   - latex: LaTeX source without delimiters.
    ///   - fontFamily: The math font. Defaults to Latin Modern.
    ///   - fontSize: Point size. Match the size of the surrounding text.
    ///   - color: The text color. Resolving it from a design system palette is the caller's job.
    /// - Returns: A `Text` segment.
    /// - Throws: ``MathRenderFailure`` describing what stopped the render, so a caller can tell
    ///   source the engine rejected from source that typeset to nothing and pick its own fallback.
    @MainActor
    public static func inlineText(
        _ latex: String,
        fontFamily: MathFontFamily = .latinModern,
        fontSize: CGFloat = 17,
        color: Color
    ) throws(MathRenderFailure) -> Text {
        let rendered = try MathImageRenderer.render(
            latex: latex,
            mode: .inline,
            fontFamily: fontFamily,
            fontSize: fontSize,
            color: color
        )
        #if canImport(UIKit)
        let image = Image(uiImage: rendered.image)
        #elseif canImport(AppKit)
        let image = Image(nsImage: rendered.image)
        #endif
        return Text(image).baselineOffset(-rendered.descent)
    }
}
