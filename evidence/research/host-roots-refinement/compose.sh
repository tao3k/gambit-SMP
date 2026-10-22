#!/bin/bash
set -euo pipefail
r=.cache/tasks/host-roots-refinement
jq -e '.exit==0' "$r/native-metadata.json" >/dev/null
rg -q '14 passing' "$r/quint-tests.log"
! rg -q 'error:|sorryAx' "$r/lean-refinement.log"
for symbol in liveRcCoverage retainedDoesNotImplyScanned protectedReload reservationSurvives enterPreserves settlePreserves nestedSettlement balancedIsNotBinding lateRootCannotRepair; do rg -q "HostRootsRefinement.$symbol" "$r/lean-scopes.log"; done
jq -r '[.components[]|.quintSource,.leanSource,.sourcePath?,.baselineModel?] + [.refinementNeeds[].subjectPath] + ["dev/modeling/ascent/assurance-planner.ss","patches/fixtures/processor-interrupt-collective-wait-cumulative.patch","vendor/gambit/lib/mem.c","vendor/gambit/lib/c_intf.c","vendor/gambit/lib/setup.c","vendor/gambit/lib/os_dyn.c","vendor/gambit/lib/os_thread.c","vendor/gambit/lib/_kernel.scm","vendor/gambit/include/gambit.h.in","vendor/gambit/examples/tcltk/tcltk.scm","vendor/ocaml/runtime/caml/memory.h","vendor/ocaml/runtime/callback.c","models/gambit/lean/HostRootSourceCensus.lean"] | map(select(.!=null))|unique|.[]' "$r/native-projection.json" | while IFS= read -r f; do openssl dgst -sha256 "$f"; done > "$r/sources.sha256"
cat "$r/models-before.sha256" "$r/sources.sha256" | jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' | jq -S . > "$r/source-bindings.json"
bundle=$(openssl dgst -sha256 "$r/source-bindings.json"|awk '{print $NF}')
native=$(openssl dgst -sha256 "$r/native-metadata.json"|awk '{print $NF}')
dsl=$(openssl dgst -sha256 dev/modeling/ascent/assurance-planner.ss|awk '{print $NF}')
jq --slurpfile h "$r/source-bindings.json" --arg b "$bundle" --arg n "$native" --arg d "$dsl" '
 . + {bundleHash:$b,nativeHash:$n,dslHash:$d,claim:("host-roots-refinement:"+$b)} |
 .needs=([.components[]|.id as $c|.needs[]|.+{component:$c}] + [.refinementNeeds[]|.+{component:"host-roots"}]) |
 .needs|=map(.+{digest:$h[0][.subjectPath]}) |
 .dependencies=(.dependencies+.refinementDependencies|map({component:.dependent.owner.componentId,obligation:.dependent.obligationId,prerequisiteComponent:.prerequisite.owner.componentId,prerequisite:.prerequisite.obligationId}))
 ' "$r/native-projection.json" > "$r/planner-input.json"
# Inherited receipts keep exact subject/check/scope identity; no new check claimed.
jq --slurpfile i "$r/planner-input.json" '[.qualifiedSlice[] as $q | $i[0].needs[]|select(.component==$q[1] and .obligationId==$q[2] and .subjectPath==$q[4] and .subjectScope==$q[6])|{component:.component,need:.obligationId,method:$q[3],artifact:$q[4],digest:.digest,check:$q[5],scope:$q[6],origin:"evidence/research/component-assurance/checks.json"}]' .cache/tasks/component-assurance/case-current.json > "$r/inherited.json"
jq -e 'length==16' "$r/inherited.json" >/dev/null
jq -e --slurpfile h "$r/source-bindings.json" '[.qualifiedSlice[]|.[4]]|unique|all(.[];$h[0][.]!=null)' .cache/tasks/component-assurance/case-current.json >/dev/null
# Validate inherited evidence digests, not just paths or matching symbol text.
jq -e --slurpfile h "$r/source-bindings.json" --slurpfile old evidence/research/component-assurance/source-bindings.json 'all(.[];. as $x|$h[0][$x.artifact]==$old[0][$x.artifact])' "$r/inherited.json" >/dev/null
{
 echo '(define-evidence (register) (sources binding) (outputs clue factor)'
 echo ' (relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))'
 jq -r '" (fact (clue "+(.claim|@json)+" "+(.claim|@json)+" \"support\" \"dev/architecture/runtime/ffi/models/sysml/host-roots-refinement.sysml\"))", (.claim as $c|[["target-model-bundle-sha256",.bundleHash],["native-output-sha256",.nativeHash],["planner-dsl-sha256",.dslHash]][]|" (fact (factor "+([$c,.[0],.[1]]|map(@json)|join(" "))+"))")' "$r/planner-input.json"
 echo ')'
} > "$r/register.ss"
jq -nr --rawfile s "$r/register.ss" '"((selector "+($s|@json)+") (constructor \"register\"))"' > "$r/submit.request.scm"
sed '$d' dev/modeling/ascent/assurance-planner.ss > "$r/common.ss"
jq -r '. as $a|(.components[]|" (fact (componentFact "+([.id,$a.claim,"native-component-study"]|map(@json)|join(" "))+"))"),(.needs[]|" (fact (needFact "+([.component,.obligationId,.kind,.premise,.subjectPath,.subjectScope]|map(@json)|join(" "))+"))"),(.methods[]|" (fact (methodFact "+([.kind,.method,.requiredCheck]|map(@json)|join(" "))+"))"),(.dependencies[]|" (fact (dependencyFact "+([.component,.obligation,.prerequisiteComponent,.prerequisite]|map(@json)|join(" "))+"))"),(.contracts[]|" (fact (contractFact "+([.contractId,.producer.componentId,.consumer.componentId,.phaseScope,.guarantee,.rely,.failureCustodian]|map(@json)|join(" "))+"))"),(.sourceRoutes[]|" (fact (sourceRouteFact "+(["host-roots",.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status]|map(@json)|join(" "))+"))")' "$r/planner-input.json" >> "$r/common.ss"
jq -n '{cases:[{id:"current",control:false},{id:"all-scoped-control",control:true},{id:"scan-only",control:true,keep:"HR-RC"},{id:"save-only",control:true,keep:"HR-MARKER"},{id:"omit-rc",control:true,omit:"HR-RC"},{id:"omit-marker",control:true,omit:"HR-MARKER"},{id:"omit-boot",control:true,omit:"HR-BOOT"},{id:"omit-exit",control:true,omit:"HR-EXIT"},{id:"omit-binding",control:true,omit:"HR-BIND"},{id:"omit-dynamic",control:true,omit:"HR-DYNAMIC"},{id:"wrong-detail-scope",control:true,wrongScope:"HR-DI"},{id:"stale-detail-digest",control:true,stale:"HR-DH"}]}' > "$r/scenarios.json"
while IFS= read -r scenario; do
 cp "$r/common.ss" "$r/case-$scenario.ss"
 jq -nr --arg s "$scenario" --slurpfile a "$r/planner-input.json" --slurpfile cs "$r/scenarios.json" --slurpfile inherited "$r/inherited.json" '
 def fact($rel;$row): " (fact ("+$rel+" "+($row|map(@json)|join(" "))+"))";
 ($cs[0].cases[]|select(.id==$s)) as $c |
 fact("scenarioFact";[$s,(if $c.control then "planner-control-only" else "source-bound-formal-receipts" end)]),
 ($a[0].needs[] as $q|$a[0].methods[]|select(.kind==$q.kind)|. as $m|
 (if $c.control or (["HR-DH","HR-DI"]|index($q.obligationId))!=null or ($inherited[0]|any(.[];.need==$q.obligationId)) then fact("artifactFact";[$s,$q.component,$q.obligationId,$m.method,$q.subjectPath,$q.digest]) else empty end),
 (if ($c.control and $c.omit!=$q.obligationId and ($c.keep==null or ($q.obligationId|startswith("HR-" )|not) or (["HR-H","HR-I","HR-S","HR-M","HR-DH","HR-DI",$c.keep]|index($q.obligationId))!=null)) or
 ($s=="current" and ((["HR-DH","HR-DI"]|index($q.obligationId))!=null or ($inherited[0]|any(.[];.need==$q.obligationId)))) then
 (if $c.control then empty else fact("receiptFact";[$s,$q.component,$q.obligationId,$m.method,$q.subjectPath,$q.digest,$m.requiredCheck,$q.subjectScope,"pass"]) end) else empty end))' >> "$r/case-$scenario.ss"
 # Finite controls synthesize evidence only under the explicit control scope.
 # Their rule replaces repetitive receipt rows, preserving every need and edge.
 cat >> "$r/case-$scenario.ss" <<'EOF'
 (relation controlDenied (scenario obligation))
 (relation controlBad (scenario obligation))
 ((receiptFact S C O M A H K T (lit "pass")) <--
  (scenarioFact S (lit "planner-control-only"))
  (modelRequired S C O M K A T _) (artifactFact S C O M A H)
  (not (controlBad S O)) (not (controlDenied S O)))
EOF
 jq -r --arg s "$scenario" --slurpfile i "$r/planner-input.json" '.cases[]|select(.id==$s and .control)|. as $c|$i[0].needs[]|. as $q|select(.obligationId==$c.omit or ($c.keep!=null and (.obligationId|startswith("HR-")) and (["HR-H","HR-I","HR-S","HR-M","HR-DH","HR-DI",$c.keep]|index($q.obligationId))==null))|" (fact (controlDenied "+([$s,.obligationId]|map(@json)|join(" "))+"))"' "$r/scenarios.json" >> "$r/case-$scenario.ss"
 jq -r --arg s "$scenario" --slurpfile i "$r/planner-input.json" '.cases[]|select(.id==$s)|. as $c|($c.wrongScope//$c.stale//empty) as $bad|$i[0].needs[]|select(.obligationId==$bad)|. as $q|$i[0].methods[]|select(.kind==$q.kind)|" (fact (controlBad "+([$s,$bad]|map(@json)|join(" "))+"))", " (fact (receiptFact "+([$s,$q.component,$bad,.method,$q.subjectPath,(if $c.stale then "stale-control" else $q.digest end),.requiredCheck,(if $c.wrongScope then "wrong-detail-scope-control" else $q.subjectScope end),"pass"]|map(@json)|join(" "))+"))"' "$r/scenarios.json" >> "$r/case-$scenario.ss"
 echo ')' >> "$r/case-$scenario.ss"
 jq -nr --rawfile s "$r/case-$scenario.ss" --slurpfile i "$r/planner-input.json" '"((selector "+($s|@json)+") (constructor \"query\") (displayBytes 1048576) (bindings "+([["target-model-bundle-sha256",$i[0].bundleHash],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")")+"))"' > "$r/case-$scenario.request.scm"
done < <(jq -r '.cases[].id' "$r/scenarios.json")
