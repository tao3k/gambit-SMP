#!/bin/bash
set -euo pipefail
task_dir=.cache/tasks/t0-chunk-close
for expected_file in expected-role-rows expected-duty-rows expected-caller-rows; do
  row_count=0
  while IFS= read -r wire_row; do
    matches=$(rg -o -F -- "$wire_row" "$task_dir/ascent-read.scm" | wc -l | tr -d ' ')
    test "$matches" = 1
    row_count=$((row_count+1))
  done < <(jq -r '.[] | "(" + (map(@json)|join(" ")) + ")"' "$task_dir/$expected_file.json")
  printf '%s %s\n' "$expected_file" "$row_count"
done
rg -q -F '("runtimeAdmitted" #f)' "$task_dir/ascent-read.scm"
rg -q -F '("executionAuthorized" #f)' "$task_dir/ascent-read.scm"
rg -q -F '("counts" (("counter" 0) ("hypotheses" 4) ("support" 0)))' "$task_dir/ascent-read.scm"
