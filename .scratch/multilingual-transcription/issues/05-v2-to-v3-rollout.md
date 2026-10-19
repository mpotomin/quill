Type: grilling
Status: resolved
Assignee: vwpzftv
Blocked by: 04

# Rolling out v3: replace v2, download, doctor, old sessions

## Question

v3 is now the engine (see "Automatic detection or an explicit language switch?"). How does quill move from v2 to it?
- Does v3 replace v2 outright, or does v2 stay selectable through `transcription.engine`? English on v3 is untested against v2; LibriSpeech gives 2.5 vs 2.1 WER.
- First run: the ~483 MB download, where it is cached, and whether the v2 cache gets cleaned up.
- What `quill doctor` checks.
- Whether existing sessions get re-transcribed (never, on demand, or automatically).

## Answer

Decided (grilling, 2026-10-19): **v3 replaces v2 outright.** There is no v2 escape hatch; if English on v3 disappoints, the fallback is reverting the change in git.

- **Engine:** `ParakeetEngine` loads `.v3` with model id `parakeet-tdt-0.6b-v3-coreml`, and v2 code is removed. FluidAudio's minimum version goes up to ≥ 0.15.6 (the trial ran 0.17.7). `transcription.engine` keeps the single value `"parakeet"`, which now means v3. No new config key.
- **Provenance:** no schema change. The existing `model` field in `transcript.json` tells v2 transcripts from v3 ones.
- **Old sessions:** never re-transcribed and no new command. Deleting `transcript.json` and relaunching still re-queues a session, but stays undocumented.
- **First run:** today's behaviour stays. The ~483 MB v3 model downloads on the first transcription; on failure the error goes to `transcribe.log` and the session retries on the next launch. No progress UI, no warm-up download, no automatic retry. This is documented in the README and release notes.
- **v2 cache:** left on disk (~600 MB). The release notes say where it is and that it's safe to delete. No automatic cleanup.
- **`quill doctor`:** the same transcription check, pointed at the v3 cache. Its message becomes "parakeet v3 models not downloaded (~483 MB)". It stays a warning, with no load check.
- **Docs:** the README model section moves to v3, ~483 MB, en/ru/de with automatic handling. Remove the "WhisperKit planned as fallback" line (README.md:107-108), since Whisper was considered and not chosen.
