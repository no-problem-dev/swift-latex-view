/// 数式のレイアウトモード。
public enum MathMode: String, Sendable, Equatable, Hashable, CaseIterable {
    /// 行内に配置し、ベースラインで垂直に揃える。
    case inline
    /// スタンドアロンブロックとして配置し、ディスプレイスタイルの余白を付与する。
    case display
}

/// LaTeX 数式とそのレイアウトモードを保持する値型。
///
/// LaTeX ソースはデリミタを除いた形で保持する。
/// 解析は ``validate()`` 呼び出しか描画時まで行わない。
public struct MathExpression: Sendable, Equatable, Hashable {
    /// デリミタを除いた LaTeX ソース文字列。
    public let latex: String

    /// レイアウトモード。
    public let mode: MathMode

    /// 数式を生成する。
    ///
    /// - Parameters:
    ///   - latex: デリミタを含まない LaTeX ソース。たとえば `#"\frac{1}{2}"#`。
    ///     `"$\frac{1}{2}$"` のようにデリミタを含めると、デリミタが文字として描画される。
    ///     散文中の数式を抽出する場合は ``MathSegmenter`` を使うとデリミタを自動除去できる。
    ///   - mode: レイアウトモード。デフォルトは ``MathMode/display``。
    public init(_ latex: String, mode: MathMode = .display) {
        self.latex = latex
        self.mode = mode
    }
}

extension MathExpression {
    /// LLM による二重エスケープを修正した LaTeX ソース。
    ///
    /// LLM が JSON 内で LaTeX を出力すると、バックスラッシュが二重エスケープされる場合がある。
    /// その結果 `\\frac` のような文字列が含まれ、エンジンは `\\` を改行として解釈してコマンド名を
    /// リテラル文字として描画してしまう。`\\` の直後に英字が続く場合を `\` に畳み込むことで修正する。
    /// 正当な改行（`a & b \\ c & d` など）の後には空白か `\` が続くため、英字は直後に来ない。
    ///
    /// レンダラーと ``validate()`` はこの正規化済み文字列を使用する。
    public var normalizedLatex: String {
        guard latex.contains(#"\\"#) else { return latex }
        var result = ""
        result.reserveCapacity(latex.count)
        let characters = Array(latex)
        var i = 0
        while i < characters.count {
            if characters[i] == "\\",
               i + 2 < characters.count,
               characters[i + 1] == "\\",
               characters[i + 2].isLetter {
                result.append("\\")
                i += 2
                continue
            }
            result.append(characters[i])
            i += 1
        }
        return result
    }
}
