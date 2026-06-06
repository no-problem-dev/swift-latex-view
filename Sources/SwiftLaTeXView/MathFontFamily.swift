internal import SwiftMath

/// The OpenType MATH font used to typeset expressions.
///
/// All fonts are bundled with the rendering engine; no app-side
/// font registration is required.
public enum MathFontFamily: String, Sendable, Equatable, Hashable, CaseIterable {
    /// Latin Modern Math — the classic TeX look. Default.
    case latinModern
    /// KP Math Light.
    case kpLight
    /// KP Math Sans.
    case kpSans
    /// XITS Math (Times-like).
    case xits
    /// TeX Gyre Termes Math (Times-like).
    case termes
    /// Asana Math (Palatino-like).
    case asana
    /// Euler Math (upright calligraphic).
    case euler
    /// Fira Math (sans-serif).
    case fira
    /// Noto Sans Math.
    case notoSans
    /// Libertinus Math.
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
