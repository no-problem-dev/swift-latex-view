[English](./README.md) | 日本語

# SwiftLaTeXView

SwiftUI ネイティブの LaTeX 数式レンダリング。言語モデルが実際に吐く LaTeX に耐える。

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 概要

モデルの出力は綺麗な LaTeX ではない。デリミタはベンダーごとに違い、JSON を経由したバックスラッシュは
二重エスケープで返り、ストリームは閉じ `$$` が届く前に表示され、金額は数式に見える。
このパッケージはそれを異常系ではなく通常系として扱う。

| デリミタ | モード | 出力元 |
|---|---|---|
| `$$...$$` | display | Claude / Gemini / GitHub |
| `\[...\]` | display | OpenAI |
| `\(...\)` | inline | OpenAI |
| `$...$` | inline | Claude / Gemini — Pandoc 規則で判定するので `costs $5 to $10` は文のまま |

- **2 つのプロダクト。** `LaTeXCore` は UI に依存せず分割と検証だけを行うので、サーバーでも CLI でも動く。
  `SwiftLaTeXView` は描画を担い、色とスペーシングを DesignSystem から読む
- **ストリーミング。** `completeUnterminated` は入力末尾の未終端デリミタを数式として扱う。
  閉じデリミタを待たずに、書かれた端から数式が出る
- **行き止まりを作らない。** パースできない LaTeX はエラー色の生ソース表示に劣化する。
  クラッシュも空ビューも起きない
- **エンジンは隠す。** SwiftMath は `internal import`。上げても公開 API は動かない

## 使い方

```swift
import SwiftLaTeXView

// 中央揃え。器からはみ出す時はレイアウトを伸ばさず横スクロールする
LaTeXView(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)

// テキストのベースラインに乗る。HStack(alignment: .firstTextBaseline) の中で使う
LaTeXView(#"a \neq 0"#, mode: .inline)
```

## ドキュメント

[API リファレンスとガイド](https://no-problem-dev.github.io/swift-latex-view/documentation/swiftlatexview/) —
文中からの数式抽出、ストリーム出力の扱い、`MathStyle` の書き方。

## インストール

`Package.swift` に追加する:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-latex-view.git", .upToNextMinor(from: "0.3.0"))
]
```

必要なプロダクトを依存に入れる:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftLaTeXView", package: "swift-latex-view"),
        // サーバー・CLI なら LaTeXCore 単体でよい
        .product(name: "LaTeXCore", package: "swift-latex-view")
    ]
)
```

## 開発に参加する

[CONTRIBUTING.md](./CONTRIBUTING.md) を参照。

## ライセンス

MIT — [LICENSE](./LICENSE) を参照。
