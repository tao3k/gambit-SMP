# Presentation-only adapter. SysML is the topology, caller and cost authority.
if $view=="d2" then
 "direction: down",
 (.materializationNodes[]|.labelText|=gsub("\\\\n";"\n")|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.materializationEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \((if .producer.nodeId==.consumer.nodeId then .labelText|gsub(" returns ";"\nreturns\n") else .labelText end)|@json)")
else
 "#+TITLE: Managed heap materialization, writer closure and peak matrices (native projection)", "#+PROPERTY: header-args :eval never", "",
 "* Current producer and consumer matrix", ":PROPERTIES:", ":CUSTOM_ID: materialization-caller-matrix", ":END:",
 "#+NAME: materialization-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.materializationCallers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Work and whole-round peak matrix", ":PROPERTIES:", ":CUSTOM_ID: materialization-benefit-matrix", ":END:",
 "#+NAME: materialization-costs-native", "| Capability | Removed work | Quantified condition | Added cost | Boundary and falsifier |", "|---+---+---+---+---|",
 (.materializationCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Exact model scopes and dependencies", "#+NAME: materialization-needs-native",
 "| Need | Kind | Subject | Exact scope | Premise |", "|---+---+---+---+---|",
 (.refinementNeeds[]|select(.obligationId|startswith("MC-"))|"| "+([.obligationId,.kind,.subjectPath,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: materialization-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
 (.refinementDependencies[299:][]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |")
end
