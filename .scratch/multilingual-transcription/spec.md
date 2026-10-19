Label: ready-for-agent

# Spec: Multilingual transcription (en / ru / de) on macOS via Parakeet v3

Charted by the map: [Multilingual transcription (en / ru / de) on macOS](map.md).

## Problem Statement

quill on macOS transcribes English only. The current engine, Parakeet TDT 0.6B v2, is an English model. When I record a session in Russian or German, or a session that mixes two or three of English, Russian and German, the transcript comes out as garbage or as phonetic English. I can't rely on quill for a large share of my meetings.

## Solution

Swap the transcription engine to Parakeet TDT 0.6B v3 via FluidAudio. v3 officially supports English, Russian and German and handles language automatically. There is nothing to choose, configure or switch. In a trial, a mixed en/de/ru session transcribed well with no hint. From my side, quill behaves exactly as before: record, stop, and get `transcript.json` / `transcript.md`. They now contain correct Russian and German text alongside English.

v3 replaces v2 outright. `transcription.engine: "parakeet"` now means v3. On the first transcription after upgrading, quill downloads the v3 model (~483 MB) once. `quill doctor` reports whether it's cached.

## User Stories

1. As a quill user, I want Russian speech transcribed in Cyrillic, so that my Russian meetings produce usable transcripts.
2. As a quill user, I want German speech transcribed correctly, including umlauts and ß, so that my German meetings produce usable transcripts.
3. As a quill user, I want English transcription to keep working, so that the upgrade doesn't cost me my existing main use case.
4. As a quill user, I want a session that mixes English with Russian or German transcribed without any setting, so that I don't have to predict which language a meeting will be in.
5. As a quill user, I want a session that mixes all three languages transcribed in one pass, so that multilingual meetings work too.
6. As a quill user, I want my mic track and the system track each handled independently, so that I can speak one language while the remote side speaks another.
7. As a quill user, I want no language menu, config key or CLI flag to manage, so that recording stays one action.
8. As a quill user, I want to accept that a very fast switch between languages may garble a second or two, so that I know the known limitation up front.
9. As a quill user, I want my existing config with `"engine": "parakeet"` to keep working unchanged, so that the upgrade needs no edits from me.
10. As a quill user, I want an unknown engine value to still fall back to parakeet with a warning, as today, so that a typo doesn't break transcription.
11. As a quill user, I want the v3 model downloaded automatically on the first transcription after upgrading, so that I don't run a separate install step.
12. As a quill user, I want a failed model download logged to the session's `transcribe.log` and retried on the next launch, as today, so that a network blip doesn't lose a session.
13. As a quill user, I want `quill doctor` to warn "parakeet v3 models not downloaded (~483 MB)" when the v3 cache is missing, so that I can pre-fetch before an important meeting.
14. As a quill user, I want `quill doctor` to stop checking the old v2 cache, so that its result reflects the model actually used.
15. As a quill user, I want `transcript.json` to record the v3 model id in its existing `model` field, so that I can tell v3 transcripts from older v2 ones.
16. As a quill user, I want my old v2 transcripts left untouched, so that the upgrade never rewrites history behind my back.
17. As a quill user, I want old sessions not re-transcribed automatically, so that the upgrade doesn't trigger a long background job.
18. As a quill user, I want pending sessions (with `meta.json` but no `transcript.json`) transcribed with v3 on the next launch, so that the queue keeps working across the upgrade.
19. As a quill user, I want the release notes to tell me where the old v2 cache (~600 MB) lives and that it's safe to delete, so that I can reclaim disk space myself.
20. As a quill user, I want the README to describe v3, its ~483 MB size and en/ru/de automatic handling, so that the docs match the app.
21. As a quill user, I want the README to stop promising a WhisperKit fallback, so that the docs don't advertise a plan that was dropped.
22. As a quill user, I want the `transcript.json` schema unchanged, with no language field, so that anything reading it keeps working.
23. As a quill user, I want `transcript.md` to look the same apart from the model name in its header, so that my reading habits don't change.
24. As a quill user, I want segments broken at sentence ends, silences and a length cap in Russian and German just as in English, so that non-English transcripts are just as readable.
25. As a quill developer, I want the engine swap to stay behind the existing `TranscriptionEngine` protocol, so that the coordinator, merge and writing code don't change.
26. As a quill developer, I want the segmentation logic unit-tested with Cyrillic and German input, so that regressions in grouping are caught without downloading a model.
27. As a quill developer, I want v2 code paths removed rather than kept selectable, so that there's one engine to maintain. Reverting in git is the escape hatch.

## Implementation Decisions

- **Engine: `ParakeetEngine` moves to v3.** It loads FluidAudio's `.v3` ASR models and reports model id `parakeet-tdt-0.6b-v3-coreml`. `name` stays `"parakeet"`. v2 loading code is removed, not kept as an option. Update the type's doc comment: v3, multilingual en/ru/de (plus other v3 languages, which aren't promised), ~483 MB.
- **Dependency:** raise the FluidAudio minimum version to ≥ 0.15.6, the first release with v3. The trial ran 0.17.7, which is a safe pin floor if the newer API is needed.
- **Language handling: none in quill.** There's no language hint, detection step, config key, menu or CLI flag. v3 handles language implicitly per audio window. Each track (mic / system) is still transcribed separately and merged by timestamp, unchanged.
- **Config:** `transcription.engine` keeps the single valid value `"parakeet"`, which now means v3. The unknown-value warning and fallback are unchanged, and there's no new key.
- **Schema: no change.** `transcript.json` keeps `engine`, `model`, `created_at`, and `segments[{speaker, start_ms, end_ms, text}]`. The `model` value distinguishes v2 from v3 transcripts. No language field at any granularity. Adding one later would be non-breaking. `transcript.md` is unchanged apart from the model name in its header.
- **Segmentation:** the existing grouping of word timings into segments is kept as is. It breaks on `.`, `?` or `!`, on a gap over 1 s, or at 60 words. v3 also emits punctuation. Make the grouping function internal (not private) so it can be unit-tested, following the precedent of `Transcript.shifted`.
- **First run:** today's behaviour is unchanged. The model downloads lazily on the first `prepare()`. A failure is written to `transcribe.log`, and the session stays pending and retries on the next launch. No progress UI, warm-up download or automatic retry.
- **Old sessions:** never re-transcribed and no new command. Deleting a session's `transcript.json` still re-queues it, but stays undocumented.
- **v2 cache:** left on disk, with no automatic cleanup. The release notes give its location and say it's safe to delete.
- **`quill doctor`:** the transcription check points at the v3 cache. Its warning reads "parakeet v3 models not downloaded (~483 MB)". It stays a warning, with no load check.
- **Docs:** the README model section moves to v3, ~483 MB, en/ru/de with automatic handling, and the known fast-switch limitation. Remove the "Whisper engine (WhisperKit large-v3-turbo) planned as the fallback" line. Release notes cover the download, the v2 cache, and the fact that old transcripts are untouched.

## Testing Decisions

- Good tests check external behaviour at the highest seam available: inputs in, observable output out. They don't assert internal calls or state.
- **Automated (new):** unit tests for the segmentation function. Feed word timings and assert the resulting segments' text, start and end. Cases:
  - Cyrillic words joined correctly.
  - German words with umlauts and ß preserved.
  - A break after sentence-ending punctuation.
  - A break on a silence gap over 1 s.
  - A break at the 60-word cap.
  - A mixed-language run (Latin then Cyrillic) that stays in one segment when there's no break condition.
  - Empty input producing no segments.
- **Prior art:** the existing transcription coordinator tests (offset shifting, merge interleaving, rendered header) are pure-function XCTest cases over the `Transcript` types. Follow the same style.
- **Not automated:** the real model. Running v3 needs the ~483 MB download, so no unit or CI test exercises it. The `TranscriptionEngine` protocol seam is verified by hand instead.
- **Manual acceptance (before merge):** record through quill itself, using the mixed-language trial method, then read each session's `transcript.json`. The required set is:
  - one English-only session, compared by eye with a v2 transcript of similar speech;
  - one Russian-only session;
  - one German-only session;
  - one mixed session (two or three of the languages);
  - one session where the system track carries a different language from the mic.

  Confirm that `model` reads `parakeet-tdt-0.6b-v3-coreml`. Also run `quill doctor` before and after the first download.
- **Doctor:** no new test. The message change is verified during manual acceptance.

## Out of Scope

- Windows and Linux.
- Languages other than English, Russian and German. v3 may handle them, but they aren't promised or tested.
- Live/streaming transcription while recording.
- An explicit language switch in any form: menu, config, CLI or per track.
- WhisperKit, or any second engine, including keeping v2 selectable.
- A language field in `transcript.json` / `transcript.md`, and any language detection.
- Re-transcribing old sessions, or a command to do so.
- Automatic cleanup of the v2 model cache.
- Download progress UI or pre-download (warm-up).

## Further Notes

- Known limitation (accepted): an instant switch from one language to another, e.g. English to Russian, can garble about 1–2 s around the switch point.
- The trial didn't cover monolingual clips, the system track, or English on v3 compared with v2. LibriSpeech gives v3 2.5 vs v2 2.1 WER. Manual acceptance covers these. If English quality on v3 is clearly worse, revert in git and reopen the map. There's no in-app fallback.
- Decision trail: see the map's Decisions so far. Each decision's detail lives in its ticket.
