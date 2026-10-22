#!/bin/bash
set -euo pipefail
r=.cache/tasks/promotion-residual
bash "$r/read-native.sh" > "$r/native.log" 2>&1
bash "$r/compose.sh" > "$r/compose.log" 2>&1
cp "$r/planner-input.json" "$r/planner-full.json"
.venv/bin/gambit-smp --task promotion-residual trajectory submit < "$r/submit.request.scm" > "$r/submit.read.scm" 2> "$r/submit.log"
jq --arg cut runtime -f "$r/cuts.jq" "$r/planner-full.json" > "$r/runtime-input.json"
jq --arg cut build -f "$r/cuts.jq" "$r/planner-full.json" > "$r/build-input.json"
cp "$r/runtime-input.json" "$r/planner-input.json"
sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/common.ss"
jq -r -f "$r/facts.jq" "$r/planner-input.json" >> "$r/common.ss"
bash "$r/render-cases.sh"
bash "$r/run-queries.sh" current all-scoped-control models-only omit-bound omit-residual omit-ffi omit-memory omit-host-freeze wrong-detail-scope stale-detail-digest > "$r/queries.log" 2>&1
cp "$r/build-input.json" "$r/build-cut/planner-input.json"
sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/build-cut/common.ss"
jq -r -f "$r/facts.jq" "$r/build-input.json" >> "$r/build-cut/common.ss"
bash "$r/build-cut/render-cases.sh"
bash "$r/build-cut/run-queries.sh" current all-scoped-control > "$r/build-cut/queries.log" 2>&1
bash "$r/assert.sh" > "$r/assertions.log" 2>&1
cp "$r/case-current.request.scm" dev/modeling/ascent/component-assurance.request.scm
cp "$r/build-cut/case-current.request.scm" dev/modeling/ascent/component-assurance-build.request.scm
jq -r --arg view matrix -f dev/modeling/ascent/render-promotion-residual.jq "$r/native-projection.json" > dev/architecture/runtime/gc/promotion-residual-matrix.org
