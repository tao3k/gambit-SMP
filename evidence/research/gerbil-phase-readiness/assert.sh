#!/bin/bash
set -euo pipefail
r=.cache/tasks/gerbil-phase-readiness
for s in current wrong-scope stale-subject missing-phase-check all-scoped-control; do
 jq -e --slurpfile i "$r/input.json" '
 .runtimeAdmitted==false and .presentationComplete==true and .counts.support==0 and .counts.hypotheses==1 and
 (.modelRequired|length)==16 and (.dependencyCycle|length)==0 and (.danglingDependency|length)==0 and (.unboundDependency|length)==0 and (.unroutedNeed|length)==0 and
 ((.modelRequired|map(.[1:])|sort)==([$i[0].needs[] as $q|$i[0].methods[]|select(.kind==$q.kind)|[$q.component,$q.obligationId,.method,.requiredCheck,$q.subjectPath,$q.subjectScope,$q.premise]]|sort))
 ' "$r/$s.json" > "$r/assert-$s.log"
done
jq -e '(.locallyChecked|map(.[2])|sort)==["GM-H","GM-I"] and (.componentReady|length)==0 and (.sourceRoute|length)==1 and (.qualifiedSlice|all(.[];.[2]!="GM-S" and .[2]!="GM-E"))' "$r/current.json" >> "$r/assert-current.log"
jq -e '(.locallyChecked|map(.[2]))==["GM-H"]' "$r/wrong-scope.json" >> "$r/assert-wrong-scope.log"
jq -e '(.locallyChecked|map(.[2]))==["GM-I"]' "$r/stale-subject.json" >> "$r/assert-stale-subject.log"
jq -e '(.locallyChecked|map(.[2]))==["GM-I"]' "$r/missing-phase-check.json" >> "$r/assert-missing-phase-check.log"
jq -e '(.locallyChecked|length)==16 and (.componentReady|length)==3' "$r/all-scoped-control.json" >> "$r/assert-all-scoped-control.log"
jq -e '(.dependencies|length)==15 and (.actions|length)==9 and (.benefits|length)==5 and (.learning|length)==4' "$r/input.json" > "$r/assert-structure.log"
