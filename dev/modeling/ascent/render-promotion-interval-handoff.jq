# Presentation-only transport. Native SysML owns topology, callers, costs and needs.
if $view=="d2" then
 "direction: down",
 (.intervalNodes[]|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.intervalEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \(.labelText|@json)")
else
 "#+TITLE: Physical interval, reader and benefit matrices (native projection)",
 "#+PROPERTY: header-args :eval never", "",
 "* Real caller and ownership matrix", ":PROPERTIES:", ":CUSTOM_ID: interval-caller-matrix", ":END:",
 "#+NAME: interval-callers-native", "| Family | Source anchors | Actual chain | Ownership contract | Failure boundary |", "|---+---+---+---+---|",
 (.intervalCallers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.ownership,.failure]|join(" | "))+" |"), "",
 "* Benefit and peak-memory matrix", ":PROPERTIES:", ":CUSTOM_ID: interval-benefit-matrix", ":END:",
 "#+NAME: interval-benefits-native", "| Capability | Removed work | Bound | Added cost | Positive condition and falsifier |", "|---+---+---+---+---|",
 (.intervalBenefits[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Model scopes and conjunctive dependencies",
 "#+NAME: interval-model-needs-native", "| Need | Kind | Subject | Exact scope | Premise |", "|---+---+---+---+---|",
 (.refinementNeeds[]|select(.obligationId|startswith("IH-"))|"| "+([.obligationId,.kind,.subjectPath,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: interval-model-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
 (.refinementDependencies[139:][]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |")
end
