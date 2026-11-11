# Presentation-only adapter. SysML is the topology, caller and cost authority.
if $view=="d2" then
 "direction: down",
 (.guaranteedNodes[]|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.guaranteedEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \(.labelText|@json)")
else
 "#+TITLE: Guaranteed-tail placement and peak matrices (native projection)", "#+PROPERTY: header-args :eval never", "",
 "* Current producer and consumer matrix", ":PROPERTIES:", ":CUSTOM_ID: guaranteed-caller-matrix", ":END:",
 "#+NAME: guaranteed-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.guaranteedCallers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Work and whole-round peak matrix", ":PROPERTIES:", ":CUSTOM_ID: guaranteed-benefit-matrix", ":END:",
 "#+NAME: guaranteed-costs-native", "| Capability | Removed work | Quantified condition | Added cost | Boundary and falsifier |", "|---+---+---+---+---|",
 (.guaranteedCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Exact model scopes and dependencies", "#+NAME: guaranteed-needs-native",
 "| Need | Kind | Subject | Exact scope | Premise |", "|---+---+---+---+---|",
 (.refinementNeeds[]|select(.obligationId|startswith("GT-"))|"| "+([.obligationId,.kind,.subjectPath,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: guaranteed-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
 (.refinementDependencies[163:][]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |")
end
