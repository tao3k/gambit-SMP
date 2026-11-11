# Presentation-only adapter. SysML is the topology, caller and cost authority.
if $view=="d2" then
 "direction: down",
 (.recoveryNodes[]|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.recoveryEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \((if .producer.nodeId==.consumer.nodeId then .labelText|gsub(" returns ";"\nreturns\n") else .labelText end)|@json)")
else
 "#+TITLE: Partial initialization and undelivered-result recovery matrices (native projection)", "#+PROPERTY: header-args :eval never", "",
 "* Current producer and consumer matrix", ":PROPERTIES:", ":CUSTOM_ID: recovery-caller-matrix", ":END:",
 "#+NAME: recovery-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.recoveryCallers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Work and whole-round peak matrix", ":PROPERTIES:", ":CUSTOM_ID: recovery-benefit-matrix", ":END:",
 "#+NAME: recovery-costs-native", "| Capability | Removed work | Quantified condition | Added cost | Boundary and falsifier |", "|---+---+---+---+---|",
 (.recoveryCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Exact model scopes and dependencies", "#+NAME: recovery-needs-native",
 "| Need | Kind | Subject | Exact scope | Premise |", "|---+---+---+---+---|",
 (.refinementNeeds[]|select(.obligationId|startswith("IR-"))|"| "+([.obligationId,.kind,.subjectPath,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: recovery-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
 (.refinementDependencies[248:][]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |")
end
