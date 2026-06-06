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

extension MathExpression {
    /// The LaTeX source with LLM over-escaping repaired.
    ///
    /// LLMs emitting LaTeX inside JSON frequently double-escape
    /// backslashes, so the decoded string contains `\\frac` instead of
    /// `\frac` — the engine then parses `\\` as a line break and renders
    /// the command name as literal letters. A `\\` immediately followed
    /// by a letter is collapsed to `\`: legitimate line breaks
    /// (`a & b \\ c & d`) are followed by whitespace or `\`, never
    /// directly by a command name.
    ///
    /// Renderers and ``validate()`` consume this form.
    public var normalizedLatex: String {
        guard latex.contains(#"\\"#) else { return latex }
        var result = ""
        result.reserveCapacity(latex.count)
        let characters = Array(latex)
        var i = 0
        while i < characters.count {
            if characters[i] == "\\",
               i + 2 < characters.count,
               characters[i + 1] == "\\",
               characters[i + 2].isLetter {
                result.append("\\")
                i += 2
                continue
            }
            result.append(characters[i])
            i += 1
        }
        return result
    }
}
