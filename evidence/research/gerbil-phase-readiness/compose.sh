#!/bin/bash
set -euo pipefail
r=.cache/tasks/gerbil-phase-readiness
{
 jq -r '.needs[].subjectPath' "$r/projection.json"
 printf '%s\n' models/build/gerbil_phase_topology.qnt dev/architecture/toolchain/models/sysml/gerbil-phase-readiness.sysml dev/modeling/ascent/assurance-planner.ss
 for f in std/iter/macros.ss std/iter/api.ss std/iter.ss std/iter/iterators.ss std/string/misc.ss std/sync/wg.ss std/make.ss gerbil/compiler/driver.ss gerbil/expander/module.ss; do printf '../gerbil-gambit-bootstrap-audit/src/%s\n' "$f"; done
} | LC_ALL=C sort -u > "$r/subjects.txt"
: > "$r/subjects.tsv"
while IFS= read -r file; do
 read -r hash rest < <(openssl dgst -sha256 -r "$file")
 printf '%s\t%s\n' "$file" "$hash" >> "$r/subjects.tsv"
done < "$r/subjects.txt"
jq -Rn '[inputs|split("\t")|{key:.[0],value:.[1]}]|from_entries' "$r/subjects.tsv" > "$r/source-bindings.json"
read -r bundle _ < <(openssl dgst -sha256 -r "$r/source-bindings.json")
read -r native _ < <(openssl dgst -sha256 -r "$r/native.json")
read -r dsl _ < <(openssl dgst -sha256 -r dev/modeling/ascent/assurance-planner.ss)
jq --arg bundle "$bundle" --arg native "$native" --arg dsl "$dsl" --slurpfile hashes "$r/source-bindings.json" '
 . + {claim:("gerbil-phase-readiness:"+$bundle),bundle:$bundle,nativeHash:$native,dslHash:$dsl} |
 .components = [.components[]] |
 .needs = [.needs[]|. + {component:.owner.componentId,digest:$hashes[0][.subjectPath]}] |
 .dependencies = [.dependencies[]|{component:.dependent.owner.componentId,obligation:.dependent.obligationId,prerequisiteComponent:.prerequisite.owner.componentId,prerequisite:.prerequisite.obligationId}] |
 .methods = [.methods[]]
 ' "$r/projection.json" > "$r/input.json"
{
 echo '(define-evidence (register) (sources binding) (outputs clue factor)'
 echo ' (relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))'
 jq -r '" (fact (clue "+(.claim|@json)+" "+(.claim|@json)+" \"support\" \"dev/architecture/toolchain/models/sysml/gerbil-phase-readiness.sysml\"))", (.claim as $c|[["target-model-bundle-sha256",.bundle],["native-output-sha256",.nativeHash],["planner-dsl-sha256",.dslHash]][]|" (fact (factor "+([$c,.[0],.[1]]|map(@json)|join(" "))+"))")' "$r/input.json"
 echo ')'
} > "$r/register.ss"
jq -nr --rawfile s "$r/register.ss" '"((selector "+($s|@json)+") (constructor \"register\"))"' > "$r/submit.request.scm"
for scenario in current wrong-scope stale-subject missing-phase-check all-scoped-control; do
 sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/$scenario.ss"
 jq -r --arg s "$scenario" '
 def fact($r;$v): " (fact ("+$r+" "+($v|map(@json)|join(" "))+"))";
 . as $i|
 (.components[]|fact("componentFact";[.componentId,$i.claim,"GerbilPhaseReadiness:native-ancestor-closure"])),
 (.needs[]|fact("needFact";[.component,.obligationId,.kind,.premise,.subjectPath,.subjectScope])),
 (.methods[]|fact("methodFact";[.kind,.method,.requiredCheck])),
 (.dependencies[]|fact("dependencyFact";[.component,.obligation,.prerequisiteComponent,.prerequisite])),
 fact("scenarioFact";[$s,if $s=="all-scoped-control" then "planner-control-only" else "source-bound-formal-receipts" end]),
 (.needs|map([.subjectPath,.digest])|unique[]|fact("availableSubjectFact";[$s]+.)),
 (.needs[] as $q|.methods[]|select(.kind==$q.kind)|. as $m|
 select($s=="all-scoped-control" or $q.obligationId=="GM-H" or $q.obligationId=="GM-I")|
 select(($s!="missing-phase-check") or $q.obligationId!="GM-H")|
 fact("receiptFact";[$s,$q.component,$q.obligationId,$m.method,$q.subjectPath,
 (if $s=="stale-subject" and $q.obligationId=="GM-H" then "stale-control" else $q.digest end),$m.requiredCheck,
 (if $s=="wrong-scope" and $q.obligationId=="GM-I" then "wrong-scope-control" else $q.subjectScope end),"pass"])),
 fact("sourceRouteFact";["build-scheduler","GM-S",(.actions|map(.sourceAnchor)|join("; ")),"existing streaming executor retained", "nine target families; other imports fixed; runtime-only remainder unproved", "attempt owns staged outputs; running process retains credits", "source-refinement-open"])
 ' "$r/input.json" >> "$r/$scenario.ss"
 echo ')' >> "$r/$scenario.ss"
 jq -nr --rawfile s "$r/$scenario.ss" --slurpfile i "$r/input.json" '"((selector "+($s|@json)+") (constructor \"query\") (displayBytes 1048576) (bindings "+([["target-model-bundle-sha256",$i[0].bundle],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")")+"))"' > "$r/$scenario.request.scm"
done
