#!/bin/bash
set -euo pipefail
r=.cache/tasks/component-assurance
e=evidence/research/component-assurance
bash "$r/guard-producers.sh"
bash "$r/assert.sh" > "$r/assertions.log" 2>&1
jq -e '.missingFiles==[] and .missingCustomIds==[] and .duplicateIds==[]' "$r/org-links.json" >/dev/null
jq -e '.exit==0 and ((.errors//[])|length)==0' "$r/native-metadata.json" >/dev/null
rg --files dev -g '*.sysml' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort > "$r/models-after.sha256"
cmp "$r/models-before.sha256" "$r/models-after.sha256"
openssl dgst -sha256 evidence/research/sync-publication-assurance/checks.json dev/modeling/tools/sync-views.py > "$r/preserved-after.sha256"
cmp "$r/preserved-before.sha256" "$r/preserved-after.sha256"
jq -e --slurpfile old "$r/entry-bindings.json" 'del(.modelSourceBindings)==($old[0]|del(.modelSourceBindings))' dev/modeling/formal-bindings.json >/dev/null
jq -r 'to_entries[]|[.key,.value]|@tsv' "$r/source-bindings.json" | while IFS=$'\t' read -r source_file expected_hash; do
 actual_hash=$(openssl dgst -sha256 "$source_file"|awk '{print $NF}'); test "$actual_hash" = "$expected_hash"
done
# Retain text/JSON producers, requests, results and failures; exclude binary caches.
rg --files --hidden --no-ignore "$r" -g '*.json' -g '*.jsonl' -g '*.ss' -g '*.scm' -g '*.log' -g '*.sh' -g '*.el' -g '*.jq' -g '*.sha256' -g '*.txt' -g '*.tsv' -g '*Scopes.lean' | while IFS= read -r source_file; do cp "$source_file" "$e/$(basename "$source_file")"; done
quint --version > "$e/quint-version.txt"
sysml --version > "$e/sysml-version.txt" 2>&1
d2 --version > "$e/d2-version.txt" 2>&1
jq -n --slurpfile p "$r/planner-input.json" --slurpfile f "$r/formal-checks.json" --slurpfile a "$r/case-current.json" --slurpfile m "$r/closure-matrix.json" --slurpfile s "$r/scenario-summary.json" --slurpfile t "$r/structural-summary.json" --slurpfile b "$r/source-bindings.json" --slurpfile o "$r/org-links.json" --slurpfile old "$r/entry-bindings.json" --arg head "$(git rev-parse HEAD)" --arg time "$(date -u +%FT%TZ)" '{
 kind:"modern-c-composed-component-assurance",status:"all-eight-research-chains-routed-source-composition-open",recordedAt:$time,repositoryHead:$head,
 authority:{policy:"dev/modeling/models/sysml/assurance-routing.sysml",build:"dev/architecture/toolchain/models/sysml/component-assurance.sysml",runtimeInterfaces:"dev/architecture/runtime/interfaces/models/sysml/component-assurance.sysml",composition:"dev/modeling/models/sysml/component-assurance.sysml",inference:"dev/modeling/ascent/assurance-planner.ss"},
 inputIdentity:{modelBundleSha256:$p[0].bundleHash,nativeOutputSha256:$p[0].nativeHash,dslSha256:$p[0].dslHash},sourceBindings:$b[0],
 components:$m[0],formal:{newComponentSuites:7,deterministicHistories:29,seed:1,samplesPerHistory:1,exhaustiveVerification:false,livenessProved:false,wholeStepInvariantsProved:false,leanFilesChecked:5,independentNamespaceProbeFiles:2,namespaceScopesForNewComponents:7,records:$f[0],retainedPilotHistory:{tests:15,source:"evidence/research/sync-publication-assurance/checks.json",sourceHashEqualityChecked:true},nativeRefinement:false},
 reasoning:{components:8,needs:32,directPrerequisites:40,sharedContracts:8,scenarioCases:16,structuralControls:5,expectedClosureSetsMatched:true,current:$a[0],scenarios:$s[0].scenarios,structural:$t[0].controls,qualifiedSliceMeaning:"Exact presented need/artifact/check/scope match; not proof of input truth",componentReadyMeaning:"Complete declared evidence frontier with every transitive prerequisite and well-formed reachable graph; not native authority",selectedHypotheses:1,supportObservations:0,nativeRuntimeAdmitted:false},
 structure:{nativeSysmlFiles:38,nativeEvaluatedScalars:497,nativeView:{nodes:12,typedConnections:19},dependencyView:{needNodes:32,edges:40,clusters:8,producer:"presentation-only serialization of native evaluated endpoints"},visuallyReviewed:true,satisfactionClaimed:false},org:$o[0],
 preservation:{legacyFormalSources:($old[0].sources|length),legacyFormalHashEqualityChecked:true,legacyRegistryNonHashFieldsUnchanged:true,priorScopedReceiptUnchanged:true,legacyPythonDeriverUnchanged:true,earlierPilotRequestRetained:true,sourceAndFormLimitFailuresRetained:true,nativeAdapterDiagnosticsRetained:true,recorderFailure:"Record script was edited during execution; partial data retained; fixed immutable retry succeeded",failedReceiptsPromoted:false},
 execution:{nativeSysmlValidation:true,nativeMetadataLookup:true,quintTypecheck:true,quintTests:true,leanCheck:true,exactNamespaceProbes:true,ascentQueries:true,orgParseAndLinks:true,newPythonMaintained:false,legacyPythonDeriverRun:false,runtimeImplementation:false,nativeRuntimeTesting:false,performanceValidation:false},
 closure:{currentQualifiedLocalSlices:16,currentSourceSimulationOpen:8,currentPlatformOpen:8,currentCompleteComponents:0,legacyGlobalObligationLedgerReclassified:false},
 remaining:["Actual GSC dynamic effects, immutable image and observation reflection","Full weighted population and parent/child progress","Complete publication group and physical I/O/cleanup","Nonzero processor root/RC scan closure and allocation-safe marker inputs","FrameSpec/origin and real chunk/Tail/weak/foreign producer coverage","Concrete C memory/owner/exit and physical destructor/user drain","Complete target step invariants, terminal stability, simulation and progress","Externally supplied receipt authentication and toolchain trusted inputs"],
 quantitativeBoundary:{nativeSpeedup:null,personDaysUsed:false,gains:"Conditional elimination of duplicate generation, coordination, scanning and unsafe implicit ownership; added validation, contention and retention must be bounded",zigSpecificGainEstablished:false},runtimePathsRetired:0,buildPathsRetired:0,nativeProfilesAccepted:0,registeredClaimsPromoted:0
}' > "$e/checks.json"
