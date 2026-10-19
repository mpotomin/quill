Type: grilling
Status: resolved
Assignee: vwpzftv
Blocked by: 05

# Does transcript.json record a language?

## Question

Parakeet v3 reports no language. Should `transcript.json` (and `transcript.md`) record a language per segment or per track? If not, confirm "no change" for the spec. Recording one would need our own detection step, such as a script heuristic (Cyrillic vs Latin) or a separate language-ID model. If yes, decide the field's shape, where it goes, and how de and en get told apart.

## Answer

Decided (grilling, 2026-10-19): **no schema change.** Neither `transcript.json` nor `transcript.md` records a language, at any granularity. No detection step is added.

- Why: Parakeet v3 reports no language. Nothing reads `transcript.json` back today, so a field would need detection we build ourselves with no consumer. A script heuristic (Cyrillic vs Latin) can't tell de from en anyway.
- Later: adding an optional field is non-breaking (unknown keys are ignored; old transcripts simply lack it), so this can be revisited when a real consumer appears.
- Spec line: "transcript.json / transcript.md: unchanged; no language field."
