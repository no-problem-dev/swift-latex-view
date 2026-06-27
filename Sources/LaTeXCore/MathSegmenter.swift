import Foundation

/// A piece of text produced by ``MathSegmenter``.
public enum MathSegment: Sendable, Equatable {
    /// Plain text, preserved exactly as it appeared in the source.
    case text(String)
    /// A math expression with its delimiters stripped.
    case math(MathExpression)
}

/// Splits plain text into text and math segments.
///
/// Recognizes the delimiter styles emitted by major LLMs:
/// - `$$...$$` and `\[...\]` — display math (multiline allowed)
/// - `\(...\)` — inline math
/// - `$...$` — inline math, guarded by Pandoc rules to avoid
///   currency false positives (see ``Options/singleDollar``)
///
/// Markdown code constructs (fenced code blocks and inline code spans)
/// are skipped, so the segmenter can run on raw Markdown source before
/// Markdown parsing. This matters because `\(...\)` cannot be recovered
/// after Markdown escape processing.
public struct MathSegmenter: Sendable {

    public struct Options: Sendable, Equatable {
        /// Whether `$...$` is recognized as inline math.
        ///
        /// Detection follows Pandoc rules: the opening `$` must be
        /// immediately followed by a non-space character, the closing `$`
        /// immediately preceded by one, and the closing `$` must not be
        /// immediately followed by a digit. The expression must not span
        /// multiple lines.
        public var singleDollar: Bool

        /// Whether an unterminated delimiter at end of input is completed
        /// as math. Enable when rendering streaming LLM output, where the
        /// closing delimiter may not have arrived yet.
        public var completeUnterminated: Bool

        /// Creates segmenter options.
        ///
        /// - Parameters:
        ///   - singleDollar: Whether `$...$` is recognized as inline math.
        ///     Defaults to `true`.
        ///   - completeUnterminated: Whether an unterminated delimiter at end
        ///     of input is completed as math. Defaults to `false`. Enable for
        ///     streaming LLM output.
        public init(singleDollar: Bool = true, completeUnterminated: Bool = false) {
            self.singleDollar = singleDollar
            self.completeUnterminated = completeUnterminated
        }
    }

    /// The options used by this segmenter.
    public let options: Options

    /// Creates a segmenter with the given options.
    ///
    /// - Parameter options: Parsing options. Defaults to ``Options/init(singleDollar:completeUnterminated:)``.
    public init(options: Options = Options()) {
        self.options = options
    }

    /// Splits `text` into alternating text and math segments.
    ///
    /// Text outside math delimiters is preserved exactly. Delimiters that
    /// do not form a valid math expression remain part of the text.
    public func segments(in text: String) -> [MathSegment] {
        var scanner = Scanner(chars: Array(text), options: options)
        return scanner.run()
    }
}

// MARK: - Scanner

private struct Scanner {
    let chars: [Character]
    let options: MathSegmenter.Options
    var i = 0
    var textStart = 0
    var segments: [MathSegment] = []

    mutating func run() -> [MathSegment] {
        while i < chars.count {
            switch chars[i] {
            case "\\": scanBackslash()
            case "`": scanBacktick()
            case "$": scanDollar()
            default: i += 1
            }
        }
        flushText(upTo: chars.count)
        return segments
    }

    // MARK: Emission

    private mutating func flushText(upTo end: Int) {
        guard end > textStart else { return }
        segments.append(.text(String(chars[textStart..<end])))
        textStart = end
    }

    private mutating func emitMath(_ latex: String, mode: MathMode, from start: Int, to end: Int) {
        flushText(upTo: start)
        segments.append(.math(MathExpression(latex, mode: mode)))
        textStart = end
        i = end
    }

    // MARK: Backslash: \[...\], \(...\), and escapes

    private mutating func scanBackslash() {
        guard i + 1 < chars.count else {
            i += 1
            return
        }
        switch chars[i + 1] {
        case "[":
            matchBackslashDelimited(closer: "]", mode: .display)
        case "(":
            matchBackslashDelimited(closer: ")", mode: .inline)
        default:
            // Escaped character (\$, \\, …) — never a delimiter.
            i += 2
        }
    }

    private mutating func matchBackslashDelimited(closer: Character, mode: MathMode) {
        let start = i
        let contentStart = i + 2
        var j = contentStart
        while j + 1 < chars.count {
            if chars[j] == "\\" {
                if chars[j + 1] == closer {
                    let latex = trimmed(contentStart..<j)
                    if latex.isEmpty {
                        i = j + 2
                    } else {
                        emitMath(latex, mode: mode, from: start, to: j + 2)
                    }
                    return
                }
                j += 2
            } else {
                j += 1
            }
        }
        completeOrSkipOpener(start: start, contentStart: contentStart, mode: mode, openerLength: 2)
    }

    // MARK: Dollar: $$...$$ and $...$

    private mutating func scanDollar() {
        if i + 1 < chars.count && chars[i + 1] == "$" {
            matchDoubleDollar()
        } else if options.singleDollar {
            matchSingleDollar()
        } else {
            i += 1
        }
    }

    private mutating func matchDoubleDollar() {
        let start = i
        let contentStart = i + 2
        var j = contentStart
        while j + 1 < chars.count {
            if chars[j] == "\\" {
                j += 2
                continue
            }
            if chars[j] == "$" && chars[j + 1] == "$" {
                let latex = trimmed(contentStart..<j)
                if latex.isEmpty {
                    i = j + 2
                } else {
                    emitMath(latex, mode: .display, from: start, to: j + 2)
                }
                return
            }
            j += 1
        }
        completeOrSkipOpener(start: start, contentStart: contentStart, mode: .display, openerLength: 2)
    }

    private mutating func matchSingleDollar() {
        let start = i
        let contentStart = i + 1
        guard contentStart < chars.count, !chars[contentStart].isWhitespace else {
            i += 1
            return
        }
        var j = contentStart
        while j < chars.count {
            let c = chars[j]
            if c == "\n" { break }
            if c == "\\" {
                j += 2
                continue
            }
            if c == "$" {
                // Pandoc rule: content may not contain an unescaped `$`,
                // so the first one found either closes the math or fails it.
                let validClose = !chars[j - 1].isWhitespace && !isDigit(at: j + 1)
                if validClose && j > contentStart {
                    emitMath(String(chars[contentStart..<j]), mode: .inline, from: start, to: j + 1)
                    return
                }
                break
            }
            j += 1
        }
        i += 1
    }

    // MARK: Code constructs (skipped verbatim)

    private mutating func scanBacktick() {
        let runStart = i
        var runLength = 0
        while i < chars.count && chars[i] == "`" {
            runLength += 1
            i += 1
        }
        if runLength >= 3 && isAtLineStart(runStart) {
            skipFencedBlock(minimumLength: runLength)
        } else {
            skipCodeSpan(length: runLength)
        }
    }

    private mutating func skipFencedBlock(minimumLength: Int) {
        while i < chars.count {
            guard let lineStart = indexAfterNextNewline() else {
                i = chars.count
                return
            }
            var j = lineStart
            while j < chars.count && (chars[j] == " " || chars[j] == "\t") { j += 1 }
            var closeLength = 0
            while j < chars.count && chars[j] == "`" {
                closeLength += 1
                j += 1
            }
            i = j
            if closeLength >= minimumLength {
                return
            }
        }
    }

    private mutating func skipCodeSpan(length: Int) {
        var j = i
        while j < chars.count {
            if chars[j] == "`" {
                var closeLength = 0
                while j < chars.count && chars[j] == "`" {
                    closeLength += 1
                    j += 1
                }
                if closeLength == length {
                    i = j
                    return
                }
            } else {
                j += 1
            }
        }
        // No closing run: the opening backticks are literal text.
    }

    // MARK: Helpers

    private mutating func completeOrSkipOpener(start: Int, contentStart: Int, mode: MathMode, openerLength: Int) {
        if options.completeUnterminated {
            let latex = trimmed(contentStart..<chars.count)
            if !latex.isEmpty {
                emitMath(latex, mode: mode, from: start, to: chars.count)
                return
            }
        }
        i = start + openerLength
    }

    private func trimmed(_ range: Range<Int>) -> String {
        let upper = min(range.upperBound, chars.count)
        guard range.lowerBound < upper else { return "" }
        return String(chars[range.lowerBound..<upper])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isDigit(at index: Int) -> Bool {
        guard index < chars.count else { return false }
        return ("0"..."9").contains(chars[index])
    }

    private func isAtLineStart(_ index: Int) -> Bool {
        var j = index - 1
        while j >= 0 {
            switch chars[j] {
            case " ", "\t": j -= 1
            case "\n": return true
            default: return false
            }
        }
        return true
    }

    /// Advances `i` past the next newline and returns the index of the
    /// following line's first character, or nil if no newline remains.
    private mutating func indexAfterNextNewline() -> Int? {
        while i < chars.count {
            if chars[i] == "\n" {
                i += 1
                return i
            }
            i += 1
        }
        return nil
    }
}
