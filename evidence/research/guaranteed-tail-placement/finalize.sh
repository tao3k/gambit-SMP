#!/bin/bash
set -euo pipefail
r=.cache/tasks/guaranteed-tail-placement
e=evidence/research/guaranteed-tail-placement
bash "$r/assert.sh" > "$r/assertions.log" 2>&1
rg -q '17 passing' "$r/quint-tests.log"
rg -q 'No violation found' "$r/quint-simulation.log"
! rg -q 'error:|sorryAx' "$r/lean.log" "$r/lean-scopes.log"
jq -e '.exit==0 and ((.errors//[])|length)==0' "$r/native-metadata.json" >/dev/null
emacs -Q --batch -l "$r/check-org.el" > "$r/org-parse.log" 2>&1
emacs -Q --batch -l "$r/check-org-links.el" > "$r/org-links.log" 2>&1
rg --files dev -g '*.sysml' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort > "$r/models-after.sha256"
cmp "$r/models-before.sha256" "$r/models-after.sha256"
sed -E 's/^[^(]+\((.*)\)= .*/\1/' "$r/preserved.sha256" | while IFS= read -r f; do openssl dgst -sha256 "$f"; done > "$r/preserved-after.sha256"
cmp "$r/preserved.sha256" "$r/preserved-after.sha256"
jq -r 'to_entries[]|[.key,.value]|@tsv' "$r/source-bindings.json" | while IFS=$'\t' read -r f h; do test "$(openssl dgst -sha256 "$f"|awk '{print $NF}')" = "$h"; done
jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' "$r/models-after.sha256" > "$r/model-bindings.json"
jq --slurpfile m "$r/model-bindings.json" '.modelSourceBindings += $m[0]' dev/modeling/formal-bindings.json > "$r/formal-bindings-next.json"
cp "$r/formal-bindings-next.json" dev/modeling/formal-bindings.json
jq -e --slurpfile old "$r/entry-formal-bindings.json" 'del(.modelSourceBindings)==($old[0]|del(.modelSourceBindings))' dev/modeling/formal-bindings.json >/dev/null
jq -n --slurpfile n "$r/native-projection.json" --slurpfile q "$r/global-qualified.json" '{qnt:{source:"models/gambit/guaranteed_tail_placement.qnt",namedHistories:17,initialSeed:17,positiveSamples:100,maxSteps:80,invariant:"safe",exhaustive:false,liveness:false,scope:"One region and context: copy fence, future suffix, guarded span, abstract rebind, unknown commit and historical peak; no full allocator or GC"},lean:{source:"models/gambit/lean/GuaranteedTailPlacement.lean",namedStatements:12,exactNamesProbed:true,wholeQntStepInduction:false,sourceRefinement:false,spatialSeparationProved:false},nativeSchemas:{partDefinitions:3,requirementDefinitions:3,satisfiedInstancesClaimed:false},exactNewScopes:[$n[0].refinementNeeds[]|select(.obligationId|startswith("GT-"))],allQualifiedLocalSlices:$q[0],nativeRuntimeTest:false}' > "$r/formal-checks.json"
{
 for dir in "$r" "$r/build-cut"; do
  for s in $(jq -r '.cases[].id' "$dir/scenarios.json"); do
   jq --arg scope "$(basename "$dir")" --arg s "$s" '{scope:$scope,scenario:$s,needs:(.modelRequired|length),qualified:(.locallyChecked|length),pending:(.pendingCheck|length),rawReadyComponents:(.componentReady|map(.[1])),partialAncestorReadinessIsNotFullOwnerReadiness:true,runtimeAdmitted}' "$dir/case-$s.json"
  done
 done
 jq '{scope:"all-source-routes",scenario:"routes-only",needs:(.modelRequired|length),routes:(.sourceRoute|length),qualified:(.qualifiedSlice|length),ready:(.assuranceReady|length),runtimeAdmitted}' "$r/source-routes.json"
} | jq -s . > "$r/scenario-summary.json"
sysml --version > "$r/sysml-version.txt" 2>&1
quint --version > "$r/quint-version.txt"
lean --version > "$r/lean-version.txt" 2>&1
d2 --version > "$r/d2-version.txt" 2>&1
while IFS= read -r f; do openssl dgst -sha256 "$f"; done < "$r/artifacts.txt" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$r/artifact-bindings.json"
cp -R "$r/." "$e/"
jq -n --slurpfile n "$r/native-values.json" --slurpfile p "$r/planner-full.json" --slurpfile s "$r/scenario-summary.json" --slurpfile h "$r/source-bindings.json" --slurpfile f "$r/formal-checks.json" --slurpfile a "$r/artifact-bindings.json" --slurpfile old "$r/entry-traceability.json" --arg head "$(git rev-parse HEAD)" --arg now "$(date -u +%FT%TZ)" '
 {kind:"modern-c-guaranteed-tail-check-restore-and-whole-round-peak-design",status:"target-kernel-checked-source-and-platform-open",recordedAt:$now,repositoryHead:$head,
 authority:{sysml:"dev/architecture/runtime/gc/models/sysml/guaranteed-tail-placement.sysml",inference:"dev/modeling/ascent/assurance-planner.ss",projection:"dev/modeling/ascent/render-guaranteed-tail-placement.jq"},
 structure:{nativeSysmlFiles:($h[0]|keys|map(select(endswith(".sysml")))|length),nativeEvaluatedScalars:($n[0]|length),components:8,needs:84,directPrerequisites:226,sharedContracts:8,sourceRoutes:36,concreteCallerFamilies:7,prepareMemPstateCalls:6},
 closure:{currentQualifiedLocalSlices:32,inheritedUnchangedSlices:30,currentSourceSimulationOpen:39,currentPlatformOpen:13,currentCompleteComponents:0,legacyGlobalObligationLedgerReclassified:false},
 formal:$f[0],inputIdentity:{modelBundleSha256:$p[0].bundleHash,nativeOutputSha256:$p[0].nativeHash,dslSha256:$p[0].dslHash},sourceBindings:$h[0],artifactBindings:$a[0],
 reasoning:{scenarios:$s[0],scenarioCases:13,runtimeCut:{needs:68,edges:203,completeOwnerComponents:4},buildCut:{needs:56,edges:123,completeOwnerComponents:4},exactUnion:{needs:84,edges:226,sourceRoutes:36},routesProjectionQualifications:0,parserLimitsRaised:false,priorFailureReceiptsPreserved:true,sourceRefinementPromoted:false},
 benefit:{modernCMandatory:true,zigIncrementalBenefitEstablished:false,placement:"Actual backing object plus aligned [lo,hi) per target; sum alone insufficient",tailReuse:"0<=q_i<=min(roleCompatibleUsableTail_i,actualResumeDemand_i); current same-PSTATE reuse credited",phasePeak:"max(preflight/copying,transfer-pending,resumed phases); preflight credits Qg only; late Qo refund cannot lower earlier peak",positivePreflightSpaceCondition:"Guaranteed Qg exceeds extra destination/metadata/held-partial costs against matched separated baseline",readerPolicy:"Short lifecycle-lock admit before pointer exposure; transfer queue pin through final scan; retired parent can derive child before releasing itself",nativeRssOrOomBoundEstablished:false,peakReductionMeasured:false,nativeSpeedupMeasured:false},
 views:{guaranteed:{nativeNodes:9,nativeEdges:12,visuallyReviewed:true},fullGraph:{nodes:84,edges:226,topologyChecked:true,visuallyReviewed:false}},
 predecessor:{receipt:$old[0].checks.path,sha256:$old[0].checks.sha256,rerun:false,inheritedScopesAndDigestsChecked:true},
 primaryEvidence:[{url:"https://simonmar.github.io/bib/papers/parallel-gc.pdf",scope:"sections3.4-3.5; separate allocation/scan frontiers and pending work; no benchmark transfer"},{url:"https://anil.recoil.org/papers/2020-icfp-retropar.pdf",scope:"section4.4; synchronized promotion readiness; no imported fiber semantics or peak claim"}],
 retainedFailures:[],unavailablePaperFullTexts:[],
 execution:{sysmlNativeValidation:true,quintHistoryChecks:true,quintPositiveSimulation:true,leanKernelChecks:true,ascentQueries:true,runtimeImplementation:false,nativeRuntimeTesting:false,performanceValidation:false,commitOrPush:false},runtimePathsRetired:[],org:{parseAndLocalLinksChecked:true,babelExecuted:false}}
 ' > "$e/checks.json"
jq --slurpfile p "$r/native-projection.json" '.benefit={modernCMandatory:true,zigIncrementalBenefitEstablished:false,nativeRows:$p[0].guaranteedCosts,guardCondition:"h<=L and L+max(Bwrite,Baddress)<=end with lower/provenance/alignment checks",wholeRoundCondition:"Every actual candidate phase below the matched baseline peak; lower copy occupancy alone insufficient",baselineDistinction:"Current same-PSTATE reuse credited; Qg substitution evaluated against explicitly separated fresh-resume baseline",lateRefundErasesPastPeak:false,nativeRssOrOomBoundEstablished:false,peakReductionMeasured:false,nativeSpeedupMeasured:false}' "$e/checks.json" > "$r/checks-benefit.json"
cp "$r/checks-benefit.json" "$e/checks.json"
rg --files --hidden --no-ignore "$e" -g '!checks.json' -g '!evidence-bindings.json' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/evidence-bindings.json"
jq --slurpfile b "$e/evidence-bindings.json" '.evidenceArtifactBindings=$b[0]' "$e/checks.json" > "$r/checks-final.json"
cp "$r/checks-final.json" "$e/checks.json"
h=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
jq --slurpfile c "$e/checks.json" --slurpfile a "$r/artifact-bindings.json" --arg h "$h" '
 .kind=$c[0].kind|.status=$c[0].status|.recordedAt=$c[0].recordedAt|
 .checks={path:"evidence/research/guaranteed-tail-placement/checks.json",sha256:$h}|
 .predecessor={snapshot:"evidence/research/guaranteed-tail-placement/entry-traceability.json",scope:"Prior source, formal and native boundaries retained"}|
 .artifactBindings+=$a[0]|
 .componentAssurance.closure=$c[0].closure|
 .componentAssurance.formalResults="evidence/research/guaranteed-tail-placement/formal-checks.json"|
 .componentAssurance.modelBundleSha256=$c[0].inputIdentity.modelBundleSha256|
 .componentModels.needs=84|.componentModels.directPrerequisites=226|.componentModels.currentQualifiedLocalSlices=32|
 .assurancePlanner.nativeScalarFields=$c[0].structure.nativeEvaluatedScalars|.assurancePlanner.nativeModelFiles=$c[0].structure.nativeSysmlFiles|
 .assurancePlanner.scenarioCases=13|.assurancePlanner.sourceRoutes=36|.assurancePlanner.currentQualifiedSlices=32|
 .assurancePlanner.currentOpenSourceNeeds=39|.assurancePlanner.currentOpenPlatformNeeds=13|
 .assurancePlanner.retainedTaskHypotheses=null|.assurancePlanner.selectedHypotheses=1|
 .assurancePlanner.queryCuts={runtime:{needs:68,edges:203,completeOwners:4},build:{needs:56,edges:123,completeOwners:4},sourceRoutes:{needs:84,routes:36,proofReceipts:0},exactUnion:{needs:84,edges:226}}|
 .assurancePlanner.requests=["dev/modeling/ascent/component-assurance.request.scm","dev/modeling/ascent/component-assurance-build.request.scm","dev/modeling/ascent/component-assurance-routes.request.scm"]|
 .guaranteedTailPlacement={design:"dev/architecture/runtime/gc/guaranteed-tail-placement-design.org",matrix:"dev/architecture/runtime/gc/guaranteed-tail-placement-matrix.org",receipt:.checks,formal:$c[0].formal,benefit:$c[0].benefit}|
 .nativeSysmlViews|=map(if .source=="dev/modeling/diagrams/component-proof-dependencies.d2" then .nodes=84|.typedConnections=226|.visuallyReviewed=false else . end)|
 .nativeSysmlViews|=map(select(.source!="dev/architecture/runtime/gc/diagrams/guaranteed-tail-placement.d2"))|
 .nativeSysmlViews+=[{source:"dev/architecture/runtime/gc/diagrams/guaranteed-tail-placement.d2",svg:"dev/architecture/runtime/gc/diagrams/guaranteed-tail-placement.svg",producer:"Native SysML scalar projection; D2 elk",nodes:9,typedConnections:12,visuallyReviewed:true,structureOnly:true}]|
 .execution=$c[0].execution
 ' dev/traceability.json > "$r/traceability-next.json"
cp "$r/traceability-next.json" dev/traceability.json
printf 'Sealed interval/tail/reader receipt %s\n' "$h"
