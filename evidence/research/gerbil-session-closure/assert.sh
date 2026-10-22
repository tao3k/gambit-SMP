#!/bin/bash
set -euo pipefail
r=.cache/tasks/gerbil-session-closure
for s in current wrong-scope stale-subject missing-phase-check all-scoped-control; do
 jq -e --slurpfile i "$r/input.json" '
 .runtimeAdmitted==false and .presentationComplete==true and .counts.support==0 and .counts.hypotheses==1 and
 (.modelRequired|length)==20 and (.dependencyCycle|length)==0 and (.danglingDependency|length)==0 and (.unboundDependency|length)==0 and (.unroutedNeed|length)==0 and
 ((.modelRequired|map(.[1:])|sort)==([$i[0].needs[] as $q|$i[0].methods[]|select(.kind==$q.kind)|[$q.component,$q.obligationId,.method,.requiredCheck,$q.subjectPath,$q.subjectScope,$q.premise]]|sort)) and
 ((.supportClosure|map(.[1])|sort)==["0","1","2","3","4","5","6","7","8"]) and
 ((.opaqueSupport|map(.[1])|sort)==["5","7","8"]) and
 ((.stateOwnership|map(.[1:])|sort)==($i[0].domains|map([.key,.ownership,.sourceAnchor])|sort)) and
 (.sourceAdmissionBlocked|length)==1 and (.sourceAdmissionBlocked[0][1]=="incomplete-source-census")
 ' "$r/$s.json" > "$r/assert-$s.log"
done
jq -e '(.locallyChecked|map(.[2])|sort)==["GM-H","GM-I","GS-H","GS-I"] and (.componentReady|length)==0 and (.sourceRoute|length)==2 and (.qualifiedSlice|all(.[];.[2]!="GS-S" and .[2]!="GS-E"))' "$r/current.json" >> "$r/assert-current.log"
jq -e '(.locallyChecked|map(.[2])|sort)==["GM-H","GM-I","GS-H"]' "$r/wrong-scope.json" >> "$r/assert-wrong-scope.log"
for s in stale-subject missing-phase-check; do
 jq -e '(.locallyChecked|map(.[2])|sort)==["GM-H","GM-I","GS-I"]' "$r/$s.json" >> "$r/assert-$s.log"
done
jq -e '(.locallyChecked|length)==20 and (.componentReady|length)==3 and (.sourceAdmissionBlocked|length)==1' "$r/all-scoped-control.json" >> "$r/assert-all-scoped-control.log"
jq -e '(.dependencies|length)==19 and (.supports|length)==10 and (.supportEdges|length)==10 and (.domains|length)==8 and (.opportunities|length)==4 and .observedCensus==false' "$r/input.json" > "$r/assert-structure.log"
