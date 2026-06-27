# Getting Started with LaTeXCore

Add platform-agnostic LaTeX math parsing to your Swift target.

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

Then add `LaTeXCore` to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "LaTeXCore", package: "swift-latex-view")
    ]
)
```

## Setup

Import the module where you need it:

```swift
import LaTeXCore
```

`LaTeXCore` has no platform requirements beyond Swift 6.2 and is safe to use in
server-side Swift, CLI tools, or any target that cannot import SwiftUI.

## Basic Usage

### Segment a string into text and math

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

### Validate before rendering

```swift
let expr = MathExpression(#"\sqrt{x^2 + y^2}"#, mode: .display)
if let error = expr.validate() {
    // Fall back to showing raw source
    print("Parse error:", error.message)
} else {
    // Safe to render
}
```

### Handle LLM over-escaping

LLMs encoding LaTeX inside JSON frequently double-escape backslashes, producing
`\\frac` instead of `\frac`. Use `normalizedLatex` to repair this automatically:

```swift
let raw = MathExpression(#"\\frac{1}{2}"#)
print(raw.normalizedLatex)  // → \frac{1}{2}
```

### Streaming LLM output

Enable `completeUnterminated` when consuming a partial stream:

```swift
let segmenter = MathSegmenter(options: .init(completeUnterminated: true))
// The closing $$ hasn't arrived yet — still produces a .math segment:
let partial = segmenter.segments(in: "Energy: $$E = mc^2")
```
