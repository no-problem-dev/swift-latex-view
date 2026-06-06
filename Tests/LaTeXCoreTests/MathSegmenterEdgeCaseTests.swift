import Testing
@testable import LaTeXCore

/// Edge cases for MathSegmenter: currency false positives (Pandoc rules),
/// escapes, Markdown code constructs, and unterminated delimiters.
struct MathSegmenterEdgeCaseTests {

    private let segmenter = MathSegmenter()

    // MARK: - Currency False Positives (Pandoc Rules)

    @Test("Currency amounts are not math")
    func currency() {
        let source = "It costs $5 and $10 in total."
        #expect(segmenter.segments(in: source) == [.text(source)])
    }

    @Test("Currency with thousands separators is not math")
    func currencyThousands() {
        let source = "I paid $20,000 and you paid $30,000."
        #expect(segmenter.segments(in: source) == [.text(source)])
    }

    @Test("Opening dollar followed by space is not math")
    func openFollowedBySpace() {
        let source = "$ x $"
        #expect(segmenter.segments(in: source) == [.text(source)])
    }

    @Test("Closing dollar preceded by space is not a valid close")
    func closePrecededBySpace() {
        let source = "$x $ y"
        #expect(segmenter.segments(in: source) == [.text(source)])
    }

    @Test("Single dollar math must not span lines")
    func singleDollarNoMultiline() {
        let source = "$a +\nb$"
        #expect(segmenter.segments(in: source) == [.text(source)])
    }

    @Test("singleDollar option disables $...$ detection entirely")
    func singleDollarDisabled() {
        let segmenter = MathSegmenter(options: .init(singleDollar: false))
        let source = "The value $x$ stays text, but $$y$$ is math."

        #expect(segmenter.segments(in: source) == [
            .text("The value $x$ stays text, but "),
            .math(MathExpression("y", mode: .display)),
            .text(" is math.")
        ])
    }

    // MARK: - Escapes

    @Test("Escaped dollars are literal")
    func escapedDollars() {
        let source = #"Price is \$5 and \$10."#
        #expect(segmenter.segments(in: source) == [.text(source)])
    }

    @Test("Escaped dollar inside math does not close it")
    func escapedDollarInsideMath() {
        let segments = segmenter.segments(in: #"$a\$b$"#)

        #expect(segments == [.math(MathExpression(#"a\$b"#, mode: .inline))])
    }

    @Test("Escaped backslash before dollar does not form a delimiter")
    func escapedBackslash() {
        // \\ is an escaped backslash; the following [ is literal.
        let source = #"A literal \\[ bracket"#
        #expect(segmenter.segments(in: source) == [.text(source)])
    }

    // MARK: - Markdown Code Constructs

    @Test("Dollars inside inline code spans are not math")
    func codeSpan() {
        let source = "Use `$HOME$` to reference it."
        #expect(segmenter.segments(in: source) == [.text(source)])
    }

    @Test("Dollars inside fenced code blocks are not math")
    func fencedCodeBlock() {
        let source = """
        Some text.

        ```swift
        let price = "$5$"
        let formula = "$$x$$"
        ```

        After the fence.
        """
        #expect(segmenter.segments(in: source) == [.text(source)])
    }

    @Test("Math after a closed fence is still detected")
    func mathAfterFence() {
        let source = """
        ```
        $skip$
        ```
        Then $x$ here.
        """
        let segments = segmenter.segments(in: source)

        #expect(segments == [
            .text("```\n$skip$\n```\nThen "),
            .math(MathExpression("x", mode: .inline)),
            .text(" here.")
        ])
    }

    @Test("Unclosed code span leaves backticks literal but skips no math")
    func unclosedCodeSpan() {
        let segments = segmenter.segments(in: "a ` b $x$")

        #expect(segments == [
            .text("a ` b "),
            .math(MathExpression("x", mode: .inline))
        ])
    }

    // MARK: - Unterminated Delimiters

    @Test("Unterminated delimiters are text by default")
    func unterminatedIsTextByDefault() {
        let sources = ["$$a + b", #"\[a + b"#, #"\(a + b"#, "$a + b"]
        for source in sources {
            #expect(segmenter.segments(in: source) == [.text(source)], "source: \(source)")
        }
    }

    @Test("completeUnterminated closes streaming display math")
    func completeUnterminatedDisplay() {
        let segmenter = MathSegmenter(options: .init(completeUnterminated: true))
        let segments = segmenter.segments(in: "The sum $$a + b")

        #expect(segments == [
            .text("The sum "),
            .math(MathExpression("a + b", mode: .display))
        ])
    }

    @Test("completeUnterminated closes streaming bracket math")
    func completeUnterminatedBracket() {
        let segmenter = MathSegmenter(options: .init(completeUnterminated: true))
        let segments = segmenter.segments(in: #"Result: \[\frac{1}{2}"#)

        #expect(segments == [
            .text("Result: "),
            .math(MathExpression(#"\frac{1}{2}"#, mode: .display))
        ])
    }

    @Test("Empty math delimiters are left as text")
    func emptyMath() {
        for source in ["$$$$", #"\[\]"#, #"\(\)"#] {
            #expect(segmenter.segments(in: source) == [.text(source)], "source: \(source)")
        }
    }

    // MARK: - LLM Output Corpus

    @Test("OpenAI-style response with bracket display and paren inline")
    func openAIStyle() {
        let source = #"""
        The quadratic formula is:

        \[
        x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
        \]

        where \(a \neq 0\) holds.
        """#
        let segments = segmenter.segments(in: source)

        #expect(segments == [
            .text("The quadratic formula is:\n\n"),
            .math(MathExpression(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#, mode: .display)),
            .text("\n\nwhere "),
            .math(MathExpression(#"a \neq 0"#, mode: .inline)),
            .text(" holds.")
        ])
    }

    @Test("Claude-style response mixing dollar math and currency")
    func claudeStyle() {
        let source = "With $n$ items at $5 each, the total is $$T = 5n$$"
        let segments = segmenter.segments(in: source)

        #expect(segments == [
            .text("With "),
            .math(MathExpression("n", mode: .inline)),
            .text(" items at $5 each, the total is "),
            .math(MathExpression("T = 5n", mode: .display))
        ])
    }
}
