Type: grilling
Status: resolved
Assignee: vwpzftv
Blocked by: 01, 02, 03

# Automatic detection or an explicit language switch?

## Question

Given the research and the trial, is automatic language handling (including mixed sessions) good enough to ship as the only mode? If not, which engine plus switch combination should the spec commit to: Parakeet v3 with a switch, Whisper with a forced language, or a hybrid?

## Answer

Decided (grilling, 2026-10-19): **ship Parakeet TDT 0.6B v3 with automatic language handling as the only mode.** No language hint and no switch in the menu, config or CLI.

- **Evidence:** the trial passed the user's bar on one 49 s clip mixing all three languages. The spec commits now and names the gaps as accepted risks rather than waiting for another trial: separate monolingual clips, the system track, long sessions, and English compared with v2. The spec must say that this rests on one clip and the user's judgement, not on measurement.
- **Known limitation, accepted:** a fast switch (mid-sentence, or within a few seconds of another) can lose about 1–2 s or come out as a garbled mix of the two languages. We won't fix it; that would need language ID per chunk.
- **Whisper:** dropped from the spec. It's listed as considered but not chosen (3× the download, speed unmeasured, language detection per file only). If v3 disappoints in real use, adding Whisper is a new effort.
- **Consequence:** the language switch design is out of scope.
