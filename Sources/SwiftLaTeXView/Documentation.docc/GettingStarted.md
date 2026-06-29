# SwiftLaTeXView をはじめる

SwiftUI アプリに LaTeX 数式レンダリングを追加する。

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

ターゲットに `SwiftLaTeXView` を追加する。`SwiftLaTeXView` を import すると
`LaTeXCore` のモデル型も自動的に利用可能になるため、追加 import は不要:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SwiftLaTeXView", package: "swift-latex-view")
    ]
)
```

## セットアップ

Swift ファイルの先頭で import する:

```swift
import SwiftUI
import SwiftLaTeXView
```

`SwiftLaTeXView` は iOS 17 以上または macOS 14 以上を必要とする。
追加のフォント登録や設定は不要 — 全数式フォントはパッケージに同梱されている。

## 基本的な使い方

### ディスプレイ数式

ディスプレイ（ブロック）モードは数式を中央揃えで全幅に描画する。
コンテナより幅広になると、レイアウトを崩さずに横スクロールする:

```swift
LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)
```

### インライン数式

インラインモードは `HStack(alignment: .firstTextBaseline)` 内でテキストのベースラインに揃える:

```swift
HStack(alignment: .firstTextBaseline) {
    Text("The Pythagorean theorem: ")
    LaTeXView(#"a^2 + b^2 = c^2"#, mode: .inline)
}
```

### テキスト連結

`Text` コンポジション（複数セグメントを連結した Markdown 段落など）に数式を埋め込む場合は
静的ヘルパー `inlineText` を使用する。`@MainActor` 修飾のため View の `body` など
メインアクター上で呼び出す:

```swift
var body: some View {
    // @MainActor コンテキスト（View body 等）で呼び出す
    let formula: Text = LaTeXView.inlineText(
        #"\alpha"#,
        fontSize: 17,
        color: .primary
    ) ?? Text("α")
    return Text("係数 ") + formula
}
```

## スタイルのカスタマイズ

`MathStyle` に準拠した型を作成し、`.mathStyle(_:)` で適用する。
全要件にはデフォルト実装があるため、必要なプロパティのみオーバーライドすればよい:

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

利用可能なフォントファミリーの一覧は ``MathFontFamily`` を参照。

## セグメント済みテキストからの描画

`LaTeXCore` から再エクスポートされた `MathSegmenter` と `LaTeXView` を組み合わせて、
テキストと数式が混在する文字列を描画する:

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
