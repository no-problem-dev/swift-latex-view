# ``SwiftLaTeXView``

SwiftUI-native LaTeX math rendering, integrated with DesignSystem, for showing model output and
user content with correct typesetting and colors that follow the app's theme.

## Overview

`SwiftLaTeXView` is the rendering half of the swift-latex-view package. It wraps the SwiftMath
typesetting engine in a SwiftUI `View` and reads color, spacing, and font tokens from the
DesignSystem environment, so math tracks the app's appearance without being configured at each
call site.

The public surface is three pieces:
- **`LaTeXView`** — the view, for display and inline math
- **`MathStyle`** — the protocol for changing font, size, and color
- **`MathFontFamily`** — the OpenType MATH fonts that ship with the package

The engine is an `internal import`, so an app never depends on SwiftMath directly and upgrading it
does not move this package's public API.

`LaTeXCore` is re-exported, so `import SwiftLaTeXView` also brings in `MathExpression`,
`MathMode`, `MathSegmenter`, `MathSegment`, and `MathParseError`. Those types are documented under
`LaTeXCore`.

### Rendering math

```swift
import SwiftUI
import SwiftLaTeXView

struct TheoremView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Display (block) math — centered, scrolling sideways if it outgrows its container
            LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)

            // Inline math — aligned to the text baseline
            HStack(alignment: .firstTextBaseline) {
                Text("where")
                LaTeXView(#"a \neq 0"#, mode: .inline)
                Text("holds.")
            }
        }
    }
}
```

### Changing the style

Conform to `MathStyle` and override only what you want to change; every requirement has a default.

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

### What happens when parsing fails

LaTeX that will not parse — a model response cut off mid-expression, most often — is drawn as its
raw source in a monospaced font, tinted with `MathStyle.errorColor(_:)`. There is no crash and no
blank view, but the view keeps no error either. Call `MathExpression.validate()` first if you need
to know why, or want to substitute your own fallback.

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
