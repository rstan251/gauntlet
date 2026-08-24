# ANSWER KEY — the critic's frozen bar

> This file occupies the exact slot "Call of Duty" occupied in Shumer's original prompt.
> Every line is BINARY: it returns PASS or FAIL when someone runs it. Nothing else goes here.
> Enforced by `gauntlet-gate.sh bar` — vague standards and un-id'd bullets BLOCK the build.

Rules the gate enforces:
1. Every bullet under a Checks heading is `- [AK-###] <assertion>`.
2. No vague words (production-ready, robust, high-quality, polished, looks good, feels…).
3. Every check anchors on something inspectable: a `command`, a /path, or a number.
4. Ids are unique and stable — critics cite them in `bar-source:`.

## Checks
- [AK-001] `<exact command>` exits 0 with 0 failures
- [AK-002] <request> returns <status/value>
- [AK-003] File `<path>` contains/exports <thing>
- [AK-004] <operation> completes in under <N> ms/s

## Must-not-regress
- [AK-101] `<existing suite command>` still exits 0

## Out of scope (critic may NOT mark these MISSING)
- <excluded behavior>
