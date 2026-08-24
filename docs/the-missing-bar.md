# The Missing Bar

*Where the gauntlet loop came from, why the interesting part was never the loop, and the gate that exists so a critic cannot invent its own standard.*

2026-08-18

---

## First, what a gauntlet loop is

Normally, building with an AI agent means you are the one checking it. You prompt, it returns something, you look at it, you tell it what is wrong, and you go round again until it is right. A **loop** removes you from that exchange: you give the agent the goal *and the standard it has to reach*, and it keeps checking its own work until it gets there. You see the result at the end.

The **gauntlet loop** is a particular shape of that. One main agent breaks the job into pieces and hands each piece to its own sub-agent, working in its own memory, blind to the others. Attached to each of those is a second agent — the **critic** — whose only job is to inspect the work and hand it back until it clears the bar. The critic never builds anything, and it starts fresh every time, so it does not know who produced the work or how many times this piece has already been rejected. It just grades.

### Where it came from

Matt Shumer posted a demo on X: a first-person shooter that Claude had built from a single prompt, with no pre-made assets. It spread because a complete, playable game out of one prompt was not what people thought these models could do yet. A few days later he published the actual method and named it the gauntlet loop. Andrej Karpathy made the point that landed hardest — work of this quality was never worth producing before, because what it took was never worth what you got back. A model does not have that limit.

### The whole method is three lines

**01 — What you are building, and to what standard.**
Shumer's was a first-person shooter at "triple-A" quality, spelled out as perfect in everything from textures to physics.

**02 — How it should build.**
The main agent splits the goal into parts itself and gives each to its own sub-agent, each with a critic attached, looping until that piece passes.

**03 — The bar the critic stops at.**
Here it was *Call of Duty*. Compare the two *blind* — the critic is not told which one Claude made — and say which is better.

Line three is the one that matters, and it is easy to skim past. He could have written "make the game good." But good is something an agent decides for itself, and an agent that sets its own standard passes its own work. So he gave it a real game to measure against instead — a shipped product, sitting right there, that the critic could go and look at.

## The problem the loop has when you leave the demo behind

> **Take the shipped game away and the loop still runs. It just quietly starts grading against a standard it made up on the way.**

Having something to copy is the exception, not the rule. A game, a landing page, a 3D world — fine, there is always a reference to point at. Now build the billing rules your own business runs on. There is no finished version of your billing rules anywhere. The critic invents one, passes work against it, and you get back a pile of features built to a bar nobody set.

A sentence in a markdown file that says "define inspectable checks; if there is no bar, ask, don't invent" is correct. It is also inert. A paragraph cannot stop a builder from spawning. A control only counts where the request lands. The test is not "does the skill file mention a bar." It is "can I make it say no."

## Two files and a script

The fix borrows its shape from Matt Pocock's `wayfinder` planning skill — the pattern, not the software. Before any builder runs, the agent writes two files. A **map**, holding every decision and the evidence behind it. And an **answer key**, holding nothing but binary checks: lines that return pass or fail when somebody runs them. The answer key drops into exactly the slot *Call of Duty* occupied.

The important word there is *binary*. "Billing module is production-ready" is not a check — it is an invitation for the critic to decide what production-ready means, which is the original problem wearing a hat. `npm test -- billing exits 0 with 0 failures` is a check.

Then the part that has teeth. `gauntlet-gate.sh` reads those files and exits non-zero when the bar is missing or soft. Exit 1 means no builder spawns.

```
$ ./gauntlet-gate.sh bar --dir .gauntlet
VERDICT: BLOCKED
  - AK-001 is not binary — vague standard the critic must invent: Billing module is production-ready
  - AK-002 has no inspectable anchor (command, path, or number): The invoice page looks good
  - bullet under a Checks heading has no [AK-###] id: - Invoices send on the 1st
No builder may spawn until the bar exists.
```

## The second control

A bar that exists but goes uncited is still a bar nobody used. So the critic's verdict has to carry a `bar-source:` line naming what it graded against — either the reference artifact, or the specific answer-key IDs. A verdict that cannot name its bar, or that cites IDs which do not exist in the key, is advisory only. It may not be recorded as a pass, and it may not force another cycle.

### What the gate refuses

| Input | Result | Why |
|---|---|---|
| no answer key, no reference | **BLOCKED** | the critic would invent its own bar |
| reference path that doesn't exist | **BLOCKED** | an artifact nobody can open is not an artifact |
| "production-ready", "looks good" | **BLOCKED** | not binary — grading on vibes |
| check with no ID | **BLOCKED** | a verdict can't cite it, so it isn't enforceable |
| TBD / ??? left in the map | **BLOCKED** | unresolved question carried into the build |
| verdict with no bar-source | **BLOCKED** | advisory only — never recorded as a pass |
| verdict citing IDs not in the key | **BLOCKED** | fabricated bar |
| well-formed map + answer key | **PASS** | builders may spawn |

## Proving it can fail

A gate that has never denied anything is decoration. The pack ships with a fixture suite whose job is to assert the refusals — seven of its eleven assertions expect a non-zero exit.

```
$ ./examples/run-deny-proof.sh
  AK-001 no-bar denied: PASS (exit 1)
  AK-002 vague denied: PASS (exit 1)
  AK-003 un-id'd denied: PASS (exit 1)
  AK-004 fog denied: PASS (exit 1)
  AK-005 fake ref denied: PASS (exit 1)
  AK-006 valid bar passes: PASS (exit 0)
  AK-007 no bar-source denied: PASS (exit 1)
  AK-008 fabricated ids denied: PASS (exit 1)
  AK-009 cited verdict passes: PASS (exit 0)
  AK-010 self key passes: PASS (exit 0)
  AK-012 syntax ok: PASS (exit 0)
--- 11 passed, 0 failed
```

Seven denials and four passes. The denials are the interesting half.

## Two things running it caught that reading it would not

The first version *silently skipped* any bullet without an ID. An answer key made entirely of unenforceable bullets would have sailed straight through, reporting a cheerfully low check count. Fixed with section-aware parsing.

The second: the gate pointed at its own answer key and blocked itself — because one of the checks legitimately *quotes* the phrase "production-ready" as an example of a banned phrase. The scanner could not tell naming a word from grading by it. Fixed by scanning outside backticks.

A brief anti-evasion rule (backtick a vague word and it still gets caught) was added, then removed. It blocked legitimate quoting again. This gate exists to catch an agent *drifting*, not an author sabotaging a gate they wrote for themselves. A control that cries wolf gets switched off by the third week.

## What was deliberately not built

`wayfinder` was not installed. It is built to drive all the way to a full specification and writes a separate file per requirement. The need was two files and a verdict. The shape was taken. The software was left.

The 34-question planning interview was not imported either. The answer key is drafted by the agent from the repository, the ticket, and the code — and when it hits something genuinely unknown, it goes and clears it. Only a real design decision gets escalated, as a one-screen brief. Nobody gets handed a questionnaire.

## The takeaway

The interesting part of the gauntlet loop was never the loop. It was that somebody put a shipped game next to the output and made the critic look at both. Everything downstream of that — the sub-agents, the fan-out, the unattended building — works because the standard was external and concrete.

Most real work does not come with a shipped game attached. So you write the answer key first, and you make something other than a paragraph enforce it.
