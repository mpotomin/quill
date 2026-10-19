Type: research
Status: resolved
Blocked by:

# Parakeet v3 via FluidAudio: languages, API, and mixed-language behaviour

## Question

What does Parakeet TDT 0.6B v3 give us through FluidAudio?
- Does it officially support Russian and German, alongside English?
- Which FluidAudio version ships v3, and how does its API differ from the v2 path `ParakeetEngine` uses now (model loading, cache location, size)?
- How does it handle language: automatic detection, a language hint, or neither? Does it report the detected language?
- What is documented or reported about code-switching (two languages in one recording or segment)?
- What accuracy (WER) and speed numbers are published for ru / de / en, compared with v2 on English?

## Answer

Full findings: branch `research/parakeet-v3`, file `research/parakeet-v3.md`.
- Russian and German are officially supported (25 languages). FluidAudio has had v3 since 0.4.0 and v3 is already its default. Switching is one line: `AsrModels.downloadAndLoad(version: .v3)`. Download is about 483 MB, separate from the v2 cache.
- The model detects language on its own and reports none. FluidAudio's `language:` is only a script filter (Latin vs Cyrillic), so it helps Russian and does nothing for de vs en. `language: .german` corrupts German in 0.15.5 (fixed in 0.15.6).
- Mixed languages: nothing official. Reports show one language being dropped when two share a ~15 s window, and spontaneous speech drifting into English. No ru/en or de/en data exists.
- WER (FLEURS): en 4.85, de 5.04, ru 5.51. English on LibriSpeech: v3 2.5 vs v2 2.1.
