# MAP — decisions and the reasoning behind them

> Sibling of `ANSWER-KEY.md`. The map holds WHY, the answer key holds WHAT-IS-CHECKED.
> Drafted by the AGENT from repo, tickets, and evidence — never a question
> marathon aimed at the human.
> The gate rejects unresolved fog: `TBD`, `TODO`, `FOG`, `???`, `ASSUMED`, "decide later".
> Clear fog by doing — read the code, run the thing, build a rough version, check the
> vendor docs — then write the answer and mark the line `FOG CLEARED: <how>`.

## Frozen request
<verbatim user request or ticket id + description>

## Decisions
- D-001 <decision> — Reason: <evidence: file:line, ticket id, memory file, API response>
- D-002 <decision> — Reason: <evidence>

## Fog cleared
- F-001 <what was unknown> — FOG CLEARED: <research/rough-build/real-world check that settled it> → feeds D-00X

## Escalated (Decision Brief only — genuine design choices, not busywork)
- E-001 <question> — WHAT / WHY / IF YES / IF NO / REC → <ticket id>

## Explicit exclusions
- <what this build is NOT doing, so the critic cannot mark it MISSING>
