# 01: Unit-test segmentation for multilingual words

**What to build:** The Parakeet engine's grouping of word timings into transcript segments is covered by unit tests for multilingual input. This happens before the engine swap, so a regression in how Russian or German speech is split into readable segments is caught without downloading a model. Make the grouping function internal (not private) so tests can reach it, following the precedent of `Transcript.shifted`. Behaviour is unchanged. Spec: [Multilingual transcription via Parakeet v3](../../multilingual-transcription/spec.md).

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The segmentation function is reachable from the test target. Its behaviour is unchanged: it breaks on `.`, `?` or `!`, on a gap over 1 s, or at 60 words.
- [ ] Test: Cyrillic words join into the expected segment text, start and end.
- [ ] Test: German words with umlauts and ß are preserved verbatim.
- [ ] Test: a break after sentence-ending punctuation.
- [ ] Test: a break on a silence gap over 1 s.
- [ ] Test: a break at the 60-word cap.
- [ ] Test: a Latin-then-Cyrillic run with no break condition stays in one segment.
- [ ] Test: empty input produces no segments.
- [ ] The tests follow the style of the existing transcription coordinator tests: pure XCTest that checks output and nothing internal. The whole suite passes.
