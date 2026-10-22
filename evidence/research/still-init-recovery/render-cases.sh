#!/bin/bash
set -euo pipefail
r=.cache/tasks/still-init-recovery
cp "$r/scenarios-template.json" "$r/scenarios.json"
while IFS= read -r scenario; do
 cp "$r/common.ss" "$r/case-$scenario.ss"
 jq -nr --arg s "$scenario" --slurpfile a "$r/planner-input.json" --slurpfile cs "$r/scenarios.json" --slurpfile inherited "$r/inherited.json" '
 def fact($r;$row): " (fact ("+$r+" "+($row|map(@json)|join(" "))+"))";
 ($cs[0].cases[]|select(.id==$s)) as $c|
 fact("scenarioFact";[$s,(if $c.control then "planner-control-only" else "source-bound-formal-receipts" end)]),
 (if $c.control then empty else
 [$a[0].needs[] as $q|$a[0].methods[]|select(.kind==$q.kind)|. as $m|
 select((["IR-H","IR-I"]|index($q.obligationId))!=null or ($inherited[0]|any(.[];.need==$q.obligationId)))|
 [$q.component,$q.obligationId,$m.method,$q.subjectPath,$q.digest,$m.requiredCheck,$q.subjectScope,"pass"]] as $rs|
 range(0;($rs|length);2) as $j|$rs[$j:$j+2] as $pair|
 if ($pair|length)==2 and $pair[0][7]==$pair[1][7] then fact("receiptRefPairFact";[$s,$pair[0][7]]+[$pair[]|[.[0],.[1],.[2],.[1],.[4],.[5]][]]) else $pair[]|fact("receiptFact";[$s]+.) end end)
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
