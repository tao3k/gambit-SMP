# Presentation only: topology and matrix rows come from native SysML values.
if $view=="d2" then
 "direction: down",
 (.promotionNodes[]|"\(.nodeId): { label: \(.labelText|@json) }"),
 (.promotionEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \(.labelText|@json)")
else
 "#+TITLE: Promotion bounds and residual epoch matrices (native projection)",
 "#+PROPERTY: header-args :eval never", "",
 "* Capacity source matrix", ":PROPERTIES:", ":CUSTOM_ID: promotion-capacity-matrix", ":END:",
 "#+NAME: promotion-capacity-native", "| Source | Anchors | Bound | Layout fact | Hazard | Replacement |", "|---+---+---+---+---+---|",
 (.capacitySources[]|"| "+([.sourceId,.sourceAnchors,.bound,.layoutFact,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Benefit and added cost matrix", ":PROPERTIES:", ":CUSTOM_ID: promotion-benefit-matrix", ":END:",
 "#+NAME: promotion-benefit-native", "| Capability | Removed work | Quantified bound | Added work or space | Condition and falsifier |", "|---+---+---+---+---|",
 (.promotionBenefits[]|"| "+([.capability,.removedWork,.bound,.addedWork,.condition]|join(" | "))+" |"), "",
 "* Model routes and conjunctive dependencies",
 "#+NAME: promotion-needs-native", "| Need | Method kind | Exact subject | Exact scope | Premise |", "|---+---+---+---+---|",
 (.refinementNeeds[]|select(.obligationId|startswith("PR-"))|"| "+([.obligationId,.kind,.subjectPath,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: promotion-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
 (.refinementDependencies[119:][]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |")
end
