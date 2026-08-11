# Changelog

## [Unreleased]

## [0.5.0] - 2026-08-11

### Changed

- Raised the swift-design-system pin to 4.0.0.

## [0.4.1] - 2026-08-11

### Fixed

- **Dark snapshots typeset the math in the light color.** The snapshot suite drove its theme axis
  with `DefaultThemeApplicable`, which sets `\.colorScheme` and nothing else. `LaTeXView` takes its
  color from `\.colorPalette`, which only `.theme(_:)` puts in the environment, so the palette
  stayed light under both themes and the math was drawn in the light `onSurface` — near-black
  glyphs, which were legible only because the ground was wrongly light as well. The suite now
  installs a `ThemeApplicable` that hands the theme to a `ThemeProvider`, the way an app does.
  Dark captures now show white math on a dark ground.

### Changed

- **Raised the swift-visual-testing pin to 3.0.0 and re-recorded the reference images.** Up to
  2.1.0 the recorder hard-coded a light `UITraitCollection`, so a dark capture was rendered over a
  light ground; `LaTeXView` paints no background of its own, which makes that ground the entire
  image. The six dark references now measure a mean pixel of [0, 0, 0] to [2, 2, 2] against
  [253, 253, 254] and up for the matching light ones.

  **This repository commits no reference images** — `.gitignore` excludes `**/__Snapshots__/` with
  the note "generated on CI", but CI builds documentation and cuts releases and never runs the
  tests, so no baseline exists in the repository or anywhere else. There is therefore no image diff
  here. Anyone holding locally recorded images must delete `__Snapshots__` and record again; kept
  images from 2.x will not match.

- **`assertComponentSnapshot` call sites pass `disableAnimations:`.** 3.0.0 added the argument, and
  all six pass `false`, which is what 2.x did. `LaTeXView` drives no animation.

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
