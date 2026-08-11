#if canImport(UIKit)
import DesignSystem
import SwiftUI
import VisualTesting

/// Drives the snapshot theme axis through the design system, the way the app does.
///
/// `LaTeXView` takes its color from `\.colorPalette`, which only `.theme(_:)` puts in the
/// environment. `DefaultThemeApplicable` sets `\.colorScheme` alone, so the palette stayed light
/// under both themes and the math was typeset in the light `onSurface` on a dark ground — legible
/// only while the ground was wrongly light too.
private struct DesignSystemThemeApplicable: ThemeApplicable {
    @MainActor
    func applyTheme<V: View>(_ view: V, theme: SnapshotTheme) -> AnyView {
        let provider = ThemeProvider(initialMode: theme == .light ? .light : .dark)
        return AnyView(
            view
                .theme(provider)
                .environment(\.colorScheme, theme == .light ? .light : .dark)
        )
    }
}

/// `VisualTesting.themeApplicable` is global, so assigning it per suite means concurrent writes
/// once suites run in parallel. Hanging it off a global `let` runs the assignment exactly once.
@MainActor
private let themeApplicableInstalled: Bool = {
    VisualTesting.themeApplicable = DesignSystemThemeApplicable()
    return true
}()

@MainActor
func setupVisualTesting() {
    _ = themeApplicableInstalled
}
#endif
