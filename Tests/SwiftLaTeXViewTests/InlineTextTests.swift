import Testing
import SwiftUI
@testable import SwiftLaTeXView

/// Tests for the inline Text API used by Markdown integrations.
///
/// `Text` content cannot be inspected, so these tests cover the
/// success/failure contract; pixel verification lives in snapshot tests.
@MainActor
struct InlineTextTests {

    @Test("Valid LaTeX produces a Text segment")
    func validLatex() throws {
        _ = try LaTeXView.inlineText("x^2", color: .black)
    }

    @Test("Invalid LaTeX fails so callers can fall back")
    func invalidLatex() {
        #expect(throws: MathRenderFailure.self) {
            try LaTeXView.inlineText(#"\notarealcommand{"#, color: .black)
        }
    }

    @Test("Font family and size are accepted")
    func customFont() throws {
        _ = try LaTeXView.inlineText(
            #"\frac{1}{2}"#,
            fontFamily: .fira,
            fontSize: 21,
            color: .blue
        )
    }
}
