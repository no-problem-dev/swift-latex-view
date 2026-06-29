import SwiftUI
@preconcurrency internal import SwiftMath

#if canImport(UIKit)
import UIKit
typealias MathPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias MathPlatformImage = NSImage
#endif

/// レイアウトに必要なメトリクスを持つ、タイプセット済み数式。
struct RenderedMath {
    let image: MathPlatformImage
    let size: CGSize
    /// ベースラインから画像上端までの距離。
    let ascent: CGFloat
    /// ベースラインから画像下端までの距離。
    /// インライン数式を周囲テキストのベースラインに揃えるために使用する。
    let descent: CGFloat
}

/// LaTeX ソースを組版エンジン経由でラスタライズした画像に変換するブリッジ。
///
/// エンジン（SwiftMath）は実装詳細として隠蔽する。呼び出し側には ``RenderedMath`` のみを公開する。
///
/// 実装メモ: SwiftMath 1.7.x は `MTTypesetter` を internal にしているため、
/// 唯一の公開組版ルートは `MTMathUILabel` であり、その `layoutSubviews()`/`layout()` と
/// `displayList` が public である。このラベルをオフスクリーンで組版器として使用してラスタライズする。
/// ウィンドウには一切アタッチしないため、描画は MainActor に束縛される。
enum MathImageRenderer {

    @MainActor
    static func render(
        latex: String,
        mode: MathMode,
        fontFamily: MathFontFamily,
        fontSize: CGFloat,
        color: Color
    ) -> RenderedMath? {
        var error: NSError?
        let normalized = MathExpression(latex, mode: mode).normalizedLatex
        guard
            let mathList = MTMathListBuilder.build(fromString: normalized, error: &error),
            error == nil
        else {
            return nil
        }

        let label = MTMathUILabel()
        if let font = MTFontManager.manager.font(withName: fontFamily.engineFontName, size: fontSize) {
            label.font = font
        }
        label.labelMode = mode == .display ? .display : .text
        label.textColor = MTColor(color)
        label.mathList = mathList

        #if canImport(UIKit)
        let fittedSize = label.intrinsicContentSize
        #else
        let fittedSize = label.fittingSize
        #endif
        // The label's layout clamps content height to fontSize/2 and can
        // shift glyphs below the frame (negative baseline), clipping
        // descender tails of short expressions like a single `n`. Give the
        // frame the clamped height so nothing is cut off.
        let frameHeight = max(ceil(fittedSize.height), ceil(fontSize / 2) + 2)
        let size = CGSize(width: ceil(fittedSize.width), height: frameHeight)
        guard size.width > 0, size.height > 0, size.width.isFinite, size.height.isFinite else {
            return nil
        }
        label.frame = CGRect(origin: .zero, size: size)

        #if canImport(UIKit)
        label.layoutSubviews()
        #else
        label.layout()
        #endif
        guard let displayList = label.displayList else { return nil }

        // Replicate the label's vertical placement to locate the baseline:
        // content is centered with its height clamped to fontSize/2 minimum.
        let contentHeight = displayList.ascent + displayList.descent
        let usedHeight = max(contentHeight, fontSize / 2)
        let baselineFromBottom = (size.height - usedHeight) / 2 + displayList.descent

        return RenderedMath(
            image: rasterize(label),
            size: size,
            ascent: size.height - baselineFromBottom,
            descent: baselineFromBottom
        )
    }

    /// ラベルは表示リストを CoreGraphics 座標系（y 上向き）で描画し、オンスクリーン補正を
    /// `layer.isGeometryFlipped` に依存する。オフスクリーン描画ではこのフリップが効かないため、
    /// コンテキストを手動でフリップしてラベルの描画メソッドを直接呼び出す。
    @MainActor
    private static func rasterize(_ label: MTMathUILabel) -> MathPlatformImage {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(bounds: label.bounds)
        return renderer.image { rendererContext in
            let context = rendererContext.cgContext
            context.saveGState()
            context.translateBy(x: 0, y: label.bounds.height)
            context.scaleBy(x: 1, y: -1)
            label.draw(label.bounds)
            context.restoreGState()
        }
        #elseif canImport(AppKit)
        let image = NSImage(size: label.bounds.size)
        image.lockFocus()
        label.draw(label.bounds)
        image.unlockFocus()
        return image
        #endif
    }
}
