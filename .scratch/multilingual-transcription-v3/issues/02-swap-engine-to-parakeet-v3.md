# 02: Swap the engine to Parakeet v3, with doctor following

**What to build:** quill transcribes with Parakeet TDT 0.6B v3, so English, Russian and German (and mixes of them) come out correctly with no setting. v3 replaces v2 outright. `transcription.engine: "parakeet"` now means v3. On the first transcription, the v3 model (~483 MB) downloads lazily, as today. `quill doctor` checks the v3 cache. Config, the `transcript.json` schema and the coordinator don't change. Spec: [Multilingual transcription via Parakeet v3](../../multilingual-transcription/spec.md).

**Blocked by:** 01: Unit-test segmentation for multilingual words

**Status:** done

- [ ] The FluidAudio dependency minimum is ≥ 0.15.6, the first release with v3. The trial ran 0.17.7.
- [ ] The Parakeet engine loads FluidAudio's v3 ASR models. Its `model` is `parakeet-tdt-0.6b-v3-coreml`, and its `name` stays `parakeet`.
- [ ] The v2 loading path is removed, not kept selectable. No new config key. The unknown-engine warning and fallback are unchanged.
- [ ] The engine's doc comment describes v3: multilingual en/ru/de with automatic handling, ~483 MB.
- [ ] No language hint, detection or field is added. The `transcript.json` schema is unchanged.
- [ ] `quill doctor`'s transcription check looks at the v3 cache and warns "parakeet v3 models not downloaded (~483 MB)" when it's missing. It stays a warning, with no load check.
- [ ] The first-run download failure behaviour is unchanged: the error goes to `transcribe.log`, and the session stays pending and retries on the next launch.
- [ ] The build passes and all tests pass, including the segmentation tests from 01.
- [ ] Smoke check: one real recorded session produces `transcript.json` with `model` = `parakeet-tdt-0.6b-v3-coreml`.
