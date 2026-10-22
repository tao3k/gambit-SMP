#!/bin/bash
set -euo pipefail
root_dir=$(pwd)
r="$root_dir/.cache/tasks/component-assurance"
lean +leanprover/lean4:v4.35.0 --version > "$r/build-lean-version.txt"
lean +leanprover/lean4:v4.35.0 -o "$r/IncrementalBuild.olean" models/build/IncrementalBuild.lean > "$r/IncrementalBuild.lean.log" 2>&1
cd models/gambit/lean
lean --version > "$r/runtime-lean-version.txt"
export LEAN_PATH="$r:$root_dir/models/gambit/lean/.lake/build/lib/lean:$root_dir/models/gambit/lean/.lake/packages/LeanPoo/.lake/build/lib/lean"
for proof_file in WorkAccounting.lean HostRootParticipation.lean SavedStackRetirementWindow.lean SynchronousPublication.lean; do
 lean -o "$r/${proof_file%.lean}.olean" "$proof_file" > "$r/$proof_file.log" 2>&1 || exit 1
done
