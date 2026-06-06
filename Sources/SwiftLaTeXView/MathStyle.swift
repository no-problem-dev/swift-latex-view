import SwiftUI
import DesignSystem

// MARK: - MathStyle Protocol

/// A protocol that defines the visual styling for math expressions.
///
/// Implement this protocol to customize how ``LaTeXView`` renders math.
/// All requirements have defaults, so a custom style only overrides
/// what it needs.
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

    /// The math font used for typesetting.
    var fontFamily: MathFontFamily { get }

    /// The point size for display (block) math.
    var displayFontSize: CGFloat { get }

    /// The point size for inline math. Should match the surrounding
    /// body text size.
    var inlineFontSize: CGFloat { get }

    /// The color of the rendered expression.
    ///
    /// - Parameter palette: The current color palette from the environment.
    func textColor(_ palette: any ColorPalette) -> Color

    /// The color used when LaTeX fails to parse and the raw source is
    /// shown instead.
    ///
    /// - Parameter palette: The current color palette from the environment.
    func errorColor(_ palette: any ColorPalette) -> Color

    /// The padding around display math blocks.
    ///
    /// - Parameter spacing: The current spacing scale from the environment.
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

/// The default math style: Latin Modern, on-surface color,
/// standard body-text sizing.
public struct DefaultMathStyle: MathStyle {
    public init() {}
}

// MARK: - Environment Key

private struct MathStyleKey: EnvironmentKey {
    static let defaultValue: any MathStyle = DefaultMathStyle()
}

extension EnvironmentValues {

    /// The style used for rendering math expressions.
    ///
    /// Use the ``SwiftUICore/View/mathStyle(_:)`` modifier to set this value.
    public var mathStyle: any MathStyle {
        get { self[MathStyleKey.self] }
        set { self[MathStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Sets a custom math style for this view hierarchy.
    ///
    /// - Parameter style: The math style to use.
    /// - Returns: A view with the math style applied.
    public func mathStyle(_ style: some MathStyle) -> some View {
        environment(\.mathStyle, style)
    }
}
