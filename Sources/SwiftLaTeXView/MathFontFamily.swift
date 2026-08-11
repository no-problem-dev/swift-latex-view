internal import SwiftMath

/// The OpenType MATH fonts available for typesetting.
///
/// All of them ship inside the typesetting engine, so an app never has to register a font or
/// bundle a resource to use one.
public enum MathFontFamily: String, Sendable, Equatable, Hashable, CaseIterable {
    /// Latin Modern Math — the traditional TeX look, and what you get unless a style says otherwise.
    case latinModern
    /// KP Math Light — a serif face at a lighter weight than Latin Modern.
    case kpLight
    /// KP Math Sans — the sans-serif companion to ``kpLight``.
    case kpSans
    /// XITS Math — Times-metric, for math set alongside a Times-like body font.
    case xits
    /// TeX Gyre Termes Math — the other Times-metric option, from the TeX Gyre family.
    case termes
    /// Asana Math — Palatino-metric, for math set alongside a Palatino-like body font.
    case asana
    /// Euler Math — upright calligraphic; distinctive rather than neutral.
    case euler
    /// Fira Math — sans-serif, the one to reach for with a sans-serif UI.
    case fira
    /// Noto Sans Math — sans-serif with unusually broad symbol coverage.
    case notoSans
    /// Libertinus Math — serif, derived from Linux Libertine.
    case libertinus
}

extension MathFontFamily {
    var engineFontName: String {
        let engineFont: MathFont = switch self {
        case .latinModern: .latinModernFont
        case .kpLight: .kpMathLightFont
        case .kpSans: .kpMathSansFont
        case .xits: .xitsFont
        case .termes: .termesFont
        case .asana: .asanaFont
        case .euler: .eulerFont
        case .fira: .firaFont
        case .notoSans: .notoSansFont
        case .libertinus: .libertinusFont
        }
        return engineFont.rawValue
    }
}
