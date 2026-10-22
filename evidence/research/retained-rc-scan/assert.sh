#!/bin/bash
set -euo pipefail
r=.cache/tasks/retained-rc-scan
for s in current all-scoped-control parent-only trace-only omit-join omit-domain omit-trace omit-commit omit-lifetime omit-memory wrong-detail-scope stale-detail-digest; do
 jq -e '.runtimeAdmitted==false and .presentationComplete==true and .counts.support==0 and .counts.hypotheses==1 and (.modelRequired|length)==48 and (.sharedContract|length)==8 and (.sourceRoute|length)==12 and (.dependencyCycle|length)==0 and (.danglingDependency|length)==0 and (.unboundDependency|length)==0 and (.unroutedNeed|length)==0' "$r/case-$s.json" > "$r/assert-$s.log"
 case "$s" in
 current) jq -e '(.locallyChecked|length)==20 and (.componentReady|length)==0 and (.componentFrontier|length)==28 and (.pendingCheck|length)==28' "$r/case-$s.json" >> "$r/assert-$s.log" ;;
 all-scoped-control) jq -e '(.locallyChecked|length)==48 and (.componentReady|map(.[1])|sort)==["build-planner","build-publisher","build-scheduler","continuation","gc-synchronous-publication","gc-work","host-roots","resource-exit"]' "$r/case-$s.json" >> "$r/assert-$s.log" ;;
 *) jq -e '(.componentReady|map(.[1])|sort)==["build-planner","build-scheduler"]' "$r/case-$s.json" >> "$r/assert-$s.log" ;;
 esac
done
for n in RC-JOIN RC-DOMAIN RC-TRACE RC-COMMIT RC-LIFETIME RC-MEMORY; do
 jq -e --arg n "$n" '.unmetDependency|contains([["current","host-roots","HR-RC","host-roots",$n],["current","host-roots","HR-S","host-roots",$n],["current","continuation","CO-S","host-roots",$n],["current","gc-work","GW-S","host-roots",$n],["current","resource-exit","RX-S","host-roots",$n],["current","gc-synchronous-publication","SP-SOURCE","host-roots",$n],["current","build-publisher","BU-S","host-roots",$n]])' "$r/case-current.json" >> "$r/assert-current.log"
done
jq -e '(.locallyChecked|contains([["parent-only","host-roots","HR-RC"],["parent-only","host-roots","HR-S"]])) and (.assuranceReady|all(.[];.[2]!="HR-RC" and .[2]!="HR-S"))' "$r/case-parent-only.json" >> "$r/assert-parent-only.log"
jq -e '.qualifiedSlice|all(.[];.[2]!="RC-I")' "$r/case-wrong-detail-scope.json" >> "$r/assert-wrong-detail-scope.log"
jq -e '.qualifiedSlice|all(.[];.[2]!="RC-H")' "$r/case-stale-detail-digest.json" >> "$r/assert-stale-detail-digest.log"
jq -e --slurpfile p "$r/native-projection.json" '(.sourceRoute|map(.[1:])|sort)==($p[0].sourceRoutes|map([.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status])|sort)' "$r/case-current.json" >> "$r/assert-current.log"
jq -e '(.edgeGroups|add|sort)==(.dependencies|sort) and (.dependencies|length)==94' "$r/planner-input.json" > "$r/assert-triple-transport.log"
