#!/bin/bash
set -euo pipefail
r=.cache/tasks/sync-publication-assurance
e=evidence/research/sync-publication-assurance
bash "$r/assert-planner.sh" > "$r/planner-assertions.log"
jq -e '.runtimeAdmitted==false and .presentationComplete==true and .retainedTaskHypotheses==2' "$r/planner-results.json" > "$r/association-boundary-check.log"
test ! -s "$r/lean-check.log"
rg -q '15 passing' "$r/quint-test.log"
jq -e '.status=="ok" and .errors==[] and .seed==20261022' "$r/quint-simulation.json" >/dev/null
jq -e '.missingFiles==[] and .missingCustomIds==[] and .duplicateIds==[]' "$r/org-links.json" >/dev/null
jq -e '.exit==0 and ((.errors//[])|length)==0' "$r/native-metadata.json" >/dev/null
rg --files dev -g '*.sysml' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort > "$r/models-after.sha256"
cmp "$r/models-before.sha256" "$r/models-after.sha256"
openssl dgst -sha256 dev/modeling/tools/sync-views.py evidence/research/t0-chunk-close/checks.json > "$r/preserved-after.sha256"
cmp "$r/preserved-before.sha256" "$r/preserved-after.sha256"
jq -e --slurpfile before "$r/entry-bindings.json" 'del(.modelSourceBindings)==($before[0]|del(.modelSourceBindings))' dev/modeling/formal-bindings.json >/dev/null
jq -r '.sources|to_entries[]|[.key,.value.sha256]|@tsv' "$r/entry-bindings.json" | while IFS=$'\t' read -r source_file expected_hash; do
  actual_hash=$(openssl dgst -sha256 "$source_file" | awk '{print $NF}')
  test "$actual_hash" = "$expected_hash"
done
jq -r 'to_entries[]|[.key,.value]|@tsv' "$r/selected-source-bindings.json" | while IFS=$'\t' read -r source_file expected_hash; do
  actual_hash=$(openssl dgst -sha256 "$source_file" | awk '{print $NF}')
  test "$actual_hash" = "$expected_hash"
done
mkdir -p "$e/initial-pilot"
cp "$r/initial-pilot/"* "$e/initial-pilot/"
for item in native-metadata.json native-component.json model-bindings.json selected-source-bindings.json assurance-bindings.json planner-input.json scenarios.json planner-results.json quint-typecheck.log quint-test.log quint-simulation.log quint-simulation.json quint-initial-parse-failure.log lean-check.log lean-version.txt lean-initial-failure.log ascent-initial-registration.ss ascent-initial-unbound-read.scm ascent-retained-id-failure.log ascent-submit.scm ascent-submit.log ascent-read.scm ascent-read.log planner-composed.ss submit.request.scm register.ss read-native.sh transport-planner.sh read-association.el check-planner.sh assert-planner.jq assert-planner.sh planner-assertions.log adapter-profile-check.log association-boundary-check.log models-before.sha256 models-after.sha256 preserved-before.sha256 preserved-after.sha256 formal-before.sha256 entry-bindings.json entry-traceability.json org-check.log org-links.json component-render.log component-d2.log planner-render.log planner-d2.log; do cp "$r/$item" "$e/$item"; done
cp "$r/"test_*.itf.json "$e/"
cp "$r/"control-* "$e/"
quint --version > "$e/quint-version.txt"
sysml --version > "$e/sysml-version.txt" 2>&1
d2 --version > "$e/d2-version.txt" 2>&1
jq -n --slurpfile p "$r/planner-results.json" --slurpfile n "$r/native-component.json" --slurpfile b "$r/assurance-bindings.json" --slurpfile i "$r/planner-input.json" --slurpfile o "$r/org-links.json" --slurpfile old "$r/entry-bindings.json" --slurpfile sim "$r/quint-simulation.json" --arg head "$(git rev-parse HEAD)" --arg time "$(date -u +%FT%TZ)" '{
 kind:"modern-c-component-assurance",recordedAt:$time,repositoryHead:$head,
 status:"target-model-slices-and-reasoning-checked-source-refinement-open",
 authority:{component:"dev/architecture/runtime/interfaces/models/sysml/synchronous-publication.sysml",policy:"dev/modeling/models/sysml/assurance-routing.sysml",inference:"dev/modeling/ascent/assurance-planner.ss",organization:"dev/organization.sysml"},
 component:$n[0],sourceBindings:$b[0],modelBundleSha256:$i[0].bundleHash,nativeOutputSha256:$i[0].nativeHash,dslSha256:$i[0].dslHash,
 execution:{nativeSysmlValidation:true,nativeMetadataLookup:true,nativeD2Export:true,quintTypecheck:true,quintTests:true,quintSimulation:true,quintExhaustiveVerification:false,leanCheck:true,ascentHypothesisQuery:true,orgParseAndLinkCheck:true,newPythonMaintained:false,legacyPythonDeriverRun:false,runtimeImplementation:false,nativeRuntimeTesting:false,performanceValidation:false},
 formal:{quint:{path:$n[0].component.quint,workers:2,sites:4,fixedCollectionAndPhase:true,modes:3,deterministicTests:15,positiveTests:11,deliberateDesignFaultControls:4,simulation:{seed:$sim[0].seed,maxSamplesBudget:500,maxStepsBudget:100,status:$sim[0].status,retainedStates:($sim[0].trace|length)},exhaustive:false,livenessProved:false,sourceSimulation:false,weakMemoryRefinement:false},lean:{path:$n[0].component.lean,theorems:9,toolchain:"Lean 4.34.0 pinned repository toolchain",scope:"Parametric debt cover, conservation, counterexamples and cost algebra; not full-transition induction or source simulation",sourceSimulation:false}},
 ascent:{source:"dev/modeling/ascent/assurance-planner.ss",association:$p[0],scenarioCases:10,baseScenarios:6,additionalControlRequests:4,expectedRowAssertionsPassed:true,qualifiedMeaning:"Exact presented artifact/check-class receipt match only",selectedHypotheses:1,retainedTaskHypotheses:2,supportObservations:0,nativeRuntimeAdmitted:false,nativeExecutionAuthorized:false,policyProfile:"unique component-local obligations; one subject per need; exactly one method/check rule per kind",unqualified:["Cross-component prerequisite transport","Multi-source proof bundle validity","Receipt producer authentication","Automatic tool execution","Other DEV component adapters"]},
 structure:{nativeSysmlFiles:35,nativeScalarFields:67,requirements:4,sourceRefinementClosedRequirements:0,componentView:{nodes:10,typedConnections:9},plannerView:{nodes:7,typedConnections:9},visuallyReviewed:true,structureOnly:true},
 org:$o[0],
 preservation:{legacyFormalSources:($old[0].sources|length),legacySourceHashesUnchanged:true,legacyRegistryNonHashFieldsUnchanged:true,newTargetFormalSources:2,oldScopedReceiptUnchanged:true,legacyPythonDeriverUnchanged:true,initialPilotRetained:true,initialDiagnosticsRetained:true,initialFailedSourceHashesNotReconstructed:true,formalBeforeSnapshot:"QNT matches final; Lean snapshot precedes proof repair and must not be labeled the successful Lean identity"},
 quantitativeBoundary:{unit:"Modeled successful FIFO batch; not native elapsed time",splitExplicit:{gates:5,queueSections:2},fusedExplicit:{gates:4,queueSections:2},fusedContained:{gates:3,queueSections:2},conditionalElimination:"Two modeled G transactions relative to split explicit reference; no assertion that adding G beats the current collector",nativeSpeedup:null,zigSpecificGainEstablished:false},
 remaining:["Actual C action/stutter simulation and source-enabled guards","Complete hook, cancellation, exit and platform profiles","C memory order and MISC/ALLOC/G/Q lock graph","Cross-phase and generation-reuse validity","Full transition induction, QNT/Lean correspondence and progress","Other DEV component-specific assurance needs and adapters"],
 runtimePathsRetired:0,buildPathsRetired:0,nativeProfilesAccepted:0,registeredClaimsPromoted:0
}' > "$e/checks.json"
