#!/bin/bash
set -euo pipefail
r=.cache/tasks/generational-barrier
for s in $(jq -r '.cases[].id' "$r/scenarios.json"); do
 jq -e --slurpfile i "$r/planner-input.json" '
 .runtimeAdmitted==false and .presentationComplete==true and .counts.support==0 and .counts.hypotheses==1 and
 (.modelRequired|length)==66 and (.sharedContract|length)==8 and (.sourceRoute|length)==24 and
 (.dependencyCycle|length)==0 and (.danglingDependency|length)==0 and (.unboundDependency|length)==0 and (.unroutedNeed|length)==0 and
 ((.modelRequired|map(.[1:])|sort)==([$i[0].needs[] as $q|$i[0].methods[]|select(.kind==$q.kind)|[$q.component,$q.obligationId,.method,.requiredCheck,$q.subjectPath,$q.subjectScope,$q.premise]]|sort))
 ' "$r/case-$s.json" > "$r/assert-$s.log"
 case "$s" in
 current) jq -e '(.locallyChecked|length)==26 and (.componentReady|length)==0 and (.componentFrontier|length)==40 and (.pendingCheck|length)==40' "$r/case-$s.json" >> "$r/assert-$s.log" ;;
 all-scoped-control) jq -e '(.locallyChecked|length)==66 and (.componentReady|length)==8' "$r/case-$s.json" >> "$r/assert-$s.log" ;;
 *) jq -e '(.assuranceReady|all(.[];.[2]!="GC-GEN")) and (.componentReady|all(.[];.[1]!="gc-work"))' "$r/case-$s.json" >> "$r/assert-$s.log" ;;
 esac
done
for n in WB-WRITERS WB-LOG WB-SNAPSHOT WB-PROMOTE WB-MEMORY; do
 jq -e --arg n "$n" '.unmetDependency|contains([["current","gc-work","GC-GEN","gc-work",$n]])' "$r/case-current.json" >> "$r/assert-current.log"
done
jq -e '.qualifiedSlice|all(.[];.[2]!="WB-I")' "$r/case-wrong-detail-scope.json" >> "$r/assert-wrong-detail-scope.log"
jq -e '.qualifiedSlice|all(.[];.[2]!="WB-H")' "$r/case-stale-detail-digest.json" >> "$r/assert-stale-detail-digest.log"
for s in omit-native-writers omit-control-writers; do
 jq -e --arg s "$s" '(.locallyChecked|contains([[$s,"gc-work","WB-WRITERS"]])) and (.assuranceReady|all(.[];.[2]!="WB-WRITERS"))' "$r/case-$s.json" >> "$r/assert-$s.log"
done
jq -e --slurpfile p "$r/native-projection.json" '(.sourceRoute|sort)==($p[0].sourceRoutes|map([(.need.owner.componentId//"host-roots"),.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status])|sort)' "$r/case-current.json" >> "$r/assert-current.log"
jq -e '(.edgeGroups|add|sort)==(.dependencies|sort) and (.dependencies|length)==159 and (.needs|map([.component,.obligationId])|unique|length)==66' "$r/planner-input.json" > "$r/assert-native-transport.log"
