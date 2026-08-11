import SwiftUI
@preconcurrency internal import SwiftMath

#if canImport(UIKit)
import UIKit
typealias MathPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias MathPlatformImage = NSImage
#endif

/// A typeset expression together with the metrics needed to place it in a layout.
struct RenderedMath {
    let image: MathPlatformImage
    let size: CGSize
    /// Distance from the baseline up to the top edge of the image.
    let ascent: CGFloat
    /// Distance from the baseline down to the bottom edge of the image. Subtract this from the
    /// image height to align inline math with the baseline of the text around it.
    let descent: CGFloat
}

/// Turns LaTeX source into a rasterized image by way of the typesetting engine.
///
/// The engine (SwiftMath) stays an implementation detail; callers only ever see ``RenderedMath``,
/// so upgrading it does not move the package's public API.
///
/// Implementation note: SwiftMath 1.7.x keeps `MTTypesetter` internal, which leaves `MTMathUILabel`
/// as the only public route to typesetting — its `layoutSubviews()`/`layout()` and `displayList`
/// are public. So a label is used offscreen as a typesetter and then rasterized. It is never
/// attached to a window, but drawing is still bound to the main actor.
enum MathImageRenderer {

    @MainActor
    static func render(
        latex: String,
        mode: MathMode,
        fontFamily: MathFontFamily,
        fontSize: CGFloat,
        color: Color
    ) throws(MathRenderFailure) -> RenderedMath {
        var error: NSError?
        let normalized = MathExpression(latex, mode: mode).normalizedLatex
        guard
            let mathList = MTMathListBuilder.build(fromString: normalized, error: &error),
            error == nil
        else {
            let message = error?.localizedDescription ?? "Unable to parse expression"
            throw MathRenderFailure(reason: .parseFailed(MathParseError(message: message)), source: normalized)
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
            throw MathRenderFailure(reason: .laidOutNothing, source: normalized)
        }
        label.frame = CGRect(origin: .zero, size: size)

        #if canImport(UIKit)
        label.layoutSubviews()
        #else
        label.layout()
        #endif
        // The engine drops its display list only when it has no math list, and one was just set,
        // so this cannot fire. It is the same "nothing to draw" outcome either way.
        guard let displayList = label.displayList else {
            throw MathRenderFailure(reason: .laidOutNothing, source: normalized)
        }

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

    /// The label draws its display list in CoreGraphics coordinates (y up) and relies on
    /// `layer.isGeometryFlipped` to correct that on screen. Offscreen there is no layer to do the
    /// flipping, so the context is flipped by hand and the label's draw method is called directly.
    /// Skipping this renders every expression upside down.
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
