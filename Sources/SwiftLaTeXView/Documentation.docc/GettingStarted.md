# Getting Started with SwiftLaTeXView

Add LaTeX math rendering to a SwiftUI app.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/no-problem-dev/swift-latex-view.git",
        .upToNextMajor(from: "0.1.0")
    )
]
```

Then add `SwiftLaTeXView` to your target. Importing `SwiftLaTeXView` also
makes the `LaTeXCore` model types available — no separate import required:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SwiftLaTeXView", package: "swift-latex-view")
    ]
)
```

## Setup

Import the module at the top of your Swift file:

```swift
import SwiftUI
import SwiftLaTeXView
```

`SwiftLaTeXView` requires iOS 17+ or macOS 14+. No additional font registration
or configuration is needed — all math fonts are bundled with the package.

## Basic Usage

### Display math

Display (block) mode renders the expression centered and full-width. If it is
wider than the container, it scrolls horizontally without affecting the layout:

```swift
LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)
```

### Inline math

Inline mode aligns the expression on the text baseline so it flows naturally
inside `HStack(alignment: .firstTextBaseline)`:

```swift
HStack(alignment: .firstTextBaseline) {
    Text("The Pythagorean theorem: ")
    LaTeXView(#"a^2 + b^2 = c^2"#, mode: .inline)
}
```

### Text concatenation

When math must participate in a `Text` composition (for example, a Markdown
paragraph built from concatenated segments), use the static `inlineText` helper:

```swift
let segment: Text = LaTeXView.inlineText(
    #"\alpha"#,
    fontSize: 17,
    color: .primary
) ?? Text("α")
```

## Customising the Style

Create a type conforming to `MathStyle` and apply it with `.mathStyle(_:)`.
All requirements have defaults — override only what you need:

```swift
struct BigDisplayStyle: MathStyle {
    var displayFontSize: CGFloat { 28 }
    var fontFamily: MathFontFamily { .xits }

    func textColor(_ palette: any ColorPalette) -> Color {
        palette.onSurface
    }
}

LaTeXView(#"\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}"#)
    .mathStyle(BigDisplayStyle())
```

Available font families are listed in ``MathFontFamily``.

## Rendering from Segmented Text

Combine `MathSegmenter` (re-exported from `LaTeXCore`) with `LaTeXView` to
render a mixed text/math string:

```swift
let input = "Energy: $$E = mc^2$$ — Einstein."
let segments = MathSegmenter().segments(in: input)

var body: some View {
    VStack(alignment: .leading) {
        ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
            switch segment {
            case .text(let string):
                Text(string)
            case .math(let expr):
                LaTeXView(expr)
            }
        }
    }
}
```
