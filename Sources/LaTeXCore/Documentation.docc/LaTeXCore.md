# ``LaTeXCore``

Platform-agnostic LaTeX math parsing for Swift — segment, validate, and normalize
math expressions from LLM output without any UI dependency.

## Overview

`LaTeXCore` provides the interpretation layer of the swift-latex-view package.
It converts raw text (including Markdown from LLM output) into strongly typed
`MathSegment` values that distinguish plain text from math expressions, and it
validates those expressions against the typesetting engine before rendering.

Because `LaTeXCore` has no SwiftUI or UIKit dependency, it can be used in
server-side Swift, CLI tools, and test targets — anywhere you need to detect or
pre-validate math before display.

### Parsing LLM output

`MathSegmenter` understands every delimiter style emitted by major LLMs:

```swift
import LaTeXCore

let segmenter = MathSegmenter()
let segments = segmenter.segments(in: "Energy: $$E = mc^2$$ — Einstein.")
// → [.text("Energy: "), .math(MathExpression("E = mc^2", mode: .display)), .text(" — Einstein.")]
```

### Streaming support

When consuming a live LLM stream, the closing delimiter may not have arrived yet.
Enable `completeUnterminated` to treat an open delimiter at end-of-input as
valid math:

```swift
let streaming = MathSegmenter(options: .init(completeUnterminated: true))
let partial = streaming.segments(in: "Consider \\(x^2 + y^2")
// → [.text("Consider "), .math(MathExpression("x^2 + y^2", mode: .inline))]
```

### Validation before rendering

Call `validate()` on a `MathExpression` to detect parse failures before handing
the expression to a renderer. This avoids crashes on malformed LLM output:

```swift
let expr = MathExpression(#"\frac{1}{2"#) // missing closing brace
if let error = expr.validate() {
    print("Cannot render: \(error.message)")
}
```

## Topics

### Essentials

- <doc:GettingStarted>

### Segmenting Text

- ``MathSegmenter``
- ``MathSegment``
- ``MathSegmenter/Options``

### Expressions

- ``MathExpression``
- ``MathMode``

### Validation

- ``MathParseError``
