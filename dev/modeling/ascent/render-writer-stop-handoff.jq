# Presentation only. Native SysML owns every contract, cut, cost, implementation step and dependency.
def row: "| "+(map(tostring)|join(" | "))+" |";
if $view=="d2" then
 "direction: down", "vars: { d2-config: { theme-id: 0 } }",
 (.nodes[]|"n_\(.nodeId): { label: \(.labelText|@json) }"),
 (.diagramEdges[]|"n_\(.producer.nodeId) -> n_\(.consumer.nodeId): \((.labelText|split(" ")|. as $w|[range(0;($w|length);3) as $i|$w[$i:$i+3]|join(" ")]|join("\n"))|@json)")
elif $view=="plan" then
 "#+TITLE: Modern C Runtime Implementation Plan", "#+LANGUAGE: en", "#+OPTIONS: toc:3 num:nil", "#+PROPERTY: header-args :eval never", "#+TODO: PLANNED BLOCKED | ACCEPTED RETIRED", "",
 "* Scope and authority", ":PROPERTIES:", ":CUSTOM_ID: modern-c-implementation-plan", ":END:",
 "This action board is generated from the research checkout's dev/architecture/runtime/gc/models/sysml/writer-stop-handoff.sysml. It adds no separate runtime semantics. Branch: modern-c; source base: 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882. The existing vector.scm edit is outside this work.",
 "This turn delivered documentation and formal-model checks only. Runtime patches, native tests, commits and pushes have not been performed. A step being model-ready is not source/native acceptance. This is a connected first slice of the wider GC/SMP refactoring blueprint, not a reduction of that blueprint to an FFI patch.", "",
 "* Execution order and gates",
 (.implementation[]|"** "+(if (.status|startswith("BLOCKED")) then "BLOCKED" else "PLANNED" end)+" "+.stepId,
 ":PROPERTIES:",":CUSTOM_ID: "+(.stepId|ascii_downcase),":SOURCE_STATUS: "+.status,":FILES: "+.files,":END:",
 "*** Change",.change,"*** Dependencies",.dependencies,"*** Acceptance after runtime work is authorized",.acceptance,"*** Failure custody and withdrawal",.rollback,""),
 "* Machine-associated proof duties", "| Step | Required obligation |", "|---+---|",
 (.implementationNeeds[]|[.step.stepId,.need.obligationId]|row),"",
 "* First patch boundary", "MC-SCOPE is the first source edit: bounded resident control schema plus no-effect lifecycle operations. It cannot activate a raw marker or new GC path. MC-GENERATE through MC-THREAD form the connected ownership slice; MC-SELECT is the first behavior switch. MC-RETIRE follows complete caller and native evidence. No second Zig ownership implementation is required.",
 "Future acceptance must independently check exact-source generation, clean bootstrap, selected GCC/Darwin profiles, GC during marker allocation, nonzero processors, nested continuation/exception escape, failed/unknown join, helper interruption and shutdown draining. These are planned checks; none was run here."
else
 "#+TITLE: Writer Closure and Repeated Helper Handoff Matrix", "#+LANGUAGE: en", "#+OPTIONS: toc:3 num:nil", "#+PROPERTY: header-args :eval never", "",
 "* Native-evaluated cuts", "These are local predicates with external stop/root witnesses, not C/OS receipts.",
 "| Case | Can hand off | Can scan frozen source |", "|---+---+---|",
 (.closureCuts|to_entries[]|[.key,.value.canHelp,.value.canScanFrozen]|row),"",
 "* Actual source and changes", "| Family | Source | Current behavior | Required change | Admission boundary |", "|---+---+---+---+---|",
 (.callers[]|[.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|row),"",
 "* Exit paths and custody", "| Path | Source behavior | Issuance contract | Unknown boundary | Custodian |", "|---+---+---+---+---|",
 (.paths[]|[.pathId,.actualPath,.contract,.failure,.custodian]|row),"",
 "* Transition refinement", "| Need | From | To | QNT steps | Guard | Lean conditional law | Source |", "|---+---+---+---+---+---+---|",
 (.transitions[]|[.need.obligationId,.fromPhase,.toPhase,.qntStep,.guardContract,.leanLaw,.sourceAnchors]|row),"",
 "* C memory duties", "| Edge | Required order | Counterexample |", "|---+---+---|",
 (.orders[]|[.edgeId,.orderContract,.rejectedShortcut]|row),"",
 "* Benefits and peak support", "| Capability | Eliminated work if admitted | Quantified boundary | Added work or memory | Positive condition or falsifier |", "|---+---+---+---+---|",
 (.costs[]|[.capability,.removedWork,.bound,.addedCost,.condition]|row),"",
 "* Closure", "| Component | Need | Method class | Scope | Status |", "|---+---+---+---+---|",
 (.needs[]|.obligationId as $id|[.owner.componentId,$id,.kind,.subjectScope,(if ($observation[0].qualifiedSlice|any(.[2]==$id)) then "Conditional local model checked" else "OPEN: source/C refinement" end)]|row),"",
 "* Obligation dependencies", "| Dependent | Prerequisite |", "|---+---|",
 (.dependencies[]|[.dependent.obligationId,.prerequisite.obligationId]|row),"",
 "* Implementation proof gates", "| Step | Required need |", "|---+---|",
 (.implementationNeeds[]|[.step.stepId,.need.obligationId]|row),"",
 "* Research gates", "| Gate | Required need |", "|---+---|",
 (.gateNeeds[]|[.gate.gateId,.need.obligationId]|row),"",
 "* Evidence boundary", "Only WS-H/WS-I may receive local checked receipts. Source stop issuance, C-memory protocol, root adapter and native acceptance remain open. Synthetic all-scoped controls test routing only. Runtime paths retired: zero."
end
