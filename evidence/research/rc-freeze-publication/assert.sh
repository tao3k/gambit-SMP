#!/bin/bash
set -euo pipefail
r=.cache/tasks/rc-freeze-publication
for s in $(jq -r '.cases[].id' "$r/scenarios.json"); do
 jq -e --slurpfile i "$r/planner-input.json" '
 .runtimeAdmitted==false and .presentationComplete==true and .counts.support==0 and .counts.hypotheses==1 and
 (.modelRequired|length)==59 and (.sharedContract|length)==8 and (.sourceRoute|length)==19 and
 (.dependencyCycle|length)==0 and (.danglingDependency|length)==0 and (.unboundDependency|length)==0 and (.unroutedNeed|length)==0 and
 ((.modelRequired|map(.[1:])|sort)==([$i[0].needs[] as $q|$i[0].methods[]|select(.kind==$q.kind)|[$q.component,$q.obligationId,.method,.requiredCheck,$q.subjectPath,$q.subjectScope,$q.premise]]|sort))
 ' "$r/case-$s.json" > "$r/assert-$s.log"
 case "$s" in
 current) jq -e '(.locallyChecked|length)==24 and (.componentReady|length)==0 and (.componentFrontier|length)==35 and (.pendingCheck|length)==35' "$r/case-$s.json" >> "$r/assert-$s.log" ;;
 all-scoped-control) jq -e '(.locallyChecked|length)==59 and (.componentReady|length)==8' "$r/case-$s.json" >> "$r/assert-$s.log" ;;
 omit-generation-source|stale-generation-digest) jq -e '(.componentReady|map(.[1])|sort)==["build-planner","build-publisher","build-scheduler","continuation","gc-synchronous-publication","host-roots","resource-exit"]' "$r/case-$s.json" >> "$r/assert-$s.log" ;;
 *) jq -e '(.componentReady|map(.[1])|sort)==["build-planner","build-scheduler"]' "$r/case-$s.json" >> "$r/assert-$s.log" ;;
 esac
done
for n in FZ-CENSUS FZ-FREEZE FZ-PUBLISH FZ-CALLBACK FZ-CLEANUP FZ-MEMORY; do
 jq -e --arg n "$n" '.unmetDependency|contains([["current","host-roots","RC-DOMAIN","host-roots",$n],["current","host-roots","HR-RC","host-roots",$n],["current","host-roots","HR-S","host-roots",$n],["current","gc-work","GC-GEN","host-roots",$n]])' "$r/case-current.json" >> "$r/assert-current.log"
done
jq -e '(.qualifiedSlice|all(.[];.[2]!="FZ-I"))' "$r/case-wrong-freeze-scope.json" >> "$r/assert-wrong-freeze-scope.log"
jq -e '(.qualifiedSlice|all(.[];.[2]!="GEN-H"))' "$r/case-stale-generation-digest.json" >> "$r/assert-stale-generation-digest.log"
jq -e '(.locallyChecked|contains([["parent-only","host-roots","RC-DOMAIN"]])) and (.assuranceReady|all(.[];.[2]!="RC-DOMAIN"))' "$r/case-parent-only.json" >> "$r/assert-parent-only.log"
jq -e --slurpfile p "$r/native-projection.json" '(.sourceRoute|sort)==($p[0].sourceRoutes|map([(.need.owner.componentId//"host-roots"),.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status])|sort)' "$r/case-current.json" >> "$r/assert-current.log"
jq -e '(.edgeGroups|add|sort)==(.dependencies|sort) and (.dependencies|length)==130 and (.needs|map([.component,.obligationId])|unique|length)==59' "$r/planner-input.json" > "$r/assert-native-transport.log"
