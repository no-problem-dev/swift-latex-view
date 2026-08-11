# Getting started with SwiftLaTeXView

Put LaTeX math into a SwiftUI app.

## Setup

Add the `SwiftLaTeXView` product to your target (see the package README for the dependency
snippet) and import it:

```swift
import SwiftUI
import SwiftLaTeXView
```

That single import also brings in the `LaTeXCore` model types, so there is no second import to
remember. `SwiftLaTeXView` requires iOS 17 or macOS 14. There is no font to register and nothing
to configure — every math font ships inside the package.

## Display math

Display (block) mode centers the expression across the full width. When a formula is wider than
its container it scrolls horizontally rather than forcing the surrounding layout to grow:

```swift
LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)
```

## Inline math

Inline mode aligns the expression to the text baseline inside an
`HStack(alignment: .firstTextBaseline)`:

```swift
HStack(alignment: .firstTextBaseline) {
    Text("The Pythagorean theorem: ")
    LaTeXView(#"a^2 + b^2 = c^2"#, mode: .inline)
}
```

## Math inside a Text composition

Where a `View` cannot go — inside a `Text` built by concatenating segments, such as a rendered
Markdown paragraph — use the static `inlineText` helper. It is `@MainActor`, so call it from a
main-actor context such as a view's `body`. It reads nothing from the environment, so pass a size
and color that match the text around it:

```swift
var body: some View {
    let formula: Text = (try? LaTeXView.inlineText(
        #"\alpha"#,
        fontSize: 17,
        color: .primary
    )) ?? Text("α")
    return Text("Coefficient ") + formula
}
```

## Changing the style

Conform to `MathStyle` and apply it with `.mathStyle(_:)`. Every requirement has a default
implementation, so spell out only what you want to change:

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

See ``MathFontFamily`` for the fonts available.

## Rendering segmented text

Combine `MathSegmenter`, re-exported from `LaTeXCore`, with `LaTeXView` to render a string that
mixes prose and formulas:

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
