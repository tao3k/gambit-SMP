#!/bin/bash
set -euo pipefail
task_dir=.cache/tasks/t0-chunk-close
rg --files dev -g '*.sysml' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort > "$task_dir/models-before.sha256"
args=(-strict -validate -json)
for binding_name in rootHandoff controlOrigin retirement workClosure; do
  for field_name in contractId quintSource leanSource resultClass compositionStatus; do
    args+=(-e "GambitPublicationClose::formalBridge.$binding_name.$field_name")
  done
done
for duty_index in {0..8}; do
  for field_name in dutyId lawSymbol sourcePath openPremise formal.contractId; do
    args+=(-e "GambitPublicationClose::duty$duty_index.$field_name")
  done
done
for caller_index in {0..31}; do
  for field_name in callerId role sourcePath sourceLines chain closingCut coverageLimit family.familyId formal.contractId; do
    args+=(-e "GambitPublicationClose::caller$caller_index.$field_name")
  done
done

sysml "${args[@]}" dev > "$task_dir/native-metadata.json"
jq -e '.exit == 0 and ((.errors // [])|length)==0' "$task_dir/native-metadata.json" >/dev/null
jq '[.output[] | select(startswith("  = ")) | ltrimstr("  = ") | fromjson]' "$task_dir/native-metadata.json" > "$task_dir/evaluated.json"
jq -e 'length==353 and all(.[]; type=="string")' "$task_dir/evaluated.json" >/dev/null
jq '{pairs:[range(0;20;5) as $i | {contract: .[$i], quint: .[$i+1], lean: .[$i+2], evidenceClass: .[$i+3], composition: .[$i+4]}], duties:[range(20;65;5) as $i | {id:.[$i],law:.[$i+1],source:.[$i+2],premise:.[$i+3],contract:.[$i+4]}], callers:[range(65;353;9) as $i | {id:.[$i],role:.[$i+1],source:.[$i+2],lines:.[$i+3],chain:.[$i+4],cut:.[$i+5],limit:.[$i+6],family:.[$i+7],contract:.[$i+8]}]}' "$task_dir/evaluated.json" > "$task_dir/native-associations.json"
jq -Rn '[inputs | capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")] | from_entries' "$task_dir/models-before.sha256" | jq -S . > "$task_dir/model-bindings.json"
