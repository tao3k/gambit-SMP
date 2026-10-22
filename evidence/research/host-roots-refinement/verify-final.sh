#!/bin/bash
set -euo pipefail
r=.cache/tasks/host-roots-refinement
e=evidence/research/host-roots-refinement
verify_bindings() {
 jq -r 'to_entries[]|[.key,.value]|@tsv' "$1" | while IFS=$'\t' read -r f expected; do
  actual=$(openssl dgst -sha256 "$f"|awk '{print $NF}'); test "$actual" = "$expected"
 done
}
verify_bindings "$e/source-bindings.json"
verify_bindings "$e/artifact-bindings.json"
verify_bindings "$e/evidence-bindings.json"
actual=$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')
jq -e --arg h "$actual" '.checks.path=="evidence/research/host-roots-refinement/checks.json" and .checks.sha256==$h and .componentModels.needs==40 and .componentModels.directPrerequisites==66' dev/traceability.json >/dev/null
jq -e --slurpfile a "$e/source-bindings.json" --slurpfile b "$e/artifact-bindings.json" --slurpfile c "$e/evidence-bindings.json" '.sourceBindings==$a[0] and .artifactBindings==$b[0] and .evidenceArtifactBindings==$c[0] and .closure.currentCompleteComponents==0 and .execution.runtimeImplementation==false and .execution.nativeRuntimeTesting==false' "$e/checks.json" >/dev/null
jq -e --slurpfile p "$e/entry-formal-bindings.json" 'del(.modelSourceBindings)==($p[0]|del(.modelSourceBindings))' dev/modeling/formal-bindings.json >/dev/null
jq -e --slurpfile a .cache/tasks/component-assurance/case-current.json '.reasoning.current==$a[0]' evidence/research/component-assurance/checks.json >/dev/null
jq -e --slurpfile a evidence/research/component-assurance/source-bindings.json '.sourceBindings==$a[0]' evidence/research/component-assurance/checks.json >/dev/null
jq -e --slurpfile p "$e/model-bindings.json" '.modelSourceBindings==$p[0]' dev/modeling/formal-bindings.json >/dev/null
jq -e '(.needs|length)==40 and (.needs|map([.component,.obligationId])|unique|length)==40 and (.dependencies|length)==66' "$e/planner-input.json" >/dev/null
jq -e '.reasoning.scenarioCases==12 and .closure.currentQualifiedLocalSlices==18 and .closure.currentSourceSimulationOpen==14 and .closure.currentPlatformOpen==8 and .reasoning.current.runtimeAdmitted==false' "$e/checks.json" >/dev/null
bash "$r/assert.sh"
test "$(rg -c ' -> ' dev/modeling/diagrams/component-proof-dependencies.d2)" = 66
test "$(rg -c ' -> ' dev/architecture/runtime/ffi/diagrams/host-roots-refinement.d2)" = 40
! rg -n '\bsorry\b|\badmit\b' models/gambit/lean/HostRootsRefinement.lean
! rg -q 'error:|sorryAx' "$e/lean-refinement.log"
jq -e '.missingFiles==[] and .missingCustomIds==[] and .duplicateIds==[]' "$e/org-links.json" >/dev/null
openssl dgst -sha256 evidence/research/component-assurance/checks.json patches/fixtures/processor-interrupt-collective-wait-cumulative.patch vendor/gambit/lib/{mem,c_intf,setup,os_dyn,os_thread}.c vendor/gambit/include/gambit.h.in > "$r/final-preserved.sha256"
cmp "$r/entry-sources.sha256" "$r/final-preserved.sha256"
for script in "$r"/*.sh; do bash -n "$script"; done
printf 'Verified current source/artifact/evidence bindings, 40 needs/66 edges, 12 ASCENT controls, formal scopes, Org links and unchanged runtime/patch/predecessor.\n'
