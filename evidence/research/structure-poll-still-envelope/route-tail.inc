# All needs/source routes, no dependency or receipt qualification in this projection.
sed '$d' dev/modeling/ascent/assurance-planner.ss | sed '/^[[:space:]]*;;/d' > "$r/source-routes.ss"
jq '.dependencies=[]|.edgeGroups=[]' "$r/planner-full.json" | jq -r -f "$r/facts.jq" >> "$r/source-routes.ss"
printf ' (fact (scenarioFact "routes-only" "traceability-projection-only"))\n)\n' >> "$r/source-routes.ss"
jq -nr --rawfile s "$r/source-routes.ss" --slurpfile i "$r/planner-full.json" '"((selector "+($s|@json)+") (constructor \"query\") (displayBytes 1048576) (bindings "+([["target-model-bundle-sha256",$i[0].bundleHash],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")")+"))"' > "$r/source-routes.request.scm"
.venv/bin/gambit-smp --task structure-poll-still-envelope trajectory clues < "$r/source-routes.request.scm" > "$r/source-routes.read.scm" 2> "$r/source-routes.log"
ASSURANCE_READ="$r/source-routes.read.scm" ASSURANCE_JSON="$r/source-routes.json" emacs -Q --batch -l "$r/read-association.el"
cp "$r/case-current.request.scm" dev/modeling/ascent/component-assurance.request.scm
cp "$r/build-cut/case-current.request.scm" dev/modeling/ascent/component-assurance-build.request.scm
cp "$r/source-routes.request.scm" dev/modeling/ascent/component-assurance-routes.request.scm
