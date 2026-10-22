#!/bin/bash
set -euo pipefail
r=.cache/tasks/host-roots-refinement
e=evidence/research/host-roots-refinement
while IFS= read -r f; do openssl dgst -sha256 "$f"; done < "$r/artifacts.txt" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/artifact-bindings.json"
cp "$r/finalize.sh" "$r/artifacts.txt" "$e/"
rg --files --hidden --no-ignore "$e" -g '!checks.json' -g '!evidence-bindings.json' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/evidence-bindings.json"
jq --slurpfile a "$e/artifact-bindings.json" --slurpfile b "$e/evidence-bindings.json" '.artifactBindings=$a[0] | .evidenceArtifactBindings=$b[0]' "$e/checks.json" > "$r/checks-final.json"
cp "$r/checks-final.json" "$e/checks.json"
receipt_hash=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
entry_hash=$(openssl dgst -sha256 "$e/entry-traceability.json"|awk '{print $NF}')
jq --slurpfile c "$e/checks.json" --slurpfile a "$e/artifact-bindings.json" --arg hash "$receipt_hash" --arg entry "$entry_hash" '
 .kind="development-modern-c-host-roots-refinement" | .status=$c[0].status | .recordedAt=$c[0].recordedAt |
 .checks={path:"evidence/research/host-roots-refinement/checks.json",sha256:$hash} |
 .predecessor={snapshot:"evidence/research/host-roots-refinement/entry-traceability.json",sha256:$entry,scope:"Previous 32-need receipt, legacy registry and failures retained; no native proof promotion"} |
 .authority.hostRoots="dev/architecture/runtime/ffi/models/sysml/host-roots-refinement.sysml" |
 .artifactBindings += $a[0] |
 .componentModels += {needs:40,directPrerequisites:66,currentQualifiedLocalSlices:18,currentCompleteComponents:0} |
 .componentAssurance.formalResults="evidence/research/host-roots-refinement/formal-checks.json" |
 .componentAssurance.closure=$c[0].closure | .componentAssurance.modelBundleSha256=$c[0].inputIdentity.modelBundleSha256 |
 .assurancePlanner={source:$c[0].authority.inference,components:8,nativeScalarFields:677,nativeModelFiles:39,scenarioCases:12,sourceRoutes:6,currentQualifiedSlices:18,currentOpenSourceNeeds:14,currentOpenPlatformNeeds:8,selectedHypotheses:1,supportObservations:0,runtimeAdmitted:false,crossComponentDependencies:"integrated-and-tested",conjunctiveMethodDemands:true,exactSubjectScopes:true,legacyStructuralControls:{receipt:"evidence/research/component-assurance/checks.json",rerun:false},legacyAssociationAdapterRecomputed:false} |
 .hostRootsRefinement={study:"dev/architecture/runtime/ffi/host-roots-refinement.org",sourceRoutes:6,sourceRoutesOpen:6,historyTests:14,leanNamedStatements:9,sharedConsumers:5,sourceRefinement:"open",nativeMemoryRefinement:"open",existingPatchCredited:true} |
 .nativeSysmlViews |= map(if .source=="dev/modeling/diagrams/component-proof-dependencies.d2" then .nodes=40 | .typedConnections=66 else . end) |
 .nativeSysmlViews += [{source:"dev/architecture/runtime/ffi/diagrams/host-roots-refinement.d2",svg:"dev/architecture/runtime/ffi/diagrams/host-roots-refinement.svg",producer:"presentation-only serialization of native SysML source routes and prerequisites; D2 elk",nodes:23,typedConnections:40,visuallyReviewed:true,structureOnly:true}] |
 .nativeSysmlViews|=unique_by(.source) |
 .execution.runtimeImplementation=false | .execution.nativeRuntimeTesting=false | .execution.performanceValidation=false
 ' dev/traceability.json > "$r/traceability-next.json"
cp "$r/traceability-next.json" dev/traceability.json
