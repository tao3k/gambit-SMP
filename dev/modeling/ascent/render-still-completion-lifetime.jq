# Presentation only: topology, obligations, costs and callers come from SysML.
if $view=="d2" then
 "direction: down",
 (.nodes[]|.labelText|=gsub("\\\\n";"\n")|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.diagramEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \((if .producer.nodeId=="unknown" then .labelText|gsub(" ";"\n") else .labelText end)|@json)")
else
 "#+TITLE: Native Completion, Exceptional Exit and Receipt Lifetime Matrix", "#+PROPERTY: header-args :eval never", "",
 "* Source caller matrix", "#+NAME: completion-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.callers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Benefit and peak-memory matrix", "#+NAME: completion-costs-native", "| Capability | Removed work | Quantified bound | Added cost | Condition or falsifier |", "|---+---+---+---+---|",
 (.completionCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Obligations and imported open premises", "#+NAME: completion-needs-native", "| Need | Kind | Exact scope | Premise |", "|---+---+---+---|",
 (.needs[]|"| "+([.obligationId,.kind,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: completion-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
(.dependencies[]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |"), "",
 "* Scoped closure observations", "#+NAME: completion-closure-observed", "| Need | Current evidence | Source/runtime boundary |", "|---+---+---|",
 (.needs[]|.obligationId as $id | "| "+$id+" | "+(if ($observation[0].qualifiedSlice|any(.[];.[2]==$id)) then "Exact local formal completion" else "Unresolved source obligation" end)+" | "+(if ($id=="NC-H" or $id=="NC-I") then "Conditional model only; no C simulation" else "No source-simulation completion" end)+" |")
end
