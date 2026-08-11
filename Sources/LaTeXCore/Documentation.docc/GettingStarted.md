# Getting started with LaTeXCore

Split, validate, and repair LaTeX in any Swift target — no UI required.

## Setup

Add the `LaTeXCore` product to your target (see the package README for the dependency snippet) and
import it:

```swift
import LaTeXCore
```

`LaTeXCore` asks only for Swift 6.2; it carries no platform constraint. It is safe in server-side
Swift, in a CLI tool, and in any target that cannot import SwiftUI.

## Splitting a string into text and math

```swift
let segmenter = MathSegmenter()
let segments = segmenter.segments(in: "Solve \\(ax^2 + bx + c = 0\\) for \\(x\\).")

for segment in segments {
    switch segment {
    case .text(let string):
        print("text:", string)
    case .math(let expr):
        print("math [\(expr.mode)]:", expr.latex)
    }
}
// text: Solve
// math [inline]: ax^2 + bx + c = 0
// text:  for
// math [inline]: x
// text: .
```

Text outside the delimiters is preserved character for character, and a delimiter that does not go
on to form valid math stays in the text rather than being dropped. Nothing in the input is lost.

## Validating before you render

```swift
let expr = MathExpression(#"\sqrt{x^2 + y^2}"#, mode: .display)
if let error = expr.validate() {
    // Fall back to the raw source
    print("Parse error:", error.message)
} else {
    // Safe to render
}
```

## Repairing double-escaped output

A model encoding LaTeX inside JSON often escapes its backslashes twice, so what arrives is
`\\frac` rather than `\frac` — which the engine reads as a line break followed by the letters
`frac`. `normalizedLatex` collapses that, and both the renderer and `validate()` already work from
this form:

```swift
let raw = MathExpression(#"\\frac{1}{2}"#)
print(raw.normalizedLatex)  // → \frac{1}{2}
```

## Keeping up with a stream

When the text is still arriving, turn on `completeUnterminated` so an unfinished expression is
still segmented as math:

```swift
let segmenter = MathSegmenter(options: .init(completeUnterminated: true))
// The closing $$ has not arrived — this still yields a .math segment:
let partial = segmenter.segments(in: "Energy: $$E = mc^2")
```

Leave it off for text that is already complete, or a stray `$` will swallow the tail of the input.
