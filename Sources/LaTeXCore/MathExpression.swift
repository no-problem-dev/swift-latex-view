/// How an expression should be placed relative to the text around it.
public enum MathMode: String, Sendable, Equatable, Hashable, CaseIterable {
    /// Set within a line of prose and aligned vertically on the text baseline.
    case inline
    /// Set as a standalone block, with display-style spacing and larger operators.
    case display
}

/// A LaTeX expression paired with the layout mode it should be set in.
///
/// The source is held exactly as given, delimiters already removed. Nothing is parsed on
/// construction — an expression only meets the engine when ``validate()`` is called or when a
/// view renders it, so building one is cheap and never fails.
public struct MathExpression: Sendable, Equatable, Hashable {
    /// The LaTeX source, with no surrounding delimiters.
    public let latex: String

    /// The layout mode this expression was built for.
    public let mode: MathMode

    /// Creates an expression.
    ///
    /// - Parameters:
    ///   - latex: LaTeX source **without** delimiters, for example `#"\frac{1}{2}"#`.
    ///     Leaving the delimiters in — `"$\frac{1}{2}$"` — typesets them as literal characters.
    ///     To pull math out of prose, use ``MathSegmenter``, which strips them for you.
    ///   - mode: The layout mode. Defaults to ``MathMode/display``.
    public init(_ latex: String, mode: MathMode = .display) {
        self.latex = latex
        self.mode = mode
    }
}

extension MathExpression {
    /// The source with LLM double-escaping repaired.
    ///
    /// A model emitting LaTeX inside JSON often escapes its backslashes twice, so what arrives is
    /// `\\frac` rather than `\frac`. The engine reads `\\` as a line break and then draws the
    /// command name as literal letters. Collapsing `\\` to `\` wherever a letter follows repairs
    /// that, and it is safe: a genuine line break (`a & b \\ c & d`) is always followed by a
    /// space or another backslash, never by a letter.
    ///
    /// Both the renderer and ``validate()`` work from this form, not from ``latex``.
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
