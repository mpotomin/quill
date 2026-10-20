# 03: Docs, release notes, and manual acceptance

**What to build:** The README and release notes describe the v3 engine accurately. The change is verified by hand on real multilingual recordings before it's considered done. This ticket is HITL: the recordings need a human speaking. Spec: [Multilingual transcription via Parakeet v3](../../multilingual-transcription/spec.md).

**Blocked by:** 02: Swap the engine to Parakeet v3, with doctor following

**Status:** needs-human (docs done in 03b88ec; manual acceptance pending)

- [ ] The README model section describes Parakeet v3, the ~483 MB one-time download, en/ru/de with automatic language handling, and the known limitation that an instant language switch can garble about 1–2 s.
- [ ] The README no longer says a WhisperKit engine is planned as the fallback.
- [ ] Release notes cover the following:
  - The v3 model downloads on the first transcription after upgrading. Run `quill doctor` to check the cache.
  - The old v2 model cache (~600 MB): where it lives and that it's safe to delete.
  - Existing transcripts are untouched and not re-transcribed.
- [ ] Manual acceptance: record through quill itself and read each session's `transcript.json`. Cover:
  - an English-only session, compared by eye with a v2 transcript of similar speech;
  - a Russian-only session;
  - a German-only session;
  - a mixed session (two or three of the languages);
  - a session where the system track carries a different language from the mic.
- [ ] Each acceptance session shows `model` = `parakeet-tdt-0.6b-v3-coreml`.
- [ ] `quill doctor` shows the v3 warning before the first download and passes after it.
- [ ] The results are recorded in a comment on this ticket. If English on v3 is clearly worse than v2, the outcome is to revert in git and reopen the map [Multilingual transcription (en / ru / de) on macOS](../../multilingual-transcription/map.md).
