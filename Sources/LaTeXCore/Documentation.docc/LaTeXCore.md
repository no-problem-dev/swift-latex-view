# ``LaTeXCore``

Platform-independent LaTeX parsing for Swift: split model output into text and math, validate it,
and repair the escaping models get wrong — with no UI dependency.

## Overview

`LaTeXCore` is the interpretation half of the swift-latex-view package. It turns raw text —
including the Markdown a model streams back — into strongly typed `MathSegment` values that
separate prose from formulas, and it can check an expression against the typesetting engine before
anything tries to draw it.

Nothing here imports SwiftUI or UIKit, so it runs anywhere the answer is not a pixel: server-side
Swift, a CLI tool, or a test target.

### Parsing model output

`MathSegmenter` recognizes every delimiter style the major models emit:

```swift
import LaTeXCore

let segmenter = MathSegmenter()
let segments = segmenter.segments(in: "Energy: $$E = mc^2$$ — Einstein.")
// → [.text("Energy: "), .math(MathExpression("E = mc^2", mode: .display)), .text(" — Einstein.")]
```

### Handling a stream

While a response is still arriving, the closing delimiter may not have been sent yet. Turning on
`completeUnterminated` treats an opening delimiter at the end of the input as valid math, so the
formula appears as it is written instead of after it finishes:

```swift
let streaming = MathSegmenter(options: .init(completeUnterminated: true))
let partial = streaming.segments(in: "Consider \\(x^2 + y^2")
// → [.text("Consider "), .math(MathExpression("x^2 + y^2", mode: .inline))]
```

### Checking before rendering

`validate()` reports what the parser objected to, which is the only way to distinguish malformed
input from a rendering problem:

```swift
let expr = MathExpression(#"\frac{1}{2"#) // missing closing brace
if let error = expr.validate() {
    print("cannot render: \(error.message)")
}
```

## Topics

### Essentials

- <doc:GettingStarted>

### Splitting text

- ``MathSegmenter``
- ``MathSegment``
- ``MathSegmenter/Options``

### Expressions

- ``MathExpression``
- ``MathMode``

### Validation

- ``MathParseError``
