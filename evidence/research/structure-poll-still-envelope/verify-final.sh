#!/bin/bash
set -euo pipefail
r=.cache/tasks/structure-poll-still-envelope
e=evidence/research/structure-poll-still-envelope
for key in sourceBindings artifactBindings evidenceArtifactBindings; do
 jq -r --arg key "$key" '.[$key]|to_entries[]|[.key,.value]|@tsv' "$e/checks.json" | while IFS=$'\t' read -r f h; do test "$(openssl dgst -sha256 "$f"|awk '{print $NF}')" = "$h"; done
done
test "$(openssl dgst -sha256 "$e/checks.json"|awk '{print $NF}')" = "$(jq -r '.checks.sha256' dev/traceability.json)"
cmp "$r/case-current.request.scm" dev/modeling/ascent/component-assurance.request.scm
cmp "$r/build-cut/case-current.request.scm" dev/modeling/ascent/component-assurance-build.request.scm
cmp "$r/source-routes.request.scm" dev/modeling/ascent/component-assurance-routes.request.scm
jq -r --arg view matrix -f dev/modeling/ascent/render-structure-poll-still-envelope.jq "$r/native-projection.json" > "$r/matrix-verify.org"
cmp "$r/matrix-verify.org" dev/architecture/runtime/gc/structure-poll-still-envelope-matrix.org
jq -r --arg view d2 -f dev/modeling/ascent/render-structure-poll-still-envelope.jq "$r/native-projection.json" > "$r/diagram-verify.d2"
cmp "$r/diagram-verify.d2" dev/architecture/runtime/gc/diagrams/structure-poll-still-envelope.d2
jq -r -f dev/modeling/ascent/render-component-dependencies.jq "$r/graph-view.json" > "$r/graph-verify.d2"
cmp "$r/graph-verify.d2" dev/modeling/diagrams/component-proof-dependencies.d2
jq -e '.missingFiles==[] and .missingCustomIds==[] and .duplicateIds==[]' "$r/org-links.json" >/dev/null
bash "$r/assert.sh" >/dev/null
jq -e --slurpfile old "$r/entry-formal-bindings.json" 'del(.modelSourceBindings)==($old[0]|del(.modelSourceBindings))' dev/modeling/formal-bindings.json >/dev/null
jq -e '.closure.currentCompleteComponents==0 and .execution.nativeRuntimeTesting==false and .execution.runtimeImplementation==false and .runtimePathsRetired==[]' "$e/checks.json" >/dev/null
printf 'Source/artifact/evidence digests, native-derived views, exact cut union, Org links and preserved boundaries verified.\n'
cmp "$r/source-routes-tail.request.scm" dev/modeling/ascent/component-assurance-routes-tail.request.scm
emacs -Q --batch -l "$r/check-receipt-transport.el" > "$r/receipt-transport-recheck.log" 2>&1
jq -e --slurpfile p "$r/planner-input.json" --slurpfile inherited "$r/inherited.json" 'sort==([$p[0].needs[] as $q|$p[0].methods[]|select(.kind==$q.kind)|. as $m|select(($q.obligationId=="SP-H" or $q.obligationId=="SP-I") or ($inherited[0]|any(.[];.need==$q.obligationId)))|["current",$q.component,$q.obligationId,$m.method,$q.subjectPath,$q.digest,$m.requiredCheck,$q.subjectScope,"pass"]]|sort)' "$r/unpacked-receipts.json" >/dev/null
jq -e '.nativeQualification.wholeDevPassed==false and .structure.nativeSysmlFiles==51 and .reasoning.scenarioCases==16 and .reasoning.metadataProjectionCuts==2 and (.reasoning.scenarios|length)==16 and .closure.currentQualifiedLocalSlices==36' "$e/checks.json" >/dev/null
