import Foundation
internal import SwiftMath

/// LaTeX ソースの解析に失敗したときのエラー。
public struct MathParseError: Error, Sendable, Equatable, Hashable {
    /// 解析失敗の内容を人間が読める形で表した文字列。
    public let message: String
}

extension MathExpression {
    /// LaTeX ソースを解析し、失敗があればエラーを返す。
    ///
    /// LLM 出力は不正または不完全な LaTeX を含む場合がある。
    /// 描画前にこのメソッドでパース可否を確認し、失敗時は生ソース表示にフォールバックできる。
    public func validate() -> MathParseError? {
        var error: NSError?
        let mathList = MTMathListBuilder.build(fromString: normalizedLatex, error: &error)
        if let error {
            return MathParseError(message: error.localizedDescription)
        }
        guard mathList != nil else {
            return MathParseError(message: "Unable to parse expression")
        }
        return nil
    }
}
