#!/bin/bash
set -euo pipefail
r=.cache/tasks/sync-publication-assurance
e=evidence/research/sync-publication-assurance
cat > "$r/current-artifacts.txt" <<'FILES'
dev/modeling/assurance-planner.org
dev/modeling/ascent/assurance-planner.ss
dev/modeling/ascent/synchronous-publication.request.scm
dev/modeling/models/sysml/assurance-routing.sysml
dev/modeling/diagrams/assurance-routing.d2
dev/modeling/diagrams/assurance-routing.svg
dev/modeling/index.org
dev/modeling/component-model-design.org
dev/modeling/formal-bindings.json
dev/architecture/runtime/interfaces/synchronous-publication-design.org
dev/architecture/runtime/interfaces/models/sysml/synchronous-publication.sysml
dev/architecture/runtime/interfaces/diagrams/synchronous-publication.d2
dev/architecture/runtime/interfaces/diagrams/synchronous-publication.svg
dev/architecture/runtime/interfaces/index.org
dev/architecture/runtime/models/sysml/composition.sysml
dev/architecture/runtime/gc/models/quint/index.org
dev/architecture/runtime/gc/models/lean/index.org
dev/index.org
dev/research/validation.org
models/gambit/synchronous_publication.qnt
models/gambit/lean/SynchronousPublication.lean
FILES
while IFS= read -r artifact_file; do openssl dgst -sha256 "$artifact_file"; done < "$r/current-artifacts.txt" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/artifact-bindings.json"
cp "$r/final-org.log" "$e/final-org.log"
cp "$r/retain-checks.sh" "$r/finalize.sh" "$e/"
rg --files --hidden --no-ignore "$e" -g '!checks.json' -g '!evidence-artifact-bindings.json' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$r/evidence-artifact-bindings.json"
cp "$r/evidence-artifact-bindings.json" "$e/evidence-artifact-bindings.json"
jq --slurpfile a "$e/artifact-bindings.json" --slurpfile b "$e/evidence-artifact-bindings.json" '.artifactBindings=$a[0] | .evidenceArtifactBindings=$b[0]' "$e/checks.json" > "$r/checks-complete.json"
cp "$r/checks-complete.json" "$e/checks.json"
receipt_hash=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
predecessor_hash=$(openssl dgst -sha256 "$e/entry-traceability.json"|awk '{print $NF}')
jq --slurpfile c "$e/checks.json" --slurpfile a "$e/artifact-bindings.json" --arg hash "$receipt_hash" --arg prev "$predecessor_hash" '.kind="development-modern-c-component-assurance" |
 .recordedAt=$c[0].recordedAt | .status=$c[0].status |
 .checks={path:"evidence/research/sync-publication-assurance/checks.json",sha256:$hash} |
 .predecessor={snapshot:"evidence/research/sync-publication-assurance/entry-traceability.json",sha256:$prev,scope:"Prior scoped receipts, formal failures and all legacy registry non-hash fields preserved"} |
 .authority.synchronousPublication=$c[0].authority.component |
 .authority.assuranceRouting=$c[0].authority.policy |
 .authority.assuranceInference=$c[0].authority.inference |
 .artifactBindings += $a[0] |
 .execution.newQuintOrLeanExecution=true |
 .execution.quintTypecheck=true | .execution.quintTests=true | .execution.quintSimulation=true |
 .execution.quintExhaustiveVerification=false | .execution.leanCheck=true |
 .assurancePlanner={source:$c[0].authority.inference,component:"gc-synchronous-publication",nativeScalarFields:67,nativeModelFiles:35,baseScenarios:6,additionalControlRequests:4,modelRequiredRows:24,qualifiedScopedRows:6,currentQualifiedSlices:2,currentOpenNeeds:["SP-SOURCE","SP-MEMORY"],selectedHypotheses:1,retainedTaskHypotheses:2,supportObservations:0,runtimeAdmitted:false,otherComponentAdapters:"pending",existingComponentProjectionRecomputed:false} |
 .t0SynchronousPublication={requirements:4,sourceRefinementClosed:0,sites:4,workers:2,modes:3,quintTests:15,leanTheorems:9,modelBundleSha256:$c[0].modelBundleSha256,sourceSimulation:"open",nativeMemoryRefinement:"open",publisherSupportErasure:"conditional",zigSpecificGainEstablished:false} |
 .nativeSysmlViews += [{source:"dev/architecture/runtime/interfaces/diagrams/synchronous-publication.d2",svg:"dev/architecture/runtime/interfaces/diagrams/synchronous-publication.svg",producer:"native sysml interconnection render; D2 elk",nodes:10,typedConnections:9,visuallyReviewed:true,structureOnly:true},{source:"dev/modeling/diagrams/assurance-routing.d2",svg:"dev/modeling/diagrams/assurance-routing.svg",producer:"native sysml interconnection render; D2 elk",nodes:7,typedConnections:9,visuallyReviewed:true,structureOnly:true}]' dev/traceability.json > "$r/traceability-next.json"
cp "$r/traceability-next.json" dev/traceability.json
