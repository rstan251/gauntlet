---
name: gauntlet
description: Run a Gauntlet Loop on a build task — builder never grades itself; a fresh independent critic inspects the real diff/artifact against a frozen success bar, with evidence-contract verdicts and hard stop conditions. Use for multi-slice builds, production-grade implementation, or when asked to gauntlet / adversarially build-review a change.
user_invocable: true
argument_hint: "[original request or ticket id]"
---

# /gauntlet — builder/critic loop for build tasks

Adopted from the Gauntlet Loop pattern (Shumer; SWE-Review arXiv:2607.06065),
then hardened so the critic cannot invent its own bar.

The one law: **the builder never declares the work finished.** A fresh critic
inspects the real artifact against a frozen bar and returns PASS, FAIL, or BLOCKED.

**Step 0** is the two-file MAP + ANSWER KEY pattern, taken from Matt Pocock's
`wayfinder` (MIT) as a pattern only, not an install.

## Why this exists

A normal agent loop is "keep coding until the tests pass." That still lets the
same model grade its own homework. A gauntlet loop adds four controls:

1. An **external bar** — measurable checks, a reference artifact, latency, security.
2. **Independent judgment** — the critic has fresh context and does not inherit the builder's rationale.
3. **Artifact inspection** — the critic runs the product. It does not grade a summary.
4. **Repeated revision** — FAIL returns one evidence-backed gap. The artifact goes through the gate again.

The original public demos used a shipped product as the bar (Shumer used Call of Duty).
Most real work has nothing to copy. Without a bar, the critic invents a standard and
passes work against it. Step 0 exists so that cannot happen.

## Non-negotiable mappings

| Gauntlet concept | Implementation |
|---|---|
| Frozen original request | Verbatim quote in `REQUEST.md` or the ticket description. Conformance is judged against THIS, never the agent plan |
| Builder | Fresh subagent. Do not reuse the critic's context |
| Critic | Fresh subagent with NO builder rationale — give it only: original request, success bar, the diff, and how to run the artifact. **Critic model ≠ builder model when you can** |
| **Bar source (BLOCKING)** | A **reference artifact** OR `.gauntlet/ANSWER-KEY.md`. Nothing else is a bar. Enforced by `gauntlet-gate.sh bar` — it EXITS 1 and no builder spawns |
| Quality bar | Deterministic tests + receipts-first evidence (raw output, ids, byte counts — narrative claims bounce) |
| Outer gauntlet | Whole-diff review after all slices pass |
| Release gate | Human merge/deploy — SEPARATE from the loop |

## Step 0 — Produce the bar (BLOCKING, runs before anything else)

The loop may not start until ONE of these exists:

- **A reference artifact** — a real running product, page, file, or URL the critic inspects.
- **`.gauntlet/ANSWER-KEY.md`** — binary PASS/FAIL checks, plus `.gauntlet/MAP.md`
  holding the decisions and the reasoning. Templates: `templates/ANSWER-KEY.md`, `templates/MAP.md`.

**The answer key is drafted by the agent** from the repo, tickets, and evidence — not by
interviewing the human. When a requirement is unknown ("fog"), **clear it by doing**:
read the code, run the thing, build a rough version to react to, check the vendor docs.
Never assume and carry on. Escalate ONLY genuine design decisions, as a one-screen
Decision Brief (WHAT / WHY / IF YES / IF NO / REC).

Then run the gate — this is a command, not a promise:

```bash
./gauntlet-gate.sh bar --dir .gauntlet
./gauntlet-gate.sh bar --dir .gauntlet --reference ./ref/target.png
```

It exits **1** on: no bar at all, a reference path that does not exist, vague standards
(production-ready, robust, looks good), checks with no id, checks with no inspectable
anchor (command / path / number), duplicate ids, an empty checks section, or unresolved fog
(`TBD`, `???`, `ASSUMED`, "decide later") left in `MAP.md`. **Exit 1 = no builder spawns.**

Proof the gate can deny:

```bash
./examples/run-deny-proof.sh   # 11 assertions, 7 of them DENIALS
```

`examples/step0-self/` is the MAP + ANSWER KEY used to build this gate — a worked example.

## The loop

1. **Freeze the request verbatim.** Record baseline: `git rev-parse HEAD`, dirty files, current test results.
2. **Define the bar** as inspectable checks (exact commands, reference artifact, latency target).
   Step 0 already guarantees one exists — a critic with no bar invents its own and passes work against it.
3. **Slice** into independently verifiable units. Coupled slices run SEQUENTIAL with one owner.
   Pilot one slice end-to-end before fanning out.
4. **Inner loop per slice:** builder implements smallest complete change + regression tests → deterministic checks → fresh critic returns the contract below → on FAIL, a builder applies the smallest corrective action → re-review.
5. **Outer gauntlet** after all slices: whole-diff review, end-to-end acceptance, regressions, security if touched, docs/rollback, **conformance vs the original request**. Independent final PASS required.
6. **Report:** delivered requirements, verification evidence, remaining concerns, rollback status, SHA, ready-for-human-review.

## Critic contract (verbatim — require this shape)

```text
VERDICT: PASS | FAIL | BLOCKED
bar-source: reference:<path-or-url> | AK-001, AK-002, ...
Requirement coverage:
- <requirement>: PASS | FAIL | MISSING — <evidence>
Largest remaining gap: <one concrete defect or none>
Reproduction/evidence: <command, output, screenshot, trace, or file:line>
Required correction: <smallest corrective action>
Regression risk: <what must be rechecked>
```

`bar-source:` is what the critic actually graded against. Validate it — a verdict that cannot
name its bar, or that cites answer-key ids which do not exist, is a **fabricated bar**:

```bash
./gauntlet-gate.sh verdict --dir .gauntlet --verdict /tmp/critic-verdict.txt
```

Exit 1 = the verdict is **ADVISORY ONLY**: it may not be recorded as a PASS and may not force
another cycle. A critic preference WITHOUT a reproduction, violated requirement, or concrete risk
is likewise **advisory**.

## Stop conditions (hard)

- **No reference artifact and no valid `ANSWER-KEY.md` → BLOCKED at Step 0.** Never build first
  and back-fill the bar afterwards — a bar written to match the diff grades nothing.
- Independent PASS on all mandatory gates → done.
- **Two consecutive cycles with no measurable improvement → BLOCKED**, escalate with the
  critic's last contract instead of looping.
- Token/time budget reached → report partial with evidence.
- Next action is destructive / production / credential / customer-facing → stop at the human gate.
- Builder-critic requirements disagreement only a human can resolve → Decision Brief.

## What NOT to do

- Never let the builder post its own PASS.
- Never let the critic write its own standard. If it had to decide what "good" means, Step 0 failed.
- Never hand the human a 34-question planning interview to produce the answer key — draft it from
  evidence and escalate only real design decisions.
- Never hand the critic the builder's explanation — diff and artifact only.
- Never substitute slice-level passes for the outer gauntlet.
- Never gauntlet trivial one-file edits — this skill is for multi-slice builds; overhead
  must earn itself.

## Sources

- [Matt Shumer, “How to Run a Gauntlet Loop”](https://somethingbig.ai/gauntlet-loop)
- [Original Claude of Duty prompt](https://github.com/mshumer/Claude-of-Duty/blob/main/prompt.md)
- [SWE-Review (arXiv:2607.06065)](https://arxiv.org/abs/2607.06065)
- Matt Pocock `wayfinder` (MIT) — MAP + answer-key *pattern* only, not an install
