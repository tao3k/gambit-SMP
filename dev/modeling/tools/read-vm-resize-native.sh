#!/bin/bash
set -euo pipefail
r=.cache/tasks/modern-c-frame-contract/cohort/resize-model
args=(-strict -validate -json)
while IFS=$'\t' read -r key expression; do args+=(-e "$expression"); done < "$r/native-queries.tsv"
files=(); while IFS= read -r f; do files+=("$f"); done < "$r/native-model-inputs.txt"
sysml "${args[@]}" "${files[@]}" > "$r/native-metadata.json" 2> "$r/sysml.log"
jq -e '.exit==0 and ((.errors//[])|length)==0' "$r/native-metadata.json" >/dev/null
jq '[.output[]|select(startswith("  = "))|ltrimstr("  = ")|fromjson]' "$r/native-metadata.json" > "$r/native-values.json"
jq -Rn '[inputs|split("\t")|.[0]|split(".")|map(. as $s|try tonumber catch $s)]' "$r/native-queries.tsv" > "$r/native-keys.json"
jq -n --slurpfile k "$r/native-keys.json" --slurpfile v "$r/native-values.json" 'if ($k[0]|length)!=($v[0]|length) then error("incomplete native evaluation") else reduce range(0;($k[0]|length)) as $i ({};setpath($k[0][$i];$v[0][$i])) end' > "$r/native-projection.json"
