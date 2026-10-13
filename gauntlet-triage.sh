#!/usr/bin/env bash
# gauntlet-triage — "what tier does this change earn?"
#
# Evaluates IN THIS ORDER (first hit wins; later signals may still bump):
#   1. hard event   2. credentials/authority   3. PII/data movement
#   4. production traffic   5. client/public visibility   6. reversibility & scope
#
# Output: one JSON object on stdout — {"tier","route","order","reasons","confidence"}.
# Exit codes: 0 = classified (whatever the tier); nonzero ONLY for usage errors.
# Tiers are never encoded in exit codes (nonzero is reserved for errors/denials).
#
# Flags (all optional booleans unless noted):
#   --event <name>          named event (checked against the 5 hard floors)
#   --credential            a credential lands on a host
#   --authority             an agent gains send/write/publish power
#   --pii                   client/person data moves between systems
#   --prod-traffic          production traffic moves (cutover-shaped)
#   --client                output a client sees (site, dashboard, report)
#   --public                public-indexed output
#   --site-publish          public content on your own site      -> route publish-review
#   --comms                 outbound human communication          -> route comms-review
#   --own-noindex           our own property behind noindex       -> T0 + own-property policy
#   --edge-fn               a serverless / edge function deploy
#   --edge-auth             ...that sits behind an auth / access policy
#   --prod-data             touches production database / storage data
#   --dns-routing           DNS / routing / access-policy / client-domain edge change
#   --first-of-class        new mechanism (broker, credential pattern, agent seat)
#   --client-promise        a client was told this is coming ("fix in progress")
#   --files <n>             files touched (default 1)
#   --reversible-mins <n>   honest minutes to fully roll back (default 5)
set -uo pipefail
EVENT=""; FILES=1; REV=5
CRED=0; AUTH=0; PII=0; PROD=0; CLIENT=0; PUBLIC=0; SITEPUB=0; COMMS=0; OWNNOIDX=0
CFW=0; CFACC=0; PRODDATA=0; DNS=0; FIRST=0; PROMISE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --event|--files|--reversible-mins)
      [ $# -ge 2 ] || { echo "missing value for $1" >&2; exit 2; }
      case "$1" in --event) EVENT="$2";; --files) FILES="$2";; *) REV="$2";; esac
      shift 2;;
    --credential) CRED=1; shift;;
    --authority) AUTH=1; shift;;
    --pii) PII=1; shift;;
    --prod-traffic) PROD=1; shift;;
    --client) CLIENT=1; shift;;
    --public) PUBLIC=1; shift;;
    --site-publish) SITEPUB=1; shift;;
    --comms) COMMS=1; shift;;
    --own-noindex) OWNNOIDX=1; shift;;
    --edge-fn) CFW=1; shift;;
    --edge-auth) CFACC=1; shift;;
    --prod-data) PRODDATA=1; shift;;
    --dns-routing) DNS=1; shift;;
    --first-of-class) FIRST=1; shift;;
    --client-promise) PROMISE=1; shift;;
    -h|--help) grep '^#' "$0" | grep -v '^#!' | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "unknown flag: $1" >&2; exit 2;;
  esac
done

TIER=""; ROUTE="null"; ORDER=""; REASONS=(); CONF="high"
add() { REASONS+=("$1"); }
emit() {
  local rj="" r
  for r in "${REASONS[@]}"; do rj="$rj\"${r//\"/\\\"}\","; done
  printf '{"tier": "%s", "route": %s, "order": "%s", "reasons": [%s], "confidence": "%s"}\n' \
    "$TIER" "$ROUTE" "$ORDER" "${rj%,}" "$CONF"
  exit 0
}

# --- 1. hard event ---------------------------------------------------------------
case "$EVENT" in
  credential-install|client-capability|ticket-close|cutover|client-visible-go-live)
    TIER="T2"; ORDER="1-hard-event"
    add "hard floor '$EVENT' — critic pass required before proceeding, no discretion"; emit;;
esac
# --- 2. credentials / authority --------------------------------------------------
if [ "$CRED" = 1 ]; then TIER="T2"; ORDER="2-credentials"; add "credential lands on a host (= credential-install floor)"; emit; fi
if [ "$AUTH" = 1 ]; then TIER="T2"; ORDER="2-credentials"; add "agent gains send/write/publish authority (= client-capability floor)"; emit; fi
# --- 3. PII / data movement ------------------------------------------------------
if [ "$PII" = 1 ]; then TIER="T2"; ORDER="3-pii"; add "client/person data moves between systems"; emit; fi
if [ "$PRODDATA" = 1 ]; then TIER="T2"; ORDER="3-pii"; add "touches production database / storage data — 'internal' is not a blast radius"; emit; fi
# --- 4. production traffic -------------------------------------------------------
if [ "$PROD" = 1 ]; then TIER="T2"; ORDER="4-prod-traffic"; add "production traffic moves (= cutover floor)"; emit; fi
if [ "$DNS" = 1 ]; then TIER="T2"; ORDER="4-prod-traffic"; add "DNS/routing/access-policy/client-domain edge — edge-wide blast radius"; emit; fi
# --- 5. client / public visibility -----------------------------------------------
if [ "$COMMS" = 1 ]; then TIER="gate"; ROUTE='"comms-review"'; ORDER="5-visibility"; add "outbound comms — your comms review owns this, not the gauntlet"; emit; fi
if [ "$SITEPUB" = 1 ]; then TIER="gate"; ROUTE='"publish-review"'; ORDER="5-visibility"; add "public site content — your publish pipeline is the review"; emit; fi
if [ "$OWNNOIDX" = 1 ]; then TIER="T0"; ORDER="5-visibility"; add "own property behind noindex — own-property publish policy covers it"; emit; fi
if [ "$CLIENT" = 1 ] || [ "$PUBLIC" = 1 ]; then TIER="T2"; ORDER="5-visibility"; add "client-facing or public-indexed output"; emit; fi
if [ "$CFW" = 1 ] && [ "$CFACC" = 0 ]; then TIER="T2"; ORDER="5-visibility"; add "edge function with NO access policy = publicly reachable"; emit; fi
# --- 6. reversibility & scope ----------------------------------------------------
ORDER="6-reversibility"
if [ "$FIRST" = 1 ]; then TIER="T2"; add "first-of-class mechanism — no precedent to lean on"; emit; fi
if [ "$REV" -le 5 ] && [ "$FILES" -le 1 ]; then
  TIER="T0"; add "single-file, rolls back in <=${REV}m with a backup"
else
  TIER="T1"; add "multi-file or slower rollback (${FILES} files, ~${REV}m) — one lite critic with a live reproduction"
fi
if [ "$PROMISE" = 1 ]; then
  case "$TIER" in T0) TIER="T1";; T1) TIER="T2";; esac
  add "client-promise bump: a client was told this is coming"
fi
[ "$CFW" = 1 ] && add "edge function behind access policy — contained, but verify the policy is actually on"
emit
