import Foundation
internal import SwiftMath

/// The reason a piece of LaTeX source could not be parsed.
public struct MathParseError: Error, Sendable, Equatable, Hashable {
    /// A human-readable account of what the parser objected to. Suitable for a log or a
    /// developer-facing diagnostic, not for an end user.
    public let message: String
}

extension MathExpression {
    /// Parses the source and reports what went wrong, or `nil` if it is sound.
    ///
    /// LLM output regularly contains LaTeX that is malformed or simply cut off mid-expression.
    /// Rendering handles that on its own by falling back to the raw source, but it discards the
    /// reason; call this first when the caller needs to know why, or wants to choose its own
    /// fallback instead of taking the built-in one.
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
