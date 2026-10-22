#!/bin/bash
set -euo pipefail
r=.cache/tasks/gerbil-initialization-closure
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
for n in 0 1 2 3 4 5 6 7 8 9; do
 for a in key number sourceAnchor kind work limit; do field "supports.$n.$a" "GerbilSessionClosure::support$n.$a"; done
 for a in producer consumer kind; do field "supportEdges.$n.$a" "GerbilSessionClosure::edge$n.$a"; done
done
for n in 0 1 2 3 4 5 6 7; do
 for a in key sourceAnchor stateText ownership benefit; do field "domains.$n.$a" "GerbilSessionClosure::domain$n.$a"; done
done
field supportRoots 'GerbilSessionClosure::roots'
for n in 0 1 2 3; do
 for a in key sourceAnchor candidate condition cost; do field "opportunities.$n.$a" "GerbilSessionClosure::opportunity$n.$a"; done
done
field observedCensus 'GerbilSessionClosure::observedCensus'
field sessionWorkRule 'GerbilSessionClosure::workRule'
for n in 0 1 2 3 4 5 6 7 8 9; do
 for a in key ownership sourceAnchor labelText rule; do field "foundationRegions.$n.$a" "GerbilFoundationIdentity::region$n.$a"; done
 for a in producer consumer; do field "foundationEdges.$n.$a" "GerbilFoundationIdentity::edge$n.$a"; done
done
for a in definitionContext consumerContext alternateContext sourceFoundationClosed workRule; do field "foundation.$a" "GerbilFoundationIdentity::$a"; done
for n in 0 1 2 3 4; do
 for a in key baseline avoided added; do field "foundationNet.$n.$a" "GerbilFoundationIdentity::net$n.$a"; done
done
for slot in history induction source platform; do
 for a in obligationId kind subjectPath subjectScope premise owner.componentId; do field "needs.foundation-$slot.$a" "GerbilFoundationIdentity::$slot.$a"; done
done
for n in 0 1 2 3; do
 for a in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "dependencies.foundation-$n.$a" "GerbilFoundationIdentity::dependency$n.$a"; done
done
for slot in history induction source platform; do
 for a in obligationId kind subjectPath subjectScope premise owner.componentId; do field "needs.session-$slot.$a" "GerbilSessionClosure::$slot.$a"; done
done
for n in 0 1 2 3; do
 for a in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "dependencies.session-$n.$a" "GerbilSessionClosure::dependency$n.$a"; done
done
for n in 0 1 2 3 4; do
 for a in caseId condition workBoundary overhead retirement; do field "benefits.$n.$a" "GerbilPhaseReadiness::benefit$n.$a"; done
done
for n in 0 1 2 3; do
 for a in mechanism primarySource evidence reflection sourceDuty.obligationId; do field "learning.$n.$a" "GerbilPhaseReadiness::learning$n.$a"; done
done
for n in 0 1 2 3 4 5 6 7 8 9 10 11; do
 for a in key kind anchor rule; do field "initNodes.$n.$a" "GerbilInitializationClosure::node$n.$a"; done
done
for n in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17; do
 for a in producer consumer; do field "initEdges.$n.$a" "GerbilInitializationClosure::edge$n.$a"; done
done
for n in 0 1 2 3 4 5 6 7; do
 for a in key rule qualified; do field "initGates.$n.$a" "GerbilInitializationClosure::gate$n.$a"; done
done
for n in 0 1 2 3 4; do
 for a in key removed mechanism added; do field "initBenefits.$n.$a" "GerbilInitializationClosure::benefit$n.$a"; done
done
for a in observedClosure gateCount consumerCount; do field "initConfig.$a" "GerbilInitializationClosure::$a"; done
for slot in history induction source platform; do
 for a in obligationId kind subjectPath subjectScope premise owner.componentId; do field "needs.init-$slot.$a" "GerbilInitializationClosure::$slot.$a"; done
done
for n in 0 1 2 3; do
 for a in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "dependencies.init-$n.$a" "GerbilInitializationClosure::dependency$n.$a"; done
done
while IFS=$'\t' read -r k e; do args+=(-e "$e"); done < "$r/queries.tsv"
sysml "${args[@]}" dev > "$r/native.json"
jq -e '.exit==0 and ((.errors//[])|length)==0' "$r/native.json" >/dev/null
jq '[.output[]|select(startswith("  = "))|ltrimstr("  = ")|fromjson]' "$r/native.json" > "$r/values.json"
jq -Rn '[inputs|split("\t")|.[0]|split(".")|map(. as $x|try tonumber catch $x)]' "$r/queries.tsv" > "$r/keys.json"
jq -n --slurpfile k "$r/keys.json" --slurpfile v "$r/values.json" 'if ($k[0]|length)!=($v[0]|length) then error("missing value") else reduce range(0;($k[0]|length)) as $i ({};setpath($k[0][$i];$v[0][$i])) end' > "$r/projection.json"
