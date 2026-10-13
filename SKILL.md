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
./examples/run-deny-proof.sh   # 15 assertions, 10 of them DENIALS
```

`examples/step0-self/` is the MAP + ANSWER KEY used to build this gate — a worked example.

### Grade the symptom the user sees, not the scaffolding behind it

A check can be perfectly inspectable and still grade the wrong thing. "File `x` contains a
`.tip` CSS rule" passes the gate — and passed a real review — while the tooltips were
functionally **broken** (native `title=` popups: ~1s delay, dead on touch, invisible to the
user who reported them). The critic honestly PASSED, because it can only grade the bar it is
handed: a weak check produces a **hollow PASS**, and the human ends up being the real critic.

Every check must encode the **observable behavior a user would experience**, not the existence
of the code that is supposed to produce it:

- Not "a `.tip` CSS rule exists" → "hovering a `.tip` shows an on-screen bubble with the definition text".
- Not "the endpoint returns a `total` field" → "the endpoint returns `total` == the count the table shows".
- Not "there is an export button" → "clicking export downloads a CSV whose rows match the filtered view".

Rule of thumb: if the check would still PASS on a build where the feature is visibly broken to
the user, the check is scaffolding, not a bar. For UI work that usually means a **visual/browser
anchor** (screenshot diff, headed-browser assertion) — a source grep alone keeps passing hollow.

## Triage — what earns a gauntlet, and how deep

Run `gauntlet-triage.sh` with honest flags BEFORE deciding review depth. It evaluates in fixed
order — 1 hard event, 2 credentials/authority, 3 PII/data movement, 4 production traffic,
5 client/public visibility, 6 reversibility & scope — and emits one JSON object (`tier`,
`route`, `order`, `reasons`, `confidence`). Exit codes never encode tiers; nonzero = usage
error only. Log the one-line result on the ticket (`triage: T1 — 4 files, internal`).

```bash
./gauntlet-triage.sh --files 4 --reversible-mins 10      # -> T1
./gauntlet-triage.sh --edge-fn                            # -> T2: publicly reachable
./examples/triage-selftest.sh                             # 18 assertions
```

- **T0 self-check:** syntax + live verify + backup. No critic.
- **T1 lite** (NOT a paperwork tier): a frozen mini-bar (3–6 binary checks), the full evidence
  contract INCLUDING `Unverified claims:`, and **at least one live reproduction** — the critic
  must run the thing, not grep for it. Three greps is a FAIL.
- **T2 full loop:** Step-0 answer key, builder/critic cycles, deny-proofs, post-cutover re-verify.

Hard floors override all discretion: `credential-install`, `client-capability`, `ticket-close`,
`cutover`, `client-visible-go-live`. Blast-radius rules: an edge function with no access policy
is publicly reachable = T2; anything touching production data = T2 — "internal" is not a blast
radius.

## The assertion audit — an unreceipted claim is not a fact

The observed lie shape: *"the REPLACE_WITH_* values are already live"* — an assumption stated
as fact and used as a reason to deploy, retracted only after challenge. The evidence standard
already bounced unreceipted OUTPUT claims; this extends it to INPUT claims — the premises a
build or verdict rests on.

1. **Every load-bearing premise needs a receipt** — a command output, an id, a read-back, a
   screenshot. "Already live", "already configured", "should be fine" are assumptions until
   receipted, and an assumption may never justify a deploy, credential install, or
   customer-facing action.
2. **A literal placeholder asserted as config is a mechanical denial.** `gauntlet-gate.sh bar`
   EXITS 1 if MAP.md or ANSWER-KEY.md contains REPLACE_WITH_* / PASTE_* / CHANGE_ME /
   YOUR_*_KEY-style tokens outside a RESOLVED/CLEARED line.
3. **The critic hunts premises, not just outputs.** The verdict contract REQUIRES an
   `Unverified claims:` line naming each claim it TESTED or REJECTED — `gauntlet-gate.sh
   verdict` refuses a verdict without it. A PASS resting on an untested premise is hollow.
4. **Retraction is not remediation.** The finding closes when the TRUE value and its receipt
   are in the record, not when someone apologizes for the claim.

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
Unverified claims: <each builder claim stated as fact without a receipt — TESTED (with result) or REJECTED; 'none' only if every load-bearing claim carried its own receipt>
```

`bar-source:` is what the critic actually graded against. Validate it — a verdict that cannot
name its bar, or that cites answer-key ids which do not exist (including on a wrapped
`bar-source:` continuation line), is a **fabricated bar**:

```bash
./gauntlet-gate.sh verdict --dir .gauntlet --verdict /tmp/critic-verdict.txt
```

Exit 1 = the verdict is **ADVISORY ONLY**: it may not be recorded as a PASS and may not force
another cycle. A critic preference WITHOUT a reproduction, violated requirement, or concrete risk
is likewise **advisory**.

## Ceiling of a local gate — say it out loud

A gate that runs inside the checked party's own shell cannot be tamper-PROOF, only
tamper-EVIDENT. An adversarial critic proved it: `command`, `builtin`, `unset`, and `exec` are
ordinary barewords subject to function lookup, and bash imports the caller's exported functions
before a script's first line — so no in-script line closes it. The deny-proofs are real value
for cooperative and careless failure (drift, self-certification, honest mistakes); they are NOT
a security boundary against a determined compromised agent. When hardening reaches this point,
stop — another round is sunk cost. Move the trust boundary out of the agent's process
(server-side gates on ticket close, credential and capability brokers, the deploy wrapper).
Never hook `verdict` onto raw deploy commands either: it exits 1 when no verdict exists and
would freeze every T0/T1 change.

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
- Never accept "already live / already configured / should work" as a premise — demand the
  receipt or list it under `Unverified claims:` as REJECTED.
- Never write a check that would still PASS on a build where the feature is visibly broken to
  the user — grade the rendered symptom, not the existence of the code behind it.
- Never gauntlet trivial one-file edits — this skill is for multi-slice builds; overhead
  must earn itself.

## Sources

- [Matt Shumer, “How to Run a Gauntlet Loop”](https://somethingbig.ai/gauntlet-loop)
- [Original Claude of Duty prompt](https://github.com/mshumer/Claude-of-Duty/blob/main/prompt.md)
- [SWE-Review (arXiv:2607.06065)](https://arxiv.org/abs/2607.06065)
- Matt Pocock `wayfinder` (MIT) — MAP + answer-key *pattern* only, not an install
