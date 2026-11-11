# Presentation only: topology, obligations, costs and callers come from SysML.
if $view=="d2" then
 "direction: down",
 (.nodes[]|.labelText|=gsub("\\\\n";"\n")|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.diagramEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \((.labelText|gsub(" ";"\n"))|@json)")
else
 "#+TITLE: Controlled Marker Layout, Root Scan, Benefits and Peak-Memory Matrix", "#+PROPERTY: header-args :eval never", "",
 "* Execution scope", "Repository Evidence/ASCENT queries completed for the exact selected source bundle; source and C-memory obligations remain open. No runtime admission.", "", "* Native layout arithmetic", "| Word bytes | Candidate subtype | SCMOBJ slots | Raw key bytes | Body bytes | Object bytes | Wrapper request | Delta from SMP |", "|---+---+---+---+---+---+---+---|",
 (.layouts[]|"| "+([.wordBytes,.subtypeCandidate,.rootWords,.keyBytes,.bodyBytes,.objectBytes,.allocatorRequest,.deltaFromSmp]|map(tostring)|join(" | "))+" |"), "",
 "* Source caller matrix", "#+NAME: root-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.callers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Benefit and peak-memory matrix", "#+NAME: root-costs-native", "| Capability | Removed work | Quantified bound | Added cost | Condition or falsifier |", "|---+---+---+---+---|",
 (.layoutCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Obligations and imported open premises", "#+NAME: root-needs-native", "| Need | Kind | Exact scope | Premise |", "|---+---+---+---|",
 (.needs[]|"| "+([.obligationId,.kind,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: root-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
(.dependencies[]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |"), "",
 "* Scoped closure observations", "#+NAME: root-closure-observed", "| Need | Current evidence | Source/runtime boundary |", "|---+---+---|",
 (.needs[]|.obligationId as $id | "| "+$id+" | "+(if ($observation[0].qualifiedSlice|any(.[];.[2]==$id)) then "Checked task-local formal slice" else "Unresolved source or native-order obligation" end)+" | "+(if ($id=="ML-H" or $id=="ML-I") then "Conditional model only; no C simulation" elif $id=="ML-ORDER" then "No C-memory/platform refinement root" else "No source-simulation root" end)+" |")
end
