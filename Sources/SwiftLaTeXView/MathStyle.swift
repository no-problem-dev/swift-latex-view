import SwiftUI
import DesignSystem

// MARK: - MathStyle Protocol

/// Describes how ``LaTeXView`` typesets and colors math.
///
/// Every requirement has a default implementation, so a conforming type only spells out what it
/// wants to change. Colors are resolved from the palette rather than declared outright, which is
/// what keeps math in step with light and dark appearances.
///
/// ## Example
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

    /// The OpenType MATH font to typeset with. Defaults to ``MathFontFamily/latinModern``.
    var fontFamily: MathFontFamily { get }

    /// Point size for display (block) math, which stands on its own line. Defaults to 20.
    var displayFontSize: CGFloat { get }

    /// Point size for inline math. Match the surrounding body text, or the baseline alignment
    /// will land the formula visibly high or low against the words. Defaults to 17.
    var inlineFontSize: CGFloat { get }

    /// Resolves the color the math is drawn in, so it can track the current appearance.
    ///
    /// - Parameter palette: The color palette currently in the environment.
    func textColor(_ palette: any ColorPalette) -> Color

    /// Resolves the color of the raw-source fallback shown when the LaTeX fails to parse.
    ///
    /// - Parameter palette: The color palette currently in the environment.
    func errorColor(_ palette: any ColorPalette) -> Color

    /// Resolves the padding around a display math block. Inline math is never padded.
    ///
    /// - Parameter spacing: The spacing scale currently in the environment.
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

/// The style in effect when nothing has been set: Latin Modern, the palette's on-surface color,
/// and sizes that sit with body text.
public struct DefaultMathStyle: MathStyle {
    public init() {}
}

// MARK: - Environment Key

private struct MathStyleKey: EnvironmentKey {
    static let defaultValue: any MathStyle = DefaultMathStyle()
}

extension EnvironmentValues {

    /// The style every ``LaTeXView`` in this hierarchy typesets with.
    ///
    /// Set it through the ``SwiftUICore/View/mathStyle(_:)`` modifier rather than writing to the
    /// environment directly.
    public var mathStyle: any MathStyle {
        get { self[MathStyleKey.self] }
        set { self[MathStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Applies a math style to this view and everything below it.
    ///
    /// - Parameter style: The style to apply.
    /// - Returns: The view, with the style installed in the environment.
    public func mathStyle(_ style: some MathStyle) -> some View {
        environment(\.mathStyle, style)
    }
}
