#!/bin/bash
set -euo pipefail
task_dir=.cache/tasks/sync-publication-assurance
rg --files dev -g '*.sysml' -0 | xargs -0 openssl dgst -sha256 | LC_ALL=C sort > "$task_dir/models-before.sha256"
args=(-strict -validate -json)
for field_name in component.componentId component.ownerPath component.bindingId modelSet.quintSource modelSet.quintSymbols modelSet.leanSource modelSet.leanSymbols modelSet.evidenceReport modelSet.scope; do
  args+=(-e "GambitSynchronousPublication::$field_name")
done
for idx in {0..3}; do
  for field_name in routeId sourcePath sourceLines afterReturn idleCut qualification; do args+=(-e "GambitSynchronousPublication::route$idx.$field_name"); done
done
for idx in {0..3}; do
  for field_name in kind method requiredCheck; do args+=(-e "GambitSynchronousPublication::method$idx.$field_name"); done
done
for idx in {0..3}; do
  for field_name in obligationId kind premise subjectPath; do args+=(-e "GambitSynchronousPublication::need$idx.$field_name"); done
done
for idx in {0..2}; do
  for field_name in dependent.obligationId prerequisite.obligationId; do args+=(-e "GambitSynchronousPublication::dependency$idx.$field_name"); done
done

sysml "${args[@]}" dev > "$task_dir/native-metadata.json"
jq -e '.exit==0 and ((.errors//[])|length)==0' "$task_dir/native-metadata.json" >/dev/null
jq '[.output[]|select(startswith("  = "))|ltrimstr("  = ")|fromjson]' "$task_dir/native-metadata.json" > "$task_dir/evaluated.json"
jq -e 'length==67 and all(.[];type=="string")' "$task_dir/evaluated.json" >/dev/null
jq '{component:{id:.[0],owner:.[1],binding:.[2],quint:.[3],quintSymbols:.[4],lean:.[5],leanSymbols:.[6],report:.[7],scope:.[8]},routes:[range(9;33;6) as $i|{id:.[$i],source:.[$i+1],lines:.[$i+2],after:.[$i+3],idle:.[$i+4],premise:.[$i+5]}],methods:[range(33;45;3) as $i|{kind:.[$i],method:.[$i+1],check:.[$i+2]}],needs:[range(45;61;4) as $i|{id:.[$i],kind:.[$i+1],premise:.[$i+2],artifact:.[$i+3]}],dependencies:[range(61;67;2) as $i|{dependent:.[$i],prerequisite:.[$i+1]}]}' "$task_dir/evaluated.json" > "$task_dir/native-component.json"
jq -Rn '[inputs|capture("^[^(]+\\((?<key>.+)\\)= (?<value>[a-f0-9]{64})$")]|from_entries' "$task_dir/models-before.sha256"|jq -S . > "$task_dir/model-bindings.json"
