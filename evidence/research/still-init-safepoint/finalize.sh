#!/bin/bash
set -euo pipefail
r=.cache/tasks/still-init-safepoint
e=evidence/research/still-init-safepoint
bash "$r/assert.sh" > "$r/assertions.log" 2>&1
rg -q '21 passing' "$r/quint-tests.log"
rg -q 'No violation found' "$r/quint-simulation.log"
! rg -q 'error:|sorryAx' "$r/lean.log" "$r/lean-scopes.log"
jq -e '.exit==0 and ((.errors//[])|length)==0' "$r/native-metadata.json" >/dev/null
emacs -Q --batch -l "$r/check-org.el" > "$r/org-parse.log" 2>&1
emacs -Q --batch -l "$r/check-org-links.el" > "$r/org-links.log" 2>&1
jq -e '.missingFiles==[] and .missingCustomIds==[] and .duplicateIds==[]' "$r/org-links.json" >/dev/null
while IFS= read -r f; do openssl dgst -sha256 "$f"; done < "$r/native-model-inputs.txt" | LC_ALL=C sort > "$r/models-after.sha256"
cmp "$r/models-before.sha256" "$r/models-after.sha256"
sed -E 's/^[^(]+\((.*)\)= .*/\1/' "$r/preserved.sha256" | while IFS= read -r f; do openssl dgst -sha256 "$f"; done > "$r/preserved-after.sha256"
cmp "$r/preserved.sha256" "$r/preserved-after.sha256"
jq -r 'to_entries[]|[.key,.value]|@tsv' "$r/source-bindings.json" | while IFS=$'\t' read -r f h; do test "$(openssl dgst -sha256 "$f"|awk '{print $NF}')" = "$h"; done
jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' "$r/models-after.sha256" > "$r/model-bindings.json"
jq --slurpfile m "$r/model-bindings.json" '.modelSourceBindings += $m[0]' dev/modeling/formal-bindings.json > "$r/formal-bindings-next.json"
cp "$r/formal-bindings-next.json" dev/modeling/formal-bindings.json
jq -e --slurpfile old "$r/entry-formal-bindings.json" 'del(.modelSourceBindings)==($old[0]|del(.modelSourceBindings))' dev/modeling/formal-bindings.json >/dev/null
jq -n --slurpfile n "$r/native-projection.json" --slurpfile q "$r/global-qualified.json" '{qnt:{source:"models/gambit/still_init_safepoint.qnt",namedHistories:21,initialSeed:17,positiveSamples:100,maxSteps:80,invariant:"safe",exhaustive:false,liveness:false,scope:"One initializer/two activation roots, req0..2 and abstract held block8; body complete and result-rooted before frozen participation; no remembered-set state or partial unknown readback"},lean:{source:"models/gambit/lean/StillInitSafepoint.lean",namedStatements:13,exactNamesProbed:true,wholeQntStepInduction:false,sourceRefinement:false,spatialSeparationProved:false,configuredAbiProved:false},nativeSchemas:{partDefinitions:3,requirementDefinitions:3,satisfiedInstancesClaimed:false},exactNewScopes:[$n[0].refinementNeeds[]|select(.obligationId|startswith("SI-"))],allQualifiedLocalSlices:$q[0],nativeRuntimeTest:false}' > "$r/formal-checks.json"
{
 for dir in "$r" "$r/build-cut"; do
  for s in $(jq -r '.cases[].id' "$dir/scenarios.json"); do
   jq --arg scope "$(basename "$dir")" --arg s "$s" '{scope:$scope,scenario:$s,needs:(.modelRequired|length),qualified:(.locallyChecked|length),pending:(.pendingCheck|length),rawReadyComponents:(.componentReady|map(.[1])),partialAncestorReadinessIsNotFullOwnerReadiness:true,runtimeAdmitted}' "$dir/case-$s.json"
  done
 done
 for suffix in '' '-tail'; do
 jq --arg suffix "$suffix" '{scope:("source-routes"+$suffix),scenario:"routes-only",needs:(.modelRequired|length),routes:(.sourceRoute|length),contracts:(.sharedContract|length),qualified:(.qualifiedSlice|length),ready:(.assuranceReady|length),runtimeAdmitted}' "$r/source-routes$suffix.json"
 done
} | jq -s . > "$r/scenario-summary.json"
sysml --version > "$r/sysml-version.txt" 2>&1
quint --version > "$r/quint-version.txt"
lean --version > "$r/lean-version.txt" 2>&1
d2 --version > "$r/d2-version.txt" 2>&1
while IFS= read -r f; do openssl dgst -sha256 "$f"; done < "$r/artifacts.txt" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$r/artifact-bindings.json"
cp -R "$r/." "$e/"
jq -n --slurpfile n "$r/native-values.json" --slurpfile p "$r/planner-full.json" --slurpfile s "$r/scenario-summary.json" --slurpfile h "$r/source-bindings.json" --slurpfile f "$r/formal-checks.json" --slurpfile a "$r/artifact-bindings.json" --slurpfile old "$r/entry-traceability.json" --arg head "$(git rev-parse HEAD)" --arg now "$(date -u +%FT%TZ)" '
 {kind:"modern-c-still-initialization-safepoint-root-custody",status:"conditional-kernels-checked-source-memory-and-generational-coverage-open",recordedAt:$now,repositoryHead:$head,
 authority:{sysml:"dev/architecture/runtime/gc/models/sysml/still-init-safepoint.sysml",inference:"dev/modeling/ascent/assurance-planner.ss",projection:"dev/modeling/ascent/render-still-init-safepoint.jq"},
 structure:{nativeSysmlFiles:($h[0]|keys|map(select(endswith(".sysml")))|length),nativeEvaluatedScalars:($n[0]|length),components:8,needs:100,directPrerequisites:288,sharedContracts:8,sourceRoutes:46,concreteCallerFamilies:8},
 closure:{currentQualifiedLocalSlices:38,inheritedUnchangedSlices:36,currentSourceSimulationOpen:49,currentPlatformOpen:13,currentCompleteComponents:0,legacyGlobalObligationLedgerReclassified:false},
 formal:$f[0],inputIdentity:{modelBundleSha256:$p[0].bundleHash,nativeOutputSha256:$p[0].nativeHash,dslSha256:$p[0].dslHash},sourceBindings:$h[0],artifactBindings:$a[0],
 reasoning:{scenarios:$s[0],scenarioCases:14,runtimeCut:{needs:84,edges:265,completeOwnerComponents:4},buildCut:{needs:56,edges:123,completeOwnerComponents:4},exactUnion:{needs:100,edges:288,sourceRoutes:46},routesProjectionQualifications:0,metadataProjectionCuts:2,sharedContractProjectionCount:8,pairedReceiptIdentityControls:2,parserLimitsRaised:false,priorFailureReceiptsPreserved:true,sourceRefinementPromoted:false},
benefit:{modernCMandatory:true,zigIncrementalBenefitEstablished:false,nativeRows:$p[0].initCosts,
selectedCase:"##make-structure still allocation/initialization/result root; sync-op and resize entry; interrupt posting/delivery; marker/native and foreign cleanup boundaries",
sourceImplicitOrdering:"Selected native fill has no ordinary GC/POLL/callback between allocation and initialized rooted handoff; not a newly demonstrated native bug",
mandatoryFill:"a body words once",sentinelAlternativeExtraWrites:"a additional words; optional alternative, not a saving",
existingScratchRootWords:3,targetRootRecords:"O(K)",targetScanSlots:"sum R_i; actual byte layout unqualified",
normalAlignedStillRequest:"8a+63 bytes under predecessor conditional WS8/pointer8 ordinary malloc assumptions",maximumNormalStillRequestBytes:65599,
mandatoryPayloadAllocationsEliminated:0,unknownStorage:"Full possible backing plus live root/init/operation metadata, no timeout refund",
publication:"Body completion AND current result root; remembered coverage additionally required in generational mode",
participation:"Fresh exact request/context/owner/root receipt freezes mutator until completion or withdrawal",
unknownModelBoundary:"QNT models preallocation uncertainty only; partial and complete-undelivered authoritative progress readback remain open",
QgCondition:"Actual omitted acquisition exceeds added root/init/unknown/remembered costs at every dominant phase; later refund never erases an earlier peak",
sourceWriteCensusComplete:false,cMemoryModelRefined:false,generationalCoverageProved:false,
nativeRssOrOomBoundEstablished:false,peakReductionMeasured:false,nativeSpeedupMeasured:false},
 views:{detail:{nativeNodes:10,nativeEdges:14,visuallyReviewed:true},fullGraph:{nodes:100,edges:288,topologyChecked:true,visuallyReviewed:false}},
 predecessor:{receipt:$old[0].checks.path,sha256:$old[0].checks.sha256,rerun:false,inheritedScopesAndDigestsChecked:true},
primaryEvidence:[{url:"https://ocaml.org/manual/5.3/intfc.html",scope:"5.1-5.2 roots and initialized fields; 7 and9 callback/exception/finalizer boundaries; mechanism learning, not imported Gambit proof"},{url:"https://anil.recoil.org/papers/2020-icfp-retropar.pdf",scope:"4.4 and5 coordinated collection and FFI/runtime integration; no imported benchmark or fiber layout"}],
retainedFailures:[{path:"evidence/research/still-init-safepoint/quint-initial-protocol-failure.log",cause:"Initial model over-scoped an earlier delivery into a later initializer; scoped event corrected, not a native bug"},{path:"evidence/research/still-init-safepoint/lean-initial-failure.log",cause:"Reserved identifier and redundant proof tactic; corrected and kernel/scope checked"}],
nativeQualification:{scope:"Predecessor51 native inputs plus new model",manifest:"evidence/research/still-init-safepoint/native-model-inputs.txt",wholeDevPassed:false,missingSelectedDependencyIgnored:false},
 execution:{sysmlNativeValidation:true,quintHistoryChecks:true,quintPositiveSimulation:true,leanKernelChecks:true,ascentQueries:true,runtimeImplementation:false,nativeRuntimeTesting:false,performanceValidation:false,commitOrPush:false},runtimePathsRetired:[],org:{scope:"8 owned Org artifacts and their referenced targets",parseAndLocalLinksChecked:true,wholeDevLinkClosureClaimed:false,babelExecuted:false}}
 ' > "$e/checks.json"
rg --files --hidden --no-ignore "$e" -g '!checks.json' -g '!evidence-bindings.json' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/evidence-bindings.json"
jq --slurpfile b "$e/evidence-bindings.json" '.evidenceArtifactBindings=$b[0]' "$e/checks.json" > "$r/checks-final.json"
cp "$r/checks-final.json" "$e/checks.json"
h=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
jq --slurpfile c "$e/checks.json" --slurpfile a "$r/artifact-bindings.json" --arg h "$h" '
 .kind=$c[0].kind|.status=$c[0].status|.recordedAt=$c[0].recordedAt|
 .checks={path:"evidence/research/still-init-safepoint/checks.json",sha256:$h}|
 .predecessor={snapshot:"evidence/research/still-init-safepoint/entry-traceability.json",scope:"Prior source, formal and native boundaries retained"}|
 .artifactBindings+=$a[0]|
 .componentAssurance.closure=$c[0].closure|
 .componentAssurance.formalResults="evidence/research/still-init-safepoint/formal-checks.json"|
 .componentAssurance.modelBundleSha256=$c[0].inputIdentity.modelBundleSha256|
 .componentModels.needs=100|.componentModels.directPrerequisites=288|.componentModels.currentQualifiedLocalSlices=38|
 .assurancePlanner.nativeScalarFields=$c[0].structure.nativeEvaluatedScalars|.assurancePlanner.nativeModelFiles=$c[0].structure.nativeSysmlFiles|
 .assurancePlanner.scenarioCases=14|.assurancePlanner.sourceRoutes=46|.assurancePlanner.currentQualifiedSlices=38|
 .assurancePlanner.currentOpenSourceNeeds=49|.assurancePlanner.currentOpenPlatformNeeds=13|
 .assurancePlanner.retainedTaskHypotheses=null|.assurancePlanner.selectedHypotheses=1|
 .assurancePlanner.queryCuts={runtime:{needs:84,edges:265,completeOwners:4},build:{needs:56,edges:123,completeOwners:4},sourceRoutes:{needs:100,routes:46,projectionCuts:2,contracts:8,proofReceipts:0},exactUnion:{needs:100,edges:288}}|
 .assurancePlanner.requests=["dev/modeling/ascent/component-assurance.request.scm","dev/modeling/ascent/component-assurance-build.request.scm","dev/modeling/ascent/component-assurance-routes.request.scm","dev/modeling/ascent/component-assurance-routes-tail.request.scm"]|
 .stillInitSafepoint={design:"dev/architecture/runtime/gc/still-init-safepoint-design.org",matrix:"dev/architecture/runtime/gc/still-init-safepoint-matrix.org",receipt:.checks,formal:$c[0].formal,benefit:$c[0].benefit}|
 .nativeSysmlViews|=map(if .source=="dev/modeling/diagrams/component-proof-dependencies.d2" then .nodes=100|.typedConnections=288|.visuallyReviewed=false else . end)|
 .nativeSysmlViews|=map(select(.source!="dev/architecture/runtime/gc/diagrams/still-init-safepoint.d2"))|
 .nativeSysmlViews+=[{source:"dev/architecture/runtime/gc/diagrams/still-init-safepoint.d2",svg:"dev/architecture/runtime/gc/diagrams/still-init-safepoint.svg",producer:"Native SysML scalar projection; D2 elk",nodes:10,typedConnections:14,visuallyReviewed:true,structureOnly:true}]|
 .execution=$c[0].execution
 ' dev/traceability.json > "$r/traceability-next.json"
cp "$r/traceability-next.json" dev/traceability.json
printf 'Sealed still initialization safe-point receipt %s\n' "$h"
