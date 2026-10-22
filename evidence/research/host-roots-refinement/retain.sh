#!/bin/bash
# Receipt assembly only: no runtime, native compiler, Python or performance work.
set -euo pipefail
r=.cache/tasks/host-roots-refinement
e=evidence/research/host-roots-refinement
bash "$r/assert.sh" > "$r/assertions.log" 2>&1
jq -e '.missingFiles==[] and .missingCustomIds==[] and .duplicateIds==[]' "$r/org-links.json" >/dev/null
jq -e '.exit==0 and ((.errors//[])|length)==0' "$r/native-metadata.json" >/dev/null
rg --files dev -g '*.sysml' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort > "$r/models-after.sha256"
cmp "$r/models-before.sha256" "$r/models-after.sha256"
openssl dgst -sha256 evidence/research/component-assurance/checks.json patches/fixtures/processor-interrupt-collective-wait-cumulative.patch vendor/gambit/lib/{mem,c_intf,setup,os_dyn,os_thread}.c vendor/gambit/include/gambit.h.in > "$r/retained-sources.sha256"
cmp "$r/entry-sources.sha256" "$r/retained-sources.sha256"
jq -r 'to_entries[]|[.key,.value]|@tsv' "$r/source-bindings.json" | while IFS=$'\t' read -r f expected; do
 actual=$(openssl dgst -sha256 "$f"|awk '{print $NF}'); test "$actual" = "$expected"
done
# Refresh only legacy native-model byte bindings; preserve all semantic fields.
jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' "$r/models-after.sha256" > "$r/model-bindings.json"
jq --slurpfile m "$r/model-bindings.json" '.modelSourceBindings += $m[0]' dev/modeling/formal-bindings.json > "$r/formal-bindings-next.json"
cp "$r/formal-bindings-next.json" dev/modeling/formal-bindings.json
jq -e --slurpfile old "$r/entry-formal-bindings.json" 'del(.modelSourceBindings)==($old[0]|del(.modelSourceBindings))' dev/modeling/formal-bindings.json >/dev/null
# Current mathematical checks are observations from the retained logs, not new executions.
jq -n --slurpfile p "$r/planner-input.json" '{newChecks:[{source:"models/gambit/host_roots_refinement.qnt",stage:"typecheck",log:"quint-typecheck.log",exitCode:0},{source:"models/gambit/host_roots_refinement.qnt",stage:"bounded-histories",log:"quint-tests.log",exitCode:0,histories:14,seed:1,samplesPerHistory:1},{source:"models/gambit/lean/HostRootSourceCensus.lean",stage:"inductive-preservation",log:"lean-census.log",exitCode:0},{source:"models/gambit/lean/HostRootsRefinement.lean",stage:"inductive-preservation",log:"lean-refinement.log",exitCode:0},{source:".cache/tasks/host-roots-refinement/probe.lean",stage:"scope-probe",log:"lean-scopes.log",exitCode:0}],nativeModelScopes:[$p[0].needs[]|select(.obligationId=="HR-DH" or .obligationId=="HR-DI")|{component,obligationId,subjectPath,subjectScope,digest}],wholeStepInvariant:false,exhaustiveVerification:false,livenessProved:false,cSourceSimulation:false}' > "$r/formal-checks.json"
for f in "$r"/case-*.json; do
 jq --arg file "$(basename "$f")" '{file:$file,componentReady:(.componentReady|map(.[1])|sort),locallyChecked:(.locallyChecked|length),sourceRoutes:(.sourceRoute|length),runtimeAdmitted}' "$f"
done | jq -s . > "$r/scenario-summary.json"
jq -n --slurpfile p "$r/planner-input.json" --slurpfile a "$r/case-current.json" '[$p[0].components[]|.id as $id|{component:$id,needs:([$p[0].needs[]|select(.component==$id)]|length),qualifiedLocal:([$a[0].locallyChecked[]|select(.[1]==$id)]|length),frontier:[$a[0].componentFrontier[]|select(.[1]==$id)|.[2]],complete:([$a[0].componentReady[]|select(.[1]==$id)]|length>0)}]' > "$r/closure-matrix.json"
jq -n '{papers:[{url:"https://anil.recoil.org/papers/2020-icfp-retropar.pdf",sections:["1.2-1.4","5.4"],use:"Foreign API and stack scanning constrain collector design; no benchmark transfer"},{url:"https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf",sections:["5.1.2.4","7.13.2.1","7.17.3"],use:"C data race, longjmp and memory-order constraints"}],freshWebRead:true,localOcamlSource:["vendor/ocaml/runtime/caml/memory.h:439-456","vendor/ocaml/runtime/callback.c:387-431"],scope:"Mechanism learning and constraints; no Gambit runtime qualification"}' > "$r/primary-evidence.json"
quint --version > "$r/quint-version.txt"
sysml --version > "$r/sysml-version.txt" 2>&1
d2 --version > "$r/d2-version.txt" 2>&1
(cd models/gambit/lean && lean --version) > "$r/lean-version.txt"
# Keep the predecessor and failed attempts intact; copy no native binaries/olean caches.
rg --files --hidden --no-ignore "$r" -g '*.json' -g '*.ss' -g '*.scm' -g '*.log' -g '*.sh' -g '*.el' -g '*.jq' -g '*.sha256' -g '*.txt' -g '*.tsv' -g '*.itf.json' -g 'probe.lean' | while IFS= read -r f; do cp "$f" "$e/$(basename "$f")"; done
cp "$r/host-roots-preview.png" "$r/components-preview.png" "$e/"
jq -n --slurpfile p "$r/planner-input.json" --slurpfile a "$r/case-current.json" --slurpfile f "$r/formal-checks.json" --slurpfile s "$r/scenario-summary.json" --slurpfile c "$r/closure-matrix.json" --slurpfile h "$r/source-bindings.json" --slurpfile o "$r/org-links.json" --arg head "$(git rev-parse HEAD)" --arg time "$(date -u +%FT%TZ)" '{
 kind:"modern-c-host-roots-source-refinement",status:"source-routes-specified-local-slices-checked-source-and-platform-open",recordedAt:$time,repositoryHead:$head,
 authority:{policy:"dev/modeling/models/sysml/assurance-routing.sysml",runtimeInterfaces:"dev/architecture/runtime/interfaces/models/sysml/component-assurance.sysml",hostRoots:"dev/architecture/runtime/ffi/models/sysml/host-roots-refinement.sysml",inference:"dev/modeling/ascent/assurance-planner.ss"},
 inputIdentity:{modelBundleSha256:$p[0].bundleHash,nativeOutputSha256:$p[0].nativeHash,dslSha256:$p[0].dslHash},sourceBindings:$h[0],
 structure:{nativeSysmlFiles:39,nativeEvaluatedScalars:677,components:8,needs:40,directPrerequisites:66,sharedContracts:8,sourceRoutes:6,views:[{source:"dev/modeling/diagrams/component-proof-dependencies.d2",needNodes:40,edges:66},{source:"dev/architecture/runtime/ffi/diagrams/host-roots-refinement.d2",needNodes:12,sourceRoutes:6,consumerNodes:5,edges:40}],nativeMetadataAuthority:true,visuallyReviewed:true,satisfactionClaimed:false},
 formal:$f[0],inherited:{localSlices:16,receipt:"evidence/research/component-assurance/checks.json",proofSourceDigestsEqual:true,rerun:false,scopeExpanded:false},
 reasoning:{scenarios:$s[0],scenarioCases:12,allExpectedClosureSetsMatched:true,sourceRoutesMatchNativeRecords:true,current:$a[0],components:$c[0],selectedHypotheses:1,supportObservations:0,nativeRuntimeAdmitted:false,syntheticControlEvidenceIsNotActualSourceProof:true},
 closure:{currentQualifiedLocalSlices:18,currentSourceSimulationOpen:14,currentPlatformOpen:8,currentCompleteComponents:0,hostRootSourceRoutesOpen:6,legacyGlobalObligationLedgerReclassified:false},org:$o[0],
 preservation:{vendorAndPatchUnchanged:true,priorScopedReceiptUnchanged:true,legacyRegistryNonHashFieldsUnchanged:true,leanInitialFailureRetained:true,sysmlReservedKeywordFailureRetained:true,wholeRequestFormBoundRetained:true,producerGuardFailureRetained:true,failedAttemptsPromoted:false},
 execution:{nativeSysmlValidation:true,nativeMetadataLookup:true,quintTypecheck:true,quintTests:true,leanCheck:true,exactNamespaceProbes:true,ascentQueries:true,orgParseAndLinks:true,newPythonMaintained:false,runtimeImplementation:false,nativeRuntimeTesting:false,performanceValidation:false},
 quantitativeBoundary:{coveredActiveLists:"P-1 more RC heads than vendor P0-only source; existing patch credit",requiredRootScan:"O(sum R_p), plus retained domains",activationMetadata:"O(D+K); no speedup predicted",zigSpecificNetGainEstablished:false,nativeSpeedup:null,personDaysUsed:false},runtimePathsRetired:0,nativeProfilesAccepted:0,
 remaining:["Retained donor scan membership and source atomic splice relation","Exclusive scratch extent and all exceptional releases","Pre-collective startup thunk root or stable representation proof","Direct run and unmatched/convert-error cleanup","Real/effective binding and admitted unwind profile","Dynamic closure identity, deletion/borrow lifetime and trampoline ABI","Concrete C happens-before and full source-step/observation/progress refinement"]
 }' > "$e/checks.json"
