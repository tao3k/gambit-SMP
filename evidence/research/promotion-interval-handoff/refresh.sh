#!/bin/bash
set -euo pipefail
r=.cache/tasks/promotion-interval-handoff
bash "$r/read-native.sh" > "$r/native.log" 2>&1
bash "$r/compose.sh" > "$r/compose.log" 2>&1
cp "$r/planner-input.json" "$r/planner-full.json"
.venv/bin/gambit-smp --task promotion-interval-handoff trajectory submit < "$r/submit.request.scm" > "$r/submit.read.scm" 2> "$r/submit.log"
for cut in runtime build; do
 jq --arg cut "$cut" -f "$r/cuts.jq" "$r/planner-full.json" > "$r/$cut-input.json"
done
cp "$r/runtime-input.json" "$r/planner-input.json"
sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/common.ss"
jq '.sourceRoutes=[]' "$r/planner-input.json" | jq -r -f "$r/facts.jq" >> "$r/common.ss"
bash "$r/render-cases.sh"
bash "$r/run-queries.sh" current all-scoped-control models-only omit-extents omit-tail omit-readers omit-memory omit-root-lifetime wrong-detail-scope stale-detail-digest > "$r/queries.log" 2>&1
cp "$r/build-input.json" "$r/build-cut/planner-input.json"
cp "$r/inherited.json" "$r/build-cut/inherited.json"
sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/build-cut/common.ss"
jq '.sourceRoutes=[]' "$r/build-input.json" | jq -r -f "$r/facts.jq" >> "$r/build-cut/common.ss"
bash "$r/build-cut/render-cases.sh"
bash "$r/build-cut/run-queries.sh" current all-scoped-control > "$r/build-cut/queries.log" 2>&1
# All needs/source routes, no dependency or receipt qualification in this projection.
sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/source-routes.ss"
jq '.dependencies=[]|.edgeGroups=[]' "$r/planner-full.json" | jq -r -f "$r/facts.jq" >> "$r/source-routes.ss"
printf ' (fact (scenarioFact "routes-only" "traceability-projection-only"))\n)\n' >> "$r/source-routes.ss"
jq -nr --rawfile s "$r/source-routes.ss" --slurpfile i "$r/planner-full.json" '"((selector "+($s|@json)+") (constructor \"query\") (displayBytes 1048576) (bindings "+([["target-model-bundle-sha256",$i[0].bundleHash],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")")+"))"' > "$r/source-routes.request.scm"
.venv/bin/gambit-smp --task promotion-interval-handoff trajectory clues < "$r/source-routes.request.scm" > "$r/source-routes.read.scm" 2> "$r/source-routes.log"
ASSURANCE_READ="$r/source-routes.read.scm" ASSURANCE_JSON="$r/source-routes.json" emacs -Q --batch -l "$r/read-association.el"
cp "$r/case-current.request.scm" dev/modeling/ascent/component-assurance.request.scm
cp "$r/build-cut/case-current.request.scm" dev/modeling/ascent/component-assurance-build.request.scm
cp "$r/source-routes.request.scm" dev/modeling/ascent/component-assurance-routes.request.scm
