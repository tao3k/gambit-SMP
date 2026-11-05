# Presentation only: topology, obligations, costs and callers come from SysML.
if $view=="d2" then
 "direction: down",
 (.nodes[]|.labelText|=gsub("\\\\n";"\n")|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.diagramEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \((if .consumer.nodeId=="freeze" or .consumer.nodeId=="seal" or .consumer.nodeId=="retain" or .producer.nodeId=="unknown" or .producer.nodeId=="enlist" or .producer.nodeId=="ready" or (.producer.nodeId=="ticket" and .consumer.nodeId=="pending") then .labelText|gsub(" ";"\n") else .labelText end)|@json)")
else
 "#+TITLE: Construction Debt Closure and Peak-Memory Matrix", "#+PROPERTY: header-args :eval never", "",
 "* Source caller matrix", "#+NAME: root-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.callers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Benefit and peak-memory matrix", "#+NAME: root-costs-native", "| Capability | Removed work | Quantified bound | Added cost | Condition or falsifier |", "|---+---+---+---+---|",
 (.closureCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Obligations and imported open premises", "#+NAME: root-needs-native", "| Need | Kind | Exact scope | Premise |", "|---+---+---+---|",
 (.needs[]|"| "+([.obligationId,.kind,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: root-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
(.dependencies[]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |"), "",
 "* Scoped closure observations", "#+NAME: root-closure-observed", "| Need | Current evidence | Source/runtime boundary |", "|---+---+---|",
 (.needs[]|.obligationId as $id | "| "+$id+" | "+(if ($observation[0].qualifiedSlice|any(.[];.[2]==$id)) then "Exact local formal root" else "Unresolved source or native-order obligation" end)+" | "+(if ($id=="CD-H" or $id=="CD-I") then "Conditional model only; no C simulation" elif $id=="CD-ORDER" then "No C-memory/platform refinement root" else "No source-simulation root" end)+" |")
end
