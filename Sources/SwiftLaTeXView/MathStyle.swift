import SwiftUI
import DesignSystem

// MARK: - MathStyle Protocol

/// 数式のスタイルを定義するプロトコル。
///
/// このプロトコルを実装して ``LaTeXView`` の描画をカスタマイズする。
/// 全要件にはデフォルト実装があるため、変更が必要なプロパティのみオーバーライドすればよい。
///
/// ## 使用例
///
/// ```swift
/// struct AccentMathStyle: MathStyle {
///     var fontFamily: MathFontFamily { .fira }
///
///     func textColor(_ palette: any ColorPalette) -> Color {
///         palette.primary
///     }
/// }
///
/// LaTeXView(#"e^{i\pi} + 1 = 0"#)
///     .mathStyle(AccentMathStyle())
/// ```
public protocol MathStyle: Sendable {

    /// 組版に使う数式フォント。
    var fontFamily: MathFontFamily { get }

    /// ディスプレイ（ブロック）数式のポイントサイズ。
    var displayFontSize: CGFloat { get }

    /// インライン数式のポイントサイズ。周囲の本文テキストに合わせること。
    var inlineFontSize: CGFloat { get }

    /// 描画する数式の色。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    func textColor(_ palette: any ColorPalette) -> Color

    /// LaTeX のパースに失敗して生ソースを表示するときの色。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    func errorColor(_ palette: any ColorPalette) -> Color

    /// ディスプレイ数式ブロックの余白。
    ///
    /// - Parameter spacing: 環境から取得した現在のスペーシングスケール。
    func padding(_ spacing: any SpacingScale) -> CGFloat
}

// MARK: - Default Implementation

extension MathStyle {

    public var fontFamily: MathFontFamily { .latinModern }

    public var displayFontSize: CGFloat { 20 }

    public var inlineFontSize: CGFloat { 17 }

    public func textColor(_ palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    public func errorColor(_ palette: any ColorPalette) -> Color {
        palette.error
    }

    public func padding(_ spacing: any SpacingScale) -> CGFloat {
        spacing.sm
    }
}

// MARK: - DefaultMathStyle

/// デフォルトの数式スタイル。Latin Modern フォント・オンサーフェイスカラー・標準本文サイズ。
public struct DefaultMathStyle: MathStyle {
    public init() {}
}

// MARK: - Environment Key

private struct MathStyleKey: EnvironmentKey {
    static let defaultValue: any MathStyle = DefaultMathStyle()
}

extension EnvironmentValues {

    /// 数式描画に使用するスタイル。
    ///
    /// 値の設定には ``SwiftUICore/View/mathStyle(_:)`` モディファイアを使う。
    public var mathStyle: any MathStyle {
        get { self[MathStyleKey.self] }
        set { self[MathStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// このビュー階層に数式スタイルを設定する。
    ///
    /// - Parameter style: 適用する数式スタイル。
    /// - Returns: 数式スタイルが適用されたビュー。
    public func mathStyle(_ style: some MathStyle) -> some View {
        environment(\.mathStyle, style)
    }
}
