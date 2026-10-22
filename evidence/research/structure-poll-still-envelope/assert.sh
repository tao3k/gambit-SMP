#!/bin/bash
set -euo pipefail
r=.cache/tasks/structure-poll-still-envelope
for dir in "$r" "$r/build-cut"; do
 for s in $(jq -r '.cases[].id' "$dir/scenarios.json"); do
  jq -e --slurpfile i "$dir/planner-input.json" '
  .runtimeAdmitted==false and .presentationComplete==true and .counts.support==0 and .counts.hypotheses==1 and
  ((.modelRequired|map(.[1:])|sort)==([$i[0].needs[] as $q|$i[0].methods[]|select(.kind==$q.kind)|[$q.component,$q.obligationId,.method,.requiredCheck,$q.subjectPath,$q.subjectScope,$q.premise]]|sort)) and
  (.sourceRoute|length)==0 and
  (.dependencyCycle|length)==0 and (.danglingDependency|length)==0 and (.unboundDependency|length)==0 and (.unroutedNeed|length)==0
  ' "$dir/case-$s.json" > "$dir/assert-$s.log"
 done
done
jq -e '(.locallyChecked|length)==28 and (.pendingCheck|length)==52 and (.componentReady|length)==0' "$r/case-current.json" > "$r/assert-current-counts.log"
jq -e '(.locallyChecked|length)==22 and (.pendingCheck|length)==34 and (.componentReady|length)==0' "$r/build-cut/case-current.json" > "$r/assert-build-counts.log"
jq -e '(.locallyChecked|length)==80 and (.componentReady|length)==4' "$r/case-all-scoped-control.json" > "$r/assert-control.log"
for s in models-only omit-placement omit-checks omit-restore omit-peak omit-root-binding wrong-detail-scope stale-detail-digest; do
 jq -e '(.assuranceReady|all(.[];.[2]!="GC-GEN")) and (.componentReady|all(.[];.[1]!="gc-work"))' "$r/case-$s.json" >> "$r/assert-control.log"
done
jq -e '.qualifiedSlice|all(.[];.[2]!="SP-I")' "$r/case-wrong-detail-scope.json" >> "$r/assert-control.log"
jq -e '.qualifiedSlice|all(.[];.[2]!="SP-H")' "$r/case-stale-detail-digest.json" >> "$r/assert-control.log"
jq -e '.locallyChecked|contains([["omit-root-binding","gc-work","SP-POLL"]])' "$r/case-omit-root-binding.json" >> "$r/assert-control.log"
jq -e '.assuranceReady|all(.[];.[2]!="SP-POLL")' "$r/case-omit-root-binding.json" >> "$r/assert-control.log"
jq -n -e --slurpfile f "$r/planner-full.json" --slurpfile r "$r/runtime-input.json" --slurpfile b "$r/build-input.json" '
 (($r[0].needs+$b[0].needs)|unique|sort)==($f[0].needs|sort) and
 (($r[0].dependencies+$b[0].dependencies)|unique|sort)==($f[0].dependencies|sort) and
 ($f[0].needs|length)==96 and ($f[0].dependencies|length)==272 and
 ([$r[0],$b[0]]|all(.[]; . as $cut|all(.dependencies[]; . as $e|$cut.needs|any(.[]; .component==$e.prerequisiteComponent and .obligationId==$e.prerequisite)))) and
 ([$r[0],$b[0]]|all(.[]; (.edgeGroups|add|sort)==(.dependencies|sort)))
 ' > "$r/assert-cut-union.log"
jq -n --slurpfile r "$r/case-current.json" --slurpfile b "$r/build-cut/case-current.json" '($r[0].locallyChecked+$b[0].locallyChecked)|map(.[1:])|unique' > "$r/global-qualified.json"
jq -e 'length==36' "$r/global-qualified.json" > "$r/assert-global-count.log"
printf 'Native needs/edge union, all source routes, qualification scopes and transitive controls passed.\n'

for suffix in '' '-tail'; do
 jq -e --slurpfile i "$r/source-routes$suffix-input.json" '
 .runtimeAdmitted==false and .presentationComplete==true and
 (.qualifiedSlice|length)==0 and (.assuranceReady|length)==0 and (.modelRequired|length)==96 and
 (.sourceRoute|sort)==($i[0].sourceRoutes|map([(.need.owner.componentId//"host-roots"),.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status])|sort) and
 (.sharedContract|sort)==($i[0].contracts|map([.contractId,.producer.componentId,.consumer.componentId,.phaseScope,.guarantee,.rely,.failureCustodian])|sort)
 ' "$r/source-routes$suffix.json" >/dev/null
done
jq -n -e --slurpfile a "$r/source-routes.json" --slurpfile b "$r/source-routes-tail.json" --slurpfile p "$r/planner-full.json" '
 (($a[0].sourceRoute+$b[0].sourceRoute)|sort)==($p[0].sourceRoutes|map([(.need.owner.componentId//"host-roots"),.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status])|sort) and
 (($a[0].sharedContract+$b[0].sharedContract)|sort)==($p[0].contracts|map([.contractId,.producer.componentId,.consumer.componentId,.phaseScope,.guarantee,.rely,.failureCustodian])|sort)
 ' >/dev/null
jq -e '(.sharedContract|length)==0' "$r/case-current.json" >/dev/null
jq -e --slurpfile q "$r/inherited.json" '(.qualifiedSlice|map(.[2])|sort)==([$q[0][].need,"SP-H","SP-I"]|sort)' <(jq -s '{qualifiedSlice:([.[].qualifiedSlice[]]|unique)}' "$r/case-current.json" "$r/build-cut/case-current.json") >/dev/null
jq -e '(.qualifiedSlice|all(.[];.[2]!="SP-H")) and (.qualifiedSlice|any(.[];.[2]=="SP-I")) and (.componentReady|all(.[];.[1]!="gc-work"))' "$r/case-paired-stale-detail.json" >/dev/null
jq -e '(.qualifiedSlice|all(.[];.[2]!="SP-H" and .[2]!="SP-I")) and (.componentReady|all(.[];.[1]!="gc-work"))' "$r/case-paired-nonpass-status.json" >/dev/null
