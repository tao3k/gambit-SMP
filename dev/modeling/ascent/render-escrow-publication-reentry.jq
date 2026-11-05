# Presentation only: topology, obligations, costs and callers come from SysML.
if $view=="d2" then
 "direction: down",
 (.nodes[]|(if .nodeId=="formal" then .labelText += "\nTask-local DSL; repository attestation unresolved" else . end)|.labelText|=gsub("\\\\n";"\n")|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.diagramEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \((if .producer.nodeId=="reenter" and .consumer.nodeId=="retain" then "reject\nstale" elif .producer.nodeId=="init" and .consumer.nodeId=="commit" then "init\nowner" elif .consumer.nodeId=="scan" or .consumer.nodeId=="freeze" or .consumer.nodeId=="deliver" or .consumer.nodeId=="commit" or .consumer.nodeId=="retain" or .producer.nodeId=="unknown" or .producer.nodeId=="enlist" or .producer.nodeId=="ready" or (.producer.nodeId=="ticket" and .consumer.nodeId=="pending") then .labelText|gsub(" ";"\n") else .labelText end)|@json)")
else
 "#+TITLE: Escrow Publication, Reentry and Peak-Memory Matrix", "#+PROPERTY: header-args :eval never", "",
 "* Execution scope", "Task-local native ASCENT cases only; repository host-source attestation remains unresolved.", "", "* Source caller matrix", "#+NAME: root-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.callers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Benefit and peak-memory matrix", "#+NAME: root-costs-native", "| Capability | Removed work | Quantified bound | Added cost | Condition or falsifier |", "|---+---+---+---+---|",
 (.publicationCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Obligations and imported open premises", "#+NAME: root-needs-native", "| Need | Kind | Exact scope | Premise |", "|---+---+---+---|",
 (.needs[]|"| "+([.obligationId,.kind,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: root-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
(.dependencies[]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |"), "",
 "* Scoped closure observations", "#+NAME: root-closure-observed", "| Need | Current evidence | Source/runtime boundary |", "|---+---+---|",
 (.needs[]|.obligationId as $id | "| "+$id+" | "+(if ($observation[0].qualifiedSlice|any(.[];.[2]==$id)) then "Checked task-local formal slice" else "Unresolved source or native-order obligation" end)+" | "+(if ($id=="EP-H" or $id=="EP-I") then "Conditional model only; no C simulation" elif $id=="EP-ORDER" then "No C-memory/platform refinement root" else "No source-simulation root" end)+" |")
end
