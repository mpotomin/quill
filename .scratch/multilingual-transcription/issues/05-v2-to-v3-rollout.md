Type: grilling
Status: open
Blocked by: 04

# Rolling out v3: replace v2, download, doctor, old sessions

## Question

v3 is now the engine (see "Automatic detection or an explicit language switch?"). How does quill move from v2 to it?
- Does v3 replace v2 outright, or does v2 stay selectable through `transcription.engine`? English on v3 is untested against v2; LibriSpeech gives 2.5 vs 2.1 WER.
- First run: the ~483 MB download, where it is cached, and whether the v2 cache gets cleaned up.
- What `quill doctor` checks.
- Whether existing sessions get re-transcribed (never, on demand, or automatically).
