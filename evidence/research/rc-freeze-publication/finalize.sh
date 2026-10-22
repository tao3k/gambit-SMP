#!/bin/bash
set -euo pipefail
r=.cache/tasks/rc-freeze-publication
e=evidence/research/rc-freeze-publication
# No model/proof rerun here: bind the already checked final bytes.
bash "$r/retain.sh"
while IFS= read -r f; do openssl dgst -sha256 "$f"; done < "$r/artifacts.txt" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/artifact-bindings.json"
cp "$r/finalize.sh" "$r/artifacts.txt" "$e/"
rg --files --hidden --no-ignore "$e" -g '!checks.json' -g '!evidence-bindings.json' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/evidence-bindings.json"
jq --slurpfile a "$e/artifact-bindings.json" --slurpfile b "$e/evidence-bindings.json" '.artifactBindings=$a[0]|.evidenceArtifactBindings=$b[0]' "$e/checks.json" > "$r/checks-final.json"
cp "$r/checks-final.json" "$e/checks.json"
receipt_hash=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
entry_hash=$(openssl dgst -sha256 "$e/entry-traceability.json"|awk '{print $NF}')
jq --slurpfile c "$e/checks.json" --slurpfile a "$e/artifact-bindings.json" --arg hash "$receipt_hash" --arg entry "$entry_hash" '
 .kind="development-modern-c-generational-native-freeze" | .status=$c[0].status | .recordedAt=$c[0].recordedAt |
 .checks={path:"evidence/research/rc-freeze-publication/checks.json",sha256:$hash} |
 .predecessor={snapshot:"evidence/research/rc-freeze-publication/entry-traceability.json",sha256:$entry,scope:"Previous source/formal/native boundaries and failure receipts preserved"} |
 .authority.nativeFreeze=$c[0].authority.nativeFreeze | .authority.generational=$c[0].authority.generational |
 .artifactBindings += $a[0] |
 .componentModels += {needs:59,directPrerequisites:130,currentQualifiedLocalSlices:24,currentCompleteComponents:0} |
 .componentAssurance.formalResults="evidence/research/rc-freeze-publication/formal-checks.json" | .componentAssurance.closure=$c[0].closure | .componentAssurance.modelBundleSha256=$c[0].inputIdentity.modelBundleSha256 |
 .assurancePlanner={source:$c[0].authority.inference,components:8,nativeScalarFields:1248,nativeModelFiles:42,scenarioCases:13,sourceRoutes:19,currentQualifiedSlices:24,currentOpenSourceNeeds:25,currentOpenPlatformNeeds:10,selectedHypotheses:1,retainedTaskHypotheses:$c[0].reasoning.retainedTaskHypotheses,supportObservations:0,runtimeAdmitted:false,crossComponentDependencies:"integrated-and-tested",conjunctiveMethodDemands:true,exactSubjectScopes:true,losslessNativeNeedTriples:true,losslessNativeDependencyGroups:true,legacyStructuralControls:{receipt:"evidence/research/component-assurance/checks.json",rerun:false},legacyAssociationAdapterRecomputed:false} |
 .generationalNativeFreeze={study:"dev/architecture/runtime/gc/modern-c-generational-design.org",freezeStudy:"dev/architecture/runtime/ffi/rc-freeze-publication.org",histories:22,leanNamedStatements:12,positiveSamplesPerModel:100,maxSteps:50,fullCollectorOrProductProof:false,sourceRefinement:false,modernCMandatory:true} |
 .nativeSysmlViews |= map(if .source=="dev/modeling/diagrams/component-proof-dependencies.d2" then .nodes=59 | .typedConnections=130 | .visuallyReviewed=false | .topologyChecked=true else . end) |
 .nativeSysmlViews += [{source:"dev/architecture/runtime/gc/diagrams/generational-admission.d2",svg:"dev/architecture/runtime/gc/diagrams/generational-admission.svg",producer:"presentation-only native SysML ViewNode/ViewEdge serialization; D2 elk",nodes:10,typedConnections:12,visuallyReviewed:true,structureOnly:true},{source:"dev/architecture/runtime/ffi/diagrams/rc-freeze-publication.d2",svg:"dev/architecture/runtime/ffi/diagrams/rc-freeze-publication.svg",producer:"presentation-only native SysML need/dependency projection; D2 elk",nodes:14,typedConnections:30,visuallyReviewed:true,structureOnly:true}] |
 .nativeSysmlViews|=unique_by(.source) |
 .execution.runtimeImplementation=false | .execution.nativeRuntimeTesting=false | .execution.performanceValidation=false
 ' dev/traceability.json > "$r/traceability-next.json"
cp "$r/traceability-next.json" dev/traceability.json
