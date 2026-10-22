#!/bin/bash
set -euo pipefail
r=.cache/tasks/still-init-recovery
for s in paired-stale-detail paired-nonpass-status; do
 sed '$d' "$r/case-all-scoped-control.ss" | sed "s/all-scoped-control/$s/g" > "$r/case-$s.ss"
 jq -nr --arg s "$s" --slurpfile p "$r/planner-input.json" '
 def fact($r;$v):" (fact ("+$r+" "+($v|map(@json)|join(" "))+"))";
 fact("controlBad";[$s,"IR-H"]),fact("controlBad";[$s,"IR-I"]),
 ([$p[0].needs[] as $q|select($q.obligationId=="IR-H" or $q.obligationId=="IR-I")|$p[0].methods[]|select(.kind==$q.kind)|[$q.component,$q.obligationId,.method,$q.subjectPath,(if $s=="paired-stale-detail" and $q.obligationId=="IR-H" then "stale-paired-control" else $q.digest end),.requiredCheck,$q.subjectScope]]|sort_by(.[1])) as $rs|
 fact("receiptPairFact";[$s,(if $s=="paired-nonpass-status" then "fail" else "pass" end)]+($rs|add))
 ' >> "$r/case-$s.ss"
 echo ')' >> "$r/case-$s.ss"
 jq -nr --rawfile s "$r/case-$s.ss" --slurpfile i "$r/planner-full.json" '"((selector "+($s|@json)+") (constructor \"query\") (displayBytes 1048576) (bindings "+([["target-model-bundle-sha256",$i[0].bundleHash],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")")+"))"' > "$r/case-$s.request.scm"
done
