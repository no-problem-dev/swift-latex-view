internal import SwiftMath

/// 数式の組版に使う OpenType MATH フォント。
///
/// 全フォントは組版エンジンに同梱しており、アプリ側でのフォント登録は不要。
public enum MathFontFamily: String, Sendable, Equatable, Hashable, CaseIterable {
    /// Latin Modern Math — 伝統的な TeX スタイル。デフォルト。
    case latinModern
    /// KP Math Light。
    case kpLight
    /// KP Math Sans。
    case kpSans
    /// XITS Math（Times 系）。
    case xits
    /// TeX Gyre Termes Math（Times 系）。
    case termes
    /// Asana Math（Palatino 系）。
    case asana
    /// Euler Math（直立カリグラフィ体）。
    case euler
    /// Fira Math（サンセリフ体）。
    case fira
    /// Noto Sans Math。
    case notoSans
    /// Libertinus Math。
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
