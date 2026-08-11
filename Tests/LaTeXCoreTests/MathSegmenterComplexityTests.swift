import Foundation
import Testing
@testable import LaTeXCore

/// Shared measurement for catching a complexity regression.
///
/// The judgement is made on **how much the time grows when the input is quadrupled**, not on an
/// absolute duration, so it does not depend on the machine. Linear growth lands near 4×,
/// quadratic near 16×, and a ceiling of 8 separates the two with room to spare. (Comparing at 2×
/// would put linear at 2.0 and quadratic at 4.0 — close enough that load noise misfires.)
///
/// Each measurement takes the **minimum** of several trials, the usual way to strip interference
/// out of a microbenchmark. Inputs are built before the clock starts: `String.count` counts
/// grapheme clusters one at a time, so growing a string until it is long enough is itself
/// quadratic and would swamp what is being measured.
enum ComplexityProbe {

    /// The seconds this thread actually spent on the CPU.
    ///
    /// A wall clock also counts the time other tests took the CPU away, which measures how busy
    /// the run was rather than how much work the code did — a bound that passes on its own and
    /// fails in a full suite. Thread CPU time is what a complexity check wants.
    static func threadSeconds() -> Double {
        Double(clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID)) / 1_000_000_000
    }

    static func bestSeconds(trials: Int = 5, _ body: () -> Void) -> Double {
        var best = Double.greatestFiniteMagnitude
        for _ in 0..<trials {
            let start = threadSeconds()
            body()
            best = Swift.min(best, threadSeconds() - start)
        }
        return best
    }

    /// How much the time grows when the input is quadrupled.
    static func growthOver4x<Input>(
        base: Int,
        make: (Int) -> Input,
        run: @escaping (Input) -> Void
    ) -> Double {
        let small = make(base)
        let large = make(base * 4)
        _ = bestSeconds(trials: 2) { run(small) }   // warm up
        let smallSeconds = bestSeconds { run(small) }
        let largeSeconds = bestSeconds { run(large) }
        return largeSeconds / Swift.max(smallSeconds, .leastNonzeroMagnitude)
    }

    /// The ceiling for calling growth linear. Linear ≒ 4.0, quadratic ≒ 16.0.
    static let linearCeiling = 8.0
}

/// Segmentation has to stay linear in the length of the input.
///
/// `MathSegmenter.segments(in:)` is the live-preview path: it runs synchronously on the main
/// actor over the whole accumulated response for every token a model streams. Growth that is
/// quadratic in the document length does not read as "slow" — it reads as a frozen UI, so it is
/// a defect in behaviour rather than in performance.
@Suite("Segmentation runs in linear time")
struct MathSegmenterComplexityTests {

    private static let segmenter = MathSegmenter()

    /// Prose carrying openers that never get their closer — a model that opened `\(` and then
    /// wandered off, or closed with the wrong delimiter. Every such opener used to rescan the
    /// whole remaining document.
    private static func text(_ unit: String, length: Int) -> String {
        String(String(repeating: unit, count: length / unit.count + 1).prefix(length))
    }

    @Test(#"Unmatched \( openers stay linear"#)
    func unmatchedParenStaysLinear() {
        let ratio = ComplexityProbe.growthOver4x(base: 4_000) {
            Self.text(#"Let \(x_i be the value. "#, length: $0)
        } run: {
            _ = Self.segmenter.segments(in: $0)
        }
        #expect(ratio < ComplexityProbe.linearCeiling, "4× the length took \(ratio)× the time (linear is about 4.0)")
    }

    @Test(#"Unmatched \[ openers stay linear"#)
    func unmatchedBracketStaysLinear() {
        let ratio = ComplexityProbe.growthOver4x(base: 4_000) {
            Self.text(#"Consider \[ E = mc^2 and more prose. "#, length: $0)
        } run: {
            _ = Self.segmenter.segments(in: $0)
        }
        #expect(ratio < ComplexityProbe.linearCeiling, "4× the length took \(ratio)× the time (linear is about 4.0)")
    }

    @Test("Openers closed by the wrong delimiter stay linear")
    func mismatchedDelimitersStayLinear() {
        let ratio = ComplexityProbe.growthOver4x(base: 4_000) {
            Self.text(#"The term \(a+b$ appears often here. "#, length: $0)
        } run: {
            _ = Self.segmenter.segments(in: $0)
        }
        #expect(ratio < ComplexityProbe.linearCeiling, "4× the length took \(ratio)× the time (linear is about 4.0)")
    }

    @Test("A long response full of unmatched openers finishes promptly")
    func largeDocumentFinishesQuickly() {
        // Before the fix this took 0.90 s in a debug build for 32k characters — on the main
        // actor, once per streamed token. 0.1 s leaves ample room.
        let source = Self.text(#"Let \(x_i be the value. "#, length: 32_000)
        let elapsed = ComplexityProbe.bestSeconds(trials: 3) { _ = Self.segmenter.segments(in: source) }
        #expect(elapsed < 0.1, "32k characters of unmatched openers took \(elapsed) s")
    }
}
