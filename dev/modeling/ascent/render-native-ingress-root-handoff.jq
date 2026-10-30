# SysML native projection owns rows; this file only formats views.
if $view=="d2" then
 "direction: down",
 (.nodes[]|"n_\(.nodeId): { label: \(.labelText|@json) }"),
 (.diagramEdges[]|"n_\(.producer.nodeId) -> n_\(.consumer.nodeId): \((.labelText|split(" ")|. as $w|[range(0;($w|length);3) as $i|$w[$i:$i+3]|join(" ")]|join("\n"))|@json)")
else
 "#+TITLE: Modern C Native Ingress, Root Custody and Peak-Memory Matrix",
 "#+LANGUAGE: en", "#+PROPERTY: header-args :eval never", "#+OPTIONS: toc:2 num:nil", "",
 "* Native-evaluated illustrative root payload", "Payload equations only; not ABI size, measured allocation, mandatory extra roots or whole-round peak.",
 "| Shape | Inputs | Converted prefix | Depth | Word bytes | Slot payload bytes |", "|---+---+---+---+---+---|",
 (.rootPayload|to_entries[]|"| "+([.key,.value.inputs,.value.converted,.value.depth,.value.wordBytes,.value.payloadBytes]|map(tostring)|join(" | "))+" |"), "",
 "* Actual caller producers", "| Family | Source | Actual chain | Required change | Qualification |", "|---+---+---+---+---|",
 (.callers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Origin and custody transitions", "| Path | Source | Current behavior | New contract | Failure boundary | Custodian |", "|---+---+---+---+---+---|",
 (.allocators[]|"| "+([.pathId,.sourceAnchors,.actualPath,.contract,.failure,.custodian]|join(" | "))+" |"), "",
 "* C memory order", "| Edge | Required order | Rejected shortcut |", "|---+---+---|",
 (.orders[]|"| "+([.edgeId,.orderContract,.rejectedShortcut]|join(" | "))+" |"), "",
 "* Benefits and added overhead", "| Capability | Removed work | Bound | Added cost | Positive condition or falsifier |", "|---+---+---+---+---|",
 (.costs[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Obligations and closure", "| Need | Kind | Exact scope | Premise | Status |", "|---+---+---+---+---|",
 (.needs[]|.obligationId as $id|"| "+([.obligationId,.kind,.subjectScope,.premise,(if ($observation[0].qualifiedSlice|any(.[2]==$id)) then "Conditional local model checked" else "OPEN: source or C-memory refinement" end)]|join(" | "))+" |"), "",
 "* Refinement dependencies", "| Dependent | Prerequisite |", "|---+---|",
 (.dependencies[]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |"), "",
 "* Admission boundary", "Only NI-H and NI-I qualify locally. No current component is fully ready. No runtime implementation, native test or performance measurement. Imported open premises are not promoted."
end
