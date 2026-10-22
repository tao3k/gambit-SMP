#!/bin/bash
set -euo pipefail
r=.cache/tasks/generational-barrier
e=evidence/research/generational-barrier
bash "$r/retain.sh"
while IFS= read -r f; do openssl dgst -sha256 "$f"; done < "$r/artifacts.txt" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/artifact-bindings.json"
cp "$r/finalize.sh" "$r/artifacts.txt" "$e/"
rg --files --hidden --no-ignore "$e" -g '!checks.json' -g '!evidence-bindings.json' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/evidence-bindings.json"
jq --slurpfile a "$e/artifact-bindings.json" --slurpfile b "$e/evidence-bindings.json" '.artifactBindings=$a[0]|.evidenceArtifactBindings=$b[0]' "$e/checks.json" > "$r/checks-final.json"
cp "$r/checks-final.json" "$e/checks.json"
receipt_hash=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
entry_hash=$(openssl dgst -sha256 "$e/entry-traceability.json"|awk '{print $NF}')
jq --slurpfile c "$e/checks.json" --slurpfile a "$e/artifact-bindings.json" --arg hash "$receipt_hash" --arg entry "$entry_hash" '
 .kind="development-modern-c-generational-barrier-amplification" | .status=$c[0].status | .recordedAt=$c[0].recordedAt |
 .checks={path:"evidence/research/generational-barrier/checks.json",sha256:$hash} |
 .predecessor={snapshot:"evidence/research/generational-barrier/entry-traceability.json",sha256:$entry,scope:"Previous source/formal/native boundaries and receipts retained"} |
 .authority.generationalBarrier=$c[0].authority.barrier | .artifactBindings += $a[0] |
 .componentModels += {needs:66,directPrerequisites:159,currentQualifiedLocalSlices:26,currentCompleteComponents:0} |
 .componentAssurance.formalResults="evidence/research/generational-barrier/formal-checks.json" | .componentAssurance.closure=$c[0].closure | .componentAssurance.modelBundleSha256=$c[0].inputIdentity.modelBundleSha256 |
 .assurancePlanner={source:$c[0].authority.inference,components:8,nativeScalarFields:$c[0].structure.nativeEvaluatedScalars,nativeModelFiles:43,scenarioCases:13,sourceRoutes:24,currentQualifiedSlices:26,currentOpenSourceNeeds:29,currentOpenPlatformNeeds:11,selectedHypotheses:1,retainedTaskHypotheses:$c[0].reasoning.retainedTaskHypotheses,supportObservations:0,runtimeAdmitted:false,crossComponentDependencies:"integrated-and-tested",conjunctiveMethodDemands:true,exactSubjectScopes:true,losslessNativeNeedTriples:true,losslessNativeDependencyGroups:true,losslessSubjectAndRouteTransport:true,legacyStructuralControls:{receipt:"evidence/research/component-assurance/checks.json",rerun:false},legacyAssociationAdapterRecomputed:false} |
 .generationalBarrier={study:"dev/architecture/runtime/gc/generational-barrier-design.org",matrix:"dev/architecture/runtime/gc/generational-barrier-matrix.org",histories:26,leanNamedStatements:14,positiveSamples:100,maxSteps:80,writerFamilies:10,amplificationCases:6,typedSchemas:3,typedLaws:3,wholeSourceOrProductProof:false,modernCMandatory:true} |
 .nativeSysmlViews |= map(if .source=="dev/modeling/diagrams/component-proof-dependencies.d2" then .nodes=66 | .typedConnections=159 | .visuallyReviewed=false | .topologyChecked=true else . end) |
 .nativeSysmlViews += [{source:"dev/architecture/runtime/gc/diagrams/generational-barrier.d2",svg:"dev/architecture/runtime/gc/diagrams/generational-barrier.svg",producer:"native SysML ViewNode/ViewEdge projection; two return edges in captions; D2 elk",nodes:11,typedConnections:13,arrowConnections:11,returnConnectionsInCaptions:2,visuallyReviewed:true,structureOnly:true}] |
 .nativeSysmlViews|=unique_by(.source) |
 .execution.runtimeImplementation=false | .execution.nativeRuntimeTesting=false | .execution.performanceValidation=false
 ' dev/traceability.json > "$r/traceability-next.json"
cp "$r/traceability-next.json" dev/traceability.json
