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
    func validLatex() {
        let text = LaTeXView.inlineText("x^2", color: .black)

        #expect(text != nil)
    }

    @Test("Invalid LaTeX returns nil so callers can fall back")
    func invalidLatex() {
        let text = LaTeXView.inlineText(#"\notarealcommand{"#, color: .black)

        #expect(text == nil)
    }

    @Test("Font family and size are accepted")
    func customFont() {
        let text = LaTeXView.inlineText(
            #"\frac{1}{2}"#,
            fontFamily: .fira,
            fontSize: 21,
            color: .blue
        )

        #expect(text != nil)
    }
}
