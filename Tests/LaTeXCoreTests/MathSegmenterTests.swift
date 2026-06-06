import Testing
@testable import LaTeXCore

/// Tests for MathSegmenter delimiter detection.
///
/// Delimiter spec (LLM output compatibility):
/// - `$$...$$` display math (multiline allowed)
/// - `\[...\]` display math (multiline allowed) — OpenAI style
/// - `\(...\)` inline math — OpenAI style
/// - `$...$` inline math (Pandoc rules, single line)
struct MathSegmenterTests {

    private let segmenter = MathSegmenter()

    // MARK: - No Math

    @Test("Plain text yields a single text segment")
    func plainText() {
        let segments = segmenter.segments(in: "Hello, World!")

        #expect(segments == [.text("Hello, World!")])
    }

    @Test("Empty string yields no segments")
    func emptyString() {
        #expect(segmenter.segments(in: "").isEmpty)
    }

    // MARK: - Display Math: $$...$$

    @Test("Double dollar yields display math")
    func doubleDollar() {
        let segments = segmenter.segments(in: "$$E = mc^2$$")

        #expect(segments == [.math(MathExpression("E = mc^2", mode: .display))])
    }

    @Test("Double dollar surrounded by text")
    func doubleDollarInText() {
        let segments = segmenter.segments(in: "Einstein said $$E = mc^2$$ in 1905.")

        #expect(segments == [
            .text("Einstein said "),
            .math(MathExpression("E = mc^2", mode: .display)),
            .text(" in 1905.")
        ])
    }

    @Test("Double dollar spans multiple lines")
    func doubleDollarMultiline() {
        let source = """
        $$
        a + b
        $$
        """
        let segments = segmenter.segments(in: source)

        #expect(segments == [.math(MathExpression("a + b", mode: .display))])
    }

    // MARK: - Display Math: \[...\]

    @Test("Bracket delimiters yield display math")
    func brackets() {
        let segments = segmenter.segments(in: #"\[x^2 + y^2 = z^2\]"#)

        #expect(segments == [.math(MathExpression("x^2 + y^2 = z^2", mode: .display))])
    }

    @Test("Bracket delimiters span multiple lines")
    func bracketsMultiline() {
        let source = "Before \\[\na + b\n\\] after"
        let segments = segmenter.segments(in: source)

        #expect(segments == [
            .text("Before "),
            .math(MathExpression("a + b", mode: .display)),
            .text(" after")
        ])
    }

    // MARK: - Inline Math: \(...\)

    @Test("Parenthesis delimiters yield inline math")
    func parentheses() {
        let segments = segmenter.segments(in: #"The value \(x = 5\) is constant."#)

        #expect(segments == [
            .text("The value "),
            .math(MathExpression("x = 5", mode: .inline)),
            .text(" is constant.")
        ])
    }

    // MARK: - Inline Math: $...$

    @Test("Single dollar yields inline math")
    func singleDollar() {
        let segments = segmenter.segments(in: "The value $x = 5$ is constant.")

        #expect(segments == [
            .text("The value "),
            .math(MathExpression("x = 5", mode: .inline)),
            .text(" is constant.")
        ])
    }

    @Test("Multiple inline math in one line")
    func multipleInline() {
        let segments = segmenter.segments(in: "$a$ and $b$")

        #expect(segments == [
            .math(MathExpression("a", mode: .inline)),
            .text(" and "),
            .math(MathExpression("b", mode: .inline))
        ])
    }

    // MARK: - Content Trimming

    @Test("Math content keeps internal whitespace but trims delimiter padding")
    func contentTrimming() {
        let segments = segmenter.segments(in: "$$ a + b $$")

        #expect(segments == [.math(MathExpression("a + b", mode: .display))])
    }

    // MARK: - Mixed Delimiters

    @Test("OpenAI and dollar styles coexist in one document")
    func mixedStyles() {
        let source = #"Inline \(a\) and $b$ then \[c\] and $$d$$"#
        let segments = segmenter.segments(in: source)

        #expect(segments == [
            .text("Inline "),
            .math(MathExpression("a", mode: .inline)),
            .text(" and "),
            .math(MathExpression("b", mode: .inline)),
            .text(" then "),
            .math(MathExpression("c", mode: .display)),
            .text(" and "),
            .math(MathExpression("d", mode: .display))
        ])
    }
}
