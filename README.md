# SwiftLaTeXView

SwiftUI ネイティブな LaTeX 数式レンダリングライブラリ。DesignSystem と統合し、LLM 出力にも堅牢な数式表示を実現します。

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 特徴

- **2 層アーキテクチャ**: `LaTeXCore`（解釈層・UI 非依存）と `SwiftLaTeXView`（描画層・DesignSystem 統合）
- **LLM 出力対応**: OpenAI（`\(...\)` `\[...\]`）/ Claude / Gemini（`$...$` `$$...$$`）のデリミタ記法を全て検出・正規化
- **通貨誤検出防止**: single-`$` は Pandoc 規則（前後非空白・閉じ直後非数字）で保守的に判定
- **ストリーミング対応**: 未終端デリミタの自動補完オプション（`completeUnterminated`）
- **パース失敗時フォールバック**: 不正な LaTeX はエラー色のソース表示に劣化（クラッシュ・空白なし）
- **エンジン隠蔽**: 組版エンジン（SwiftMath）は `internal import` で完全に隠蔽。公開 API は安定

## クイックスタート

```swift
import SwiftUI
import SwiftLaTeXView

struct ContentView: View {
    var body: some View {
        VStack {
            // ディスプレイ数式
            LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)

            // インライン数式（ベースライン揃え）
            HStack(alignment: .firstTextBaseline) {
                Text("where")
                LaTeXView(#"a \neq 0"#, mode: .inline)
                Text("holds.")
            }
        }
    }
}
```

### テキストから数式を検出する（LaTeXCore）

```swift
import LaTeXCore

let segmenter = MathSegmenter()
let segments = segmenter.segments(in: "The energy is $$E = mc^2$$ as shown.")
// [.text("The energy is "), .math(MathExpression("E = mc^2", mode: .display)), .text(" as shown.")]

// ストリーミング LLM 出力には未終端補完を有効化
let streaming = MathSegmenter(options: .init(completeUnterminated: true))
```

### スタイルカスタマイズ

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

## インストール

### Swift Package Manager

`Package.swift` に以下を追加：

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-latex-view.git", from: "0.1.0")
]
```

ターゲットに追加：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftLaTeXView", package: "swift-latex-view"),
        // 解釈層のみ必要な場合（サーバー・CLI でも使用可）
        .product(name: "LaTeXCore", package: "swift-latex-view")
    ]
)
```

## アーキテクチャ

```
SwiftMath (組版エンジン、internal に隠蔽)
    ↑
LaTeXCore ──── MathExpression / MathSegmenter / validate()
    ↑           （SwiftUI 非依存・サーバーでも使用可）
SwiftLaTeXView ─ LaTeXView / MathStyle / Environment
    ↑           （DesignSystem トークン連動）
あなたのアプリ
```

| デリミタ | モード | 出力元 |
|---|---|---|
| `$$...$$` | display | Claude / Gemini / GitHub |
| `\[...\]` | display | OpenAI |
| `\(...\)` | inline | OpenAI |
| `$...$` | inline | Claude / Gemini（Pandoc 規則で判定） |

## テスト

```bash
# 解釈層 + エンジン統合（macOS CLI）
swift test

# UI スナップショット（iOS シミュレータ）
xcodebuild test -scheme swift-latex-view-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## ライセンス

MIT
