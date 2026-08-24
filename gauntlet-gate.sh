#!/usr/bin/env bash
# gauntlet-gate.sh — the Step 0 bar gate for /gauntlet.
# A gate that cannot fail the build is not a gate. This one exits non-zero.
#
#   gauntlet-gate.sh bar     --dir <.gauntlet dir> [--reference <path-or-url>]
#   gauntlet-gate.sh verdict --dir <.gauntlet dir> --verdict <critic verdict file>
#
# exit 0 = PASS (builders may spawn / verdict is binding)
# exit 1 = BLOCKED (no builder spawns / verdict is advisory-only, never a PASS)
# exit 2 = usage error
set -uo pipefail

MODE="${1:-}"; shift || true
DIR=""; REF=""; VERDICT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dir)       DIR="${2:-}";     shift 2 ;;
    --reference) REF="${2:-}";     shift 2 ;;
    --verdict)   VERDICT="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$DIR" ] || { echo "usage: gauntlet-gate.sh {bar|verdict} --dir <.gauntlet dir> [--reference <p>] [--verdict <f>]" >&2; exit 2; }

KEY="$DIR/ANSWER-KEY.md"
MAP="$DIR/MAP.md"
FAILS=()
fail() { FAILS+=("$1"); }

# Vague words that let a critic invent its own bar — the exact failure mode this gate exists for.
VAGUE='production[- ]ready|production[- ]grade|high[- ]quality|best practice|robust|seamless|polished|intuitive|clean code|well[- ]structured|properly|as needed|as appropriate|good enough|looks good|feels |excellent|solid|nice|modern|scalable(\b|$)|user[- ]friendly'
FOG='(^|[^A-Za-z])(TBD|TODO|FOG|\?\?\?|ASSUMED|ASSUMPTION|DECIDE LATER|figure out later)([^A-Za-z]|$)'

check_bar() {
  if [ ! -f "$KEY" ]; then
    if [ -n "$REF" ]; then
      # Reference-artifact lane (Shumer's Call of Duty slot). It must be a real, inspectable thing.
      if [ -e "$REF" ] || printf '%s' "$REF" | grep -Eq '^https?://'; then
        echo "BAR SOURCE: reference artifact -> $REF"
        return 0
      fi
      fail "reference artifact does not exist and is not a URL: $REF"
    else
      fail "no ANSWER-KEY.md at $KEY and no --reference artifact — the critic would invent its own bar"
    fi
    return 1
  fi

  # --- MAP.md must exist and carry no unresolved fog ---
  if [ ! -f "$MAP" ]; then
    fail "ANSWER-KEY.md present but MAP.md missing — checks with no recorded reasoning are unreviewable"
  else
    local fog
    fog=$(grep -nEi "$FOG" "$MAP" | grep -viE '^[0-9]+:.*(RESOLVED|CLEARED)' || true)
    [ -n "$fog" ] && fail "MAP.md has unresolved fog (clear it by research/rough-build, do not assume):
$(printf '%s\n' "$fog" | sed 's/^/      MAP.md:/')"
  fi

  # --- Answer key must be binary, id'd, and inspectable ---
  local n=0 ids="" insec=0
  while IFS= read -r line; do
    # Section-aware: inside a "## Checks" heading, EVERY bullet must be an id'd binary check.
    case "$line" in
      "#"*) if printf '%s' "$line" | grep -Eiq '^#+[[:space:]]*checks?\b'; then insec=1; else insec=0; fi
            continue ;;
    esac
    case "$line" in
      "- "*|"* "*) ;;
      *) continue ;;
    esac
    local id body
    id=$(printf '%s' "$line" | sed -n 's/^[-*] \[\([A-Z][A-Z0-9]*-[0-9][0-9]*\)\].*/\1/p')
    if [ -z "$id" ]; then
      [ "$insec" -eq 1 ] && fail "bullet under a Checks heading has no [AK-###] id, so it is not gradeable: ${line:0:80}"
      continue
    fi
    case " $ids " in *" $id "*) fail "duplicate check id $id" ;; esac
    ids="$ids $id"
    n=$((n+1))
    body=$(printf '%s' "$line" | sed 's/^[-*] \[[A-Z0-9-]*\][[:space:]]*//')
    # binary: no vague adjectives the critic can grade on vibes.
    # Backtick spans are literals (commands, tokens, quoted example text) — scan OUTSIDE them,
    # otherwise a check that merely NAMES a banned word gets blocked. Known limit: someone can
    # evade by backticking their vague standard. Not defended — this gate guards against an agent
    # DRIFTING, not against an author sabotaging a gate they wrote for themselves.
    local scan
    scan=$(printf '%s' "$body" | sed 's/`[^`]*`/ /g')
    printf '%s' "$scan" | grep -Eiq "$VAGUE" \
      && fail "$id is not binary — vague standard the critic must invent: ${body:0:80}"

    # inspectable: must anchor on a command, a path, or a number
    printf '%s' "$body" | grep -Eq '`[^`]+`|[0-9]|/[A-Za-z0-9_.-]' \
      || fail "$id has no inspectable anchor (command, path, or number): ${body:0:80}"
  done < "$KEY"

  [ "$n" -eq 0 ] && fail "ANSWER-KEY.md contains zero '- [AK-###] ...' checks"
  [ ${#FAILS[@]} -eq 0 ] && echo "BAR SOURCE: $KEY ($n binary checks:$ids)"
  return 0
}

check_verdict() {
  [ -f "$VERDICT" ] || { fail "verdict file not found: $VERDICT"; return 1; }
  local src
  src=$(grep -iE '^[[:space:]]*bar-source:' "$VERDICT" | head -1 | sed 's/^[^:]*:[[:space:]]*//')
  if [ -z "$src" ]; then
    fail "verdict has no 'bar-source:' line — it cannot say what it graded against, so it is ADVISORY ONLY and may never be recorded as a PASS"
    return 1
  fi
  if printf '%s' "$src" | grep -Eq '^reference:'; then
    echo "VERDICT BAR SOURCE: $src"; return 0
  fi
  local cited bad=""
  cited=$(printf '%s' "$src" | grep -oE '[A-Z][A-Z0-9]*-[0-9]+' || true)
  [ -z "$cited" ] && { fail "bar-source cites no answer-key ids and no reference: $src"; return 1; }
  [ -f "$KEY" ] || { fail "bar-source cites answer-key ids but $KEY does not exist"; return 1; }
  for c in $cited; do
    grep -q "^- \[$c\]" "$KEY" || bad="$bad $c"
  done
  [ -n "$bad" ] && fail "verdict cites answer-key ids that do not exist in $KEY:$bad (fabricated bar)"
  [ ${#FAILS[@]} -eq 0 ] && echo "VERDICT BAR SOURCE: $(printf '%s' "$cited" | tr '\n' ' ')"
  return 0
}

case "$MODE" in
  bar)     check_bar ;;
  verdict) [ -n "$VERDICT" ] || { echo "verdict mode needs --verdict <file>" >&2; exit 2; }; check_verdict ;;
  *) echo "usage: gauntlet-gate.sh {bar|verdict} --dir <.gauntlet dir> [--reference <p>] [--verdict <f>]" >&2; exit 2 ;;
esac

if [ ${#FAILS[@]} -gt 0 ]; then
  echo "VERDICT: BLOCKED"
  for f in "${FAILS[@]}"; do echo "  - $f"; done
  if [ "$MODE" = "verdict" ]; then
    echo "This verdict is ADVISORY ONLY — it may not be recorded as a PASS and may not force another cycle."
  else
    echo "No builder may spawn until the bar exists. Draft it from repo, tickets, and evidence;"
    echo "escalate ONLY genuine design decisions as a Decision Brief (WHAT/WHY/IF YES/IF NO/REC)."
  fi
  exit 1
fi
echo "VERDICT: PASS"
exit 0
