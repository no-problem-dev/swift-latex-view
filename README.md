English | [日本語](./README.ja.md)

# SwiftLaTeXView

SwiftUI-native LaTeX math rendering for Swift, integrated with DesignSystem. Robust display of LLM output and user-generated content with correct typesetting and automatic theming.

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- **Two-layer architecture**: `LaTeXCore` (interpretation layer, no UI dependency) and `SwiftLaTeXView` (rendering layer, DesignSystem integration)
- **LLM output support**: Detects and normalizes all delimiter styles from OpenAI (`\(...\)` `\[...\]`), Claude, and Gemini (`$...$` `$$...$$`)
- **Currency false-positive prevention**: Single `$` uses conservative Pandoc rules (non-whitespace adjacent, not immediately followed by digit)
- **Streaming support**: Auto-completion option for unterminated delimiters (`completeUnterminated`)
- **Parse-failure fallback**: Invalid LaTeX degrades to raw source display in error color — no crashes, no empty views
- **Engine encapsulation**: The typesetting engine (SwiftMath) is hidden behind `internal import`; public API remains stable

## Quick Start

```swift
import SwiftUI
import SwiftLaTeXView

struct ContentView: View {
    var body: some View {
        VStack {
            // Display math
            LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)

            // Inline math, baseline-aligned with surrounding text
            HStack(alignment: .firstTextBaseline) {
                Text("where")
                LaTeXView(#"a \neq 0"#, mode: .inline)
                Text("holds.")
            }
        }
    }
}
```

### Detecting math in text (LaTeXCore)

```swift
import LaTeXCore

let segmenter = MathSegmenter()
let segments = segmenter.segments(in: "The energy is $$E = mc^2$$ as shown.")
// [.text("The energy is "), .math(MathExpression("E = mc^2", mode: .display)), .text(" as shown.")]

// Enable unterminated completion for streaming LLM output
let streaming = MathSegmenter(options: .init(completeUnterminated: true))
```

### Custom styling

```swift
struct AccentMathStyle: MathStyle {
    var fontFamily: MathFontFamily { .fira }
    var displayFontSize: CGFloat { 28 }

    func textColor(_ palette: any ColorPalette) -> Color {
        palette.primary
    }
}

LaTeXView(#"e^{i\pi} + 1 = 0"#)
    .mathStyle(AccentMathStyle())
```

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-latex-view.git", from: "")
]
```

Add to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftLaTeXView", package: "swift-latex-view"),
        // LaTeXCore only, for server-side Swift or CLI targets
        .product(name: "LaTeXCore", package: "swift-latex-view")
    ]
)
```

## Architecture

```
SwiftMath (typesetting engine, hidden behind internal import)
    ↑
LaTeXCore ──── MathExpression / MathSegmenter / validate()
    ↑           (no SwiftUI dependency — usable in server-side Swift)
SwiftLaTeXView ─ LaTeXView / MathStyle / Environment
    ↑           (DesignSystem token integration)
Your App
```

| Delimiter | Mode | Source |
|---|---|---|
| `$$...$$` | display | Claude / Gemini / GitHub |
| `\[...\]` | display | OpenAI |
| `\(...\)` | inline | OpenAI |
| `$...$` | inline | Claude / Gemini (Pandoc rules) |

## Testing

```bash
# Interpretation layer + engine integration (macOS CLI)
swift test

# UI snapshots (iOS Simulator)
xcodebuild test -scheme swift-latex-view-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## License

MIT
