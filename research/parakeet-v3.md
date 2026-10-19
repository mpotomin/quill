# Parakeet TDT 0.6B v3 via FluidAudio: languages, API, mixed-language behaviour

Resolves `.scratch/multilingual-transcription/issues/01-parakeet-v3-capabilities.md`.
Researched 2026-10-19. Quill pins FluidAudio `from: "0.7.0"`, resolved to **0.15.5**
(`19600a48`, `macos/Package.resolved`); latest tag is **v0.17.7** (2026-10-07).

Sources (abbreviated below):
- **[NV]** NVIDIA model card — https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3
- **[FI-HF]** FluidInference CoreML card — https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml
- **[FA]** FluidAudio source at tag v0.15.5 — https://github.com/FluidInference/FluidAudio/tree/v0.15.5
- **[BENCH]** `Documentation/Benchmarks.md` (FluidAudio, same tag)
- **[TLF]** `Documentation/ASR/TokenLanguageFilter.md`
- GitHub issues/PRs on FluidInference/FluidAudio: #512, #594, #630, #840, #842, #847, #850

## 1. Russian and German support

**Yes, both official.** NVIDIA lists 25 European languages incl. German (de) and
Russian (ru), plus English and Ukrainian [NV, "Supported Languages"]. The FluidInference
CoreML port is the same model, "25 European languages" [FI-HF]. FluidAudio docs: "Parakeet
TDT v3 | Batch speech-to-text, 25 European languages (0.6B params). Default ASR model."
[FA `Documentation/Models.md`].

## 2. FluidAudio version and API differences vs our v2 path

- **v3 has shipped since v0.4.0** (commit `6ef85af4`, 2025-08-25, "nvidia/parakeet-tdt-0.6b-v3 (#77)").
  It is already available in our pinned 0.15.5 — no dependency bump required to switch.
  `AsrModelVersion` has `.v2`, `.v3`, `.tdtCtc110m`, `.tdtJa`
  [FA `ASR/Parakeet/SlidingWindow/TDT/AsrModels.swift:5`]. `.v3` is the **default** for
  `downloadAndLoad`, `load`, `defaultCacheDirectory` (same file, lines 590–593, 683).
- **Loading:** identical call shape — `AsrModels.downloadAndLoad(version: .v3)` instead of
  `.v2` (our `ParakeetEngine.swift:31`). `AsrManager` / `TdtDecoderState` / `transcribe(url,
  decoderState:)` unchanged. v3 loads `JointDecisionv3.mlmodelc` (joint exposing top-K
  ids/logits for language filtering) instead of `JointDecision.mlmodelc`, and accepts
  `encoderPrecision: .int8` (default, `Encoder.mlmodelc`) or `.int4` (`EncoderInt4.mlmodelc`)
  [FA `ModelNames.swift` `requiredModelsV3`, `ParakeetEncoderPrecision`].
- **New optional parameter:** `transcribe(_:decoderState:language: Language? = nil)` —
  "Optional language hint for script-aware token filtering (v3 only)… Silently ignored for
  v2" [FA `AsrManager.swift` ~L345–380]. Additive; existing call compiles unchanged.
- **Cache location:** `~/Library/Application Support/FluidAudio/Models/<repo folder>`
  [FA `Shared/MLModelConfigurationUtils.swift:37`], i.e. `.../parakeet-tdt-0.6b-v3-coreml`
  next to the existing `.../parakeet-tdt-0.6b-v2-coreml`. Separate download; v2 cache is not reused.
- **Size (HF treesize API, files FluidAudio fetches):** v3 ≈ Encoder 446.2 MB + Decoder 23.6 MB
  + JointDecisionv3 12.7 MB + Preprocessor 0.5 MB + vocab 0.15 MB ≈ **~483 MB**.
  v2 ≈ 446.2 + 14.4 + 3.5 + 0.3 ≈ **~465 MB**. (Whole HF repos are 3.6 GB / 2.6 GB because
  they hold alternative variants that FluidAudio does not download.) Exact on-disk size after
  CoreML compile: *unverified*.
- **Behavioural flags relevant to v3:** `ASRConfig.melChunkContext` (default `true`) and
  `dualDecodeArbitration` (default `false`), added for v3 multilingual long-form drift at
  ~15 s chunk boundaries (#594) [FA `AsrTypes.swift:39–83`, `ChunkProcessor.swift:34`].
- **Caveat for 0.15.5 specifically:** passing `language: .german` triggers an English-token
  blocklist meant for French that corrupts clean German (`so`→`zu`, `Sohn`→`Lohn`,
  `herzlich`→`hertz`; de +2.9pp WER, de/en code-switch +5.2pp) (#840). Fixed in
  **v0.15.6** by #847 (`englishBlocklistApplies` → French only). If we pin 0.15.5, do not
  pass a Latin-script hint; or bump to ≥0.15.6.

## 3. Language handling: detection, hints, reporting

- **Automatic, implicit.** "The model automatically detects the language of the audio and
  transcribes it without requiring additional prompting." [NV, Description]. There is a
  single shared 8,192-token SentencePiece vocab across all 25 languages [NV, Training].
- **No model-level language hint/conditioning.** PR #630 (quoted in #842): "Parakeet TDT v3
  has no language conditioning token." NVIDIA maintainer in NeMo #14799 (as quoted in #842):
  "parakeet-v3 model doesn't receive or output language id". *Quoted second-hand; NeMo issue
  not opened directly.*
- **FluidAudio's `language:` is a decode-time filter, not conditioning.** `TokenLanguageFilter`
  picks the best top-K token whose **script** (Latin vs Cyrillic) matches the hint [TLF].
  Built for #512 (Polish emitted as Cyrillic). So for **ru vs en/de it is meaningful**
  (Cyrillic vs Latin); for **de vs en it is a no-op** script-wise (both Latin), except the
  French-only blocklist (≥0.15.6). `Language` enum covers en, de, ru, uk, etc.
  [FA `Shared/TokenLanguageFilter.swift:4`]. A wrong hint on a mixed ru/en recording would
  suppress the other script — *inferred from the algorithm, not tested*.
- **No detected-language output.** `ASRResult` fields: `text, confidence, duration,
  processingTime, tokenTimings, performanceMetrics, ctcDetectedTerms, ctcAppliedTerms` —
  no language field [FA `ASR/Parakeet/AsrTypes.swift:90–97`]. Language would have to be
  inferred from the text (e.g. script, NLLanguageRecognizer). (FluidAudio's separate
  *Nemotron Multilingual* streaming model does have `auto` mode and `detectedLanguage`, but
  supports en/es/fr/it/pt/de/zh/ja — **no ru** [FA `Documentation/Models.md`].)

## 4. Code-switching

- **NVIDIA: nothing documented** about code-switching on the model card [NV]. *Not covered.*
- **Reported in FluidAudio (all user reports, CoreML port, mostly es/en and fr/en):**
  - #850 (closed 2026-08-19): ~7.5 s English + ~12 s Spanish in one 15 s encoder window →
    **English half deleted entirely**, confidence 0.993; deterministic; reversed order decodes
    both; a 0.9 s English phrase inside Spanish also deleted. Language hint does not help.
    Reporter's caveat: spliced TTS voices, not a natural speaker.
  - #842 (closed as upstream behaviour): spontaneous Spanish decoded through an English
    lexicon; reproduced on upstream fp32 NVIDIA weights (MLX), i.e. **model behaviour, not the
    port**; language state appears **window-global and bidirectional** (hard audio corrupts a
    clean lead-in in either order). Read/TTS speech fine; driven by speech rate.
  - #594 (fixed by #596): French drifting to English at ~15 s chunk boundary in batch mode.
  - #630 (per #842): French English-drift 0–7% on read speech vs 31.3% on a spontaneous interview.
  - #840: de/en code-switching measured; auto mode works, `language:` hint made it worse in 0.15.5.
- **Nothing found specific to ru/en or de/en full-window mixing.** Expect English prior to
  dominate ambiguous frames; ru/en mixes may additionally show script leakage (#512 class).
  *Needs our own test clips.*

## 5. Accuracy and speed

WER %, punctuation/case removed. NVIDIA = A100 NeMo greedy [NV]; FluidAudio = CoreML on M4 Pro,
FLEURS full test [BENCH].

| lang | NVIDIA FLEURS | NVIDIA CoVoST | FluidAudio FLEURS (WER / CER) | FluidAudio RTFx |
|---|---|---|---|---|
| en | 4.85 | 6.80 | 5.4 / 2.5 | 207× |
| de | 5.04 | 4.84 | 5.9 / 1.9 | 221× |
| ru | 5.51 | 3.00 | 7.2 / 2.2 | 210× |

English, v3 vs v2 (FluidAudio CoreML, LibriSpeech test-clean, 2620 files) [BENCH]:

| model | WER | CER | overall RTFx |
|---|---|---|---|
| v3 | 2.5% | 1.0% | 155.6× |
| v2 | 2.1% | 0.7% | 145.8× |

FluidAudio: "Use v2 if you only need English, it is a bit more accurate" [BENCH].
NVIDIA v3 Open ASR Leaderboard avg 6.34%, LS test-clean 1.93% [NV]. FluidInference HF card
claims ~110× RTF on M4 Pro [FI-HF]. NVIDIA v2 English numbers were not fetched (*unverified*
for a NeMo-to-NeMo comparison). All published non-English WERs are read-speech benchmarks;
spontaneous speech is reported markedly worse (#842).

## Bottom line

v3 covers en/de/ru officially, is a one-line version switch in our pinned FluidAudio
(~+18 MB download, new cache folder), auto-detects language implicitly, does not report it,
and only offers a script-level hint (useful for ru, not for de/en). Mixed-language audio
within one ~15 s window is a known weak spot (deletion / English drift), with no fix upstream.
Bump to ≥0.15.6 before ever passing `language: .german`.
