#!/bin/sh
set -eu
# Usage: run.sh SOURCE_REPOSITORY MATERIALIZED_CANDIDATE OUTPUT
repo=$(cd "$1" && pwd)
source=$(cd "$2" && pwd)
output=$3
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
test ! -e "$output"
mkdir -p "$output"
output=$(cd "$output" && pwd)
expected=$(jq -r '.files["lib/setup.c"].candidateSha256' "$repo/evidence/research/processor-interrupt-collective-wait/source.lock.json")
actual=$(shasum -a 256 "$source/lib/setup.c" | cut -d ' ' -f 1)
test "$expected" = "$actual"
expected_header=$(jq -r '.files["include/gambit.h.in"].candidateSha256' "$repo/evidence/research/processor-interrupt-collective-wait/source.lock.json")
actual_header=$(shasum -a 256 "$source/include/gambit.h.in" | cut -d ' ' -f 1)
test "$expected_header" = "$actual_header"
# The delimited region includes the complete registry code and raise_interrupt.
# No behavior is translated, instrumented with hooks, or rewritten.
awk '/^#ifndef ___SINGLE_VM/ && !started {started=1} /^___EXP_FUNC\(void,___init_procedural_interrupt\)/ {exit} started {print}' \
  "$source/lib/setup.c" > "$output/registry.inc"
cp "$here/component.c" "$output/component.c"
printf '%s\n' "$actual" > "$output/source.sha256"
"${CC:-/usr/bin/clang}" -std=c11 -O1 -g -pthread -Wall -Wextra -Werror -Wno-unused-variable \
  "$output/component.c" -o "$output/component"
"$output/component" > "$output/native.log"
cat "$output/native.log"
# Address checks are separate from race checks. ASan sees only this component's
# native accesses and fixture destinations, not the whole Gambit heap.
"${CC:-/usr/bin/clang}" -std=c11 -O1 -g -pthread -fsanitize=address \
  "$output/component.c" -o "$output/component-asan"
"$output/component-asan" > "$output/asan.log" 2>&1
cat "$output/asan.log"
"${CC:-/usr/bin/clang}" -std=c11 -O1 -g -pthread -fsanitize=thread \
  "$output/component.c" -o "$output/component-tsan"
"$output/component-tsan" > "$output/tsan.log" 2>&1
cat "$output/tsan.log"
# Test sensitivity controls, not claims about unmodified historical C source.
# Current source must pass; deleting a reader lease must fail this same witness.
for control in admission replay; do
  mkdir "$output/$control"
  cp "$output/component.c" "$output/$control/component.c"
  if [ "$control" = admission ]; then
    sed 's/old, old + 4/old, old/' "$output/registry.inc" > "$output/$control/registry.inc"
  else
    sed 's/if (!vm_registry_enter())/if (0)/' "$output/registry.inc" > "$output/$control/registry.inc"
  fi
  "${CC:-/usr/bin/clang}" -std=c11 -O1 -g -pthread \
    "$output/$control/component.c" -o "$output/$control/component"
  ulimit -c 0
  if "$output/$control/component" > "$output/$control/result.log" 2>&1; then
    echo "mutation unexpectedly accepted: $control" >&2; exit 1
  else
    status=$?
    test "$status" -eq 134
    grep -q 'Assertion failed' "$output/$control/result.log"
    if [ "$control" = admission ]; then
      grep -Fq 'atomic_load(&phase)==0' "$output/$control/result.log"
    else
      grep -Fq 'atomic_load(&phase)==1' "$output/$control/result.log"
    fi
    printf 'MUTATION-REJECTED %s exit=%s\n' "$control" "$status"
  fi
done
for model in vm_registry_repeated_retirement vm_registry_processor_retirement vm_registry_failed_join_retention; do
  "${QUINT:-quint}" test "$repo/models/gambit/$model.qnt" --seed=0x19 --max-samples=1 \
    > "$output/$model.log" 2>&1
  cat "$output/$model.log"
done
printf 'REGISTRY-REUSE-REVIEW-OK\n'
