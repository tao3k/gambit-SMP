#!/bin/bash
set -euo pipefail
r=.cache/tasks/host-roots-refinement
for case_id in current all-scoped-control scan-only save-only omit-rc omit-marker omit-boot omit-exit omit-binding omit-dynamic wrong-detail-scope stale-detail-digest; do
 jq -e '.runtimeAdmitted==false and .presentationComplete==true and .counts.support==0 and .counts.hypotheses==1 and (.modelRequired|length)==40 and (.sharedContract|length)==8 and (.sourceRoute|length)==6 and (.dependencyCycle|length)==0 and (.danglingDependency|length)==0 and (.unboundDependency|length)==0 and (.unroutedNeed|length)==0' "$r/case-$case_id.json" > "$r/assert-$case_id.log"
 case "$case_id" in
 current) jq -e '(.locallyChecked|length)==18 and (.componentReady|length)==0 and (.componentFrontier|length)==22' "$r/case-$case_id.json" >> "$r/assert-$case_id.log" ;;
 all-scoped-control) jq -e '(.locallyChecked|length)==40 and (.componentReady|map(.[1])|sort)==["build-planner","build-publisher","build-scheduler","continuation","gc-synchronous-publication","gc-work","host-roots","resource-exit"]' "$r/case-$case_id.json" >> "$r/assert-$case_id.log" ;;
 *) jq -e '(.componentReady|map(.[1])|sort)==["build-planner","build-scheduler"]' "$r/case-$case_id.json" >> "$r/assert-$case_id.log" ;;
 esac
done
for need in HR-RC HR-MARKER HR-BOOT HR-EXIT HR-BIND HR-DYNAMIC; do
 jq -e --arg n "$need" '.unmetDependency|contains([["current","host-roots","HR-S","host-roots",$n],["current","continuation","CO-S","host-roots",$n],["current","gc-work","GW-S","host-roots",$n],["current","resource-exit","RX-S","host-roots",$n],["current","gc-synchronous-publication","SP-SOURCE","host-roots",$n],["current","build-publisher","BU-S","host-roots",$n]])' "$r/case-current.json" >> "$r/assert-current.log"
done
jq -e '(.locallyChecked|contains([["scan-only","host-roots","HR-RC"],["scan-only","host-roots","HR-S"]])) and (.assuranceReady|all(.[];.[2]!="HR-S"))' "$r/case-scan-only.json" >> "$r/assert-scan-only.log"
jq -e '(.locallyChecked|contains([["save-only","host-roots","HR-MARKER"],["save-only","host-roots","HR-S"]])) and (.assuranceReady|all(.[];.[2]!="HR-S"))' "$r/case-save-only.json" >> "$r/assert-save-only.log"
jq -e '.qualifiedSlice|all(.[];.[2]!="HR-DI")' "$r/case-wrong-detail-scope.json" >> "$r/assert-wrong-detail-scope.log"
jq -e '.qualifiedSlice|all(.[];.[2]!="HR-DH")' "$r/case-stale-detail-digest.json" >> "$r/assert-stale-detail-digest.log"
jq -e --slurpfile p "$r/native-projection.json" '(.sourceRoute|map(.[1:])|sort)==($p[0].sourceRoutes|map([.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status])|sort)' "$r/case-current.json" >> "$r/assert-current.log"
