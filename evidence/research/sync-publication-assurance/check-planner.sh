#!/bin/bash
set -euo pipefail
receipt_dir=.cache/tasks/sync-publication-assurance
.venv/bin/gambit-smp --task sync-publication-assurance trajectory submit < "$receipt_dir/submit.request.scm" > "$receipt_dir/ascent-submit.scm" 2> "$receipt_dir/ascent-submit.log"
.venv/bin/gambit-smp --task sync-publication-assurance trajectory clues < dev/modeling/ascent/synchronous-publication.request.scm > "$receipt_dir/ascent-read.scm" 2> "$receipt_dir/ascent-read.log"
ASSURANCE_READ="$receipt_dir/ascent-read.scm" ASSURANCE_JSON="$receipt_dir/planner-results.json" emacs -Q --batch -l "$receipt_dir/read-association.el"
for control_case in cycle unrouted transitive wrong-artifact; do
  sed '$d' "$receipt_dir/planner-composed.ss" > "$receipt_dir/control-$control_case.ss"
  case "$control_case" in
  cycle) echo ' (fact (dependencyFact "gc-synchronous-publication" "SP-HISTORY" "SP-SOURCE"))' >> "$receipt_dir/control-$control_case.ss" ;;
  unrouted) echo ' (fact (needFact "gc-synchronous-publication" "SP-UNROUTED" "unmapped-control" "Planner control only" "control-only"))' >> "$receipt_dir/control-$control_case.ss" ;;
  transitive) echo ' (fact (dependencyFact "gc-synchronous-publication" "SP-MEMORY" "SP-DEEP"))' >> "$receipt_dir/control-$control_case.ss" ;;
  wrong-artifact) cat >> "$receipt_dir/control-$control_case.ss" <<'FACTS'
 (fact (scenarioFact "wrong-artifact" "planner-control-only"))
 (fact (artifactFact "wrong-artifact" "gc-synchronous-publication" "QNT" "unrelated.qnt" "unrelated-bytes"))
 (fact (receiptFact "wrong-artifact" "gc-synchronous-publication" "QNT" "unrelated.qnt" "unrelated-bytes" "bounded-histories" "pass"))
FACTS
  ;;
  esac
  echo ')' >> "$receipt_dir/control-$control_case.ss"
  jq -nr --rawfile s "$receipt_dir/control-$control_case.ss" --slurpfile i "$receipt_dir/planner-input.json" '"((selector " + ($s|@json) + ") (constructor \"query\") (displayBytes 65536) (bindings " + ([["target-model-bundle-sha256",$i[0].bundleHash],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")") + "))"' > "$receipt_dir/control-$control_case.request.scm"
  .venv/bin/gambit-smp --task sync-publication-assurance trajectory clues < "$receipt_dir/control-$control_case.request.scm" > "$receipt_dir/control-$control_case.read.scm" 2> "$receipt_dir/control-$control_case.log"
  ASSURANCE_READ="$receipt_dir/control-$control_case.read.scm" ASSURANCE_JSON="$receipt_dir/control-$control_case.json" emacs -Q --batch -l "$receipt_dir/read-association.el"
done
