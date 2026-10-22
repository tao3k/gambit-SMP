#!/bin/bash
# Native evaluation and structural transport only; policy remains in SysML/ASCENT.
set -euo pipefail
r=.cache/tasks/generational-barrier
: > "$r/native-queries.tsv"
field() { printf '%s\t%s\n' "$1" "$2" >> "$r/native-queries.tsv"; }
idx=0
for study_ref in GambitBuildAssurance::planner GambitBuildAssurance::scheduler GambitBuildAssurance::publisher GambitRuntimeAssurance::work GambitRuntimeAssurance::roots GambitRuntimeAssurance::control GambitRuntimeAssurance::release; do
 field "components.$idx.id" "$study_ref.component.componentId"
 field "components.$idx.owner" "$study_ref.component.ownerPath"
 field "components.$idx.binding" "$study_ref.component.bindingId"
 for attr in quintSource quintScope baselineModel leanSource leanScope sourcePath sourceAnchors stateProjection eventProjection invariant abstractionBoundary; do field "components.$idx.$attr" "$study_ref.$attr"; done
 for slot in history induction source platform; do
  for attr in obligationId kind premise subjectPath subjectScope; do field "components.$idx.needs.$slot.$attr" "$study_ref.$slot.$attr"; done
 done
 idx=$((idx+1))
done
p=GambitSynchronousPublication
field components.7.id "$p::component.componentId"
field components.7.owner "$p::component.ownerPath"
field components.7.binding "$p::component.bindingId"
field components.7.quintSource "$p::modelSet.quintSource"
field components.7.leanSource "$p::modelSet.leanSource"
field components.7.stateProjection "$p::component.stateProjection"
field components.7.eventProjection "$p::component.eventProjection"
field components.7.abstractionBoundary "$p::component.openPremises"
for spec in history:0 induction:1 source:2 platform:3; do
 slot=${spec%:*}; number=${spec#*:}
 for attr in obligationId kind premise subjectPath subjectScope; do field "components.7.needs.$slot.$attr" "$p::need$number.$attr"; done
done
idx=0
for method_name in interleaving induction sourceRefinement nativeMemoryOrder environmentRefinement; do
 for attr in kind method requiredCheck; do field "methods.$idx.$attr" "GambitAssuranceRouting::$method_name.$attr"; done
 idx=$((idx+1))
done
idx=0
for study_ref in GambitBuildAssurance::planner GambitBuildAssurance::scheduler GambitBuildAssurance::publisher GambitRuntimeAssurance::work GambitRuntimeAssurance::roots GambitRuntimeAssurance::control GambitRuntimeAssurance::release; do
 for num in 0 1 2; do
  for attr in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "dependencies.$idx.$attr" "${study_ref}Dependency$num.$attr"; done
  idx=$((idx+1))
 done
done
for num in 0 1 2; do
 for attr in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "dependencies.$idx.$attr" "GambitSynchronousPublication::dependency$num.$attr"; done
 idx=$((idx+1))
done
for num in {0..15}; do
 for attr in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "dependencies.$idx.$attr" "GambitComponentAssurance::dependency$num.$attr"; done
 idx=$((idx+1))
done
for num in {0..7}; do
 for attr in contractId producer.componentId consumer.componentId phaseScope guarantee rely failureCustodian; do field "contracts.$num.$attr" "GambitComponentAssurance::contract$num.$attr"; done
done
idx=0
for need in history induction rc marker boot exitState bindingState dynamic; do
 for attr in obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$attr" "GambitHostRootsRefinement::$need.$attr"; done
 idx=$((idx+1))
done
for num in {0..25}; do
 for attr in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "refinementDependencies.$num.$attr" "GambitHostRootsRefinement::dependency$num.$attr"; done
done
idx=0
for route in rc marker boot exitState bindingState dynamic; do
 for attr in need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$attr" "GambitHostRootsRefinement::${route}Route.$attr"; done
 idx=$((idx+1))
done
idx=8
for need in history induction joinResult membership tracing commitState lifetime memoryOrder; do
 for attr in obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$attr" "GambitRetainedRcScan::$need.$attr"; done
 idx=$((idx+1))
done
for num in {0..27}; do
 idx=$((num+26))
 for attr in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "refinementDependencies.$idx.$attr" "GambitRetainedRcScan::dependency$num.$attr"; done
done
idx=6
for route in joinResult membership tracing commitState lifetime memoryOrder; do
 for attr in need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$attr" "GambitRetainedRcScan::${route}Route.$attr"; done
 idx=$((idx+1))
done
for attr in identity membership freeze scanSnapshot trace commit acknowledgement physicalLifetime capacity memoryOrder quarantine; do field "retainedProtocol.$attr" "GambitRetainedRcScan::protocol.$attr"; done
for attr in rootComponent.componentId collectorComponent.componentId; do field "retainedProtocol.$attr" "GambitRetainedRcScan::protocol.$attr"; done
idx=16
for need in history induction census freeze publication callback cleanup memoryOrder; do
 for attr in owner.componentId obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$attr" "GambitRcFreezePublication::$need.$attr"; done
 idx=$((idx+1))
done
for need in history induction source; do
 for attr in owner.componentId obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$attr" "GambitGenerationalAdmission::$need.$attr"; done
 idx=$((idx+1))
done
idx=54
for spec in GambitRcFreezePublication:28 GambitGenerationalAdmission:6; do
 package=${spec%:*}; last=${spec#*:}
 for ((n=0;n<=last;n++)); do
  for attr in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "refinementDependencies.$idx.$attr" "$package::dependency$n.$attr"; done
  idx=$((idx+1))
 done
done
idx=12
for n in census freeze publication callback cleanup memoryOrder; do
 for attr in need.owner.componentId need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$attr" "GambitRcFreezePublication::${n}Route.$attr"; done
 idx=$((idx+1))
done
for attr in need.owner.componentId need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$attr" "GambitGenerationalAdmission::sourceRoute.$attr"; done
for attr in identity preparation close receipt publication mutation collector deletion cleanup unknown; do field "freezeProtocol.$attr" "GambitRcFreezePublication::protocol.$attr"; done
for attr in allocationPolicy minor mature stores overflow roots continuation ffi major retirement; do field "generationalPolicy.$attr" "GambitGenerationalAdmission::candidate.$attr"; done
idx=0
for n in primitive converter dynamic tcl release resources exports; do
 for attr in routeId sourceAnchors authority obligation boundary; do field "census.$idx.$attr" "GambitRcFreezePublication::$n.$attr"; done
 idx=$((idx+1))
done
idx=0
for n in scheme stores nursery remembered domains minor mature major release ffi; do
 for attr in nodeId labelText; do field "viewNodes.$idx.$attr" "GambitGenerationalAdmission::$n.$attr"; done
 idx=$((idx+1))
done
for n in {0..11}; do
 for attr in producer.nodeId consumer.nodeId labelText; do field "viewEdges.$n.$attr" "GambitGenerationalAdmission::edge$n.$attr"; done
done
idx=27
for n in history induction writers logs scanCut promotion memoryOrder; do
 for a in owner.componentId obligationId kind premise subjectPath subjectScope; do field "refinementNeeds.$idx.$a" "GambitGenerationalBarrier::$n.$a"; done
 idx=$((idx+1))
done
for n in {0..28}; do
 idx=$((90+n))
 for a in dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId; do field "refinementDependencies.$idx.$a" "GambitGenerationalBarrier::dependency$n.$a"; done
done
idx=19
for n in writers logs scanCut promotion memoryOrder; do
 for a in need.owner.componentId need.obligationId sourceAnchors patchAnchors projection failureCustodian status; do field "sourceRoutes.$idx.$a" "GambitGenerationalBarrier::${n}Route.$a"; done
 idx=$((idx+1))
done
for a in authority fastPath overflow cut rootStore publication promotion failure elision scopeBoundary; do field "barrierProtocol.$a" "GambitGenerationalBarrier::protocol.$a"; done
for n in {0..9}; do
 for a in writerId sourceAnchors actualChain storeClass boundary; do field "barrierWriters.$n.$a" "GambitGenerationalBarrier::writer$n.$a"; done
done
for n in {0..5}; do
 for a in capability mechanism removedWork addedWork condition falsifier; do field "amplification.$n.$a" "GambitGenerationalBarrier::benefit$n.$a"; done
done
idx=0
for n in semantic writeOp cards hints cut capacity pendingCopy readyCopy complete retry quarantine; do
 for a in nodeId labelText; do field "barrierNodes.$idx.$a" "GambitGenerationalBarrier::$n.$a"; done
 idx=$((idx+1))
done
for n in {0..12}; do
 for a in producer.nodeId consumer.nodeId labelText; do field "barrierEdges.$n.$a" "GambitGenerationalBarrier::edge$n.$a"; done
done
args=(-strict -validate -json)
while IFS=$'\t' read -r key expression; do args+=(-e "$expression"); done < "$r/native-queries.tsv"
rg --files dev -g '*.sysml' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort > "$r/models-before.sha256"
sysml "${args[@]}" dev > "$r/native-metadata.json"
jq -e '.exit==0 and ((.errors//[])|length)==0' "$r/native-metadata.json" >/dev/null
jq '[.output[]|select(startswith("  = "))|ltrimstr("  = ")|fromjson]' "$r/native-metadata.json" > "$r/native-values.json"
jq -Rn '[inputs|split("\t")|.[0]|split(".")|map(. as $s | try tonumber catch $s)]' "$r/native-queries.tsv" > "$r/native-keys.json"
jq -n --slurpfile k "$r/native-keys.json" --slurpfile v "$r/native-values.json" 'if ($k[0]|length)!=($v[0]|length) or ($v[0]|any(.[];type!="string")) then error("Incomplete/non-scalar native evaluation") else reduce range(0;($k[0]|length)) as $i ({};setpath($k[0][$i];$v[0][$i])) end' > "$r/native-projection.json"
jq '[.components[]|{id,owner,binding,quintSource,leanSource,needs}]' "$r/native-projection.json" > "$r/component-models.json"
