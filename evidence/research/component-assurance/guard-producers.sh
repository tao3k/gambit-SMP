#!/bin/bash
set -euo pipefail
r=.cache/tasks/component-assurance
jq -e --slurpfile formal "$r/formal-checks.json" --slurpfile previous evidence/research/sync-publication-assurance/checks.json -f "$r/qualify-formal.jq" "$r/planner-input.json" > "$r/producer-qualification.log"
jq -e 'length==21 and all(.[];.exitCode==0)' "$r/formal-checks.json" > "$r/formal-completeness.log"
jq -r '.[]|[.source,.sourceSha256]|@tsv' "$r/formal-checks.json" | while IFS=$'\t' read -r source_file expected_hash; do
 actual_hash=$(openssl dgst -sha256 "$source_file"|awk '{print $NF}'); test "$actual_hash" = "$expected_hash"
done
for slice in Build Runtime; do
 jq -r --arg slice "$slice" '.components[(if $slice=="Build" then 0 else 3 end):(if $slice=="Build" then 3 else 7 end)][].leanScope|split(":") as $s|$s[1]|split(";")[]|"#check "+$s[0]+"."+.' "$r/native-projection.json" | while IFS= read -r symbol_check; do
  rg -q -F -x "$symbol_check" "$r/${slice}Scopes.lean"
 done
done
