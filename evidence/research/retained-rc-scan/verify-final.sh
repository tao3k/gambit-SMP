#!/bin/bash
set -euo pipefail
r=.cache/tasks/retained-rc-scan
e=evidence/research/retained-rc-scan
verify_bindings() {
 jq -r 'to_entries[]|[.key,.value]|@tsv' "$1" | while IFS=$'\t' read -r f expected; do
  actual=$(openssl dgst -sha256 "$f"|awk '{print $NF}'); test "$actual" = "$expected"
 done
}
verify_bindings "$e/source-bindings.json"
verify_bindings "$e/artifact-bindings.json"
verify_bindings "$e/evidence-bindings.json"
actual=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
jq -e --arg h "$actual" '.checks.path=="evidence/research/retained-rc-scan/checks.json" and .checks.sha256==$h and .componentModels.needs==48 and .componentModels.directPrerequisites==94' dev/traceability.json >/dev/null
jq -e --slurpfile a "$e/source-bindings.json" --slurpfile b "$e/artifact-bindings.json" --slurpfile c "$e/evidence-bindings.json" '.sourceBindings==$a[0] and .artifactBindings==$b[0] and .evidenceArtifactBindings==$c[0] and .closure.currentCompleteComponents==0 and .execution.runtimeImplementation==false and .execution.nativeRuntimeTesting==false' "$e/checks.json" >/dev/null
jq -e --slurpfile p "$e/entry-formal-bindings.json" 'del(.modelSourceBindings)==($p[0]|del(.modelSourceBindings))' dev/modeling/formal-bindings.json >/dev/null
jq -e --slurpfile p "$e/model-bindings.json" '.modelSourceBindings==$p[0]' dev/modeling/formal-bindings.json >/dev/null
jq -e '(.needs|length)==48 and (.needs|map([.component,.obligationId])|unique|length)==48 and (.dependencies|length)==94 and (.edgeGroups|add|sort)==(.dependencies|sort)' "$e/planner-input.json" >/dev/null
jq -e '.reasoning.scenarioCases==12 and .closure.currentQualifiedLocalSlices==20 and .closure.currentSourceSimulationOpen==19 and .closure.currentPlatformOpen==9 and .reasoning.current.runtimeAdmitted==false' "$e/checks.json" >/dev/null
bash "$r/assert.sh"
test "$(rg -c ' -> ' dev/modeling/diagrams/component-proof-dependencies.d2)" = 94
test "$(rg -c ' -> ' dev/architecture/runtime/ffi/diagrams/host-roots-refinement.d2)" = 74
test "$(rg -c ' -> ' dev/architecture/runtime/ffi/diagrams/retained-rc-scan.d2)" = 46
! rg -n '\bsorry\b|\badmit\b' models/gambit/lean/RetainedRcScan.lean
! rg -q 'error:|sorryAx' "$e/lean-refinement.log"
rg -q '15 passing' "$e/quint-final-tests.log"
rg -q 'No violation found' "$e/quint-final-simulation.log"
jq -e '.missingFiles==[] and .missingCustomIds==[] and .duplicateIds==[]' "$e/org-links.json" >/dev/null
openssl dgst -sha256 evidence/research/host-roots-refinement/checks.json evidence/research/component-assurance/checks.json patches/fixtures/processor-interrupt-collective-wait-cumulative.patch vendor/gambit/lib/{mem,setup,os_thread}.c vendor/gambit/include/gambit.h.in models/gambit/host_roots_refinement.qnt models/gambit/lean/HostRootsRefinement.lean > "$r/final-preserved.sha256"
cmp "$r/entry-sources.sha256" "$r/final-preserved.sha256"
for script in "$r"/*.sh; do bash -n "$script"; done
printf 'Verified source/artifact/evidence identities, 48 needs/94 edges, 12 ASCENT controls, formal scopes and bounds, Org links, unchanged runtime/patch and predecessor receipts.\n'
