#!/bin/bash
set -euo pipefail
r=.cache/tasks/retained-rc-scan
e=evidence/research/retained-rc-scan
while IFS= read -r f; do openssl dgst -sha256 "$f"; done < "$r/artifacts.txt" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/artifact-bindings.json"
cp "$r/finalize.sh" "$r/artifacts.txt" "$e/"
rg --files --hidden --no-ignore "$e" -g '!checks.json' -g '!evidence-bindings.json' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/evidence-bindings.json"
jq --slurpfile a "$e/artifact-bindings.json" --slurpfile b "$e/evidence-bindings.json" '.artifactBindings=$a[0] | .evidenceArtifactBindings=$b[0]' "$e/checks.json" > "$r/checks-final.json"
cp "$r/checks-final.json" "$e/checks.json"
receipt_hash=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
entry_hash=$(openssl dgst -sha256 "$e/entry-traceability.json"|awk '{print $NF}')
jq --slurpfile c "$e/checks.json" --slurpfile a "$e/artifact-bindings.json" --arg hash "$receipt_hash" --arg entry "$entry_hash" '
 .kind="development-modern-c-retained-rc-scan" | .status=$c[0].status | .recordedAt=$c[0].recordedAt |
 .checks={path:"evidence/research/retained-rc-scan/checks.json",sha256:$hash} |
 .predecessor={snapshot:"evidence/research/retained-rc-scan/entry-traceability.json",sha256:$entry,scope:"Previous source studies, formal sources, receipts and failed observations preserved without native admission"} |
 .authority.retainedRoots="dev/architecture/runtime/ffi/models/sysml/retained-rc-scan.sysml" | .artifactBindings += $a[0] |
 .componentModels += {needs:48,directPrerequisites:94,currentQualifiedLocalSlices:20,currentCompleteComponents:0} |
 .componentAssurance.formalResults="evidence/research/retained-rc-scan/formal-checks.json" | .componentAssurance.closure=$c[0].closure | .componentAssurance.modelBundleSha256=$c[0].inputIdentity.modelBundleSha256 |
 .assurancePlanner={source:$c[0].authority.inference,components:8,nativeScalarFields:878,nativeModelFiles:40,scenarioCases:12,sourceRoutes:12,currentQualifiedSlices:20,currentOpenSourceNeeds:19,currentOpenPlatformNeeds:9,selectedHypotheses:1,retainedTaskHypotheses:2,supportObservations:0,runtimeAdmitted:false,crossComponentDependencies:"integrated-and-tested",conjunctiveMethodDemands:true,exactSubjectScopes:true,losslessNativeDependencyTriples:true,legacyStructuralControls:{receipt:"evidence/research/component-assurance/checks.json",rerun:false},legacyAssociationAdapterRecomputed:false} |
 .retainedRcScan={study:"dev/architecture/runtime/ffi/retained-rc-scan.org",sourceNeedsOpen:5,memoryNeedOpen:1,historyTests:15,sampledPositiveTraces:100,maxSteps:50,leanNamedStatements:11,readerWriterKernelInduction:true,wholeGcRefinement:false,nativeRefinement:false} |
 .nativeSysmlViews |= map(if .source=="dev/modeling/diagrams/component-proof-dependencies.d2" then .nodes=48 | .typedConnections=94 elif .source=="dev/architecture/runtime/ffi/diagrams/host-roots-refinement.d2" then .nodes=37 | .typedConnections=74 else . end) |
 .nativeSysmlViews += [{source:"dev/architecture/runtime/ffi/diagrams/retained-rc-scan.d2",svg:"dev/architecture/runtime/ffi/diagrams/retained-rc-scan.svg",producer:"presentation-only serialization of native SysML source routes and prerequisites; D2 elk",nodes:24,typedConnections:46,visuallyReviewed:true,structureOnly:true}] |
 .nativeSysmlViews|=unique_by(.source) |
 .execution.quintSimulation=true | .execution.runtimeImplementation=false | .execution.nativeRuntimeTesting=false | .execution.performanceValidation=false
 ' dev/traceability.json > "$r/traceability-next.json"
cp "$r/traceability-next.json" dev/traceability.json
