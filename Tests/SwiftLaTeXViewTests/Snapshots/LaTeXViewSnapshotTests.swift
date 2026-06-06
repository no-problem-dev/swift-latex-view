#if canImport(UIKit)
import Testing
import SwiftUI
import VisualTesting
import DesignSystem
@testable import SwiftLaTeXView

/// Snapshot tests for LaTeXView rendering.
@Suite("LaTeXView Snapshots")
@MainActor
struct LaTeXViewSnapshotTests {

    init() { setupVisualTesting() }

    private let snapshotSize = CGSize(width: 400, height: 200)

    // MARK: - Display Math

    @Test
    func displayQuadraticFormula() {
        let view = LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)
            .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "LaTeXView",
            stateName: "display-quadratic",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }

    @Test
    func displaySummation() {
        let view = LaTeXView(#"\sum_{i=1}^{n} i = \frac{n(n+1)}{2}"#)
            .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "LaTeXView",
            stateName: "display-summation",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }

    @Test
    func displayMatrix() {
        let view = LaTeXView(#"\begin{pmatrix} a & b \\ c & d \end{pmatrix}"#)
            .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "LaTeXView",
            stateName: "display-matrix",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }

    // MARK: - Inline Math

    @Test
    func inlineWithinText() {
        let view = HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("where")
            LaTeXView(#"a \neq 0"#, mode: .inline)
            Text("holds.")
        }
        .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "LaTeXView",
            stateName: "inline-baseline",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }

    // MARK: - Error Fallback

    @Test
    func invalidLatexFallsBackToSource() {
        let view = LaTeXView(#"\notarealcommand{x"#)
            .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "LaTeXView",
            stateName: "error-fallback",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }

    // MARK: - Style Customization

    @Test
    func customStyle() {
        struct AccentMathStyle: MathStyle {
            var fontFamily: MathFontFamily { .fira }
            var displayFontSize: CGFloat { 28 }
            func textColor(_ palette: any ColorPalette) -> Color {
                palette.primary
            }
        }
        let view = LaTeXView(#"e^{i\pi} + 1 = 0"#)
            .mathStyle(AccentMathStyle())
            .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "LaTeXView",
            stateName: "custom-style",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }
}
#endif
