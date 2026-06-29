# LaTeXCore をはじめる

Swift ターゲットにプラットフォーム非依存の LaTeX 数式解析を追加する。

## インストール

`Package.swift` に以下を追加する:

```swift
dependencies: [
    .package(
        url: "https://github.com/no-problem-dev/swift-latex-view.git",
        .upToNextMajor(from: "0.1.1")
    )
]
```

ターゲットに `LaTeXCore` を追加する:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "LaTeXCore", package: "swift-latex-view")
    ]
)
```

## セットアップ

必要な箇所で import する:

```swift
import LaTeXCore
```

`LaTeXCore` は Swift 6.2 以上を要求するだけで、プラットフォーム制約はない。
サーバーサイド Swift・CLI ツール・SwiftUI を import できないターゲットでも安全に使用できる。

## 基本的な使い方

### 文字列をテキストと数式に分割する

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

### 描画前に検証する

```swift
let expr = MathExpression(#"\sqrt{x^2 + y^2}"#, mode: .display)
if let error = expr.validate() {
    // 生ソースにフォールバック
    print("Parse error:", error.message)
} else {
    // 安全に描画可能
}
```

### LLM の二重エスケープを修正する

LLM が JSON 内で LaTeX をエンコードすると、バックスラッシュが二重エスケープされて
`\\frac` のような文字列が含まれる場合がある。`normalizedLatex` で自動的に修正できる:

```swift
let raw = MathExpression(#"\\frac{1}{2}"#)
print(raw.normalizedLatex)  // → \frac{1}{2}
```

### ストリーミング LLM 出力に対応する

部分的なストリームを受信する場合は `completeUnterminated` を有効にする:

```swift
let segmenter = MathSegmenter(options: .init(completeUnterminated: true))
// 閉じ $$ がまだ届いていない — それでも .math セグメントを生成する:
let partial = segmenter.segments(in: "Energy: $$E = mc^2")
```
