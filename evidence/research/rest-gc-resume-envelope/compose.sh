#!/bin/bash
set -euo pipefail
r=.cache/tasks/rest-gc-resume-envelope
jq -e '.exit==0' "$r/native-metadata.json" >/dev/null
rg -q '16 passing' "$r/quint-tests.log"
rg -q 'No violation found' "$r/quint-simulation.log"
! rg -q 'error:|sorryAx' "$r/lean-kernel.log"
jq -r '[.components[]|.quintSource,.leanSource,.sourcePath?,.baselineModel?] + [.refinementNeeds[].subjectPath] + ["dev/modeling/ascent/assurance-planner.ss","patches/fixtures/processor-interrupt-collective-wait-cumulative.patch","vendor/gambit/lib/mem.c","vendor/gambit/lib/mem.h","vendor/gambit/lib/c_intf.c","vendor/gambit/lib/setup.c","vendor/gambit/lib/os_dyn.c","vendor/gambit/lib/os_thread.c","vendor/gambit/lib/os_base.c","vendor/gambit/lib/os_base.h","vendor/gambit/lib/os_io.c","vendor/gambit/lib/os_files.c","vendor/gambit/lib/_kernel.scm","vendor/gambit/lib/_kernel.c","vendor/gambit/gsc/_t-c-2.scm","vendor/gambit/gsc/_t-c-1.scm","vendor/gambit/include/gambit.h.in","vendor/gambit/examples/tcltk/tcltk.scm","vendor/gambit/examples/Xlib-simple/Xlib.scm","vendor/ocaml/runtime/minor_gc.c","vendor/ocaml/runtime/memory.c","vendor/gambit/lib/_thread.scm","vendor/gambit/lib/_thread#.scm","vendor/gambit/lib/_gambit#.scm","vendor/gambit/lib/_io.scm","vendor/ocaml/runtime/caml/memory.h","vendor/ocaml/runtime/callback.c","vendor/chez/c/gcwrapper.c","models/gambit/lean/HostRootSourceCensus.lean"] | map(select(.!=null))|unique|.[]' "$r/native-projection.json" | while IFS= read -r f; do openssl dgst -sha256 "$f"; done > "$r/sources.sha256"
cat "$r/models-before.sha256" "$r/sources.sha256" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' | jq -S . > "$r/source-bindings.json"
bundle=$(openssl dgst -sha256 "$r/source-bindings.json"|awk '{print $NF}')
native=$(openssl dgst -sha256 "$r/native-metadata.json"|awk '{print $NF}')
dsl=$(openssl dgst -sha256 dev/modeling/ascent/assurance-planner.ss|awk '{print $NF}')
jq --slurpfile h "$r/source-bindings.json" --arg b "$bundle" --arg n "$native" --arg d "$dsl" '
 .+{bundleHash:$b,nativeHash:$n,dslHash:$d,claim:("rest-gc-resume-envelope:"+$b)} |
 .needs=([.components[]|.id as $c|.needs[]|.+{component:$c}]+[.refinementNeeds[]|.+{component:(.owner.componentId//"host-roots")}]) |
 .needs|=map(.+{digest:$h[0][.subjectPath]}) |
 .dependencies=(.dependencies+.refinementDependencies|map({component:.dependent.owner.componentId,obligation:.dependent.obligationId,prerequisiteComponent:.prerequisite.owner.componentId,prerequisite:.prerequisite.obligationId})) |
 .edgeGroups=[.dependencies|group_by([.component,.obligation])[]|. as $g|range(0;length;5) as $i|$g[$i:$i+5]]
 ' "$r/native-projection.json" > "$r/planner-input.json"
jq --slurpfile i "$r/planner-input.json" '[.qualifiedSlice[] as $q|$i[0].needs[]|select(.component==$q[1] and .obligationId==$q[2] and .subjectPath==$q[4] and .subjectScope==$q[6])|{component:.component,need:.obligationId,method:$q[3],artifact:$q[4],digest:.digest,check:$q[5],scope:$q[6],origin:"evidence/research/guaranteed-tail-placement/checks.json"}]' .cache/tasks/rest-gc-resume-envelope/predecessor-qualified.json > "$r/inherited.json"
jq -e 'length==32' "$r/inherited.json" >/dev/null
jq -e --slurpfile old evidence/research/guaranteed-tail-placement/source-bindings.json 'all(.[];. as $x|$x.digest==$old[0][$x.artifact])' "$r/inherited.json" >/dev/null
{
 echo '(define-evidence (register) (sources binding) (outputs clue factor)'
 echo ' (relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))'
 jq -r '" (fact (clue "+(.claim|@json)+" "+(.claim|@json)+" \"support\" \"dev/architecture/runtime/gc/models/sysml/rest-gc-resume-envelope.sysml\"))", (.claim as $c|[["target-model-bundle-sha256",.bundleHash],["native-output-sha256",.nativeHash],["planner-dsl-sha256",.dslHash]][]|" (fact (factor "+([$c,.[0],.[1]]|map(@json)|join(" "))+"))")' "$r/planner-input.json"
 echo ')'
} > "$r/register.ss"
jq -nr --rawfile s "$r/register.ss" '"((selector "+($s|@json)+") (constructor \"register\"))"' > "$r/submit.request.scm"
sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/common.ss"
jq -r -f "$r/facts.jq" "$r/planner-input.json" >> "$r/common.ss"
jq -e '(.edgeGroups|add|sort)==(.dependencies|sort) and (.dependencies|length)==248 and (.needs|length)==90' "$r/planner-input.json" > "$r/triple-roundtrip.log"
cp "$r/scenarios-template.json" "$r/scenarios.json"
while IFS= read -r scenario; do
 cp "$r/common.ss" "$r/case-$scenario.ss"
 jq -nr --arg s "$scenario" --slurpfile a "$r/planner-input.json" --slurpfile cs "$r/scenarios.json" --slurpfile inherited "$r/inherited.json" '
 def fact($r;$row): " (fact ("+$r+" "+($row|map(@json)|join(" "))+"))";
 ($cs[0].cases[]|select(.id==$s)) as $c|
 fact("scenarioFact";[$s,(if $c.control then "planner-control-only" else "source-bound-formal-receipts" end)]),
 (if $c.control then empty else
 ($a[0].needs[] as $q|$a[0].methods[]|select(.kind==$q.kind)|. as $m|
 select((["RG-H","RG-I"]|index($q.obligationId))!=null or ($inherited[0]|any(.[];.need==$q.obligationId)))|
 fact("receiptFact";[$s,$q.component,$q.obligationId,$m.method,$q.subjectPath,$q.digest,$m.requiredCheck,$q.subjectScope,"pass"])) end)
 ' >> "$r/case-$scenario.ss"
 cat >> "$r/case-$scenario.ss" <<'EOF'
 (relation controlDenied (scenario obligation))
 (relation controlBad (scenario obligation))
 ((receiptFact S C O M A H K T (lit "pass")) <--
  (scenarioFact S (lit "planner-control-only")) (modelRequired S C O M K A T _)
  (artifactFact S C O M A H) (not (controlBad S O)) (not (controlDenied S O)))
EOF
 jq -r --arg s "$scenario" -f "$r/render-available.jq" "$r/planner-input.json" >> "$r/case-$scenario.ss"
 jq -r --arg s "$scenario" '.cases[]|select(.id==$s)|.denied[]?|" (fact (controlDenied "+([$s,.]|map(@json)|join(" "))+"))"' "$r/scenarios.json" >> "$r/case-$scenario.ss"
 jq -r --arg s "$scenario" --slurpfile i "$r/planner-input.json" '.cases[]|select(.id==$s)|. as $c|($c.wrongScope//$c.stale//empty) as $bad|$i[0].needs[]|select(.obligationId==$bad)|. as $q|$i[0].methods[]|select(.kind==$q.kind)|" (fact (controlBad "+([$s,$bad]|map(@json)|join(" "))+"))", " (fact (receiptFact "+([$s,$q.component,$bad,.method,$q.subjectPath,(if $c.stale then "stale-control" else $q.digest end),.requiredCheck,(if $c.wrongScope then "wrong-scope-control" else $q.subjectScope end),"pass"]|map(@json)|join(" "))+"))"' "$r/scenarios.json" >> "$r/case-$scenario.ss"
 echo ')' >> "$r/case-$scenario.ss"
 jq -nr --rawfile s "$r/case-$scenario.ss" --slurpfile i "$r/planner-input.json" '"((selector "+($s|@json)+") (constructor \"query\") (displayBytes 1048576) (bindings "+([["target-model-bundle-sha256",$i[0].bundleHash],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")")+"))"' > "$r/case-$scenario.request.scm"
done < <(jq -r '.cases[].id' "$r/scenarios.json")
