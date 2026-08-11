/// Re-exported so that `import SwiftLaTeXView` also brings in the `LaTeXCore` model types
/// (`MathExpression`, `MathSegmenter`, and the rest). Splitting prose and rendering it are the
/// same job at the call site, so they should not need two imports.
@_exported import LaTeXCore
