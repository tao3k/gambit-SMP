#!/bin/bash
# Thin serialization of native evaluated metadata; no architecture parser.
set -euo pipefail
task_dir=.cache/tasks/t0-chunk-close
jq -r '[.pairs[]|.quint,.lean] + [.duties[].source] + [.callers[].source] | unique[]' "$task_dir/native-associations.json" |
while IFS= read -r source_file; do
  test -f "$source_file"
  digest=$(openssl dgst -sha256 "$source_file" | awk '{print $NF}')
  jq -n --arg key "$source_file" --arg value "$digest" '{key:$key,value:$value}'
done | jq -s 'from_entries' > "$task_dir/association-source-hashes.json"
jq --slurpfile hashes "$task_dir/association-source-hashes.json" '.pairs |= map(. + {quintHash:$hashes[0][.quint],leanHash:$hashes[0][.lean]}) | .duties |= map(. + {sourceHash:$hashes[0][.source]}) | .callers |= map(. + {sourceHash:$hashes[0][.source]})' "$task_dir/native-associations.json" > "$task_dir/digested-associations.json"
# Verify selected root identities against retained source registry, not only caller facts.
jq -e --slurpfile f "$task_dir/entry-bindings.json" 'all(.pairs[]; . as $p | $f[0].sources[$p.quint].sha256==$p.quintHash and $f[0].sources[$p.lean].sha256==$p.leanHash)' "$task_dir/digested-associations.json" >/dev/null
selector=dev/modeling/ascent/publication-close.ss
cat > "$selector" <<'QUERY'
;; Generated transport from native SysML evaluation, bound by the scoped receipt.
;; Source metadata remains in GambitPublicationClose; all new duties OPEN.
(define-evidence (query)
 (sources clue factor binding) (outputs question roleModel closureDuty callerDuty)
 (include clue-selection-schema)
 (relation question (claim))
 (relation nativePair (contract quint quintHash lean leanHash evidenceClass composition))
 (relation nativeDuty (duty law source sourceHash contract premise))
 (relation roleModel (claim contract quint quintHash lean leanHash evidenceClass composition premise targetBundle nativeOutputHash))
 (relation closureDuty (claim duty law source sourceHash contract premise targetBundle nativeOutputHash))
 (relation nativeCaller (caller role source lines sourceHash family contract cut boundary))
 (relation callerDuty (claim caller role source lines sourceHash family contract cut boundary targetBundle nativeOutputHash))

QUERY
jq -r '.pairs[] | " (fact (nativePair " + ([.contract,.quint,.quintHash,.lean,.leanHash,.evidenceClass,.composition]|map(@json)|join(" ")) + "))"' "$task_dir/digested-associations.json" >> "$selector"
jq -r '.duties[] | " (fact (nativeDuty " + ([.id,.law,.source,.sourceHash,.contract,.premise]|map(@json)|join(" ")) + "))"' "$task_dir/digested-associations.json" >> "$selector"
jq -r '.callers[] | " (fact (nativeCaller " + ([.id,.role,.source,.lines,.sourceHash,.family,.contract,.cut,.limit]|map(@json)|join(" ")) + "))"' "$task_dir/digested-associations.json" >> "$selector"

cat >> "$selector" <<'QUERY'
 ((roleModel C K Q QH L LH E S P T N) <--
  (nativePair K Q QH L LH E S) (clue I D C _ _ _)
  (factor I D (lit "quint-model") Q) (factor I D (lit "lean-model") L)
  (factor I D (lit "model-source-sha256") QH) (factor I D (lit "model-source-sha256") LH)
  (factor I D (lit "association-source-sha256") H) (binding (lit "association-source-sha256") H)
  (factor I D (lit "association-bundle-sha256") B) (binding (lit "association-bundle-sha256") B)
  (factor I D (lit "open-premise") P)
  (binding (lit "role-model-bundle-sha256") T) (binding (lit "native-output-sha256") N))
 ((closureDuty C D Y S SH K P T N) <--
  (nativeDuty D Y S SH K P) (roleModel C K _ _ _ _ _ _ _ T N))
 ((callerDuty C I R S L SH F K X B T N) <--
  (nativeCaller I R S L SH F K X B) (roleModel C K _ _ _ _ _ _ _ T N))

 ((question C) <-- (roleModel C _ _ _ _ _ _ _ _ _ _)))
QUERY
model_digest=$(openssl dgst -sha256 "$task_dir/model-bindings.json" | awk '{print $NF}')
native_digest=$(openssl dgst -sha256 "$task_dir/native-metadata.json" | awk '{print $NF}')
association_digest=$(openssl dgst -sha256 dev/modeling/models/sysml/assurance.sysml | awk '{print $NF}')
association_bundle=$(jq -r '.componentModels.associationBundle' "$task_dir/entry-bindings.json")
jq -nr --rawfile selector "$selector" --arg a "$association_digest" --arg b "$association_bundle" --arg t "$model_digest" --arg n "$native_digest" '"((selector " + ($selector|@json) + ") (constructor \"query\") (displayBytes 65536) (bindings " + ([ ["association-source-sha256",$a], ["association-bundle-sha256",$b], ["role-model-bundle-sha256",$t], ["native-output-sha256",$n] ] | "(" + (map("(" + (map(@json)|join(" ")) + ")")|join(" ")) + ")") + "))"' > dev/modeling/ascent/publication-close.request.scm
jq --slurpfile f "$task_dir/entry-bindings.json" --arg t "$model_digest" --arg n "$native_digest" '[.pairs[] as $p | $f[0].componentModels.uses[] | select(.bindingId==$p.contract) | ["component-model:"+.componentId+":"+$f[0].componentModels.associationBundle,$p.contract,$p.quint,$p.quintHash,$p.lean,$p.leanHash,$p.evidenceClass,$p.composition,.openPremises,$t,$n]]' "$task_dir/digested-associations.json" > "$task_dir/expected-role-rows.json"
jq --slurpfile r "$task_dir/expected-role-rows.json" --arg t "$model_digest" --arg n "$native_digest" '[.duties[] as $d | $r[0][] | select(.[1]==$d.contract) | [.[0],$d.id,$d.law,$d.source,$d.sourceHash,$d.contract,$d.premise,$t,$n]]' "$task_dir/digested-associations.json" > "$task_dir/expected-duty-rows.json"
jq --slurpfile r "$task_dir/expected-role-rows.json" --arg t "$model_digest" --arg n "$native_digest" '[.callers[] as $d | $r[0][] | select(.[1]==$d.contract) | [.[0],$d.id,$d.role,$d.source,$d.lines,$d.sourceHash,$d.family,$d.contract,$d.cut,$d.limit,$t,$n]]' "$task_dir/digested-associations.json" > "$task_dir/expected-caller-rows.json"
