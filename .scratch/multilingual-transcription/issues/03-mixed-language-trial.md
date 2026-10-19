Type: task
Status: open
Blocked by: 01

# Run Parakeet v3 on real en / ru / de and mixed sessions

## Question

How well does Parakeet v3 actually do on recordings like yours? Gather sample sessions: English-only, Russian-only, German-only, and at least two mixed ones (e.g. ru+en, de+en). Run v3 on them in a throwaway harness, outside the main code. Record the per-language quality, how it handles the switch points, and English quality compared with v2. ## Method

Record the samples through quill itself, without a separate harness:

1. On a throwaway `trial/parakeet-v3` branch (never merged), edit `macos/Sources/quill/Transcription/ParakeetEngine.swift`: `AsrModels.downloadAndLoad(version: .v2)` → `.v3`, and `model` → `"parakeet-tdt-0.6b-v3-coreml"`. Bump FluidAudio in `macos/Package.swift` to ≥ 0.15.6.
2. Build and run quill. The first transcription downloads the v3 model (~483 MB).
3. Menu bar → **Start recording** (⌘R), speak into the mic, then **Stop recording**. quill transcribes the mic track automatically.
4. **Open recordings folder** and read the session's `transcript.json` (`transcribe.log` if it failed).
5. Clips to make: short monolingual en, ru and de; mixed ru+en and de+en, including quick switches that land within ~15 s of each other (the reported failure zone). Optionally, play a real meeting through the speakers to test the system track.

Out of scope here: live/streaming transcription (words appearing while speaking). The trial judges accuracy only.

## Notes

Use FluidAudio ≥ 0.15.6 and pass no German hint (bug in 0.15.5). If v3 drops or anglicises speech at switch points, run the same clips through WhisperKit (with `detectLanguage: true` and with the language forced) for comparison, and measure its speed. HITL: the human supplies (or records) the samples and judges the transcripts.
