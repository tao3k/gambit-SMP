#!/bin/bash
set -euo pipefail
r=.cache/tasks/component-assurance
e=evidence/research/component-assurance
while IFS= read -r artifact_file; do openssl dgst -sha256 "$artifact_file"; done < "$r/artifacts.txt" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/artifact-bindings.json"
cp "$r/finalize.sh" "$r/artifacts.txt" "$e/"
rg --files --hidden --no-ignore "$e" -g '!checks.json' -g '!evidence-bindings.json' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$r/evidence-bindings.json"
cp "$r/evidence-bindings.json" "$e/evidence-bindings.json"
jq --slurpfile a "$e/artifact-bindings.json" --slurpfile b "$e/evidence-bindings.json" '.artifactBindings=$a[0] | .evidenceArtifactBindings=$b[0]' "$e/checks.json" > "$r/checks-final.json"
cp "$r/checks-final.json" "$e/checks.json"
receipt_hash=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
entry_hash=$(openssl dgst -sha256 "$e/entry-traceability.json"|awk '{print $NF}')
jq --slurpfile c "$e/checks.json" --slurpfile a "$e/artifact-bindings.json" --arg hash "$receipt_hash" --arg entry "$entry_hash" '
 .kind="development-modern-c-composed-component-assurance" | .status=$c[0].status | .recordedAt=$c[0].recordedAt |
 .checks={path:"evidence/research/component-assurance/checks.json",sha256:$hash} |
 .predecessor={snapshot:"evidence/research/component-assurance/entry-traceability.json",sha256:$entry,scope:"Prior receipts and legacy formal ledger retained without source-proof promotion"} |
 .authority.assuranceRouting=$c[0].authority.policy | .authority.assuranceInference=$c[0].authority.inference |
 .authority.buildAssurance=$c[0].authority.build | .authority.runtimeAssurance=$c[0].authority.runtimeInterfaces | .authority.componentAssurance=$c[0].authority.composition |
 .artifactBindings += $a[0] | del(.artifactBindings["dev/modeling/ascent/synchronous-publication.request.scm"]) |
 .componentModels={components:8,componentStudies:7,needs:32,sharedContracts:8,directPrerequisites:40,currentQualifiedLocalSlices:16,currentCompleteComponents:0,legacyProjection:"Retained in predecessor snapshot; not reinterpreted"} |
 .assurancePlanner={source:$c[0].authority.inference,components:8,nativeScalarFields:497,nativeModelFiles:38,scenarioCases:16,structuralControls:5,currentQualifiedSlices:16,currentOpenSourceNeeds:8,currentOpenPlatformNeeds:8,selectedHypotheses:1,supportObservations:0,runtimeAdmitted:false,crossComponentDependencies:"integrated-and-tested",conjunctiveMethodDemands:true,exactSubjectScopes:true,legacyAssociationAdapterRecomputed:false} |
 .componentAssurance={matrix:"dev/modeling/component-assurance.org",formalResults:"evidence/research/component-assurance/formal-checks.json",closure:$c[0].closure,modelBundleSha256:$c[0].inputIdentity.modelBundleSha256,sourceRefinement:"open",legacyGlobalLedgerReclassified:false,oldPilotRequest:"evidence/research/component-assurance/entry-pilot.request.scm"} |
 .execution.newQuintOrLeanExecution=true | .execution.quintTypecheck=true | .execution.quintTests=true | .execution.quintSimulation=false | .execution.quintExhaustiveVerification=false | .execution.leanCheck=true | .execution.exactNamespaceProbes=true | .execution.crossComponentAscentControls=true |
 .nativeSysmlViews += [{source:"dev/modeling/diagrams/component-assurance.d2",svg:"dev/modeling/diagrams/component-assurance.svg",producer:"native sysml interconnection export; D2 elk",nodes:12,typedConnections:19,visuallyReviewed:true,structureOnly:true},{source:"dev/modeling/diagrams/component-proof-dependencies.d2",svg:"dev/modeling/diagrams/component-proof-dependencies.svg",producer:"presentation-only serialization of native-evaluated SysML endpoints; D2 elk",nodes:32,clusters:8,typedConnections:40,visuallyReviewed:true,structureOnly:true}]' dev/traceability.json > "$r/traceability-next.json"
jq '.nativeSysmlViews|=unique_by(.source)' "$r/traceability-next.json" > dev/traceability.json
