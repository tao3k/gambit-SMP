#!/bin/bash
set -euo pipefail
r=.cache/tasks/promotion-residual
for dir in "$r" "$r/build-cut"; do
 for s in $(jq -r '.cases[].id' "$dir/scenarios.json"); do
  jq -e --slurpfile i "$dir/planner-input.json" '
  .runtimeAdmitted==false and .presentationComplete==true and .counts.support==0 and .counts.hypotheses==1 and
  ((.modelRequired|map(.[1:])|sort)==([$i[0].needs[] as $q|$i[0].methods[]|select(.kind==$q.kind)|[$q.component,$q.obligationId,.method,.requiredCheck,$q.subjectPath,$q.subjectScope,$q.premise]]|sort)) and
  (.sourceRoute|sort)==($i[0].sourceRoutes|map([(.need.owner.componentId//"host-roots"),.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status])|sort) and
  (.dependencyCycle|length)==0 and (.danglingDependency|length)==0 and (.unboundDependency|length)==0 and (.unroutedNeed|length)==0
  ' "$dir/case-$s.json" > "$dir/assert-$s.log"
 done
done
jq -e '(.locallyChecked|length)==22 and (.pendingCheck|length)==38 and (.componentReady|length)==0' "$r/case-current.json" > "$r/assert-current-counts.log"
jq -e '(.locallyChecked|length)==22 and (.pendingCheck|length)==34 and (.componentReady|length)==0' "$r/build-cut/case-current.json" > "$r/assert-build-counts.log"
jq -e '(.locallyChecked|length)==60 and (.componentReady|length)==5' "$r/case-all-scoped-control.json" > "$r/assert-control.log"
for s in models-only omit-bound omit-residual omit-ffi omit-memory omit-host-freeze wrong-detail-scope stale-detail-digest; do
 jq -e '(.assuranceReady|all(.[];.[2]!="GC-GEN")) and (.componentReady|all(.[];.[1]!="gc-work"))' "$r/case-$s.json" >> "$r/assert-control.log"
done
jq -e '.qualifiedSlice|all(.[];.[2]!="PR-I")' "$r/case-wrong-detail-scope.json" >> "$r/assert-control.log"
jq -e '.qualifiedSlice|all(.[];.[2]!="PR-H")' "$r/case-stale-detail-digest.json" >> "$r/assert-control.log"
jq -e '.locallyChecked|contains([["omit-host-freeze","gc-work","PR-FFI"]])' "$r/case-omit-host-freeze.json" >> "$r/assert-control.log"
jq -e '.assuranceReady|all(.[];.[2]!="PR-FFI")' "$r/case-omit-host-freeze.json" >> "$r/assert-control.log"
jq -n -e --slurpfile f "$r/planner-full.json" --slurpfile r "$r/runtime-input.json" --slurpfile b "$r/build-input.json" '
 ([($r[0].needs+$b[0].needs)[]]|unique|sort)==($f[0].needs|sort) and
 (($r[0].dependencies+$b[0].dependencies)|unique|sort)==($f[0].dependencies|sort) and
 ($f[0].needs|length)==72 and ($f[0].dependencies|length)==179 and
 ([$r[0],$b[0]]|all(.[]; . as $cut|all(.dependencies[]; . as $e|$cut.needs|any(.[]; .component==$e.prerequisiteComponent and .obligationId==$e.prerequisite)))) and
 ([$r[0],$b[0]]|all(.[]; (.edgeGroups|add|sort)==(.dependencies|sort)))
 ' > "$r/assert-cut-union.log"
jq -n --slurpfile r "$r/case-current.json" --slurpfile b "$r/build-cut/case-current.json" '($r[0].locallyChecked+$b[0].locallyChecked)|map(.[1:])|unique' > "$r/global-qualified.json"
jq -e 'length==28' "$r/global-qualified.json" > "$r/assert-global-count.log"
printf 'Exact native cut union, scopes, source routes and negative controls passed.\n'
