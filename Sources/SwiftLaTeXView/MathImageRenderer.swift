import SwiftUI
@preconcurrency internal import SwiftMath

#if canImport(UIKit)
import UIKit
typealias MathPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias MathPlatformImage = NSImage
#endif

/// A typeset math expression with the metrics needed for layout.
struct RenderedMath {
    let image: MathPlatformImage
    let size: CGSize
    /// Distance from the baseline to the top of the image.
    let ascent: CGFloat
    /// Distance from the baseline to the bottom of the image.
    /// Used to align inline math with surrounding text baselines.
    let descent: CGFloat
}

/// Bridges LaTeX source to a rasterized image via the typesetting engine.
///
/// The engine (SwiftMath) stays an implementation detail: callers see
/// only ``RenderedMath``.
///
/// Implementation note: SwiftMath 1.7.x keeps `MTTypesetter` internal,
/// so the only public typesetting route is `MTMathUILabel`, whose
/// `layoutSubviews()`/`layout()` and `displayList` are public. The label
/// is used off-screen as a typesetter and rasterized; it is never
/// attached to a window. This makes rendering main-actor bound.
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
        guard
            let mathList = MTMathListBuilder.build(fromString: latex, error: &error),
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

    /// The label draws its display list in CoreGraphics coordinates (y-up)
    /// and relies on `layer.isGeometryFlipped` for on-screen correction —
    /// which offscreen rendering ignores. Flip the context manually and
    /// invoke the label's draw method directly.
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
