# Presentation only: all obligations, transitions, source rows, costs and topology come from native SysML.
if $view=="d2" then
 "direction: down", "vars: { d2-config: { theme-id: 0 } }",
 (.nodes[]|"n_\(.nodeId): { label: \(.labelText|@json) }"),
 (.diagramEdges[]|"n_\(.producer.nodeId) -> n_\(.consumer.nodeId): \((.labelText|split(" ")|. as $w|[range(0;($w|length);3) as $i|$w[$i:$i+3]|join(" ")]|join("\n"))|@json)")
else
 "#+TITLE: Modern C Thread Thunk and Native Activation Closure Matrix", "#+LANGUAGE: en", "#+PROPERTY: header-args :eval never", "#+OPTIONS: toc:2 num:nil", "",
 "* Root value slot arithmetic", "Only value slots of two safe candidate layouts are compared. This is neither the current unregistered-carrier baseline nor a whole-runtime memory result.",
 "| Shape | Workers | Word bytes | Duplicate slot bytes | Shared slot bytes | Slot saving bytes |", "|---+---+---+---+---+---|",
 (.rootPayload|to_entries[]|"| "+([.key,.value.workers,.value.wordBytes,.value.oldSlotsBytes,.value.sharedSlotBytes,.value.slotSavingBytes]|map(tostring)|join(" | "))+" |"), "",
 "* Creation and exit transitions", "| Need | From | To | QNT action | Guard and custody | Conditional Lean law | Source |", "|---+---+---+---+---+---+---|",
 (.transitions[]|"| "+([.need.obligationId,.fromPhase,.toPhase,.qntStep,.guardContract,.leanLaw,.sourceAnchors]|join(" | "))+" |"), "",
 "* Source routes", "| Need | Source | Refinement duty | Failure custodian | Status |", "|---+---+---+---+---|",
 (.sourceRoutes[]|"| "+([.need.obligationId,.sourceAnchors,.projection,.failureCustodian,.status]|join(" | "))+" |"), "",
 "* Actual producers and run callers", "| Family | Source | Actual chain | Change | Admission |", "|---+---+---+---+---|",
 (.callers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Custody paths", "| Path | Source | Current | Required | Failure | Custodian |", "|---+---+---+---+---+---|",
 (.allocators[]|"| "+([.pathId,.sourceAnchors,.actualPath,.contract,.failure,.custodian]|join(" | "))+" |"), "",
 "* C memory order", "| Edge | Required order | Rejected shortcut |", "|---+---+---|",
 (.orders[]|"| "+([.edgeId,.orderContract,.rejectedShortcut]|join(" | "))+" |"), "",
 "* Benefit and peak matrix", "| Capability | Removed work | Quantified boundary | Added support | Positive condition or falsifier |", "|---+---+---+---+---|",
 (.costs[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Closure matrix", "| Need | Kind | Exact scope | Premise | Status |", "|---+---+---+---+---|",
 (.needs[]|.obligationId as $id|"| "+([.obligationId,.kind,.subjectScope,.premise,(if ($observation[0].qualifiedSlice|any(.[2]==$id)) then "Conditional local model checked" else "OPEN: source or C memory refinement" end)]|join(" | "))+" |"), "",
 "* Dependencies", "| Dependent | Prerequisite |", "|---+---|",
 (.dependencies[]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |"), "",
 "* Evidence boundary", "Only TA-H and TA-I qualify locally. No complete component is admitted. The all-scoped ASCENT case is a synthetic policy control, not source evidence. No runtime implementation, native test, retired runtime path or measured speedup."
end
