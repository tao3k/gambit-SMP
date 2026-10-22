#!/bin/bash
set -euo pipefail
r=.cache/tasks/component-assurance
printf '%s\n' 'import IncrementalBuild' > "$r/BuildScopes.lean"
jq -r '.components[:3][].leanScope|split(":") as $s|$s[1]|split(";")[]|"#check "+$s[0]+"."+.' "$r/native-projection.json" >> "$r/BuildScopes.lean"
printf '%s\n' 'import WorkAccounting' 'import HostRootParticipation' 'import SavedStackRetirementWindow' > "$r/RuntimeScopes.lean"
jq -r '.components[3:7][].leanScope|split(":") as $s|$s[1]|split(";")[]|"#check "+$s[0]+"."+.' "$r/native-projection.json" >> "$r/RuntimeScopes.lean"
LEAN_PATH="$(pwd)/$r" lean +leanprover/lean4:v4.35.0 "$r/BuildScopes.lean" > "$r/BuildScopes.log" 2>&1
root_dir=$(pwd)
cd models/gambit/lean
LEAN_PATH="$root_dir/$r:$root_dir/models/gambit/lean/.lake/packages/LeanPoo/.lake/build/lib/lean" lean "$root_dir/$r/RuntimeScopes.lean" > "$root_dir/$r/RuntimeScopes.log" 2>&1
