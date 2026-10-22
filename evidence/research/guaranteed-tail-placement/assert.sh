#!/bin/bash
set -euo pipefail
r=.cache/tasks/guaranteed-tail-placement
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
jq -e '(.locallyChecked|length)==24 and (.pendingCheck|length)==44 and (.componentReady|length)==0' "$r/case-current.json" > "$r/assert-current-counts.log"
jq -e '(.locallyChecked|length)==22 and (.pendingCheck|length)==34 and (.componentReady|length)==0' "$r/build-cut/case-current.json" > "$r/assert-build-counts.log"
jq -e '(.locallyChecked|length)==68 and (.componentReady|length)==4' "$r/case-all-scoped-control.json" > "$r/assert-control.log"
for s in models-only omit-placement omit-checks omit-restore omit-peak omit-root-binding wrong-detail-scope stale-detail-digest; do
 jq -e '(.assuranceReady|all(.[];.[2]!="GC-GEN")) and (.componentReady|all(.[];.[1]!="gc-work"))' "$r/case-$s.json" >> "$r/assert-control.log"
done
jq -e '.qualifiedSlice|all(.[];.[2]!="GT-I")' "$r/case-wrong-detail-scope.json" >> "$r/assert-control.log"
jq -e '.qualifiedSlice|all(.[];.[2]!="GT-H")' "$r/case-stale-detail-digest.json" >> "$r/assert-control.log"
jq -e '.locallyChecked|contains([["omit-root-binding","gc-work","GT-RESTORE"]])' "$r/case-omit-root-binding.json" >> "$r/assert-control.log"
jq -e '.assuranceReady|all(.[];.[2]!="GT-RESTORE")' "$r/case-omit-root-binding.json" >> "$r/assert-control.log"
jq -e --slurpfile i "$r/planner-full.json" '
 .runtimeAdmitted==false and .presentationComplete==true and (.qualifiedSlice|length)==0 and (.assuranceReady|length)==0 and (.modelRequired|length)==84 and
 (.sourceRoute|sort)==($i[0].sourceRoutes|map([(.need.owner.componentId//"host-roots"),.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status])|sort) and (.sourceRoute|length)==36
 ' "$r/source-routes.json" > "$r/assert-routes.log"
jq -n -e --slurpfile f "$r/planner-full.json" --slurpfile r "$r/runtime-input.json" --slurpfile b "$r/build-input.json" '
 (($r[0].needs+$b[0].needs)|unique|sort)==($f[0].needs|sort) and
 (($r[0].dependencies+$b[0].dependencies)|unique|sort)==($f[0].dependencies|sort) and
 ($f[0].needs|length)==84 and ($f[0].dependencies|length)==226 and
 ([$r[0],$b[0]]|all(.[]; . as $cut|all(.dependencies[]; . as $e|$cut.needs|any(.[]; .component==$e.prerequisiteComponent and .obligationId==$e.prerequisite)))) and
 ([$r[0],$b[0]]|all(.[]; (.edgeGroups|add|sort)==(.dependencies|sort)))
 ' > "$r/assert-cut-union.log"
jq -n --slurpfile r "$r/case-current.json" --slurpfile b "$r/build-cut/case-current.json" '($r[0].locallyChecked+$b[0].locallyChecked)|map(.[1:])|unique' > "$r/global-qualified.json"
jq -e 'length==32' "$r/global-qualified.json" > "$r/assert-global-count.log"
printf 'Native needs/edge union, all source routes, qualification scopes and transitive controls passed.\n'
