#!/bin/bash
set -euo pipefail
r=.cache/tasks/still-init-recovery
for suffix in '' '-tail'; do
 if [[ -z "$suffix" ]]; then
  jq '.dependencies=[]|.edgeGroups=[]|.sourceRoutes=.sourceRoutes[:23]' "$r/planner-full.json" > "$r/source-routes-input.json"
 else
  jq '.dependencies=[]|.edgeGroups=[]|.sourceRoutes=.sourceRoutes[23:]|.contracts=[]' "$r/planner-full.json" > "$r/source-routes-tail-input.json"
 fi
 sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/source-routes$suffix.ss"
 jq -r -f "$r/facts.jq" "$r/source-routes$suffix-input.json" >> "$r/source-routes$suffix.ss"
 printf ' (fact (scenarioFact "routes-only" "traceability-projection-only"))\n)\n' >> "$r/source-routes$suffix.ss"
 jq -nr --rawfile s "$r/source-routes$suffix.ss" --slurpfile i "$r/planner-full.json" '"((selector "+($s|@json)+") (constructor \"query\") (displayBytes 1048576) (bindings "+([["target-model-bundle-sha256",$i[0].bundleHash],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")")+"))"' > "$r/source-routes$suffix.request.scm"
 .venv/bin/gambit-smp --task still-init-recovery trajectory clues < "$r/source-routes$suffix.request.scm" > "$r/source-routes$suffix.read.scm" 2> "$r/source-routes$suffix.log"
 ASSURANCE_READ="$r/source-routes$suffix.read.scm" ASSURANCE_JSON="$r/source-routes$suffix.json" emacs -Q --batch -l "$r/read-association.el"
done
cp "$r/case-current.request.scm" dev/modeling/ascent/component-assurance.request.scm
cp "$r/build-cut/case-current.request.scm" dev/modeling/ascent/component-assurance-build.request.scm
cp "$r/source-routes.request.scm" dev/modeling/ascent/component-assurance-routes.request.scm
cp "$r/source-routes-tail.request.scm" dev/modeling/ascent/component-assurance-routes-tail.request.scm
