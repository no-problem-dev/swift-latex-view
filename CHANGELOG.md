# Changelog

## [Unreleased]

## [0.4.0] - 2026-08-11

### Changed

- Doc comments, the DocC catalogs, and this file are now English. No code changed.

## [0.3.0] - 2026-08-10

### Changed

- Raised the swift-design-system pin to 3.0.0. DesignSystem types appear in this package's public
  API, so consumers have to move to design-system 3.x as well.

## [0.2.0] - 2026-07-19

### Changed

- Raised the swift-design-system pin to 2.0.1.

## [0.1.2] - 2026-07-19

### Added

- DocC landing pages and Getting Started articles for both targets, published to GitHub Pages.

### Changed

- Documented the delimiter contract on the public API.
- README split into English and Japanese.

## [0.1.1] - 2026-06-06

### Fixed

- Display math wider than its container now scrolls horizontally instead of overflowing.

## [0.1.0] - 2026-06-06

### Added

- `MathExpression` and `MathSegmenter`, covering the `$...$`, `$$...$$`, `\(...\)`, and `\[...\]`
  delimiter styles, with Pandoc rules for single `$`, escape handling, code-construct skipping,
  and completion of unterminated delimiters for streamed input.
- `MathExpression.validate()`, keeping SwiftMath behind an `internal import`.
- `LaTeXView`, `MathStyle`, and environment injection.
- `LaTeXView.inlineText` for embedding math in a `Text` composition.
- `normalizedLatex`, which repairs the double-escaped `\\command` that models emit from JSON.

### Fixed

- Offscreen rasterization drew every expression upside down.
- Short expressions were clipped by the engine's height clamp.
