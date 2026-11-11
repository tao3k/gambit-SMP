# Presentation-only adapter. SysML is the topology, caller and cost authority.
if $view=="d2" then
 "direction: down",
 (.initNodes[]|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.initEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \(.labelText|@json)")
else
 "#+TITLE: Still initialization, safe-point and root custody and peak matrices (native projection)", "#+PROPERTY: header-args :eval never", "",
 "* Current producer and consumer matrix", ":PROPERTIES:", ":CUSTOM_ID: init-caller-matrix", ":END:",
 "#+NAME: init-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.initCallers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Work and whole-round peak matrix", ":PROPERTIES:", ":CUSTOM_ID: init-benefit-matrix", ":END:",
 "#+NAME: init-costs-native", "| Capability | Removed work | Quantified condition | Added cost | Boundary and falsifier |", "|---+---+---+---+---|",
 (.initCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Exact model scopes and dependencies", "#+NAME: init-needs-native",
 "| Need | Kind | Subject | Exact scope | Premise |", "|---+---+---+---+---|",
 (.refinementNeeds[]|select(.obligationId|startswith("SI-"))|"| "+([.obligationId,.kind,.subjectPath,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: init-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
 (.refinementDependencies[232:][]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |")
end
