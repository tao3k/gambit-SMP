# Presentation-only adapter. SysML is the topology, caller and cost authority.
if $view=="d2" then
 "direction: down",
 (.ledgerNodes[]|.labelText|=gsub("\\\\n";"\n")|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.ledgerEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \((if .producer.nodeId==.consumer.nodeId then .labelText|gsub(" returns ";"\nreturns\n") else .labelText end)|@json)")
else
 "#+TITLE: Still inventory reconstruction, consistent views and peak matrices (native projection)", "#+PROPERTY: header-args :eval never", "",
 "* Current producer and consumer matrix", ":PROPERTIES:", ":CUSTOM_ID: ledger-caller-matrix", ":END:",
 "#+NAME: ledger-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.ledgerCallers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Work and whole-round peak matrix", ":PROPERTIES:", ":CUSTOM_ID: ledger-benefit-matrix", ":END:",
 "#+NAME: ledger-costs-native", "| Capability | Removed work | Quantified condition | Added cost | Boundary and falsifier |", "|---+---+---+---+---|",
 (.ledgerCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Exact model scopes and dependencies", "#+NAME: ledger-needs-native",
 "| Need | Kind | Subject | Exact scope | Premise |", "|---+---+---+---+---|",
 (.refinementNeeds[]|select(.obligationId|startswith("LS-"))|"| "+([.obligationId,.kind,.subjectPath,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: ledger-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
 (.refinementDependencies[349:][]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |")
end
