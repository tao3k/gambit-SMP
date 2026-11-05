# Presentation-only adapter. SysML is the topology, caller and cost authority.
if $view=="d2" then
 "direction: down",
 (.structureNodes[]|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.structureEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \(.labelText|@json)")
else
 "#+TITLE: Structure POLL, frames and still and peak matrices (native projection)", "#+PROPERTY: header-args :eval never", "",
 "* Current producer and consumer matrix", ":PROPERTIES:", ":CUSTOM_ID: structure-caller-matrix", ":END:",
 "#+NAME: structure-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.structureCallers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Work and whole-round peak matrix", ":PROPERTIES:", ":CUSTOM_ID: structure-benefit-matrix", ":END:",
 "#+NAME: structure-costs-native", "| Capability | Removed work | Quantified condition | Added cost | Boundary and falsifier |", "|---+---+---+---+---|",
 (.structureCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Exact model scopes and dependencies", "#+NAME: structure-needs-native",
 "| Need | Kind | Subject | Exact scope | Premise |", "|---+---+---+---+---|",
 (.refinementNeeds[]|select(.obligationId|startswith("SP-"))|"| "+([.obligationId,.kind,.subjectPath,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: structure-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
 (.refinementDependencies[208:][]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |")
end
