Label: wayfinder:map

# Multilingual transcription (en / ru / de) on macOS

## Destination

A spec, ready to hand off, for quill on macOS transcribing English, Russian and German, including sessions where two of the three are mixed. The spec names the engine/model and says how the language gets chosen: automatic detection if it works well enough on mixed sessions, otherwise an explicit language switch.

## Notes

- Domain: `macos/` only. Engine seam is `TranscriptionEngine` (`macos/Sources/quill/Transcription/TranscriptionEngine.swift`); current engine is `ParakeetEngine` (Parakeet TDT 0.6B v2 via FluidAudio). Config already has `transcription.engine`.
- Main priority: Parakeet TDT 0.6B v3 (believed to cover ru + de). Look at Whisper (WhisperKit large-v3-turbo, the engine the README already plans) only as the comparison or fallback.
- Preference: automatic per-session language handling, including mixed sessions. An explicit switch is the fallback.
- Each track (mic / system) is transcribed separately, then merged, so each track can carry its own language.
- Skills: grilling + domain-modeling for HITL tickets; research for research tickets.

## Decisions so far

- [Parakeet v3 via FluidAudio: languages, API, and mixed-language behaviour](issues/01-parakeet-v3-capabilities.md): ru and de are supported and the swap is one line. No language ID or hint for de vs en; mixed-language windows are a known weak spot.
- [WhisperKit large-v3-turbo as the comparison / fallback engine](issues/02-whisperkit-comparison.md): detects language per 30 s window and can force a language; about 3× the download; speed unmeasured.

## Not yet specified

- **The language switch design (if auto-detect falls short):** where it lives (config, menu bar, CLI flag, per-session or per-track), and its default.
- **Transcript format:** whether `transcript.json` records a language, per segment or per track.
- **Model rollout:** moving from v2 to v3 (or adding Whisper): download size, what `quill doctor` checks, whether v2 stays as the English engine, re-transcribing old sessions.
- **English quality:** whether v3 (or Whisper) is noticeably worse than v2 on English-only meetings, which would argue for keeping v2 for English.

## Out of scope

- Windows and Linux: only macOS matters for this effort.
- Languages other than English, Russian and German.
- Live/streaming transcription while recording: a separate feature. This effort is about post-recording accuracy.
