# Presentation-only adapter. SysML is the topology, caller and cost authority.
if $view=="d2" then
 "direction: down",
 (.ownerNodes[]|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.ownerEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \((if .producer.nodeId==.consumer.nodeId then .labelText|gsub(" returns ";"\nreturns\n") else .labelText end)|@json)")
else
 "#+TITLE: Stopped-owner, native isolation and receipt retirement matrices (native projection)", "#+PROPERTY: header-args :eval never", "",
 "* Current producer and consumer matrix", ":PROPERTIES:", ":CUSTOM_ID: owner-caller-matrix", ":END:",
 "#+NAME: owner-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.ownerCallers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Work and whole-round peak matrix", ":PROPERTIES:", ":CUSTOM_ID: owner-benefit-matrix", ":END:",
 "#+NAME: owner-costs-native", "| Capability | Removed work | Quantified condition | Added cost | Boundary and falsifier |", "|---+---+---+---+---|",
 (.ownerCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Exact model scopes and dependencies", "#+NAME: owner-needs-native",
 "| Need | Kind | Subject | Exact scope | Premise |", "|---+---+---+---+---|",
 (.refinementNeeds[]|select(.obligationId|startswith("OR-"))|"| "+([.obligationId,.kind,.subjectPath,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: owner-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
 (.refinementDependencies[274:][]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |")
end
