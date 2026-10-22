#!/bin/bash
set -euo pipefail
r=.cache/tasks/build-concurrency
args=(-strict -validate -json)
: > "$r/keys.txt"
for node in planning frontend readiness execution; do
 for field in boundaryId labelText sourceAnchor redesign gain addedCost openCondition sourceDuty.obligationId sourceDuty.owner.componentId; do
  printf '%s\n' "$node.$field" >> "$r/keys.txt"
  args+=(-e "GerbilModuleBuild::$node.$field")
 done
done
for edge in edge0 edge1 edge2; do
 for field in producer.boundaryId consumer.boundaryId; do
  printf '%s\n' "$edge.$field" >> "$r/keys.txt"
  args+=(-e "GerbilModuleBuild::$edge.$field")
 done
done
sysml "${args[@]}" dev > "$r/native.json"
jq -e '.exit == 0 and ((.errors // []) | length) == 0' "$r/native.json" >/dev/null
jq '[.output[] | select(startswith("  = ")) | ltrimstr("  = ") | fromjson]' "$r/native.json" > "$r/values.json"
jq -Rn '[inputs | split(".")]' "$r/keys.txt" > "$r/keys.json"
jq -n --slurpfile k "$r/keys.json" --slurpfile v "$r/values.json" 'if ($k[0]|length) != ($v[0]|length) then error("missing native value") else reduce range(0;($k[0]|length)) as $i ({}; setpath($k[0][$i]; $v[0][$i])) end' > "$r/projection.json"
