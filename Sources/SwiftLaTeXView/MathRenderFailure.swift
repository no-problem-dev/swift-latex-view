import LaTeXCore

/// Why an expression could not be turned into an image.
///
/// Everything that stops a render puts the same thing on screen — the source, set in the error
/// color — so a caller watching the view cannot tell source the engine rejected from source it
/// accepted and laid out to nothing. Those call for different responses: the first is malformed
/// output worth reporting, the second is an expression that is simply empty. This is where the
/// difference is kept.
public struct MathRenderFailure: Error, Sendable, Equatable {

    /// What stopped the render.
    public enum Reason: Sendable, Equatable {
        /// The engine rejected the source, and this is what it objected to. The message is the
        /// engine's own — the same one ``LaTeXCore/MathExpression/validate()`` reports.
        case parseFailed(MathParseError)

        /// The engine accepted the source and typeset a box with no width, so there is nothing to
        /// draw. Empty source does this, and so does valid-but-empty markup like `\frac{}{}`.
        case laidOutNothing
    }

    /// What stopped the render.
    public let reason: Reason

    /// The source the engine was actually handed: ``LaTeXCore/MathExpression/normalizedLatex``,
    /// not the string as it arrived.
    ///
    /// A fallback has to show this. Showing the raw string instead puts text on screen that is not
    /// what anything objected to — double-escaped model output would read `\\frac` while the
    /// engine had been given `\frac`.
    public let source: String

    /// Creates a failure.
    ///
    /// - Parameters:
    ///   - reason: What stopped the render.
    ///   - source: The source the engine was handed.
    public init(reason: Reason, source: String) {
        self.reason = reason
        self.source = source
    }
}
