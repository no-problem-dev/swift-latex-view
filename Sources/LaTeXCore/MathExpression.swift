/// The layout mode of a math expression.
public enum MathMode: String, Sendable, Equatable, Hashable, CaseIterable {
    /// Rendered within a line of text, vertically centered on the baseline.
    case inline
    /// Rendered as a standalone block with display-style spacing.
    case display
}

/// A LaTeX math expression with its layout mode.
///
/// This is a plain value type: the LaTeX source is not parsed until
/// ``validate()`` is called or the expression is rendered.
public struct MathExpression: Sendable, Equatable, Hashable {
    /// The LaTeX source, without surrounding delimiters.
    public let latex: String

    /// The layout mode.
    public let mode: MathMode

    public init(_ latex: String, mode: MathMode = .display) {
        self.latex = latex
        self.mode = mode
    }
}
