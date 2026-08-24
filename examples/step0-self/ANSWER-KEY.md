# ANSWER KEY — Step 0 answer-key gate for /gauntlet

## Checks
- [AK-001] `gauntlet-gate.sh bar --dir <dir-with-no-ANSWER-KEY.md>` exits 1
- [AK-002] `gauntlet-gate.sh bar --dir <dir>` exits 1 when a check contains a vague standard such as `production-ready` or `looks good`
- [AK-003] `gauntlet-gate.sh bar --dir <dir>` exits 1 when a bullet under a Checks heading has no `[AK-###]` id
- [AK-004] `gauntlet-gate.sh bar --dir <dir>` exits 1 when `MAP.md` still contains `TBD`, `???`, or `ASSUMED`
- [AK-005] `gauntlet-gate.sh bar --dir <dir> --reference <nonexistent path>` exits 1
- [AK-006] `gauntlet-gate.sh bar --dir <dir>` exits 0 on a well-formed MAP + ANSWER-KEY pair and prints the check ids
- [AK-007] `gauntlet-gate.sh verdict --verdict <file with no bar-source line>` exits 1
- [AK-008] `gauntlet-gate.sh verdict --verdict <file citing AK ids absent from the key>` exits 1
- [AK-009] `gauntlet-gate.sh verdict --verdict <file citing real AK ids>` exits 0
- [AK-010] File `SKILL.md` contains a `## Step 0` heading and a `bar-source:` line inside the critic contract
- [AK-011] Files `templates/MAP.md` and `templates/ANSWER-KEY.md` exist
- [AK-012] `bash -n gauntlet-gate.sh` exits 0

## Must-not-regress
- [AK-101] File `SKILL.md` still contains the verbatim critic contract block and all 5 original stop conditions
