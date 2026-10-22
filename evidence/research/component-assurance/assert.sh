#!/bin/bash
set -euo pipefail
r=.cache/tasks/component-assurance
for scenario_id in $(jq -r 'keys[]' "$r/expected.json"); do
 jq -e --arg s "$scenario_id" --slurpfile e "$r/expected.json" '
 .runtimeAdmitted==false and .presentationComplete==true and .counts.support==0 and .counts.hypotheses==1 and
 ((.componentReady|map(.[1])|sort)==($e[0][$s]|sort)) and
 (.modelRequired|length==32) and (.sharedContract|length==8)
 ' "$r/case-$scenario_id.json" > "$r/assert-$scenario_id.log"
done
jq -e '(.locallyChecked|length==16) and (.qualifiedSlice|length==16) and (.componentFrontier|length==16)' "$r/case-current.json"
jq -e '.unmetDependency|contains([["grandparent-gap","build-publisher","BU-S","host-roots","HR-M"]])' "$r/case-grandparent-gap.json"
jq -e '.locallyChecked|contains([["grandparent-gap","host-roots","HR-S"],["grandparent-gap","continuation","CO-S"],["grandparent-gap","build-publisher","BU-S"]])' "$r/case-grandparent-gap.json"
jq -e '.missingModel|contains([["missing-subject","gc-work","GW-H","QNT"]])' "$r/case-missing-subject.json"
jq -e '.dependencyCycle|contains([["host-roots","HR-H"],["host-roots","HR-S"],["continuation","CO-S"]])' "$r/control-cycle.json"
jq -e '.unroutedNeed|contains([["all-scoped-control","host-roots","HR-X","unmapped-control"]])' "$r/control-unrouted.json"
jq -e '.danglingDependency|contains([["all-scoped-control","gc-work","GW-S","absent-component","MISSING"]])' "$r/control-dangling.json"
jq -e '.unboundDependency|contains([["all-scoped-control","gc-work","GW-S","host-roots","HR-S"]])' "$r/control-unbound.json"
jq -e '(.locallyChecked|all(.[];.[2]!="BP-I" and .[2]!="BS-I" and .[2]!="BU-I" and .[2]!="GW-I" and .[2]!="HR-I" and .[2]!="CO-I" and .[2]!="RX-I" and .[2]!="SP-INDUCTION")) and (.componentReady|length==0) and (.qualifiedSlice|length==32)' "$r/control-multi-method.json"
for control_name in cycle unrouted dangling unbound multi-method; do
 jq -e '.runtimeAdmitted==false and .presentationComplete==true and .counts.support==0 and .counts.hypotheses==1' "$r/control-$control_name.json" > "$r/assert-$control_name.log"
done
for control_name in cycle unrouted dangling unbound multi-method; do
 jq -e --arg s "$control_name" --slurpfile e "$r/expected-structural.json" '(.componentReady|map(.[1])|sort)==($e[0][$s]|sort)' "$r/control-$control_name.json" >> "$r/assert-$control_name.log"
done
