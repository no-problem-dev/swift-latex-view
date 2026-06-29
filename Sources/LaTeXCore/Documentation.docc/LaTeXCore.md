# ``LaTeXCore``

Swift 向けのプラットフォーム非依存 LaTeX 数式解析ライブラリ。UI 非依存で LLM 出力の数式を分割・検証・正規化する。

## Overview

`LaTeXCore` は swift-latex-view パッケージの解釈層を担う。
生テキスト（LLM が出力する Markdown を含む）を強型の `MathSegment` に変換し、
テキストと数式を区別する。また、組版エンジンに渡す前に数式の妥当性を検証できる。

`LaTeXCore` は SwiftUI・UIKit に依存しないため、
サーバーサイド Swift・CLI ツール・テストターゲットなど、画面表示が不要な場所でも使用できる。

### LLM 出力の解析

`MathSegmenter` は主要 LLM が出力するすべてのデリミタ記法を認識する:

```swift
import LaTeXCore

let segmenter = MathSegmenter()
let segments = segmenter.segments(in: "Energy: $$E = mc^2$$ — Einstein.")
// → [.text("Energy: "), .math(MathExpression("E = mc^2", mode: .display)), .text(" — Einstein.")]
```

### ストリーミング対応

ライブの LLM ストリームを受信する際は、閉じデリミタがまだ届いていない場合がある。
`completeUnterminated` を有効にすると、入力末尾の開きデリミタを有効な数式として扱う:

```swift
let streaming = MathSegmenter(options: .init(completeUnterminated: true))
let partial = streaming.segments(in: "Consider \\(x^2 + y^2")
// → [.text("Consider "), .math(MathExpression("x^2 + y^2", mode: .inline))]
```

### 描画前の検証

不正な LLM 出力でクラッシュを回避するため、描画前に `validate()` でパース失敗を検出する:

```swift
let expr = MathExpression(#"\frac{1}{2"#) // 閉じ括弧が欠けている
if let error = expr.validate() {
    print("描画不可: \(error.message)")
}
```

## Topics

### 基本

- <doc:GettingStarted>

### テキスト分割

- ``MathSegmenter``
- ``MathSegment``
- ``MathSegmenter/Options``

### 数式

- ``MathExpression``
- ``MathMode``

### 検証

- ``MathParseError``
