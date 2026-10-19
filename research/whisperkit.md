# WhisperKit large-v3-turbo as comparison / fallback engine

Answers `.scratch/multilingual-transcription/issues/02-whisperkit-comparison.md`.
Researched 2026-10-19.

Sources pinned:
- [WK] argmaxinc/WhisperKit `main` @ `9f99b5cb6a907730543823ad271b82532782a899` (2026-10-10); latest tag `v1.1.1`. https://github.com/argmaxinc/WhisperKit
- [OW] openai/whisper @ `86098128c0b4f24f0e2aa2994de830614b474227`. https://github.com/openai/whisper
- [MC] HF model card `openai/whisper-large-v3-turbo`. https://huggingface.co/openai/whisper-large-v3-turbo
- [HF] HF tree `argmaxinc/whisperkit-coreml`. https://huggingface.co/argmaxinc/whisperkit-coreml
- [WKP] WhisperKit paper, arXiv:2507.10860 (ICML 2025 workshop).

## 1. Language detection: per file or per 30 s window? Does it follow a switch?

**WhisperKit detects per 30 s window, not per file** (verified in source).

- `TranscribeTask` loops over the audio in windows (`while seek < seekClipEnd - windowPadding`, [WK] `Sources/WhisperKit/Core/TranscribeTask.swift:116`) and calls `decodeWithFallback(... decodingOptions: options ...)` for each window (`:167`).
- Inside `decodeWithFallback`, if the model is multilingual, `options.language == nil` and `options.detectLanguage` is true, it runs `textDecoder.detectLanguage` on *that window's encoder output* and re-prefills the decoder prompt with the result (`:340-358`). The detected language is written into a local copy (`currentDecodingOptions`), never back into `options`, so the next window detects again.
- `detectLanguage` defaults to `!usePrefillPrompt` ([WK] `Core/Configurations.swift:229`); `usePrefillPrompt` defaults to `true`, so **you must pass `detectLanguage: true` explicitly** (or `usePrefillPrompt: false`, in which case the model predicts the language token itself during decoding — `:375-378`).
- With `chunkingStrategy: .vad` ([WK] `Core/Models.swift:342`), long audio is split at VAD boundaries into ≤30 s chunks that are transcribed independently (`Core/WhisperKit.swift:1044-1066`), each with its own detection.

So **it can follow a language change, at 30 s-window (or VAD-chunk) granularity**. Caveats:
- A window containing two languages gets one language token; the minority language will be transcribed under the wrong token (often translated/transliterated). Inference from how Whisper's prompt format works (one `<|lang|>` token per decode; [OW] paper §2.3) — not tested.
- **The result does not expose per-window language.** `TranscriptionResult.language` is a single `String` ([WK] `Core/Models.swift:546`) and the inout `detectedLanguage` is overwritten each window, so it ends up as the *last* window's language. `TranscriptionSegment` has no language field (`Models.swift:575-586`). To record per-segment language you would need VAD chunking + per-chunk results, or call `WhisperKit.detectLanguage(audioArray:)` (`Core/WhisperKit.swift:549`) yourself per chunk.
- Contrast: reference openai/whisper **locks to one language per file**: it detects "using up to the first 30 seconds" and reuses it for the whole file ([OW] `whisper/transcribe.py:149-152`). WhisperKit's per-window behavior differs from upstream.

## 2. Can language be forced (en / ru / de)?

**Yes.** `DecodingOptions(language: "ru")` with the default `usePrefillPrompt: true` forces the `<|ru|>` prefill token ([WK] `Configurations.swift:144,165,200`; README server table "`language` | Source language code | Auto-detect", README:313). Detection is skipped when `language != nil` (`TranscribeTask.swift:341`). Also set `task: .transcribe` (default, `Configurations.swift:193`).

## 3. Speed, size, fit to `TranscriptionEngine`

- **Model**: large-v3-turbo = large-v3 with decoder pruned 32→4 layers, 809 M params ([MC]). WhisperKit README recommends `large-v3-v20240930_turbo` "on macOS for maximum speed and accuracy" (README:193).
- **Download size** (CoreML, [HF] API sum of files): `openai_whisper-large-v3-v20240930_turbo` ≈ **1.64 GB**; compressed variant `..._turbo_632MB` ≈ 632 MB.
- **Speed per hour on Apple Silicon: UNVERIFIED.** No first-party per-hour figure for M-series found in README/model card. Indirect data: OpenAI lists turbo at ~8× large speed ([OW] README:71); HF Open ASR leaderboard RTFx 200 for turbo on GPU ([MC], not Apple Silicon). [WKP] reports streaming latency (0.46 s) and 2.2 % WER, not batch throughput. Argmax publishes per-device numbers in the `argmaxinc/whisperkit-benchmarks` HF Space (not checked). **Measure on target hardware** (e.g. `whisperkit-cli transcribe --model large-v3-v20240930_turbo` on a 1 h file).
- **Protocol fit**: good. `transcribe(audioPath:decodeOptions:) -> [TranscriptionResult]`; each `TranscriptionSegment` has `start`/`end` (Float seconds, file-relative), `text`, plus `avgLogprob`, `compressionRatio`, `noSpeechProb`, optional `words` ([WK] `Models.swift:575-586`) → map directly to `TranscriptSegment(start:end:text:)`. Note `text` may contain special tokens unless `skipSpecialTokens: true` (`Configurations.swift:146`). `prepare()` = `WhisperKit(...)` init/model download; `release()` = drop the instance (unloadModels exists — not verified in detail).

## 4. Known failure modes for ru / de

- **Translating instead of transcribing**: turbo "is not trained for translation tasks" and "will return the original language even if `--task translate` is specified" ([OW] README:88,102) — so turbo is *less* prone to accidental English translation than large-v3. Remaining risk: wrong detected language (e.g. de window detected as en) → output in the wrong language. Forcing `language` eliminates this for monolingual files.
- **Hallucinations on silence / repetition**: model card states predictions "may include texts that are not actually spoken" and the model is "prone to generating repetitive texts", worse for lower-resource languages ([MC] "Performance and Limitations"). WhisperKit mitigations, all on by default: `compressionRatioThreshold 2.4`, `logProbThreshold -1.0`, `noSpeechThreshold 0.6`, temperature fallback ([WK] `Configurations.swift:157-161,213-216`). `chunkingStrategy: .vad` additionally avoids feeding long silence to the model. Specific ru/de hallucination rates: **unverified** (no primary source found); ru and de are both high-resource in Whisper training data ([OW] paper Appendix), so expect better than average.

## Bottom line

WhisperKit-turbo is a viable fallback: forceable language, per-30 s-window auto-detection (so it can follow switches coarsely, unlike upstream Whisper), segment timestamps that map 1:1 onto `TranscriptSegment`, ~0.6-1.6 GB model. Gaps: no per-segment language in the result, intra-window code-switching not handled, Apple Silicon throughput must be measured.
