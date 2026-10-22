#!/bin/bash
set -euo pipefail
r=.cache/tasks/component-assurance
printf '%s\n' 'import IncrementalBuild' > "$r/BuildScopes.lean"
jq -r '.components[:3][].leanScope|split(":") as $s|$s[1]|split(";")[]|"#check "+$s[0]+"."+.' "$r/native-projection.json" >> "$r/BuildScopes.lean"
printf '%s\n' 'import WorkAccounting' 'import HostRootParticipation' 'import SavedStackRetirementWindow' > "$r/RuntimeScopes.lean"
jq -r '.components[3:7][].leanScope|split(":") as $s|$s[1]|split(";")[]|"#check "+$s[0]+"."+.' "$r/native-projection.json" >> "$r/RuntimeScopes.lean"
