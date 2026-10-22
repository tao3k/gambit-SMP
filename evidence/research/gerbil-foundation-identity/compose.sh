#!/bin/bash
set -euo pipefail
r=.cache/tasks/gerbil-foundation-identity
{
 jq -r '.needs[].subjectPath' "$r/projection.json"
 printf '%s\n' models/build/foundation_binding_parameters.qnt dev/architecture/toolchain/models/sysml/foundation-binding.sysml dev/modeling/ascent/foundation-binding.rules.scm evidence/research/gerbil-foundation-identity/dune-identity-web-snapshot.txt vendor/ocaml/typing/ident.ml .cache/tasks/gerbil-foundation-identity/compose.sh
 for f in gerbil/expander/stx.ss gerbil/expander/top.ss gerbil/expander/init.ss gerbil/base.ss gerbil/core.ss; do printf '../gerbil-gambit-bootstrap-audit/src/%s\n' "$f"; done
 printf '%s\n' models/build/gerbil_phase_topology.qnt dev/architecture/toolchain/models/sysml/gerbil-phase-readiness.sysml dev/modeling/ascent/assurance-planner.ss models/build/gerbil_session_topology.qnt dev/architecture/toolchain/models/sysml/gerbil-session-closure.sysml dev/modeling/ascent/gerbil-session-closure.rules.scm evidence/research/gerbil-session-closure/dune-memo-web-snapshot.txt vendor/chez/s/syntax.ss vendor/ocaml/middle_end/compilenv.ml vendor/ocaml/typing/persistent_env.ml .cache/tasks/gerbil-session-closure/compose.sh
 for f in std/iter/macros.ss std/iter/api.ss std/iter.ss std/iter/iterators.ss std/string/misc.ss std/sync/wg.ss std/make.ss gerbil/compiler/driver.ss gerbil/compiler/base.ss gerbil/compiler/compile.ss gerbil/compiler/optimize.ss gerbil/compiler/optimize-base.ss gerbil/expander/module.ss gerbil/expander/core.ss gerbil/expander/root.ss gerbil/core/match.ss gerbil/core/contract.ss gerbil/runtime/loader.ss; do printf '../gerbil-gambit-bootstrap-audit/src/%s\n' "$f"; done
 for f in macros.ssi macros.scm macros~1.scm macros.ssxi.ss api.ssi; do printf "../gerbil-gambit-bootstrap-audit/build/lib/std/iter/%s\n" "$f"; done

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
 . + {claim:("gerbil-foundation-identity:"+$bundle),bundle:$bundle,nativeHash:$native,dslHash:$dsl} |
 .components = [.components[]] |
 .needs = [.needs[]|. + {component:.owner.componentId,digest:$hashes[0][.subjectPath]}] |
 .dependencies = [.dependencies[]|{component:.dependent.owner.componentId,obligation:.dependent.obligationId,prerequisiteComponent:.prerequisite.owner.componentId,prerequisite:.prerequisite.obligationId}] |
 .methods = [.methods[]]
 ' "$r/projection.json" > "$r/input.json"
{
 echo '(define-evidence (register) (sources binding) (outputs clue factor)'
 echo ' (relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))'
 jq -r '" (fact (clue "+(.claim|@json)+" "+(.claim|@json)+" \"support\" \"dev/architecture/toolchain/models/sysml/foundation-binding.sysml\"))", (.claim as $c|[["target-model-bundle-sha256",.bundle],["native-output-sha256",.nativeHash],["planner-dsl-sha256",.dslHash]][]|" (fact (factor "+([$c,.[0],.[1]]|map(@json)|join(" "))+"))")' "$r/input.json"
 echo ')'
} > "$r/register.ss"
jq -nr --rawfile s "$r/register.ss" '"((selector "+($s|@json)+") (constructor \"register\"))"' > "$r/submit.request.scm"
for scenario in current wrong-scope stale-subject missing-phase-check all-scoped-control; do
 sed '$d' dev/modeling/ascent/assurance-planner.ss | sed 's/sharedContract sourceRoute)/sharedContract sourceRoute supportClosure opaqueSupport stateOwnership sourceAdmissionBlocked imageCandidate canonicalDefinition reconstructionRequired serializedInstanceRequired foundationAdmissionBlocked)/' > "$r/$scenario.ss"
 cat dev/modeling/ascent/gerbil-session-closure.rules.scm >> "$r/$scenario.ss"
 cat dev/modeling/ascent/foundation-binding.rules.scm >> "$r/$scenario.ss"
 jq -r --arg s "$scenario" '
 def fact($r;$v): " (fact ("+$r+" "+($v|map(@json)|join(" "))+"))";
 . as $i|
 (.components[]|fact("componentFact";[.componentId,$i.claim,"GerbilPhaseReadiness:native-ancestor-closure"])),
 (.needs|group_by(.component)[]|. as $ns|range(0;length;3) as $j|$ns[$j:$j+3] as $g|
 if ($g|length)==3 then fact("needTripleFact";[$g[0].component]+[$g[]|.obligationId,.kind,.premise,.subjectPath,.subjectScope])
 else $g[]|fact("needFact";[.component,.obligationId,.kind,.premise,.subjectPath,.subjectScope]) end),
 (.methods[]|fact("methodFact";[.kind,.method,.requiredCheck])),
 (.dependencies|group_by([.component,.obligation])[]|. as $ds|range(0;length;3) as $j|$ds[$j:$j+3] as $g|
 if ($g|length)==3 then fact("dependencyTripleFact";[$g[0].component,$g[0].obligation]+[$g[]|.prerequisiteComponent,.prerequisite])
 else $g[]|fact("dependencyFact";[.component,.obligation,.prerequisiteComponent,.prerequisite]) end),
 fact("scenarioFact";[$s,if $s=="all-scoped-control" then "planner-control-only" else "source-bound-formal-receipts" end]),
 (.needs|map([.subjectPath,.digest])|unique[]|fact("availableSubjectFact";[$s]+.)),
 (.needs[] as $q|.methods[]|select(.kind==$q.kind)|. as $m|
 select($s=="all-scoped-control" or $q.obligationId=="GM-H" or $q.obligationId=="GM-I" or $q.obligationId=="GS-H" or $q.obligationId=="GS-I" or $q.obligationId=="FI-H" or $q.obligationId=="FI-I")|
 select(($s!="missing-phase-check") or $q.obligationId!="FI-H")|
 fact("receiptFact";[$s,$q.component,$q.obligationId,$m.method,$q.subjectPath,
 (if $s=="stale-subject" and $q.obligationId=="FI-H" then "stale-control" else $q.digest end),$m.requiredCheck,
 (if $s=="wrong-scope" and $q.obligationId=="FI-I" then "wrong-scope-control" else $q.subjectScope end),"pass"])),
 fact("sourceRouteFact";["build-scheduler","GM-S",(.actions|map(.sourceAnchor)|join("; ")),"existing streaming executor retained", "nine target families; other imports fixed; runtime-only remainder unproved", "attempt owns staged outputs; running process retains credits", "source-refinement-open"])
 ,fact("sourceRouteFact";["build-scheduler","GS-S",(.supports|map(.sourceAnchor)|join("; ")),"current batch and prior streaming patch remain distinct","executable support and transitive mutable footprints; opaque initializers retained","session owns writes and output attempts; support pin remains until borrower drain","source-census-open"]),
 (.supports[]|fact("supportNodeFact";[(.number|tostring),.kind,.sourceAnchor])),
 (.supportEdges[]|select(.kind=="exec")|fact("executionFact";[(.producer|tostring),(.consumer|tostring)])),
 ([.supportRoots|scan("[0-9]+") ][]|fact("rootSupportFact";[.])),
 (.domains[]|fact("domainFact";[.key,.ownership,.sourceAnchor])),
 fact("censusFact";[(.observedCensus|tostring)]),
 (.foundationRegions[]|fact("foundationRegionFact";[.key,.ownership,.sourceAnchor,.rule])),
 fact("foundationClosedFact";[(.foundation.sourceFoundationClosed|tostring)]),
 fact("sourceRouteFact";["build-scheduler","FI-S",(.foundationRegions|map(.sourceAnchor)|join("; ")),"no runtime patch", "definition identity, context eq and ordered marks; source foundation remains open", "canonical definition/effect owner plus session-owned writes and lifetime", "source-refinement-open"])
 ' "$r/input.json" >> "$r/$scenario.ss"
 echo ')' >> "$r/$scenario.ss"
 jq -nr --rawfile s "$r/$scenario.ss" --slurpfile i "$r/input.json" '"((selector "+($s|@json)+") (constructor \"query\") (displayBytes 1048576) (bindings "+([["target-model-bundle-sha256",$i[0].bundle],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")")+"))"' > "$r/$scenario.request.scm"
done
