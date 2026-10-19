Type: grilling
Status: open
Blocked by: 05

# Does transcript.json record a language?

## Question

Parakeet v3 reports no language. Should `transcript.json` (and `transcript.md`) record a language per segment or per track? If not, confirm "no change" for the spec. Recording one would need our own detection step, such as a script heuristic (Cyrillic vs Latin) or a separate language-ID model. If yes, decide the field's shape, where it goes, and how de and en get told apart.
