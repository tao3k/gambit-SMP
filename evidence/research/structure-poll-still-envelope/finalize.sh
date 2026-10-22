#!/bin/bash
set -euo pipefail
r=.cache/tasks/structure-poll-still-envelope
e=evidence/research/structure-poll-still-envelope
bash "$r/assert.sh" > "$r/assertions.log" 2>&1
rg -q '18 passing' "$r/quint-tests.log"
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
jq -n --slurpfile n "$r/native-projection.json" --slurpfile q "$r/global-qualified.json" '{qnt:{source:"models/gambit/structure_poll_still_envelope.qnt",namedHistories:18,initialSeed:17,positiveSamples:100,maxSteps:80,invariant:"safe",exhaustive:false,liveness:false,scope:"One constructor a255 batch, abstract section100/still21/effect4 units; unknown potential backing fully charged, no GC ack before init; not source peak measurements"},lean:{source:"models/gambit/lean/StructurePollStillEnvelope.lean",namedStatements:17,exactNamesProbed:true,wholeQntStepInduction:false,sourceRefinement:false,spatialSeparationProved:false,configuredAbiProved:false},nativeSchemas:{partDefinitions:3,requirementDefinitions:3,satisfiedInstancesClaimed:false},exactNewScopes:[$n[0].refinementNeeds[]|select(.obligationId|startswith("SP-"))],allQualifiedLocalSlices:$q[0],nativeRuntimeTest:false}' > "$r/formal-checks.json"
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
 {kind:"modern-c-structure-slow-poll-frame-and-still-joint-peak",status:"conditional-kernels-checked-effects-layout-and-source-open",recordedAt:$now,repositoryHead:$head,
 authority:{sysml:"dev/architecture/runtime/gc/models/sysml/structure-poll-still-envelope.sysml",inference:"dev/modeling/ascent/assurance-planner.ss",projection:"dev/modeling/ascent/render-structure-poll-still-envelope.jq"},
 structure:{nativeSysmlFiles:($h[0]|keys|map(select(endswith(".sysml")))|length),nativeEvaluatedScalars:($n[0]|length),components:8,needs:96,directPrerequisites:272,sharedContracts:8,sourceRoutes:44,concreteCallerFamilies:6},
 closure:{currentQualifiedLocalSlices:36,inheritedUnchangedSlices:34,currentSourceSimulationOpen:47,currentPlatformOpen:13,currentCompleteComponents:0,legacyGlobalObligationLedgerReclassified:false},
 formal:$f[0],inputIdentity:{modelBundleSha256:$p[0].bundleHash,nativeOutputSha256:$p[0].nativeHash,dslSha256:$p[0].dslHash},sourceBindings:$h[0],artifactBindings:$a[0],
 reasoning:{scenarios:$s[0],scenarioCases:16,runtimeCut:{needs:80,edges:249,completeOwnerComponents:4},buildCut:{needs:56,edges:123,completeOwnerComponents:4},exactUnion:{needs:96,edges:272,sourceRoutes:44},routesProjectionQualifications:0,metadataProjectionCuts:2,sharedContractProjectionCount:8,pairedReceiptIdentityControls:2,parserLimitsRaised:false,priorFailureReceiptsPreserved:true,sourceRefinementPromoted:false},
benefit:{modernCMandatory:true,zigIncrementalBenefitEstablished:false,nativeRows:$p[0].structureCosts,
selectedCase:"Existing ##structure POLL1, recursive POLL2, RETN fs5 and make-structure still path",
countOnlyCapEstablished:false,reason:"Arbitrary live graph, installed interrupts, exceptions, retry/capture versions and other VM participants require explicit bounded inputs",
representation:"Conditional no-handles WS8, pointer8; header defaults, not a qualified rebuilt native profile",
stackFrameWords:8,heapFrameWords:7,maximumSingleTraversalStackWords:65528,maximumSingleCanonicalHeapFrameCohortWords:57337,
defaultFirstPollInternalStackWords:12,defaultFirstPollInternalHeapWords:11,defaultRecursivePollInternalStackWords:20,defaultRecursivePollInternalHeapWords:19,
restrictedTransferWords:52,firstBreakWords:4,mixedCallerTransferCapEstablished:false,
stillCharge:"a+6 words",normalAlignedStillRequest:"8a+63 bytes",maximumNormalStillRequestBytes:65599,
zeroDeferredThresholdActuals:1018,conditionalLp64MsectionRequestBytes:1048615,
allocationMetric:"Distinct requested backing containers; allocator overhead/low-level-exec/custom routes need their own bindings; not RSS",
poolReturnDeltaAcquiredBytes:0,pendingSettlementDeltaAcquiredBytes:0,
QgCondition:"Role-compatible preaccepted tail omits an actual acquisition through all dominant phases; later still/callback/error/unknown holds cannot erase net credit",
stillCanBePaidByMovableTail:false,lateRefundErasesPastPeak:false,nativeRssOrOomBoundEstablished:false,peakReductionMeasured:false,nativeSpeedupMeasured:false},
 views:{detail:{nativeNodes:12,nativeEdges:18,visuallyReviewed:true},fullGraph:{nodes:96,edges:272,topologyChecked:true,visuallyReviewed:false}},
 predecessor:{receipt:$old[0].checks.path,sha256:$old[0].checks.sha256,rerun:false,inheritedScopesAndDigestsChecked:true},
 primaryEvidence:[{url:"https://simonmar.github.io/bib/papers/parallel-gc.pdf",scope:"3.4-3.5; distinct scan/allocation frontiers and pending work; no imported benchmark or rest bound"},{url:"https://anil.recoil.org/papers/2020-icfp-retropar.pdf",scope:"4.4; synchronized parallel minor/promotion readiness and C-API safe-point choice; not Gambit continuation proof"}],
retainedFailures:[{path:"evidence/research/structure-poll-still-envelope/whole-dev-native-failure.json",cause:"Concurrent unselected foundation-binding model syntax; no whole-DEV native pass claim"},{path:"evidence/research/structure-poll-still-envelope/whole-dev-org-links-open.json",cause:"Concurrent unselected foundation documents have open links; Org checked for8 owned artifacts only"},{path:"evidence/research/structure-poll-still-envelope/ascent-form-bound-failure.log",cause:"Unpacked receipts exceed unchanged form limit; exact paired transport"},{path:"evidence/research/structure-poll-still-envelope/ascent-column-bound-failure.log",cause:"Initial pair17 columns exceeds unchanged bound; equal-status pair16 with unequal-status fallback"},{path:"evidence/research/structure-poll-still-envelope/ascent-route-byte-bound-failure.log",cause:"Full metadata selector exceeds unchanged source bound; two exact-union projection cuts"},{path:"evidence/research/structure-poll-still-envelope/lean-library-name-failure.log",cause:"Unavailable library theorem name; proof rewritten by induction/omega"}],
nativeQualification:{scope:"Predecessor50 native inputs plus new model",manifest:"evidence/research/structure-poll-still-envelope/native-model-inputs.txt",wholeDevPassed:false,missingSelectedDependencyIgnored:false},
 execution:{sysmlNativeValidation:true,quintHistoryChecks:true,quintPositiveSimulation:true,leanKernelChecks:true,ascentQueries:true,runtimeImplementation:false,nativeRuntimeTesting:false,performanceValidation:false,commitOrPush:false},runtimePathsRetired:[],org:{scope:"8 owned Org artifacts and their referenced targets",parseAndLocalLinksChecked:true,wholeDevLinkClosureClaimed:false,babelExecuted:false}}
 ' > "$e/checks.json"
rg --files --hidden --no-ignore "$e" -g '!checks.json' -g '!evidence-bindings.json' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/evidence-bindings.json"
jq --slurpfile b "$e/evidence-bindings.json" '.evidenceArtifactBindings=$b[0]' "$e/checks.json" > "$r/checks-final.json"
cp "$r/checks-final.json" "$e/checks.json"
h=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
jq --slurpfile c "$e/checks.json" --slurpfile a "$r/artifact-bindings.json" --arg h "$h" '
 .kind=$c[0].kind|.status=$c[0].status|.recordedAt=$c[0].recordedAt|
 .checks={path:"evidence/research/structure-poll-still-envelope/checks.json",sha256:$h}|
 .predecessor={snapshot:"evidence/research/structure-poll-still-envelope/entry-traceability.json",scope:"Prior source, formal and native boundaries retained"}|
 .artifactBindings+=$a[0]|
 .componentAssurance.closure=$c[0].closure|
 .componentAssurance.formalResults="evidence/research/structure-poll-still-envelope/formal-checks.json"|
 .componentAssurance.modelBundleSha256=$c[0].inputIdentity.modelBundleSha256|
 .componentModels.needs=96|.componentModels.directPrerequisites=272|.componentModels.currentQualifiedLocalSlices=36|
 .assurancePlanner.nativeScalarFields=$c[0].structure.nativeEvaluatedScalars|.assurancePlanner.nativeModelFiles=$c[0].structure.nativeSysmlFiles|
 .assurancePlanner.scenarioCases=16|.assurancePlanner.sourceRoutes=44|.assurancePlanner.currentQualifiedSlices=36|
 .assurancePlanner.currentOpenSourceNeeds=47|.assurancePlanner.currentOpenPlatformNeeds=13|
 .assurancePlanner.retainedTaskHypotheses=null|.assurancePlanner.selectedHypotheses=1|
 .assurancePlanner.queryCuts={runtime:{needs:80,edges:249,completeOwners:4},build:{needs:56,edges:123,completeOwners:4},sourceRoutes:{needs:96,routes:44,projectionCuts:2,contracts:8,proofReceipts:0},exactUnion:{needs:96,edges:272}}|
 .assurancePlanner.requests=["dev/modeling/ascent/component-assurance.request.scm","dev/modeling/ascent/component-assurance-build.request.scm","dev/modeling/ascent/component-assurance-routes.request.scm","dev/modeling/ascent/component-assurance-routes-tail.request.scm"]|
 .structurePollStillEnvelope={design:"dev/architecture/runtime/gc/structure-poll-still-envelope-design.org",matrix:"dev/architecture/runtime/gc/structure-poll-still-envelope-matrix.org",receipt:.checks,formal:$c[0].formal,benefit:$c[0].benefit}|
 .nativeSysmlViews|=map(if .source=="dev/modeling/diagrams/component-proof-dependencies.d2" then .nodes=96|.typedConnections=272|.visuallyReviewed=false else . end)|
 .nativeSysmlViews|=map(select(.source!="dev/architecture/runtime/gc/diagrams/structure-poll-still-envelope.d2"))|
 .nativeSysmlViews+=[{source:"dev/architecture/runtime/gc/diagrams/structure-poll-still-envelope.d2",svg:"dev/architecture/runtime/gc/diagrams/structure-poll-still-envelope.svg",producer:"Native SysML scalar projection; D2 elk",nodes:12,typedConnections:18,visuallyReviewed:true,structureOnly:true}]|
 .execution=$c[0].execution
 ' dev/traceability.json > "$r/traceability-next.json"
cp "$r/traceability-next.json" dev/traceability.json
printf 'Sealed structure/POLL/still receipt %s\n' "$h"
