#!/bin/bash
# Scalar native metadata + actual file/check identities. Reasoning stays in DSL.
set -euo pipefail
task_dir=.cache/tasks/sync-publication-assurance
jq -e '. as $n | (.needs|map(.id)|unique|length)==(.needs|length) and
  (.methods|map(.kind)|unique|length)==(.methods|length) and
  all(.needs[]; . as $q | ($n.methods|map(select(.kind==$q.kind))|length)==1) and
  all(.dependencies[]; . as $d | ($n.needs|map(.id)|index($d.dependent))!=null and
    ($n.needs|map(.id)|index($d.prerequisite))!=null)' "$task_dir/native-component.json" > "$task_dir/adapter-profile-check.log"
qnt_source=$(jq -r '.component.quint' "$task_dir/native-component.json")
lean_source=$(jq -r '.component.lean' "$task_dir/native-component.json")
qnt_hash=$(openssl dgst -sha256 "$qnt_source"|awk '{print $NF}')
lean_hash=$(openssl dgst -sha256 "$lean_source"|awk '{print $NF}')
dsl=dev/modeling/ascent/assurance-planner.ss
dsl_hash=$(openssl dgst -sha256 "$dsl"|awk '{print $NF}')
native_hash=$(openssl dgst -sha256 "$task_dir/native-metadata.json"|awk '{print $NF}')
for source_file in "$qnt_source" "$lean_source" "$dsl" vendor/gambit/lib/mem.c vendor/gambit/lib/setup.c vendor/gambit/lib/os_base.c vendor/gambit/lib/os_thread.c vendor/gambit/include/gambit.h.in; do
  openssl dgst -sha256 "$source_file"
done | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' > "$task_dir/selected-source-bindings.json"
jq -S --slurpfile a "$task_dir/selected-source-bindings.json" '. + $a[0]' "$task_dir/model-bindings.json" > "$task_dir/assurance-bindings.json"
bundle_hash=$(openssl dgst -sha256 "$task_dir/assurance-bindings.json"|awk '{print $NF}')
jq --arg q "$qnt_hash" --arg l "$lean_hash" --arg p "$dsl_hash" --arg n "$native_hash" --arg b "$bundle_hash" '. + {quintHash:$q,leanHash:$l,dslHash:$p,nativeHash:$n,bundleHash:$b,claim:("component-assurance:"+.component.id+":"+$b)}' "$task_dir/native-component.json" > "$task_dir/planner-input.json"
# The check producer is verified before this serialization is invoked.
jq -e '.status=="ok" and .errors==[]' "$task_dir/quint-simulation.json" >/dev/null
rg -q '15 passing' "$task_dir/quint-test.log"
test ! -s "$task_dir/lean-check.log"
{
  echo '(define-evidence (register) (sources binding) (outputs clue factor)'
  echo ' (relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))'
  jq -r '" (fact (clue \"sync-publication-assurance\" " + (.claim|@json) + " \"support\" \"dev/architecture/runtime/interfaces/models/sysml/synchronous-publication.sysml\"))"' "$task_dir/planner-input.json"
  jq -r '[["target-model-bundle-sha256",.bundleHash],["native-output-sha256",.nativeHash],["planner-dsl-sha256",.dslHash],["quint-model",.component.quint],["lean-model",.component.lean],["model-source-sha256",.quintHash],["model-source-sha256",.leanHash],["source-refinement-status","open"]][] | " (fact (factor \"sync-publication-assurance\" " + (map(@json)|join(" ")) + "))"' "$task_dir/planner-input.json"
  echo ')'
} > "$task_dir/register.ss"
sed "s/\"sync-publication-assurance\"/\"sync-publication-assurance:$bundle_hash\"/g" "$task_dir/register.ss" > "$task_dir/register-bound.ss"
mv "$task_dir/register-bound.ss" "$task_dir/register.ss"
jq -nr --rawfile s "$task_dir/register.ss" '"((selector " + ($s|@json) + ") (constructor \"register\"))"' > "$task_dir/submit.request.scm"
test "$(tail -n 1 "$dsl")" = ')'
sed '$d' "$dsl" > "$task_dir/planner-composed.ss"
jq -r '" (fact (componentFact " + ([.component.id,.claim,"dev/architecture/runtime/interfaces/models/sysml/synchronous-publication.sysml"]|map(@json)|join(" ")) + "))", (.component.id as $c | .needs[] | " (fact (needFact " + ([$c,.id,.kind,.premise,.artifact]|map(@json)|join(" ")) + "))"), (.methods[] | " (fact (methodFact " + ([.kind,.method,.check]|map(@json)|join(" ")) + "))")' "$task_dir/planner-input.json" >> "$task_dir/planner-composed.ss"
jq -r '.component.id as $c | .dependencies[] | " (fact (dependencyFact " + ([$c,.dependent,.prerequisite]|map(@json)|join(" ")) + "))"' "$task_dir/planner-input.json" >> "$task_dir/planner-composed.ss"

# Scenarios are controls of the planner, not fictional native evidence.
jq -n --slurpfile i "$task_dir/planner-input.json" --slurpfile h "$task_dir/selected-source-bindings.json" '$i[0] as $a | {scenarios:["current","missing-qnt","no-receipts","typecheck-only","stale-receipt","wrong-scope"],component:$a.component.id,artifacts:[{method:"QNT",path:$a.component.quint,hash:$a.quintHash},{method:"Lean",path:$a.component.lean,hash:$a.leanHash},{method:"C-memory",path:"vendor/gambit/lib/mem.c",hash:$h[0]["vendor/gambit/lib/mem.c"]}]}' > "$task_dir/scenarios.json"
jq -r '. as $a | .scenarios[] as $s | " (fact (scenarioFact " + ($s|@json) + " " + (if $s=="current" then "actual-formal-receipts" else "planner-control-only" end|@json) + "))", ($a.artifacts[] | select($s!="missing-qnt" or .method!="QNT") | " (fact (artifactFact " + ([$s,$a.component,.method,.path,.hash]|map(@json)|join(" ")) + "))"), ($a.artifacts[] | select($s!="no-receipts" and .method!="C-memory") | " (fact (receiptFact " + ([$s,$a.component,.method,.path,(if $s=="stale-receipt" and .method=="QNT" then "stale-source-control" else .hash end),(if .method=="Lean" then "inductive-preservation" elif $s=="typecheck-only" then "typecheck" elif $s=="wrong-scope" then "unrelated-property" else "bounded-histories" end),"pass"]|map(@json)|join(" ")) + "))")' "$task_dir/scenarios.json" >> "$task_dir/planner-composed.ss"
echo ')' >> "$task_dir/planner-composed.ss"
jq -nr --rawfile s "$task_dir/planner-composed.ss" --slurpfile i "$task_dir/planner-input.json" '"((selector " + ($s|@json) + ") (constructor \"query\") (displayBytes 65536) (bindings " + ([["target-model-bundle-sha256",$i[0].bundleHash],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")") + "))"' > dev/modeling/ascent/synchronous-publication.request.scm
