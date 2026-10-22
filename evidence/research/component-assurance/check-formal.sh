#!/bin/bash
# Formal producers only. Every result is tied to its current source bytes.
set -euo pipefail
root_dir=$(pwd)
r="$root_dir/.cache/tasks/component-assurance"
: > "$r/formal-records.jsonl"
record_check() {
 local source_file=$1 stage=$2 log_file=$3
 shift 3
 local status_code=0
 if "$@" > "$log_file" 2>&1; then status_code=0; else status_code=$?; fi
 local source_hash
 source_hash=$(openssl dgst -sha256 "$source_file"|awk '{print $NF}')
 local check_scope=""
 if test "$stage" = bounded-histories; then check_scope="$(basename "$source_file" .qnt):Test\$"; fi
 jq -n --arg source "$source_file" --arg stage "$stage" --arg scope "$check_scope" --arg log "$log_file" --arg sha "$source_hash" --argjson rc "$status_code" '{source:$source,stage:$stage,sourceSha256:$sha,scope:$scope,exitCode:$rc,log:$log}' >> "$r/formal-records.jsonl"
 test "$status_code" = 0
}
for source_file in models/build/{planner,scheduler,publisher}_contract.qnt models/gambit/{gc_work,host_roots,continuation,resource_exit}_contract.qnt; do
 model_name=$(basename "$source_file" .qnt)
 record_check "$source_file" typecheck "$r/$model_name.typecheck.log" quint typecheck "$source_file"
 record_check "$source_file" bounded-histories "$r/$model_name.tests.log" quint test "$source_file" --backend typescript --seed 1 --max-samples 1 --match 'Test$' --out-itf "$r/${model_name}_{test}_{seq}.itf.json"
done
record_check models/build/IncrementalBuild.lean inductive-preservation "$r/IncrementalBuild.lean.log" lean +leanprover/lean4:v4.35.0 -o "$r/IncrementalBuild.olean" models/build/IncrementalBuild.lean
cd models/gambit/lean
export LEAN_PATH="$r:$root_dir/models/gambit/lean/.lake/build/lib/lean:$root_dir/models/gambit/lean/.lake/packages/LeanPoo/.lake/build/lib/lean"
for proof_file in WorkAccounting.lean HostRootParticipation.lean SavedStackRetirementWindow.lean SynchronousPublication.lean; do
 record_check "$proof_file" inductive-preservation "$r/$proof_file.log" lean -o "$r/${proof_file%.lean}.olean" "$proof_file"
done
cd "$root_dir"
record_check "$r/BuildScopes.lean" scope-probe "$r/BuildScopes.log" env LEAN_PATH="$r" lean +leanprover/lean4:v4.35.0 "$r/BuildScopes.lean"
cd models/gambit/lean
record_check "$r/RuntimeScopes.lean" scope-probe "$r/RuntimeScopes.log" lean "$r/RuntimeScopes.lean"
cd "$root_dir"
# Normalize local proof filenames after the successfully observed invocations.
jq -s 'map(if (.source|contains("/")) then . else .source=("models/gambit/lean/"+.source) end)' "$r/formal-records.jsonl" > "$r/formal-checks.json"
