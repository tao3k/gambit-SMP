#!/bin/bash
set -euo pipefail
r=.cache/tasks/gerbil-phase-readiness
args=(-strict -validate -json)
: > "$r/queries.tsv"
field() { printf '%s\t%s\n' "$1" "$2" >> "$r/queries.tsv"; }
i=0
for n in macroInterface phaseSupport facade expandA expandB nativeA nativeB runtimeOnly link; do
 for a in key number predecessors sourceAnchor labelText contract; do field "actions.$i.$a" "GerbilPhaseReadiness::$n.$a"; done
 i=$((i+1))
done
for spec in planner scheduler publisher; do
 for a in componentId ownerPath bindingId; do field "components.$spec.$a" "GambitBuildAssurance::$spec.component.$a"; done
 for slot in history induction source platform; do
  for a in obligationId kind subjectPath subjectScope premise owner.componentId; do field "needs.$spec-$slot.$a" "GambitBuildAssurance::$spec.$slot.$a"; done
 done
 for n in 0 1 2; do
  for a in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "dependencies.$spec-$n.$a" "GambitBuildAssurance::${spec}Dependency$n.$a"; done
 done
done
for slot in history induction source platform; do
 for a in obligationId kind subjectPath subjectScope premise owner.componentId; do field "needs.detail-$slot.$a" "GerbilPhaseReadiness::$slot.$a"; done
done
for n in 0 1 2 3 4 5; do
 for a in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "dependencies.detail-$n.$a" "GerbilPhaseReadiness::dependency$n.$a"; done
done
for m in interleaving induction sourceRefinement environmentRefinement; do
 for a in kind method requiredCheck; do field "methods.$m.$a" "GambitAssuranceRouting::$m.$a"; done
done
field benefitRule 'GerbilPhaseReadiness::benefitRule'
field cohort 'GerbilPhaseReadiness::cohort'
for n in 0 1 2 3 4; do
 for a in caseId condition workBoundary overhead retirement; do field "benefits.$n.$a" "GerbilPhaseReadiness::benefit$n.$a"; done
done
for n in 0 1 2 3; do
 for a in mechanism primarySource evidence reflection sourceDuty.obligationId; do field "learning.$n.$a" "GerbilPhaseReadiness::learning$n.$a"; done
done
while IFS=$'\t' read -r k e; do args+=(-e "$e"); done < "$r/queries.tsv"
sysml "${args[@]}" dev > "$r/native.json"
jq -e '.exit==0 and ((.errors//[])|length)==0' "$r/native.json" >/dev/null
jq '[.output[]|select(startswith("  = "))|ltrimstr("  = ")|fromjson]' "$r/native.json" > "$r/values.json"
jq -Rn '[inputs|split("\t")|.[0]|split(".")|map(. as $x|try tonumber catch $x)]' "$r/queries.tsv" > "$r/keys.json"
jq -n --slurpfile k "$r/keys.json" --slurpfile v "$r/values.json" 'if ($k[0]|length)!=($v[0]|length) then error("missing value") else reduce range(0;($k[0]|length)) as $i ({};setpath($k[0][$i];$v[0][$i])) end' > "$r/projection.json"
