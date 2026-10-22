#!/bin/bash
set -euo pipefail
r=.cache/tasks/still-init-recovery
e=evidence/research/still-init-recovery
bash "$r/assert.sh" > "$r/assertions.log" 2>&1
rg -q '31 passing' "$r/quint-tests.log"
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
jq -n --slurpfile n "$r/native-projection.json" --slurpfile q "$r/global-qualified.json" '{qnt:{source:"models/gambit/still_init_recovery.qnt",namedHistories:31,initialSeed:17,positiveSamples:100,maxSteps:100,invariant:"safe",exhaustive:false,liveness:false,scope:"One operation/three fields/two owner generations/one recipient slot; distinct reserved, physical and committed progress, partial/completed/accepted lost replies; abstract backing8; native memory/source refinement open"},lean:{source:"models/gambit/lean/StillInitRecovery.lean",namedStatements:16,exactNamesProbed:true,wholeQntStepInduction:false,sourceRefinement:false,spatialSeparationProved:false,configuredAbiProved:false},nativeSchemas:{partDefinitions:3,requirementDefinitions:3,satisfiedInstancesClaimed:false},exactNewScopes:[$n[0].refinementNeeds[]|select(.obligationId|startswith("IR-"))],allQualifiedLocalSlices:$q[0],nativeRuntimeTest:false}' > "$r/formal-checks.json"
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
 {kind:"modern-c-partial-initialization-and-undelivered-result-recovery",status:"conditional-progress-and-admission-kernels-checked-native-refinement-open",recordedAt:$now,repositoryHead:$head,
 authority:{sysml:"dev/architecture/runtime/gc/models/sysml/still-init-recovery.sysml",inference:"dev/modeling/ascent/assurance-planner.ss",projection:"dev/modeling/ascent/render-still-init-recovery.jq"},
 structure:{nativeSysmlFiles:($h[0]|keys|map(select(endswith(".sysml")))|length),nativeEvaluatedScalars:($n[0]|length),components:8,needs:106,directPrerequisites:314,sharedContracts:8,sourceRoutes:50,concreteCallerFamilies:8},
 closure:{currentQualifiedLocalSlices:40,inheritedUnchangedSlices:38,currentSourceSimulationOpen:53,currentPlatformOpen:13,currentCompleteComponents:0,legacyGlobalObligationLedgerReclassified:false},
 formal:$f[0],inputIdentity:{modelBundleSha256:$p[0].bundleHash,nativeOutputSha256:$p[0].nativeHash,dslSha256:$p[0].dslHash},sourceBindings:$h[0],artifactBindings:$a[0],
 reasoning:{scenarios:$s[0],scenarioCases:16,runtimeCut:{needs:94,edges:297,completeOwnerComponents:5},buildCut:{needs:56,edges:123,completeOwnerComponents:4},exactUnion:{needs:106,edges:314,sourceRoutes:50},routesProjectionQualifications:0,metadataProjectionCuts:2,sharedContractProjectionCount:8,pairedReceiptIdentityControls:2,parserLimitsRaised:false,subjectReferenceIdentityInverseChecked:true,qualificationPolicyAstUnchanged:true,addedLosslessTransportForms:11,emptyInputSpecializationForms:17,priorFailureReceiptsPreserved:true,sourceRefinementPromoted:false},
benefit:{modernCMandatory:true,zigIncrementalBenefitEstablished:false,nativeRows:$p[0].recoveryCosts,
selectedCase:"STRUCTURE result/R3/R1; native pair/vector; UTF8 partial error and output slot; directory/error-text/string-list and SFUN release consumers",
sourceBoundary:"Selected source endpoints are synchronous, not an existing lost-reply API; proposed service readback/admission remains a target contract",
mandatoryFill:"a body writes; remaining suffix a-p only after authoritative idle cursor",mandatoryPayloadAllocationsEliminated:0,
checkpointCount:"ceil(a/q) only for admitted batch q; synchronous fast path may use a final cut only",
inputStorage:"E owned snapshot bytes unless a stable borrow and lifetime are proved",recordStorage:"O(L+T) live operations plus retained receipts; actual layout unqualified",
rootStorage:"Registered source/receiver overlap; one backing object, actual slots sum R_i",
normalAlignedStillRequest:"8a+63 bytes under predecessor conditional WS8/pointer8 ordinary malloc assumptions",maximumNormalStillRequestBytes:65599,
unknownStorage:"Full possible B + input E + root/init/dedup records; no timeout refund or second allocation",
unknownModelBoundary:"Partial and complete/accepted lost replies modeled; delayed stale transport, native memcpy/decoder/callbacks, root scanning and receipt retirement open",
publication:"Written fields are not a result-root receipt; recipient root and acceptance receipt must linearize together",
externalEffectExactlyOnceEstablished:false,crashRecoveryEstablished:false,livenessEstablished:false,
QgCondition:"max_t(P_t-Q_t+A_t) below max_t(P_t); actual omitted acquisition must survive input/root/unknown/receipt overlaps; unsafe replay is not a valid performance baseline",
cMemoryModelRefined:false,generationalCoverageProved:false,nativeRssOrOomBoundEstablished:false,peakReductionMeasured:false,nativeSpeedupMeasured:false},
 views:{detail:{nativeNodes:10,nativeEdges:17,visuallyReviewed:true},fullGraph:{nodes:106,edges:314,topologyChecked:true,visuallyReviewed:false}},
 predecessor:{receipt:$old[0].checks.path,sha256:$old[0].checks.sha256,rerun:false,inheritedScopesAndDigestsChecked:true},
primaryEvidence:[{url:"https://www.cs.cmu.edu/~wing/publications/HerlihyWing90.pdf",scope:"2 and4 invocation/response and representation relation; not source linearizability"},{url:"https://web.stanford.edu/~ouster/cgi-bin/papers/rifl.pdf",scope:"2-3 identity/completion/retry/lifetime; no imported RPC, crash or performance claims"},{url:"https://ocaml.org/manual/5.3/intfc.html",scope:"5.1-5.2 roots/valid fields and7 callback boundary"}],
retainedFailures:[{path:"evidence/research/still-init-recovery/quint-initial-control-gap.log",cause:"Idle physical/committed equality missing from initial invariant; prefix-reset control failed; corrected model, not native bug"},{path:"evidence/research/still-init-recovery/lean-initial-failure.log",cause:"Constructor case binder, reserved identifier and unavailable tactic; corrected and kernel/scope checked"},{path:"evidence/research/still-init-recovery/ascent-source-byte-bound-failure.log",cause:"Uncompressed larger ancestor cut exceeds unchanged source byte bound"},{path:"evidence/research/still-init-recovery/ascent-form-bound-failure.log",cause:"First dictionary transport exceeds unchanged form bound; final exact owner-edge/subject transport verified independently"},{path:"evidence/research/still-init-recovery/transport-initial-failure.log",cause:"Initial Emacs checker binding syntax; corrected independent inverse passes"}],
nativeQualification:{scope:"Predecessor52 native inputs plus new model",manifest:"evidence/research/still-init-recovery/native-model-inputs.txt",wholeDevPassed:false,missingSelectedDependencyIgnored:false},
 execution:{sysmlNativeValidation:true,quintHistoryChecks:true,quintPositiveSimulation:true,leanKernelChecks:true,ascentQueries:true,runtimeImplementation:false,nativeRuntimeTesting:false,performanceValidation:false,commitOrPush:false},runtimePathsRetired:[],org:{scope:"8 owned Org artifacts and their referenced targets",parseAndLocalLinksChecked:true,wholeDevLinkClosureClaimed:false,babelExecuted:false}}
 ' > "$e/checks.json"
rg --files --hidden --no-ignore "$e" -g '!checks.json' -g '!evidence-bindings.json' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/evidence-bindings.json"
jq --slurpfile b "$e/evidence-bindings.json" '.evidenceArtifactBindings=$b[0]' "$e/checks.json" > "$r/checks-final.json"
cp "$r/checks-final.json" "$e/checks.json"
h=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
jq --slurpfile c "$e/checks.json" --slurpfile a "$r/artifact-bindings.json" --arg h "$h" '
 .kind=$c[0].kind|.status=$c[0].status|.recordedAt=$c[0].recordedAt|
 .checks={path:"evidence/research/still-init-recovery/checks.json",sha256:$h}|
 .predecessor={snapshot:"evidence/research/still-init-recovery/entry-traceability.json",scope:"Prior source, formal and native boundaries retained"}|
 .artifactBindings+=$a[0]|
 .componentAssurance.closure=$c[0].closure|
 .componentAssurance.formalResults="evidence/research/still-init-recovery/formal-checks.json"|
 .componentAssurance.modelBundleSha256=$c[0].inputIdentity.modelBundleSha256|
 .componentModels.needs=106|.componentModels.directPrerequisites=314|.componentModels.currentQualifiedLocalSlices=40|
 .assurancePlanner.nativeScalarFields=$c[0].structure.nativeEvaluatedScalars|.assurancePlanner.nativeModelFiles=$c[0].structure.nativeSysmlFiles|
 .assurancePlanner.scenarioCases=16|.assurancePlanner.sourceRoutes=50|.assurancePlanner.currentQualifiedSlices=40|
 .assurancePlanner.currentOpenSourceNeeds=53|.assurancePlanner.currentOpenPlatformNeeds=13|
 .assurancePlanner.retainedTaskHypotheses=null|.assurancePlanner.selectedHypotheses=1|
 .assurancePlanner.queryCuts={runtime:{needs:94,edges:297,completeOwners:5},build:{needs:56,edges:123,completeOwners:4},sourceRoutes:{needs:106,routes:50,projectionCuts:2,contracts:8,proofReceipts:0},exactUnion:{needs:106,edges:314}}|
 .assurancePlanner.requests=["dev/modeling/ascent/component-assurance.request.scm","dev/modeling/ascent/component-assurance-build.request.scm","dev/modeling/ascent/component-assurance-routes.request.scm","dev/modeling/ascent/component-assurance-routes-tail.request.scm"]|
 .stillInitRecovery={design:"dev/architecture/runtime/gc/still-init-recovery-design.org",matrix:"dev/architecture/runtime/gc/still-init-recovery-matrix.org",receipt:.checks,formal:$c[0].formal,benefit:$c[0].benefit}|
 .nativeSysmlViews|=map(if .source=="dev/modeling/diagrams/component-proof-dependencies.d2" then .nodes=106|.typedConnections=314|.visuallyReviewed=false else . end)|
 .nativeSysmlViews|=map(select(.source!="dev/architecture/runtime/gc/diagrams/still-init-recovery.d2"))|
 .nativeSysmlViews+=[{source:"dev/architecture/runtime/gc/diagrams/still-init-recovery.d2",svg:"dev/architecture/runtime/gc/diagrams/still-init-recovery.svg",producer:"Native SysML scalar projection; D2 elk",nodes:10,typedConnections:17,visuallyReviewed:true,structureOnly:true}]|
 .execution=$c[0].execution
 ' dev/traceability.json > "$r/traceability-next.json"
cp "$r/traceability-next.json" dev/traceability.json
printf 'Sealed partial initializer and result recovery receipt %s\n' "$h"
