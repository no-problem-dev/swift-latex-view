import Testing
import SwiftUI
import LaTeXCore
@testable import SwiftLaTeXView

/// A render that does not produce an image has to say which kind of failure it was.
///
/// Both kinds put the same fallback on screen — the source in the error color — so the view gives
/// a caller nothing to go on. Malformed model output and source that typesets to an empty box are
/// different problems with different responses, and collapsing them to one `nil` throws that away.
@MainActor
struct MathRenderFailureTests {

    private func render(_ latex: String) throws(MathRenderFailure) -> RenderedMath {
        try MathImageRenderer.render(
            latex: latex,
            mode: .display,
            fontFamily: .latinModern,
            fontSize: 20,
            color: .black
        )
    }

    private func renderFailure(_ latex: String, _ comment: Comment? = nil) -> MathRenderFailure? {
        do {
            _ = try render(latex)
            Issue.record(comment ?? "\(latex.debugDescription) rendered instead of failing")
            return nil
        } catch {
            return error
        }
    }

    @Test("Source the engine rejects is reported as a parse failure")
    func parseFailureIsDistinct() throws {
        let failure = try #require(renderFailure(#"\notarealcommand{"#))

        guard case .parseFailed(let parseError) = failure.reason else {
            Issue.record("expected .parseFailed, got \(failure.reason)")
            return
        }
        #expect(!parseError.message.isEmpty)
    }

    @Test("Source that typesets to an empty box is not reported as a parse failure")
    func emptyLayoutIsDistinct() throws {
        // `\frac{}{}` is valid LaTeX. The engine accepts it and lays out a box with no width, so
        // there is nothing to draw — a different problem from source the engine rejected.
        #expect(MathExpression(#"\frac{}{}"#).validate() == nil)
        let failure = try #require(renderFailure(#"\frac{}{}"#))

        #expect(failure.reason == .laidOutNothing)
    }

    @Test("The two failures are told apart", arguments: [
        (#"\notarealcommand{"#, true),
        (#"\frac{}{}"#, false),
        ("", false),
        ("{}", false)
    ])
    func failuresAreDistinguishable(latex: String, isParseFailure: Bool) throws {
        let failure = try #require(renderFailure(latex))

        if case .parseFailed = failure.reason {
            #expect(isParseFailure, "\(latex.debugDescription) reported a parse failure")
        } else {
            #expect(!isParseFailure, "\(latex.debugDescription) reported \(failure.reason)")
        }
    }

    @Test("The parse failure carries the engine's own message")
    func messageMatchesValidate() throws {
        let latex = #"\notarealcommand{"#
        let expected = try #require(MathExpression(latex).validate())
        let failure = try #require(renderFailure(latex))

        #expect(failure.reason == .parseFailed(expected))
    }

    @Test("The failure carries the source the engine was actually given")
    func sourceIsNormalized() throws {
        // A model emitting LaTeX inside JSON double-escapes its backslashes. The engine is handed
        // the collapsed form, so that is what it rejected — and that is what a fallback has to
        // show. Reporting the raw string would put `\\notarealcommand` on screen, which is not
        // the text anything objected to.
        let failure = try #require(renderFailure(#"\\notarealcommand{"#))

        #expect(failure.source == #"\notarealcommand{"#)
    }

    @Test("A render that succeeds throws nothing")
    func successThrowsNothing() throws {
        let rendered = try render("x^2 + y^2")

        #expect(rendered.size.width > 0)
        #expect(rendered.size.height > 0)
    }
}

/// The inline `Text` API is what Markdown integrations call. It has to pass the reason on rather
/// than flattening it to `nil`, or the caller can only report "some math did not render".
@MainActor
struct InlineTextFailureTests {

    @Test("Invalid LaTeX reports why, rather than returning nothing")
    func invalidLatexReportsReason() throws {
        do {
            _ = try LaTeXView.inlineText(#"\notarealcommand{"#, color: .black)
            Issue.record("expected a failure")
        } catch {
            guard case .parseFailed(let parseError) = error.reason else {
                Issue.record("expected .parseFailed, got \(error.reason)")
                return
            }
            #expect(!parseError.message.isEmpty)
        }
    }

    @Test("Empty math is reported as an empty layout, not as invalid syntax")
    func emptyMathReportsLayout() throws {
        do {
            _ = try LaTeXView.inlineText("", color: .black)
            Issue.record("expected a failure")
        } catch {
            #expect(error.reason == .laidOutNothing)
        }
    }
}
