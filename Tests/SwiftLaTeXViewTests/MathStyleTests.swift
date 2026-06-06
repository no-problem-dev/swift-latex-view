import Testing
import SwiftUI
@testable import SwiftLaTeXView

/// Tests for the MathStyle protocol defaults and environment plumbing.
struct MathStyleTests {

    @Test("DefaultMathStyle uses Latin Modern with standard sizes")
    func defaultStyle() {
        let style = DefaultMathStyle()

        #expect(style.fontFamily == .latinModern)
        #expect(style.displayFontSize == 20)
        #expect(style.inlineFontSize == 17)
    }

    @Test("Protocol defaults let a custom style override only what it needs")
    func protocolDefaults() {
        struct FiraStyle: MathStyle {
            var fontFamily: MathFontFamily { .fira }
        }
        let style = FiraStyle()

        #expect(style.fontFamily == .fira)
        #expect(style.displayFontSize == DefaultMathStyle().displayFontSize)
    }

    @Test("mathStyle environment value round-trips")
    func environmentRoundTrip() {
        struct MarkerStyle: MathStyle {
            var displayFontSize: CGFloat { 99 }
        }
        var environment = EnvironmentValues()

        #expect(environment.mathStyle.displayFontSize == DefaultMathStyle().displayFontSize)

        environment.mathStyle = MarkerStyle()

        #expect(environment.mathStyle.displayFontSize == 99)
    }
}
