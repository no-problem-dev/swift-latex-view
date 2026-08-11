English | [日本語](./README.ja.md)

# SwiftLaTeXView

SwiftUI-native LaTeX math rendering, robust to the LaTeX that language models actually emit.

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Overview

Model output is not clean LaTeX. Delimiters vary by vendor, backslashes come back double-escaped
from JSON, streams arrive with the closing `$$` still in flight, and prices look like math. This
package takes all of that as the normal case.

| Delimiter | Mode | Emitted by |
|---|---|---|
| `$$...$$` | display | Claude / Gemini / GitHub |
| `\[...\]` | display | OpenAI |
| `\(...\)` | inline | OpenAI |
| `$...$` | inline | Claude / Gemini — judged by Pandoc's rules, so `costs $5 to $10` stays prose |

- **Two products.** `LaTeXCore` splits and validates text with no UI dependency, so it runs on the
  server or in a CLI. `SwiftLaTeXView` renders, and reads its colors and spacing from DesignSystem.
- **Streaming.** `completeUnterminated` treats a dangling delimiter at the end of the input as math,
  so a formula appears as it is typed rather than after the closing delimiter lands.
- **No dead ends.** LaTeX that fails to parse degrades to its raw source in the error color — never
  a crash, never an empty view.
- **The engine stays hidden.** SwiftMath is an `internal import`; upgrading it does not move the
  public API.

## Usage

```swift
import SwiftLaTeXView

// Centered, and scrolls sideways rather than stretching the layout it sits in.
LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)

// On the text baseline, inside an HStack(alignment: .firstTextBaseline).
LaTeXView(#"a \neq 0"#, mode: .inline)
```

## Documentation

[API reference and guides](https://no-problem-dev.github.io/swift-latex-view/documentation/swiftlatexview/) —
pulling math out of prose, handling streamed output, and writing a `MathStyle`.

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-latex-view.git", .upToNextMinor(from: "0.5.0"))
]
```

Then depend on whichever product you need:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftLaTeXView", package: "swift-latex-view"),
        // LaTeXCore alone, for server-side Swift or CLI targets
        .product(name: "LaTeXCore", package: "swift-latex-view")
    ]
)
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT — see [LICENSE](./LICENSE).
