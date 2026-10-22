#!/bin/bash
set -euo pipefail
r=.cache/tasks/component-assurance
wrap() {
 jq -nr --rawfile s "$1" --slurpfile i "$r/planner-input.json" '"((selector "+($s|@json)+") (constructor \"query\") (displayBytes 1048576) (bindings "+([["target-model-bundle-sha256",$i[0].bundleHash],["native-output-sha256",$i[0].nativeHash],["planner-dsl-sha256",$i[0].dslHash]]|"("+(map("("+(map(@json)|join(" "))+")")|join(" "))+")")+"))"' > "$2"
}
while IFS= read -r scenario_id; do
 cp "$r/common.ss" "$r/case-$scenario_id.ss"
 rg -F "\"$scenario_id\" " "$r/scenario-facts.ss" >> "$r/case-$scenario_id.ss"
 echo ')' >> "$r/case-$scenario_id.ss"
 wrap "$r/case-$scenario_id.ss" "$r/case-$scenario_id.request.scm"
done < <(jq -r '.cases[].id' "$r/scenarios.json")
cp "$r/case-current.request.scm" dev/modeling/ascent/component-assurance.request.scm
for control_name in cycle unrouted dangling unbound multi-method; do
 cp "$r/common.ss" "$r/control-$control_name.ss"
 rg -F '"all-scoped-control" ' "$r/scenario-facts.ss" >> "$r/control-$control_name.ss"
 case "$control_name" in
 cycle) echo ' (fact (dependencyFact "host-roots" "HR-H" "continuation" "CO-S"))' >> "$r/control-$control_name.ss" ;;
 unrouted) cat >> "$r/control-$control_name.ss" <<'FACTS'
 (fact (needFact "host-roots" "HR-X" "unmapped-control" "Control only" "control-only" "control-only"))
 (fact (dependencyFact "host-roots" "HR-S" "host-roots" "HR-X"))
FACTS
 ;;
 dangling) echo ' (fact (dependencyFact "gc-work" "GW-S" "absent-component" "MISSING"))' >> "$r/control-$control_name.ss" ;;
 unbound) sed '/(fact (componentFact "host-roots" /d' "$r/control-$control_name.ss" > "$r/control-unbound.tmp"; mv "$r/control-unbound.tmp" "$r/control-$control_name.ss" ;;
 multi-method) echo ' (fact (methodFact "induction" "SecondProof" "independent-audit"))' >> "$r/control-$control_name.ss" ;;
 esac
 echo ')' >> "$r/control-$control_name.ss"
 wrap "$r/control-$control_name.ss" "$r/control-$control_name.request.scm"
done
