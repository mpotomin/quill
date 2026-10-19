Type: research
Status: resolved
Blocked by:

# WhisperKit large-v3-turbo as the comparison / fallback engine

## Question

Where would WhisperKit (large-v3-turbo) stand if Parakeet v3 isn't good enough?
- Language detection: per file or per 30 s window? Can it follow a language change within a recording, or does it lock onto one language?
- Can the language be forced (en / ru / de)?
- Speed per hour of audio on Apple Silicon, model size, and how it would fit the `TranscriptionEngine` protocol (timestamps, segments).
- Known failure modes for ru / de: translating instead of transcribing, hallucinations on silence.

## Answer

Full findings: branch `research/whisperkit`, file `research/whisperkit.md`.
- WhisperKit detects language again every 30 s window (or per VAD chunk), but only when `detectLanguage: true` is set. It reports one language per file. Getting language per segment needs VAD chunks plus our own detection call on each.
- Forcing a language works (`DecodingOptions(language:)`). Translating instead of transcribing is low risk for turbo.
- About 1.64 GB download (about 632 MB compressed). Speed on Apple Silicon is unverified and needs measuring. Fits `TranscriptionEngine` cleanly.
