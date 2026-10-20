import FluidAudio
import XCTest

@testable import quill

/// Grouping of word timings into readable transcript segments, for
/// multilingual input. Runs without a model download.
final class ParakeetSegmentationTests: XCTestCase {
    private func w(_ word: String, _ start: TimeInterval, _ end: TimeInterval) -> WordTiming {
        WordTiming(word: word, startTime: start, endTime: end)
    }

    func testCyrillicWordsJoinIntoOneSegment() {
        let segments = ParakeetEngine.segments(from: [
            w("Привет,", 0.0, 0.4),
            w("как", 0.5, 0.7),
            w("дела?", 0.8, 1.2),
        ])
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments.first?.text, "Привет, как дела?")
        XCTAssertEqual(segments.first?.start, 0.0)
        XCTAssertEqual(segments.first?.end, 1.2)
    }

    func testGermanUmlautsAndEszettArePreservedVerbatim() {
        let segments = ParakeetEngine.segments(from: [
            w("Grüße", 0.0, 0.3),
            w("aus", 0.4, 0.5),
            w("Köln,", 0.6, 0.9),
            w("schöne", 1.0, 1.3),
            w("Straße", 1.4, 1.8),
        ])
        XCTAssertEqual(segments.map(\.text), ["Grüße aus Köln, schöne Straße"])
    }

    func testBreaksAfterSentenceEndingPunctuation() {
        let segments = ParakeetEngine.segments(from: [
            w("Das", 0.0, 0.2), w("stimmt.", 0.3, 0.6),
            w("Wirklich?", 0.7, 1.0),
            w("Ja!", 1.1, 1.3),
            w("Gut", 1.4, 1.6),
        ])
        XCTAssertEqual(segments.map(\.text), ["Das stimmt.", "Wirklich?", "Ja!", "Gut"])
        XCTAssertEqual(segments.map(\.start), [0.0, 0.7, 1.1, 1.4])
        XCTAssertEqual(segments.map(\.end), [0.6, 1.0, 1.3, 1.6])
    }

    func testBreaksOnSilenceGapOverOneSecond() {
        let segments = ParakeetEngine.segments(from: [
            w("один", 0.0, 0.5),
            w("два", 1.5, 1.8),  // 1.0 s gap: no break
            w("три", 2.9, 3.2),  // 1.1 s gap: break
        ])
        XCTAssertEqual(segments.map(\.text), ["один два", "три"])
        XCTAssertEqual(segments.map(\.start), [0.0, 2.9])
        XCTAssertEqual(segments.map(\.end), [1.8, 3.2])
    }

    func testBreaksAtSixtyWordCap() {
        let words = (0..<61).map { i in w("слово", Double(i) * 0.5, Double(i) * 0.5 + 0.3) }
        let segments = ParakeetEngine.segments(from: words)
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].text.split(separator: " ").count, 60)
        XCTAssertEqual(segments[0].end, 29.8)
        XCTAssertEqual(segments[1].text, "слово")
        XCTAssertEqual(segments[1].start, 30.0)
    }

    func testLatinThenCyrillicWithoutBreakStaysInOneSegment() {
        let segments = ParakeetEngine.segments(from: [
            w("meeting", 0.0, 0.4),
            w("about", 0.5, 0.7),
            w("бюджет", 0.8, 1.2),
            w("проекта", 1.3, 1.7),
        ])
        XCTAssertEqual(segments.map(\.text), ["meeting about бюджет проекта"])
        XCTAssertEqual(segments.first?.start, 0.0)
        XCTAssertEqual(segments.first?.end, 1.7)
    }

    func testEmptyInputProducesNoSegments() {
        XCTAssertTrue(ParakeetEngine.segments(from: []).isEmpty)
    }
}
