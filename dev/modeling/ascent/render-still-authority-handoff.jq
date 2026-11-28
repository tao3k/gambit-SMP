# Presentation-only adapter. SysML is the topology, caller and cost authority.
if $view=="d2" then
 "direction: down",
 (.authorityNodes[]|.labelText|=gsub("\\\\n";"\n")|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.authorityEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \((if .producer.nodeId==.consumer.nodeId then .labelText|gsub(" returns ";"\nreturns\n") else .labelText end)|@json)")
else
 "#+TITLE: Heap authority, canonical still handoff and peak matrices (native projection)", "#+PROPERTY: header-args :eval never", "",
 "* Current producer and consumer matrix", ":PROPERTIES:", ":CUSTOM_ID: authority-caller-matrix", ":END:",
 "#+NAME: authority-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.authorityCallers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Work and whole-round peak matrix", ":PROPERTIES:", ":CUSTOM_ID: authority-benefit-matrix", ":END:",
 "#+NAME: authority-costs-native", "| Capability | Removed work | Quantified condition | Added cost | Boundary and falsifier |", "|---+---+---+---+---|",
 (.authorityCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Exact model scopes and dependencies", "#+NAME: authority-needs-native",
 "| Need | Kind | Subject | Exact scope | Premise |", "|---+---+---+---+---|",
 (.refinementNeeds[]|select(.obligationId|startswith("AH-"))|"| "+([.obligationId,.kind,.subjectPath,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: authority-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
 (.refinementDependencies[322:][]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |")
end
