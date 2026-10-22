#!/bin/bash
set -euo pipefail
r=.cache/tasks/component-assurance
jq -e '.components|length==8' "$r/native-projection.json" >/dev/null
jq -e '.methods|map(.kind)|unique|length==5' "$r/native-projection.json" >/dev/null
jq -n --slurpfile n "$r/native-projection.json" --slurpfile old "$r/entry-bindings.json" '
 [$n[0].components[]|.quintSource,.leanSource,.sourcePath?,.baselineModel?] + ($old[0].sources|keys) +
 ["dev/modeling/ascent/assurance-planner.ss","vendor/gambit/gsc/makefile.in","vendor/gambit/gsc/_front.scm","vendor/gambit/gsc/_t-c-1.scm","vendor/gambit/gsc/_t-c-3.scm","vendor/gambit/lib/mem.c","vendor/gambit/lib/c_intf.c","vendor/gambit/lib/setup.c","vendor/gambit/include/gambit.h.in"] | map(select(.!=null))|unique' > "$r/source-paths.json"
jq -r '.[]' "$r/source-paths.json" | while IFS= read -r source_file; do openssl dgst -sha256 "$source_file"; done > "$r/sources.sha256"
cat "$r/models-before.sha256" "$r/sources.sha256" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' | jq -S . > "$r/source-bindings.json"
bundle_hash=$(openssl dgst -sha256 "$r/source-bindings.json"|awk '{print $NF}')
native_hash=$(openssl dgst -sha256 "$r/native-metadata.json"|awk '{print $NF}')
dsl_hash=$(openssl dgst -sha256 dev/modeling/ascent/assurance-planner.ss|awk '{print $NF}')
jq --slurpfile hashes "$r/source-bindings.json" --arg b "$bundle_hash" --arg n "$native_hash" --arg d "$dsl_hash" '
 . + {bundleHash:$b,nativeHash:$n,dslHash:$d,claim:("component-assurance:"+$b)} |
 .components |= map(. + {needs:(.needs|to_entries|map(.value + {slot:.key}))}) |
 .needs=[.components[]|.id as $c|.needs[]|. + {component:$c,digest:$hashes[0][.subjectPath]}] |
 .dependencies |= map({component:.dependent.owner.componentId,obligation:.dependent.obligationId,prerequisiteComponent:.prerequisite.owner.componentId,prerequisite:.prerequisite.obligationId})
 ' "$r/native-projection.json" > "$r/planner-input.json"
# Retained proofs are scoped inputs, not promoted native observations.
for model_name in planner scheduler publisher; do rg -q '4 passing' "$r/${model_name}_contract.tests.log"; done
rg -q '4 passing' "$r/gc_work_contract.tests.log"
rg -q '5 passing' "$r/host_roots_contract.tests.log"
rg -q '3 passing' "$r/continuation_contract.tests.log"
rg -q '5 passing' "$r/resource_exit_contract.tests.log"
test -f "$r/BuildScopes.log"; test -f "$r/RuntimeScopes.log"
# All compilation commands must have completed successfully before this adapter runs.
jq -n '{cases:[{id:"current",control:false},{id:"all-scoped-control",control:true},
 {id:"omit-BP",control:true,omit:"BP-H"},{id:"omit-BS",control:true,omit:"BS-I"},
 {id:"omit-BU",control:true,omit:"BU-H"},{id:"omit-GW",control:true,omit:"GW-H"},
 {id:"omit-HR",control:true,omit:"HR-H"},{id:"omit-CO",control:true,omit:"CO-I"},
 {id:"omit-RX",control:true,omit:"RX-H"},{id:"stale-digest",control:true,stale:"HR-H"},
 {id:"wrong-scope",control:true,scope:"BP-I"},{id:"wrong-owner",control:true,owner:"BS-I"},
 {id:"missing-subject",control:true,missing:"GW-H"},{id:"failed-status",control:true,failed:"BU-E"},
 {id:"grandparent-gap",control:true,omit:"HR-M"},{id:"wrong-class",control:true,check:"BP-H"}]}' > "$r/scenarios.json"
{
 echo '(define-evidence (register) (sources binding) (outputs clue factor)'
 echo ' (relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))'
 jq -r '" (fact (clue "+(.claim|@json)+" "+(.claim|@json)+" \"support\" \"dev/modeling/models/sysml/component-assurance.sysml\"))", (.claim as $c|[["target-model-bundle-sha256",.bundleHash],["native-output-sha256",.nativeHash],["planner-dsl-sha256",.dslHash]][]|" (fact (factor "+([$c,.[0],.[1]]|map(@json)|join(" "))+"))")' "$r/planner-input.json"
 echo ')'
} > "$r/register.ss"
jq -nr --rawfile s "$r/register.ss" '"((selector "+($s|@json)+") (constructor \"register\"))"' > "$r/submit.request.scm"
sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/common.ss"
jq -r '. as $a|(.components[]|" (fact (componentFact "+([.id,$a.claim,"native-component-study"]|map(@json)|join(" "))+"))"),(.needs[]|" (fact (needFact "+([.component,.obligationId,.kind,.premise,.subjectPath,.subjectScope]|map(@json)|join(" "))+"))"),(.methods[]|" (fact (methodFact "+([.kind,.method,.requiredCheck]|map(@json)|join(" "))+"))"),(.dependencies[]|" (fact (dependencyFact "+([.component,.obligation,.prerequisiteComponent,.prerequisite]|map(@json)|join(" "))+"))"),(.contracts[]|" (fact (contractFact "+([.contractId,.producer.componentId,.consumer.componentId,.phaseScope,.guarantee,.rely,.failureCustodian]|map(@json)|join(" "))+"))")' "$r/planner-input.json" >> "$r/common.ss"
jq -nr --slurpfile a "$r/planner-input.json" --slurpfile cases "$r/scenarios.json" '
 def fact($rel;$row): " (fact ("+$rel+" "+($row|map(@json)|join(" "))+"))";
 $cases[0].cases[] as $s | fact("scenarioFact";[$s.id,(if $s.control then "planner-control-only" else "actual-scoped-formal-receipts" end)]),
 ($a[0].needs[] as $q|$a[0].methods[]|select(.kind==$q.kind)|. as $m|
 (if $s.missing!=$q.obligationId then fact("artifactFact";[$s.id,$q.component,$q.obligationId,$m.method,$q.subjectPath,$q.digest]) else empty end),
 (if ($s.id!="current" or $q.slot=="history" or $q.slot=="induction") and $s.omit!=$q.obligationId then
 fact("receiptFact";[$s.id,(if $s.owner==$q.obligationId then "build-planner" else $q.component end),$q.obligationId,$m.method,$q.subjectPath,(if $s.stale==$q.obligationId then "stale-control" else $q.digest end),(if $s.check==$q.obligationId then "typecheck" else $m.requiredCheck end),(if $s.scope==$q.obligationId then "unrelated-lemma-control" else $q.subjectScope end),(if $s.failed==$q.obligationId then "fail" else "pass" end)]) else empty end))' > "$r/scenario-facts.ss"
cat "$r/common.ss" "$r/scenario-facts.ss" > "$r/composed.ss"
echo ')' >> "$r/composed.ss"
jq -nr --rawfile s "$r/composed.ss" --slurpfile i "$r/planner-input.json" '"((selector "+($s|@json)+") (constructor \"query\") (displayBytes 1048576) (bindings "+([["target-model-bundle-sha256",$i[0].bundleHash],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")")+"))"' > dev/modeling/ascent/component-assurance.request.scm
