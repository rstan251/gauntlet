#!/usr/bin/env bash
# Regression proof for the Step 0 gate. A gate that cannot fail the build is not a gate,
# so this asserts the DENIALS, not just the pass.
cd "$(dirname "$0")/.." || exit 2
G=./gauntlet-gate.sh; F=examples/deny-fixtures; D=$F/f4-valid; P=0; N=0
ck(){ if [ "$2" = "$3" ]; then echo "  $1: PASS (exit $2)"; P=$((P+1)); else echo "  $1: FAIL (exit $2, want $3)"; N=$((N+1)); fi; }
"$G" bar --dir "$F/f1-nobar" >/dev/null 2>&1; ck "AK-001 no-bar denied"        $? 1
"$G" bar --dir "$F/f2-vague" >/dev/null 2>&1; ck "AK-002 vague denied"         $? 1
"$G" bar --dir "$F/f6-noid"  >/dev/null 2>&1; ck "AK-003 un-id'd denied"       $? 1
"$G" bar --dir "$F/f3-fog"   >/dev/null 2>&1; ck "AK-004 fog denied"           $? 1
"$G" bar --dir "$F/f1-nobar" --reference /does/not/exist.png >/dev/null 2>&1; ck "AK-005 fake ref denied" $? 1
"$G" bar --dir "$D"          >/dev/null 2>&1; ck "AK-006 valid bar passes"     $? 0
"$G" verdict --dir "$D" --verdict "$D/v1-nosource.txt"   >/dev/null 2>&1; ck "AK-007 no bar-source denied"  $? 1
"$G" verdict --dir "$D" --verdict "$D/v2-fabricated.txt" >/dev/null 2>&1; ck "AK-008 fabricated ids denied" $? 1
"$G" verdict --dir "$D" --verdict "$D/v3-good.txt"       >/dev/null 2>&1; ck "AK-009 cited verdict passes"  $? 0
"$G" bar --dir "$F/f7-placeholder" >/dev/null 2>&1; ck "AK-013 placeholder-as-fact denied" $? 1
"$G" verdict --dir "$D" --verdict "$D/v4-noclaims.txt" >/dev/null 2>&1; ck "AK-014 no-unverified-claims-line denied" $? 1
"$G" verdict --dir "$D" --verdict "$D/v5-wrapped-fabricated.txt" >/dev/null 2>&1; ck "AK-015 fabricated id on a wrapped bar-source line denied" $? 1
"$G" verdict --dir "$D" --verdict "$D/v6-wrapped-good.txt" >/dev/null 2>&1; ck "AK-016 wrapped honest bar-source passes" $? 0
"$G" bar --dir examples/step0-self >/dev/null 2>&1;      ck "AK-010 self key passes" $? 0
bash -n "$G" >/dev/null 2>&1;                            ck "AK-012 syntax ok"       $? 0
echo "---"; echo "$P passed, $N failed"; [ "$N" -eq 0 ]
