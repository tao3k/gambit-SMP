def row: "| "+(map(tostring)|join(" | "))+" |";
if $view=="d2" then
 "direction: down", "vars: { d2-config: { theme-id: 0 } }",
 (.nodes[]|"n_\(.nodeId): { label: \(.labelText|@json) }"),
 (.diagramEdges[]|"n_\(.producer.nodeId) -> n_\(.consumer.nodeId): \((.labelText|split(" ")|. as $w|[range(0;($w|length);3) as $i|$w[$i:$i+3]|join(" ")]|join("\n"))|@json)")
else
 "#+TITLE: MC-SCOPE Source, Benefit and Patched SMP Milestone Matrix", "#+LANGUAGE: en", "#+OPTIONS: toc:3 num:nil", "#+PROPERTY: header-args :eval never", "",
 "* Fixed support budget", "| Profile | Word bytes | VM slots | Actor bits | Role bits per class combined | Owner roles | Generation bits | Maximum generation | VM record bytes |", "|---+---+---+---+---+---+---+---+---|",
 (.layout|to_entries[]|[.key,.value.wordBytes,.value.capacity,.value.actorBits,.value.roleCount,.value.ownerRoles,.value.generationBits,.value.maxGeneration,.value.vmBytes]|row),"",
 "* Packed word contract", "| Field | Encoding | Contract |", "|---+---+---|",
 (.fields[]|[.fieldId,.encoding,.contract]|row),"",
 "* Actual source / future consumer distinction", "| Family | Source | Existing behavior | Change | Boundary |", "|---+---+---+---+---|",
 (.callers[]|[.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|row),"",
 "* Atomic protocol", "| Edge | Required order | Rejected shortcut / cost |", "|---+---+---|",
 (.orders[]|[.edgeId,.orderContract,.rejectedShortcut]|row),"",
 "* Refinement", "| Need | From | To | QNT | Guard | Conditional Lean law | C source |", "|---+---+---+---+---+---+---|",
 (.transitions[]|[.need.obligationId,.fromPhase,.toPhase,.qntStep,.guardContract,.leanLaw,.sourceAnchors]|row),"",
 "* Four remaining 8/12 contracts", "| Need | Gate | Retained evidence | Required architectural replacement | Retirement / acceptance condition | Why MC-SCOPE is insufficient |", "|---+---+---+---+---+---|",
 (.milestones[]|[.need.obligationId,.milestoneId,.currentEvidence,.replacement,.retirement,.boundary]|row),"",
 "* Benefit and peak matrix", "| Capability | Mechanism | Quantified boundary | Added work / memory | Falsifier or limit |", "|---+---+---+---+---|",
 (.costs[]|[.capability,.removedWork,.bound,.addedCost,.condition]|row),"",
 "* Closure", "| Component | Need | Kind | Scope | Status |", "|---+---+---+---+---|",
 (.needs[]|.obligationId as $id|[.owner.componentId,$id,.kind,.subjectScope,(if ($observation[0].qualifiedSlice|any(.[2]==$id)) then "Conditional local model checked" else "OPEN: source/C/native qualification" end)]|row),"",
 "* Dependencies", "| Dependent | Prerequisite |", "|---+---|",
 (.dependencies[]|[.dependent.obligationId,.prerequisite.obligationId]|row),"",
 "* Research gates", "| Gate | Need |", "|---+---|",
 (.gateNeeds[]|[.gate.gateId,.need.obligationId]|row),"",
 "* Boundary", "Only NS-H and NS-I qualify locally. The actual source primitive is committed; code-compilation evidence is separate from assurance. No generated activation/GC consumer is switched, native controls are not executed, no old path retires, and the retained qualification stays 8/12."
end
