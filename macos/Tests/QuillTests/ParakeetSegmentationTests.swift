import FluidAudio
import XCTest

@testable import quill

/// Grouping of word timings into readable transcript segments, for
/// multilingual input. Runs without a model download.
final class ParakeetSegmentationTests: XCTestCase {
    private func word(_ word: String, _ start: TimeInterval, _ end: TimeInterval) -> WordTiming {
        WordTiming(word: word, startTime: start, endTime: end)
    }

    func testCyrillicWordsJoinIntoOneSegment() {
        let segments = ParakeetEngine.segments(from: [
            word("Привет,", 0.0, 0.4),
            word("как", 0.5, 0.7),
            word("дела?", 0.8, 1.2),
        ])
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments.first?.text, "Привет, как дела?")
        XCTAssertEqual(segments.first?.start, 0.0)
        XCTAssertEqual(segments.first?.end, 1.2)
    }

    func testGermanUmlautsAndEszettArePreservedVerbatim() {
        let segments = ParakeetEngine.segments(from: [
            word("Grüße", 0.0, 0.3),
            word("aus", 0.4, 0.5),
            word("Köln,", 0.6, 0.9),
            word("schöne", 1.0, 1.3),
            word("Straße", 1.4, 1.8),
        ])
        XCTAssertEqual(segments.map(\.text), ["Grüße aus Köln, schöne Straße"])
    }

    func testBreaksAfterSentenceEndingPunctuation() {
        let segments = ParakeetEngine.segments(from: [
            word("Das", 0.0, 0.2), word("stimmt.", 0.3, 0.6),
            word("Wirklich?", 0.7, 1.0),
            word("Ja!", 1.1, 1.3),
            word("Gut", 1.4, 1.6),
        ])
        XCTAssertEqual(segments.map(\.text), ["Das stimmt.", "Wirklich?", "Ja!", "Gut"])
        XCTAssertEqual(segments.map(\.start), [0.0, 0.7, 1.1, 1.4])
        XCTAssertEqual(segments.map(\.end), [0.6, 1.0, 1.3, 1.6])
    }

    func testBreaksOnSilenceGapOverOneSecond() {
        let segments = ParakeetEngine.segments(from: [
            word("один", 0.0, 0.5),
            word("два", 1.5, 1.8),  // 1.0 s gap: no break
            word("три", 2.9, 3.2),  // 1.1 s gap: break
        ])
        XCTAssertEqual(segments.map(\.text), ["один два", "три"])
        XCTAssertEqual(segments.map(\.start), [0.0, 2.9])
        XCTAssertEqual(segments.map(\.end), [1.8, 3.2])
    }

    func testBreaksAtSixtyWordCap() {
        let words = (0..<61).map { i in word("слово", Double(i) * 0.5, Double(i) * 0.5 + 0.3) }
        let segments = ParakeetEngine.segments(from: words)
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].text.split(separator: " ").count, 60)
        XCTAssertEqual(segments[0].end, 29.8)
        XCTAssertEqual(segments[1].text, "слово")
        XCTAssertEqual(segments[1].start, 30.0)
    }

    func testLatinThenCyrillicWithoutBreakStaysInOneSegment() {
        let segments = ParakeetEngine.segments(from: [
            word("meeting", 0.0, 0.4),
            word("about", 0.5, 0.7),
            word("бюджет", 0.8, 1.2),
            word("проекта", 1.3, 1.7),
        ])
        XCTAssertEqual(segments.map(\.text), ["meeting about бюджет проекта"])
        XCTAssertEqual(segments.first?.start, 0.0)
        XCTAssertEqual(segments.first?.end, 1.7)
    }

    func testEmptyInputProducesNoSegments() {
        XCTAssertTrue(ParakeetEngine.segments(from: []).isEmpty)
    }
}
