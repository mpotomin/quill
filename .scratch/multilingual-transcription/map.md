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
- [Run Parakeet v3 on real en / ru / de and mixed sessions](issues/03-mixed-language-trial.md): one mixed en/de/ru clip transcribed well with no hint, and the user is happy. Only the instant switch from English to Russian garbled about 1–2 s. Monolingual clips, the system track and English vs v2 were not tested.
- [Automatic detection or an explicit language switch?](issues/04-auto-detect-or-switch.md): Parakeet v3 with automatic handling is the only mode, with no hint and no switch. Fast-switch loss is an accepted limitation. Whisper is considered but not chosen.
- [Rolling out v3: replace v2, download, doctor, old sessions](issues/05-v2-to-v3-rollout.md): v3 replaces v2 outright and `"parakeet"` now means v3. Old sessions are not re-transcribed, the v2 cache is left on disk, doctor checks the v3 cache, and the README drops the Whisper plan.

## Not yet specified

_(none)_

## Out of scope

- Windows and Linux: only macOS matters for this effort.
- Languages other than English, Russian and German.
- Live/streaming transcription while recording: a separate feature. This effort is about post-recording accuracy.
- An explicit language switch (menu, config, CLI, per track): auto-detect was judged good enough. See [Automatic detection or an explicit language switch?](issues/04-auto-detect-or-switch.md).
- WhisperKit as a second engine: considered but not chosen. See the same ticket.
