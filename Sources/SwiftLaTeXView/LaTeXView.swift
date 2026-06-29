import SwiftUI
import DesignSystem
import LaTeXCore

/// LaTeX 数式を描画する SwiftUI ビュー。
///
/// 色・サイズ・数式フォントは DesignSystem 環境と適用中の ``MathStyle`` から取得する。
///
/// ```swift
/// LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)
///
/// // インライン数式 — テキストのベースラインに揃える:
/// HStack(alignment: .firstTextBaseline) {
///     Text("where")
///     LaTeXView(#"a \neq 0"#, mode: .inline)
///     Text("holds.")
/// }
/// ```
///
/// LaTeX ソースがパースできない場合（LLM の出力が途中で切れた場合など）は、
/// モノスペースフォントでスタイルのエラー色を使って生ソースを表示するフォールバックに切り替わる。
public struct LaTeXView: View {

    /// 描画する数式。
    public let expression: MathExpression

    @Environment(\.mathStyle) private var style
    @Environment(\.colorPalette) private var palette
    @Environment(\.spacingScale) private var spacing

    /// 既存の ``MathExpression`` からビューを生成する。
    ///
    /// ``MathSegmenter`` でテキストと数式を分割した後など、
    /// 既に ``MathExpression`` を持っている場合に使用する。
    ///
    /// - Parameter expression: 描画する数式。
    public init(_ expression: MathExpression) {
        self.expression = expression
    }

    /// LaTeX 文字列からビューを生成する。
    ///
    /// - Parameters:
    ///   - latex: デリミタを含まない LaTeX ソース。たとえば `#"\frac{1}{2}"#`。
    ///     `"$\frac{1}{2}$"` のようにデリミタを含めると、デリミタが文字として描画される。
    ///   - mode: レイアウトモード。デフォルトは ``MathMode/display``。
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

/// コンテナより幅広のディスプレイ数式を、周囲のレイアウトを崩さずに横スクロールで表示するビュー。
/// KaTeX の `overflow-x: auto` に相当する。
/// 収まる場合は中央揃えにし、バウンスを無効化してスクロールビューを静止させる。
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

    /// インライン数式を `Text` のセグメントとして描画し、テキスト連結に使えるようにする。
    ///
    /// 数式を複数セグメントを連結した `Text` コンポジション（Markdown 段落など）の中に
    /// 埋め込みたい場合に使用する。`View` を埋め込めない文脈で有用。
    /// タイプセット時の descent を使って、周囲のテキストのベースラインに揃える。
    ///
    /// ``LaTeXView`` イニシャライザと異なり、このメソッドは環境非依存である。
    /// 周囲の ``SwiftUICore/EnvironmentValues/mathStyle`` やカラーパレットを参照しない。
    /// 周囲のテキストに合わせた `fontFamily`・`fontSize`・`color` を明示的に渡す必要がある。
    ///
    /// - Parameters:
    ///   - latex: デリミタを含まない LaTeX ソース。
    ///   - fontFamily: 数式フォント。デフォルトは Latin Modern。
    ///   - fontSize: ポイントサイズ。周囲のテキストのサイズに合わせること。
    ///   - color: テキストの色。デザインシステムのパレットからの色解決は呼び出し側の責務。
    /// - Returns: `Text` セグメント。LaTeX のパースに失敗した場合は `nil`。
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
