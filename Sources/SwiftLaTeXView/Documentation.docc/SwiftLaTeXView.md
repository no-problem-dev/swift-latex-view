# ``SwiftLaTeXView``

SwiftUI-native LaTeX math rendering integrated with the DesignSystem — display
LLM output and user content with correct typesetting and automatic theming.

## Overview

`SwiftLaTeXView` provides the rendering layer of the swift-latex-view package.
It wraps the SwiftMath typesetting engine in a SwiftUI `View` that reads colors,
spacing, and font tokens from the DesignSystem environment, so math expressions
automatically adapt to your app's visual theme.

The public API has three levels:
- **`LaTeXView`** — drop-in view for display and inline math
- **`MathStyle`** — protocol to customise font, size, and color
- **`MathFontFamily`** — enum of bundled OpenType MATH fonts

The typesetting engine (SwiftMath) is hidden behind `internal import`; your app
never depends on it directly, so the engine can be upgraded without breaking changes.

### Basic rendering

```swift
import SwiftUI
import SwiftLaTeXView

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Display (block) math — centered, scrolls if wider than container
            LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)

            // Inline math — baseline-aligned with surrounding text
            HStack(alignment: .firstTextBaseline) {
                Text("where")
                LaTeXView(#"a \neq 0"#, mode: .inline)
                Text("holds.")
            }
        }
    }
}
```

### Custom styling

Implement `MathStyle` to override only the properties you need:

```swift
struct AccentMathStyle: MathStyle {
    var fontFamily: MathFontFamily { .fira }
    var displayFontSize: CGFloat { 24 }

    func textColor(_ palette: any ColorPalette) -> Color {
        palette.primary
    }
}

LaTeXView(#"e^{i\pi} + 1 = 0"#)
    .mathStyle(AccentMathStyle())
```

### Fallback behavior

When LaTeX fails to parse (common with truncated LLM output), `LaTeXView` shows
the raw source in a monospaced font using `MathStyle.errorColor(_:)`. It never
crashes or produces an empty view.

## Topics

### Essentials

- <doc:GettingStarted>

### Rendering

- ``LaTeXView``

### Styling

- ``MathStyle``
- ``DefaultMathStyle``
- ``MathFontFamily``

### Environment

- ``SwiftUICore/EnvironmentValues/mathStyle``
- ``SwiftUICore/View/mathStyle(_:)``

### Core Types (re-exported from LaTeXCore)

- `MathExpression`
- `MathMode`
- `MathSegmenter`
- `MathSegment`
- `MathParseError`
