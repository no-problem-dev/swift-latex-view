import Testing
@testable import LaTeXCore

/// Tests for LLM over-escape normalization.
///
/// LLMs emitting LaTeX inside JSON frequently double-escape backslashes,
/// so the decoded string contains `\\frac` instead of `\frac`. SwiftMath
/// then parses `\\` as a line break and renders the command name as
/// literal letters (observed on device: `n \\ge 30` → "n" stacked over
/// "ge30").
struct MathNormalizationTests {

    @Test("Double backslash before a letter collapses to a command")
    func collapsesOverEscapedCommands() {
        let expression = MathExpression(#"n \\ge 30"#)

        #expect(expression.normalizedLatex == #"n \ge 30"#)
    }

    @Test("Fully over-escaped expression is recovered")
    func recoversFullExpression() {
        let expression = MathExpression(
            #"Z = \\frac{\\bar{X}_n - \\mu}{\\sigma / \\sqrt{n}} \\xrightarrow{d} N(0, 1)"#
        )

        #expect(expression.normalizedLatex
            == #"Z = \frac{\bar{X}_n - \mu}{\sigma / \sqrt{n}} \xrightarrow{d} N(0, 1)"#)
    }

    @Test("Legitimate matrix line breaks are preserved")
    func preservesMatrixLineBreaks() {
        let matrix = #"\begin{pmatrix} a & b \\ c & d \end{pmatrix}"#

        #expect(MathExpression(matrix).normalizedLatex == matrix)
    }

    @Test("Line break followed by space and command is preserved")
    func preservesSpacedLineBreaks() {
        let latex = #"x = 1 \\ \gamma = 2"#

        #expect(MathExpression(latex).normalizedLatex == latex)
    }

    @Test("Correctly escaped input is untouched")
    func correctInputUntouched() {
        let latex = #"\frac{a}{b} + \sqrt{x}"#

        #expect(MathExpression(latex).normalizedLatex == latex)
    }

    @Test("Validation uses the normalized form")
    func validationUsesNormalizedForm() {
        // Raw form parses as linebreak + letters; normalized form must be
        // what validate() and renderers consume.
        #expect(MathExpression(#"\\notarealcommand{x"#).validate() != nil)
        #expect(MathExpression(#"\\frac{a}{b}"#).validate() == nil)
    }
}
