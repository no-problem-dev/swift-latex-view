import Foundation
internal import SwiftMath

/// An error produced when LaTeX source cannot be parsed as math.
public struct MathParseError: Error, Sendable, Equatable, Hashable {
    /// A human-readable description of the parse failure.
    public let message: String
}

extension MathExpression {
    /// Parses the LaTeX source and returns the failure, if any.
    ///
    /// Use this to decide between rendering math and falling back to the
    /// raw source — important for LLM output, which can contain malformed
    /// or truncated LaTeX.
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
