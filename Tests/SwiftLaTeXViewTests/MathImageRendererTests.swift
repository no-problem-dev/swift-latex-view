import Testing
import SwiftUI
@testable import SwiftLaTeXView

/// Engine-integration tests for the internal math image renderer.
///
/// These run on both macOS (CLI) and iOS: they validate the SwiftMath
/// bridge without requiring a UI host. The renderer is main-actor bound
/// because the engine's only public typesetting route goes through a view.
@MainActor
struct MathImageRendererTests {

    @Test("Valid LaTeX renders to a non-empty image")
    func rendersValidLatex() {
        let rendered = MathImageRenderer.render(
            latex: "x^2 + y^2",
            mode: .display,
            fontFamily: .latinModern,
            fontSize: 20,
            color: .black
        )

        #expect(rendered != nil)
        #expect((rendered?.size.width ?? 0) > 0)
        #expect((rendered?.size.height ?? 0) > 0)
    }

    @Test("Invalid LaTeX returns nil")
    func invalidLatexReturnsNil() {
        let rendered = MathImageRenderer.render(
            latex: #"\notarealcommand{"#,
            mode: .display,
            fontFamily: .latinModern,
            fontSize: 20,
            color: .black
        )

        #expect(rendered == nil)
    }

    @Test("Display style sets operator limits above/below, growing height")
    func displayTallerThanInline() {
        func height(_ mode: MathMode) -> CGFloat {
            MathImageRenderer.render(
                latex: #"\sum_{i=1}^{n} i"#,
                mode: mode,
                fontFamily: .latinModern,
                fontSize: 20,
                color: .black
            )?.size.height ?? 0
        }

        #expect(height(.display) > height(.inline))
    }

    @Test("Renderer reports a descent for baseline alignment")
    func descentForBaseline() {
        let rendered = MathImageRenderer.render(
            latex: #"\frac{a}{b}"#,
            mode: .inline,
            fontFamily: .latinModern,
            fontSize: 17,
            color: .black
        )

        // A fraction extends below the baseline.
        #expect((rendered?.descent ?? 0) > 0)
    }

    @Test("Every font family renders", arguments: MathFontFamily.allCases)
    func allFontFamiliesRender(family: MathFontFamily) {
        let rendered = MathImageRenderer.render(
            latex: #"\int_0^1 x\,dx"#,
            mode: .display,
            fontFamily: family,
            fontSize: 20,
            color: .black
        )

        #expect(rendered != nil, "family: \(family)")
    }
}
