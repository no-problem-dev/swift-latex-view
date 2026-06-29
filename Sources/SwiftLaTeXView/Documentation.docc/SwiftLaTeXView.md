# ``SwiftLaTeXView``

DesignSystem と統合した SwiftUI ネイティブの LaTeX 数式レンダリングライブラリ。
LLM 出力やユーザーコンテンツを正確なタイプセットと自動テーマ対応で表示する。

## Overview

`SwiftLaTeXView` は swift-latex-view パッケージの描画層を担う。
SwiftMath 組版エンジンを SwiftUI の `View` としてラップし、
DesignSystem 環境から色・スペーシング・フォントトークンを読み取るため、
数式はアプリのビジュアルテーマに自動的に追従する。

公開 API は 3 つの層で構成される:
- **`LaTeXView`** — ディスプレイ数式とインライン数式に対応するビュー
- **`MathStyle`** — フォント・サイズ・色をカスタマイズするプロトコル
- **`MathFontFamily`** — 同梱済み OpenType MATH フォントの enum

組版エンジン（SwiftMath）は `internal import` で隠蔽しており、
アプリが直接依存することはない。エンジンをアップグレードしても公開 API は変わらない。

### 基本的な描画

```swift
import SwiftUI
import SwiftLaTeXView

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            // ディスプレイ（ブロック）数式 — 中央揃え、コンテナを超えると横スクロール
            LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)

            // インライン数式 — テキストのベースラインに揃える
            HStack(alignment: .firstTextBaseline) {
                Text("where")
                LaTeXView(#"a \neq 0"#, mode: .inline)
                Text("holds.")
            }
        }
    }
}
```

### スタイルのカスタマイズ

`MathStyle` を実装して必要なプロパティのみオーバーライドする:

```swift
struct AccentMathStyle: MathStyle {
    var fontFamily: MathFontFamily { .fira }
    var displayFontSize: CGFloat { 24 }

    func textColor(_ palette: any ColorPalette) -> Color {
        palette.primary
    }
}

LaTeXView(#"e^{i\pi} + 1 = 0"#)
    .mathStyle(AccentMathStyle())
```

### フォールバック動作

LaTeX のパースに失敗した場合（LLM 出力の途中切れなど）、`LaTeXView` は
`MathStyle.errorColor(_:)` を使ったモノスペースフォントで生ソースを表示する。
クラッシュも空ビューも発生しない。

## Topics

### 基本

- <doc:GettingStarted>

### レンダリング

- ``LaTeXView``

### スタイリング

- ``MathStyle``
- ``DefaultMathStyle``
- ``MathFontFamily``

### 環境

- ``SwiftUICore/EnvironmentValues/mathStyle``
- ``SwiftUICore/View/mathStyle(_:)``

### コア型（LaTeXCore から再エクスポート）

- `MathExpression`
- `MathMode`
- `MathSegmenter`
- `MathSegment`
- `MathParseError`
