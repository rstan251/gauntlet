# Gauntlet

A builder/critic loop for agentic coding. The builder never grades itself. A fresh critic inspects the real artifact against a frozen bar. A shell gate can refuse to start the build.

If you have used "keep going until the tests pass," this is the version that still works when there is no shipped product to copy.

## The problem it solves

Matt Shumer's gauntlet loop built a playable FPS from one prompt. The critic's bar was Call of Duty — a real game sitting there to look at.

Take that game away and the loop still runs. It just grades against a standard the agent invented on the way. Ninety minutes later you have a pile of features built to a bar nobody set.

This pack is the fix:

1. **Freeze the original request.** Conformance is judged against that, not against the agent's later plan.
2. **Write the bar first.** Either a reference artifact, or two files: `MAP.md` (decisions) and `ANSWER-KEY.md` (binary checks).
3. **Run a gate that can say no.** Vague words, missing ids, unresolved `TBD`, fake paths, `REPLACE_WITH_*` placeholders posing as config — exit 1, no builder spawns.
4. **Critic returns a contract.** Verdict, `bar-source:`, coverage, one gap, a reproduction, and `Unverified claims:`. A verdict that cannot name its bar, or never hunted unreceipted claims, is advisory only.
5. **Stop on evidence.** Independent PASS, two dead cycles, budget, or a human-only decision.

## Install

Works with Claude Code, Codex, Cursor, Grok, or any agent that loads `SKILL.md`.

```bash
# zip
curl -L https://github.com/rstan251/gauntlet/archive/refs/heads/main.zip -o gauntlet.zip
unzip gauntlet.zip
mv gauntlet-main ~/.claude/skills/gauntlet   # Claude Code / Codex
# or: mv gauntlet-main ~/.agents/skills/gauntlet
# or: mv gauntlet-main .claude/skills/gauntlet   # project-local

chmod +x ~/.claude/skills/gauntlet/gauntlet-gate.sh
```

```bash
# git
git clone https://github.com/rstan251/gauntlet.git ~/.claude/skills/gauntlet
chmod +x ~/.claude/skills/gauntlet/gauntlet-gate.sh
```

Then ask the agent: `run /gauntlet on this: <your request>`

## Prove the gate can fail

A gate that has never denied anything is decoration.

```bash
cd ~/.claude/skills/gauntlet   # or wherever you put it
./examples/run-deny-proof.sh
```

Expect 15 passed, 0 failed. Ten of those assertions are denials.

```bash
./examples/triage-selftest.sh   # 18 passed, 0 failed
```

## Use it on a real build

In the project you are building:

```bash
mkdir -p .gauntlet
cp /path/to/gauntlet/templates/MAP.md .gauntlet/MAP.md
cp /path/to/gauntlet/templates/ANSWER-KEY.md .gauntlet/ANSWER-KEY.md
# agent fills both from repo evidence — do not interview yourself for 34 questions
/path/to/gauntlet/gauntlet-gate.sh bar --dir .gauntlet
```

Exit 0 = builders may spawn. Exit 1 = the bar is missing or soft. Fix the files. Do not start coding.

After a critic writes a verdict:

```bash
/path/to/gauntlet/gauntlet-gate.sh verdict --dir .gauntlet --verdict /tmp/critic-verdict.txt
```

## What is in the box

| File | Role |
|---|---|
| `SKILL.md` | The loop. Drop this in a skills folder. |
| `gauntlet-gate.sh` | The teeth. `bar` and `verdict` modes. Exit 1 blocks. |
| `gauntlet-triage.sh` | Which tier a change earns (T0 / T1 / T2), as JSON. |
| `templates/` | Blank MAP + ANSWER KEY. |
| `examples/run-deny-proof.sh` | 15 assertions, 10 denials. |
| `examples/triage-selftest.sh` | 18 triage assertions. |
| `examples/deny-fixtures/` | Malformed bars the gate must refuse. |
| `examples/step0-self/` | The MAP + KEY used to build the gate itself. |
| `docs/the-missing-bar.md` | The essay: where this came from and why Step 0 exists. |

## What a check looks like

Bad (the gate blocks these):

```
- Billing module is production-ready
- The invoice page looks good
```

Good:

```
- [AK-001] `npm test -- billing` exits 0 with 0 failures
- [AK-002] POST /api/invoices with no auth header returns 401
- [AK-003] File `src/billing/proration.ts` exports dayBasedProrate
```

Binary. Id'd. Anchored on a command, a path, or a number.

## What this is not

- Not a replacement for your merge/deploy review.
- Not worth the overhead on a one-line fix.
- Not an install of Pocock's `wayfinder` — that is a different tool. This took the two-file shape and left the software.
- Not a promise the agent will follow the skill. The shell gate is what can actually refuse.

## Credit

- Matt Shumer — [Gauntlet Loop](https://somethingbig.ai/gauntlet-loop) and [Claude of Duty](https://github.com/mshumer/Claude-of-Duty)
- [SWE-Review](https://arxiv.org/abs/2607.06065)
- Matt Pocock `wayfinder` (MIT) — MAP + answer-key pattern only
- Iron Noodle — Step 0 gate, critic contract, deny-proof

MIT. Use it, fork it, tell us if the gate lets something through that it should not.
