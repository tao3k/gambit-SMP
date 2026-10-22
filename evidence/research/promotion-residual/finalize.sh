#!/bin/bash
set -euo pipefail
r=.cache/tasks/promotion-residual
e=evidence/research/promotion-residual
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
jq -n --slurpfile n "$r/native-projection.json" --slurpfile q "$r/global-qualified.json" '{qnt:{source:"models/gambit/promotion_residual.qnt",namedHistories:17,initialSeed:17,positiveSamples:100,maxSteps:80,invariant:"safe",exhaustive:false,liveness:false,scope:"Two unique objects/two cards/one writer/one handoff; conservative branch retains source"},lean:{source:"models/gambit/lean/PromotionResidual.lean",namedStatements:10,exactNamesProbed:true,wholeQntStepInduction:false,sourceRefinement:false},nativeSchemas:{partDefinitions:2,requirementDefinitions:2,satisfiedInstancesClaimed:false},exactNewScopes:[$n[0].refinementNeeds[]|select(.obligationId|startswith("PR-"))],allQualifiedLocalSlices:$q[0],nativeRuntimeTest:false}' > "$r/formal-checks.json"
for dir in "$r" "$r/build-cut"; do
 for s in $(jq -r '.cases[].id' "$dir/scenarios.json"); do
  jq --arg scope "$(basename "$dir")" --arg s "$s" '{scope:$scope,scenario:$s,needs:(.modelRequired|length),qualified:(.locallyChecked|length),pending:(.pendingCheck|length),completeComponents:(.componentReady|map(.[1])),runtimeAdmitted}' "$dir/case-$s.json"
 done
done | jq -s . > "$r/scenario-summary.json"
sysml --version > "$r/sysml-version.txt" 2>&1
quint --version > "$r/quint-version.txt"
lean --version > "$r/lean-version.txt" 2>&1
d2 --version > "$r/d2-version.txt" 2>&1
while IFS= read -r f; do openssl dgst -sha256 "$f"; done < "$r/artifacts.txt" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$r/artifact-bindings.json"
cp -R "$r/." "$e/"
jq -n --slurpfile n "$r/native-values.json" --slurpfile p "$r/planner-full.json" --slurpfile g "$r/global-qualified.json" --slurpfile s "$r/scenario-summary.json" --slurpfile h "$r/source-bindings.json" --slurpfile f "$r/formal-checks.json" --slurpfile a "$r/artifact-bindings.json" --slurpfile old "$r/entry-traceability.json" --arg head "$(git rev-parse HEAD)" --arg now "$(date -u +%FT%TZ)" '
 {kind:"modern-c-promotion-capacity-and-residual-epoch-design",status:"target-kernel-checked-source-and-memory-open",recordedAt:$now,repositoryHead:$head,
 authority:{sysml:"dev/architecture/runtime/gc/models/sysml/promotion-residual.sysml",inference:"dev/modeling/ascent/assurance-planner.ss",projection:"dev/modeling/ascent/render-promotion-residual.jq"},
 structure:{nativeSysmlFiles:($h[0]|keys|map(select(endswith(".sysml")))|length),nativeEvaluatedScalars:($n[0]|length),components:8,needs:72,directPrerequisites:179,sharedContracts:8,sourceRoutes:28},
 closure:{currentQualifiedLocalSlices:28,inheritedUnchangedSlices:26,currentSourceSimulationOpen:32,currentPlatformOpen:12,currentCompleteComponents:0,legacyGlobalObligationLedgerReclassified:false},
 formal:$f[0],inputIdentity:{modelBundleSha256:$p[0].bundleHash,nativeOutputSha256:$p[0].nativeHash,dslSha256:$p[0].dslHash},sourceBindings:$h[0],artifactBindings:$a[0],
 reasoning:{scenarios:$s[0],scenarioCases:12,runtimeCut:{needs:60,edges:162,completeOwnerComponents:5},buildCut:{needs:56,edges:123,completeOwnerComponents:3},exactUnion:{needs:72,edges:179,sourceRoutes:28},parserLimitsRaised:false,fullRequestFailureRetained:true,sourceRefinementPromoted:false},
 benefit:{modernCMandatory:true,zigIncrementalBenefitEstablished:false,frameHeapWords:"fs+2",frameSourceWords:"roundUp(fs+3,4)",maxAdmittedFrameWords:8194,maxFrameBytesAtWord8:65552,payloadBound:"Bpayload<=Y+S only with closed no-handle unchanged layouts",physicalBound:"Bdest+Bwork+Bresume with disjoint committed intervals; packing and platform proof open",workCondition:"A<(k-1)*M with complete matched-work premises",extraMetadataFloor:"C*b+Ls*entryBytes+N*descriptorBytes relative to already-budgeted single bank and context logs",loserBodySavingClaimed:false,peakMemoryImprovementClaimed:false,nativeSpeedupMeasured:false},
 views:{promotion:{nativeNodes:8,nativeEdges:8,visuallyReviewed:true},fullGraph:{nodes:72,edges:179,topologyChecked:true,visuallyReviewed:false}},
 predecessor:{receipt:$old[0].checks.path,sha256:$old[0].checks.sha256,rerun:false,inheritedScopesAndDigestsChecked:true},
 primaryEvidence:[{url:"https://anil.recoil.org/papers/2020-icfp-retropar.pdf",scope:"section4.4; parallel promotion and C API tradeoff; no benchmark transfer"},{url:"https://simonmar.github.io/bib/papers/parallel-gc.pdf",scope:"sections2.1,4.1; aging residual edges re-recorded after scavenging; not proof of residuals in all-promote target"}],
 retainedFailures:["quint-initial-failure.log","lean-initial-failure.log","quint-closed-epoch-failure.log","quint-closed-epoch-simulation-failure.log","native-keyword-failure.json","native-redefinition-failure.json","full-request-byte-bound.ss","full-request-byte-bound.log"],
 execution:{sysmlNativeValidation:true,quintHistoryChecks:true,quintPositiveSimulation:true,leanKernelChecks:true,ascentQueries:true,runtimeImplementation:false,nativeRuntimeTesting:false,performanceValidation:false,commitOrPush:false},runtimePathsRetired:[],org:{parseAndLocalLinksChecked:true,babelExecuted:false}}
 ' > "$e/checks.json"
rg --files --hidden --no-ignore "$e" -g '!checks.json' -g '!evidence-bindings.json' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$e/evidence-bindings.json"
jq --slurpfile b "$e/evidence-bindings.json" '.evidenceArtifactBindings=$b[0]' "$e/checks.json" > "$r/checks-final.json"
cp "$r/checks-final.json" "$e/checks.json"
h=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
jq --slurpfile c "$e/checks.json" --slurpfile a "$r/artifact-bindings.json" --slurpfile m "$r/model-bindings.json" --arg h "$h" '
 .kind=$c[0].kind|.status=$c[0].status|.recordedAt=$c[0].recordedAt|
 .checks={path:"evidence/research/promotion-residual/checks.json",sha256:$h}|
 .predecessor={snapshot:"evidence/research/promotion-residual/entry-traceability.json",scope:"Prior source, formal and native boundaries retained"}|
 .artifactBindings+=$a[0]|
 .componentAssurance.closure=$c[0].closure|
 .assurancePlanner.nativeScalarFields=$c[0].structure.nativeEvaluatedScalars|.assurancePlanner.nativeModelFiles=$c[0].structure.nativeSysmlFiles|
 .assurancePlanner.scenarioCases=12|.assurancePlanner.sourceRoutes=28|
 .assurancePlanner.currentQualifiedSlices=28|.assurancePlanner.currentOpenSourceNeeds=32|.assurancePlanner.currentOpenPlatformNeeds=12|
 .assurancePlanner.retainedTaskHypotheses=null|.assurancePlanner.selectedHypotheses=1|
 .assurancePlanner.queryCuts={runtime:{needs:60,edges:162},build:{needs:56,edges:123},exactUnion:{needs:72,edges:179}}|
 .assurancePlanner.requests=["dev/modeling/ascent/component-assurance.request.scm","dev/modeling/ascent/component-assurance-build.request.scm"]|
 .componentAssurance.formalResults="evidence/research/promotion-residual/formal-checks.json"|
 .componentAssurance.modelBundleSha256=$c[0].inputIdentity.modelBundleSha256|
 .componentModels.needs=72|.componentModels.directPrerequisites=179|.componentModels.currentQualifiedLocalSlices=28|
 .promotionResidual={design:"dev/architecture/runtime/gc/promotion-residual-design.org",matrix:"dev/architecture/runtime/gc/promotion-residual-matrix.org",receipt:.checks,formal:$c[0].formal,benefit:$c[0].benefit}|
 .nativeSysmlViews|=map(if .source=="dev/modeling/diagrams/component-proof-dependencies.d2" then .nodes=72|.typedConnections=179|.visuallyReviewed=false else . end)|
 .nativeSysmlViews|=map(select(.source!="dev/architecture/runtime/gc/diagrams/promotion-residual.d2"))|
 .nativeSysmlViews+=[{source:"dev/architecture/runtime/gc/diagrams/promotion-residual.d2",svg:"dev/architecture/runtime/gc/diagrams/promotion-residual.svg",producer:"Native SysML scalar projection; D2 elk",nodes:8,typedConnections:8,visuallyReviewed:true,structureOnly:true}]|
 .execution=$c[0].execution
 ' dev/traceability.json > "$r/traceability-next.json"
cp "$r/traceability-next.json" dev/traceability.json
printf 'Sealed source-bound promotion/residual receipt %s\n' "$h"
