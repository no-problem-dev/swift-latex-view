import Testing
@testable import LaTeXCore

/// Tests for MathExpression.validate().
///
/// The parsing engine (SwiftMath) is an implementation detail of LaTeXCore:
/// these tests only observe the public MathParseError surface.
struct MathValidationTests {

    @Test("Valid expressions pass validation", arguments: [
        "x^2",
        #"\frac{a}{b}"#,
        #"E = mc^2"#,
        #"\sum_{i=1}^{n} i = \frac{n(n+1)}{2}"#,
        #"\int_0^\infty e^{-x^2} \, dx = \frac{\sqrt{\pi}}{2}"#,
        #"\begin{pmatrix} a & b \\ c & d \end{pmatrix}"#,
        #"\alpha + \beta \neq \gamma"#,
        #"\sqrt{x^2 + y^2}"#,
        #"\frac{a}"#         // engine is lenient: empty denominator
    ])
    func validExpressions(latex: String) {
        let error = MathExpression(latex).validate()

        #expect(error == nil, "expected valid: \(latex)")
    }

    @Test("Invalid expressions fail validation", arguments: [
        "{a",                // unclosed brace
        #"\notarealcommand"#,
        #"a}"#               // unopened brace
    ])
    func invalidExpressions(latex: String) {
        let error = MathExpression(latex).validate()

        #expect(error != nil, "expected invalid: \(latex)")
    }

    @Test("Parse errors carry a human-readable message")
    func errorMessage() {
        let error = MathExpression("{a").validate()

        #expect(error.map { !$0.message.isEmpty } == true)
    }

    @Test("Validation does not depend on mode")
    func modeIndependent() {
        #expect(MathExpression("x^2", mode: .inline).validate() == nil)
        #expect(MathExpression("x^2", mode: .display).validate() == nil)
    }
}
