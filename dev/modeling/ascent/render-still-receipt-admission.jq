# Presentation only: topology, obligations, costs and callers come from SysML.
if $view=="d2" then
 "direction: down",
 (.nodes[]|.labelText|=gsub("\\\\n";"\n")|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.diagramEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \(.labelText|@json)")
else
 "#+TITLE: Allocation Receipts and Snapshot Admission Matrix", "#+PROPERTY: header-args :eval never", "",
 "* Source caller matrix", "#+NAME: receipt-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.callers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Benefit and peak-memory matrix", "#+NAME: receipt-costs-native", "| Capability | Removed work | Quantified bound | Added cost | Condition or falsifier |", "|---+---+---+---+---|",
 (.receiptCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Obligations and imported open premises", "#+NAME: receipt-needs-native", "| Need | Kind | Exact scope | Premise |", "|---+---+---+---|",
 (.needs[]|"| "+([.obligationId,.kind,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: receipt-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
(.dependencies[]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |"), "",
 "* Scoped closure observations", "#+NAME: receipt-closure-observed", "| Need | Current evidence | Source/runtime boundary |", "|---+---+---|",
 (.needs[]|.obligationId as $id | "| "+$id+" | "+(if ($observation[0].qualifiedSlice|any(.[];.[2]==$id)) then "Exact local formal receipt" else "Unresolved source obligation" end)+" | "+(if ($id=="RA-H" or $id=="RA-I") then "Conditional model only; no C simulation" else "No source-simulation receipt" end)+" |")
end
