# MAP — Step 0 answer-key gate for /gauntlet

## Frozen request
2026-08-18: implement the two-file MAP + ANSWER KEY pattern, so the critic never invents its own bar.

## Decisions
- D-001 The gate is an executable script, not a paragraph in SKILL.md — Reason: a control only counts where the request lands. A "fix" that cannot deny anything is not a fix. Verify a gate by making it DENY.
- D-002 Two bar lanes, reference artifact OR ANSWER-KEY.md — Reason: Shumer's Call of Duty lane is still valid when a real artifact exists. Most work has none.
- D-003 The answer key is agent-drafted from repo / tickets / evidence — Reason: the 34-question human interview is exactly what not to import.
- D-004 Take the pattern, do not install `wayfinder` or its dependency skills — Reason: wayfinder writes one file per requirement; this pack wants two files and a verdict.
- D-005 Second control at the verdict, not only at Step 0 — Reason: a bar that exists but goes uncited still lets a critic grade on vibes. `bar-source:` makes the verdict name its bar.

## Fog cleared
- F-001 Do we already have an elicitation/answer-key mechanism? — FOG CLEARED: searched local skills and notes for wayfinder|grill-me|answer.key → zero hits. Real gap, not a rebuild.
- F-002 Is the video's problem #1 (agent writes its own critic prompt) also a gap? — FOG CLEARED: SKILL.md already pins a verbatim critic contract and critic model ≠ builder model.
- F-003 What silently passes a malformed key? — FOG CLEARED: built fixtures and ran them; the first cut skipped un-id'd bullets entirely. Fixed with section-aware parsing, re-proved.

## Explicit exclusions
- Not installing wayfinder, grill-me, or Pocock's dependency skills.
- Not changing the outer gauntlet or the human merge/deploy gate.
- Not auto-generating answer keys — Step 0 requires an agent to draft one.

## Acceptance evidence (2026-08-18)
All 13 answer-key checks executed: 13 passed, 0 failed.
Gate self-run: `gauntlet-gate.sh bar --dir examples/step0-self` → PASS, 13 checks recognised.
Fixtures live in the session scratchpad; the gate DENIED on all 5 malformed-bar cases and both
malformed-verdict cases before this key was accepted.
