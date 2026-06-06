#if canImport(UIKit)
import SwiftUI
import VisualTesting

/// Setup function for VisualTesting configuration.
@MainActor
func setupVisualTesting() {
    VisualTesting.themeApplicable = DefaultThemeApplicable()
}
#endif
