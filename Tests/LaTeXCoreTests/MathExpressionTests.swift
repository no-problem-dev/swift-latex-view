import Testing
@testable import LaTeXCore

/// Tests for the MathExpression value type
struct MathExpressionTests {

    @Test("Default mode is display")
    func defaultModeIsDisplay() {
        let expression = MathExpression(#"\frac{a}{b}"#)

        #expect(expression.latex == #"\frac{a}{b}"#)
        #expect(expression.mode == .display)
    }

    @Test("Inline mode is preserved")
    func inlineModeIsPreserved() {
        let expression = MathExpression("x^2", mode: .inline)

        #expect(expression.mode == .inline)
    }

    @Test("Expressions with same latex and mode are equal")
    func equality() {
        #expect(MathExpression("a+b") == MathExpression("a+b"))
        #expect(MathExpression("a+b") != MathExpression("a+b", mode: .inline))
        #expect(MathExpression("a+b") != MathExpression("a-b"))
    }
}
