import AVFoundation
import FluidAudio
import Foundation

/// Parakeet TDT 0.6B v3 (multilingual: English, Russian, German and mixes,
/// handled automatically with no language hint) via FluidAudio's Core ML
/// port. Other v3 languages may work but aren't promised. Models download
/// once into FluidAudio's managed cache (~483 MB); after that, transcription
/// runs entirely on-device.
actor ParakeetEngine: TranscriptionEngine {
    enum EngineError: Error, CustomStringConvertible {
        case notPrepared
        case unreadableAudio(URL, Error?)

        var description: String {
            switch self {
            case .notPrepared: return "parakeet engine used before prepare()"
            case .unreadableAudio(let url, let e):
                return "unreadable or empty audio \(url.lastPathComponent)"
                    + (e.map { ": \($0)" } ?? "")
            }
        }
    }

    nonisolated let name = "parakeet"
    nonisolated let model = "parakeet-tdt-0.6b-v3-coreml"

    /// The FluidAudio model version this engine loads; Doctor checks the same one.
    static let asrVersion: AsrModelVersion = .v3

    /// Silence longer than this between words starts a new segment.
    static let segmentGapSeconds: TimeInterval = 1.0
    /// Hard cap on words per segment so a run-on speaker still wraps.
    static let maxWordsPerSegment = 60

    private var manager: AsrManager?

    func prepare() async throws {
        guard manager == nil else { return }
        let models = try await AsrModels.downloadAndLoad(version: Self.asrVersion)
        let manager = AsrManager()
        try await manager.loadModels(models)
        self.manager = manager
    }

    func transcribe(_ audio: URL) async throws -> [TranscriptSegment] {
        guard let manager else { throw EngineError.notPrepared }

        // A track with no frames (recorder died before its first buffer)
        // makes AVFoundation raise an ObjC exception deep inside the
        // resampler — uncatchable from Swift, so it takes the whole daemon
        // down. Check readability up front instead.
        do {
            let probe = try AVAudioFile(forReading: audio)
            guard probe.length > 0 else { throw EngineError.unreadableAudio(audio, nil) }
        } catch let error as EngineError {
            throw error
        } catch {
            throw EngineError.unreadableAudio(audio, error)
        }

        var state = try TdtDecoderState()
        let result = try await manager.transcribe(audio, decoderState: &state)

        let words = buildWordTimings(from: result.tokenTimings ?? [])
        guard !words.isEmpty else {
            let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty
                ? []
                : [TranscriptSegment(start: 0, end: result.duration, text: text)]
        }
        return Self.segments(from: words)
    }

    func release() async {
        if let manager { await manager.cleanup() }
        manager = nil
    }

    /// Group word timings into readable segments: break on sentence-ending
    /// punctuation (parakeet v3 emits punctuation), a silence gap, or a hard
    /// length cap so a run-on speaker still wraps.
    /// Internal (not private) so unit tests can exercise it.
    static func segments(from words: [WordTiming]) -> [TranscriptSegment] {
        var out: [TranscriptSegment] = []
        var current: [WordTiming] = []

        func flush() {
            guard let first = current.first, let last = current.last else { return }
            out.append(
                TranscriptSegment(
                    start: first.startTime,
                    end: last.endTime,
                    text: current.map(\.word).joined(separator: " ")
                ))
            current = []
        }

        for word in words {
            if let last = current.last, word.startTime - last.endTime > segmentGapSeconds {
                flush()
            }
            current.append(word)
            let endsSentence =
                word.word.hasSuffix(".")
                || word.word.hasSuffix("?")
                || word.word.hasSuffix("!")
            if endsSentence || current.count >= maxWordsPerSegment {
                flush()
            }
        }
        flush()
        return out
    }
}
