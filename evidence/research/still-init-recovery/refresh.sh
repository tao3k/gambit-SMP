#!/bin/bash
set -euo pipefail
r=.cache/tasks/still-init-recovery
bash "$r/read-native.sh" > "$r/native.log" 2>&1
bash "$r/compose.sh" > "$r/compose.log" 2>&1
cp "$r/planner-input.json" "$r/planner-full.json"
.venv/bin/gambit-smp --task still-init-recovery trajectory submit < "$r/submit.request.scm" > "$r/submit.read.scm" 2> "$r/submit.log"
for cut in runtime build; do
 jq --arg cut "$cut" -f "$r/cuts.jq" "$r/planner-full.json" > "$r/$cut-input.json"
done
cp "$r/runtime-input.json" "$r/planner-input.json"
ASSURANCE_CORE="$r/common.ss" emacs -Q --batch -l "$r/specialize-inference.el"
jq '.sourceRoutes=[]|.contracts=[]' "$r/planner-input.json" | jq -r -f "$r/facts.jq" >> "$r/common.ss"
bash "$r/render-cases.sh"
bash "$r/render-pair-controls.sh"
bash "$r/run-queries.sh" current all-scoped-control models-only omit-progress omit-roots omit-delivery omit-abort omit-root-binding wrong-detail-scope stale-detail-digest paired-stale-detail paired-nonpass-status > "$r/queries.log" 2>&1
cp "$r/build-input.json" "$r/build-cut/planner-input.json"
cp "$r/inherited.json" "$r/build-cut/inherited.json"
ASSURANCE_CORE="$r/build-cut/common.ss" emacs -Q --batch -l "$r/specialize-inference.el"
jq '.sourceRoutes=[]|.contracts=[]' "$r/build-input.json" | jq -r -f "$r/facts.jq" >> "$r/build-cut/common.ss"
bash "$r/build-cut/render-cases.sh"
bash "$r/build-cut/run-queries.sh" current all-scoped-control > "$r/build-cut/queries.log" 2>&1
bash "$r/render-route-cuts.sh"
