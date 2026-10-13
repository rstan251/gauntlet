#!/usr/bin/env bash
# Selftest for gauntlet-triage.sh — asserts tier/route per spec,
# including the blast-radius corrections and the evaluation ordering. JSON out, exit 0 always
# on classification; nonzero only for usage errors (asserted too).
cd "$(dirname "$0")/.." || exit 2
T=./gauntlet-triage.sh; P=0; N=0
want(){ # name, expected-substring, flags...
  local name="$1" exp="$2"; shift 2
  local out rc; out=$($T "$@" 2>&1); rc=$?
  if [ $rc -eq 0 ] && printf '%s' "$out" | grep -q "$exp"; then
    echo "  $name: PASS"; P=$((P+1))
  else
    echo "  $name: FAIL (rc=$rc, got: ${out:0:110})"; N=$((N+1))
  fi
}
want "TS-01 hard event -> T2"                 '"tier": "T2", "route": null, "order": "1-hard-event"'  --event cutover
want "TS-02 5th floor recognized"             '"order": "1-hard-event"'                               --event client-visible-go-live
want "TS-03 credential -> T2 order 2"         '"order": "2-credentials"'                              --credential
want "TS-04 authority grant -> T2"            '"order": "2-credentials"'                              --authority
want "TS-05 PII movement -> T2 order 3"       '"order": "3-pii"'                                      --pii
want "TS-06 prod data -> T2"                  'not a blast radius'                                    --edge-fn --edge-auth --prod-data
want "TS-07 edge fn w/o access -> T2"         'NO access policy'                                      --edge-fn
want "TS-08 edge fn WITH access -> T1"        '"tier": "T1"'                                          --edge-fn --edge-auth --files 3
want "TS-09 comms routes to gate"             '"route": "comms-review"'                                 --comms
want "TS-10 own site routes to gate"          '"route": "publish-review"'                           --site-publish
want "TS-11 own noindex -> T0"                '"tier": "T0"'                                          --own-noindex
want "TS-12 single reversible file -> T0"     '"tier": "T0"'                                          --files 1 --reversible-mins 3
want "TS-13 multi-file -> T1"                 '"tier": "T1"'                                          --files 4 --reversible-mins 10
want "TS-14 first-of-class -> T2"             'first-of-class'                                        --files 2 --first-of-class
want "TS-15 client-promise bumps T1->T2"      '"tier": "T2"'                                          --files 4 --client-promise
want "TS-16 ordering: pii beats visibility"   '"order": "3-pii"'                                      --pii --client
# exit-code discipline: classification always 0; bad flag nonzero
$T --files 1 >/dev/null 2>&1;        [ $? -eq 0 ] && { echo "  TS-17 classify exit 0: PASS"; P=$((P+1)); } || { echo "  TS-17 FAIL"; N=$((N+1)); }
$T --bogus-flag >/dev/null 2>&1;     [ $? -ne 0 ] && { echo "  TS-18 bad flag nonzero: PASS"; P=$((P+1)); } || { echo "  TS-18 FAIL"; N=$((N+1)); }
echo "---"; echo "$P passed, $N failed"; [ "$N" -eq 0 ]
