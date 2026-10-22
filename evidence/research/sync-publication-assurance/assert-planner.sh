#!/bin/bash
set -euo pipefail
r=.cache/tasks/sync-publication-assurance
jq -e --slurpfile data "$r/planner-results.json" -f "$r/assert-planner.jq" "$r/planner-results.json"
jq -e '.dependencyCycle|contains([["gc-synchronous-publication","SP-HISTORY"],["gc-synchronous-publication","SP-SOURCE"]])' "$r/control-cycle.json"
jq -e '.nextAction|contains([["current","gc-synchronous-publication","SP-HISTORY","repair-dependency-cycle","QNT","SP-HISTORY"]])' "$r/control-cycle.json"
jq -e '.unroutedNeed|contains([["current","gc-synchronous-publication","SP-UNROUTED","unmapped-control"]])' "$r/control-unrouted.json"
jq -e '.nextAction|contains([["current","gc-synchronous-publication","SP-UNROUTED","define-method-policy","Unassigned","unmapped-control"]])' "$r/control-unrouted.json"
jq -e '.unmetDependency|contains([["current","gc-synchronous-publication","SP-SOURCE","SP-DEEP"]])' "$r/control-transitive.json"
jq -e '(.missingModel|contains([["wrong-artifact","gc-synchronous-publication","SP-HISTORY","QNT"]])) and (.qualifiedSlice|all(.[]; .[0]!="wrong-artifact"))' "$r/control-wrong-artifact.json"
