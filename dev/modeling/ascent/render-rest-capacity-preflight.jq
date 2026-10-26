# Presentation only: topology, obligations, costs and callers come from SysML.
if $view=="d2" then
 "direction: down",
 (.nodes[]|.labelText|=gsub("\\\\n";"\n")|"n_\(.nodeId): { label: \(.labelText|@json) }"),
 (.diagramEdges[]|"n_\(.producer.nodeId) -> n_\(.consumer.nodeId): \((.labelText|split(" ") | . as $w | [range(0; ($w|length); 4) as $i | $w[$i:$i+4] | join(" ")] | join("\n"))|@json)")
else
 "#+TITLE: Rest Capacity Preflight, Caller Cuts and Peak-Memory Matrix", "#+PROPERTY: header-args :eval never", "",
 "* Execution scope", "Repository Evidence/ASCENT queries completed for the exact selected source bundle; source and C-memory obligations remain open. No runtime admission.", "", "* Inherited native layout arithmetic", "These are aligned-wrapper requests, not backend pages, usable size or RSS.", "| Word bytes | Candidate subtype | SCMOBJ slots | Raw key bytes | Body bytes | Object bytes | Wrapper request | Delta from SMP |", "|---+---+---+---+---+---+---+---|",
 (.layouts[]|"| "+([.wordBytes,.subtypeCandidate,.rootWords,.keyBytes,.bodyBytes,.objectBytes,.allocatorRequest,.deltaFromSmp]|map(tostring)|join(" | "))+" |"), "",
 "* Inherited post-CONS repair examples", "Arithmetic only; actual physical reservation and current-host generated frame/ABI admission remain open.", "| Profile | Actual args | Formal count | Remaining after first CONS | Pair words | Vector words | Repair words | Repair bytes |", "|---+---+---+---+---+---+---+---|",
 (.repairBounds|to_entries[]|"| "+([.key,.value.actual,.value.formal,.value.remaining,.value.pairWords,.value.vectorWords,.value.completionWords,.value.completionBytes]|map(tostring)|join(" | "))+" |"), "",
 "* Native-evaluated caller preflight budget", "This covers the first CONS; it is not native allocator/FrameSpec admission.", "| Profile | Actual | Formal | Rest pairs | Caller words | Caller bytes | Extra versus post-CONS |", "|---+---+---+---+---+---+---|",
 (.preflightBounds|to_entries[]|"| "+([.key,.value.actual,.value.formal,.value.pairs,.value.callerWords,.value.callerBytes,.value.extraVsPostCons]|map(tostring)|join(" | "))+" |"), "",
 "* Fresh separate heap-section geometry", "Payload arithmetic only; excludes allocator headers, existing objects, stack demand and actual allocation success/RSS.", "| Profile | Full section words | Half words | Data words | Max rest no handles | Max rest handles | Section payload bytes |", "|---+---+---+---+---+---+---|",
 (.freshGeometry|to_entries[]|"| "+([.key,.value.sectionWords,.value.halfWords,.value.usableWords,.value.noHandlesMax,.value.handlesMax,.value.sectionPayloadBytes]|map(tostring)|join(" | "))+" |"), "",
 "* Source caller matrix", "#+NAME: root-callers-native", "| Family | Source | Actual chain | Hazard | Replacement |", "|---+---+---+---+---|",
 (.callers[]|"| "+([.callerId,.sourceAnchors,.actualChain,.hazard,.replacement]|join(" | "))+" |"), "",
 "* Benefit and peak-memory matrix", "#+NAME: root-costs-native", "| Capability | Removed work | Quantified bound | Added cost | Condition or falsifier |", "|---+---+---+---+---|",
 (.capacityCosts[]|"| "+([.capability,.removedWork,.bound,.addedCost,.condition]|join(" | "))+" |"), "",
 "* Obligations and imported open premises", "#+NAME: root-needs-native", "| Need | Kind | Exact scope | Premise |", "|---+---+---+---|",
 (.needs[]|"| "+([.obligationId,.kind,.subjectScope,.premise]|join(" | "))+" |"), "",
 "#+NAME: root-dependencies-native", "| Dependent | Prerequisite |", "|---+---|",
(.dependencies[]|"| \(.dependent.obligationId) | \(.prerequisite.obligationId) |"), "",
 "* Scoped closure observations", "#+NAME: root-closure-observed", "| Need | Current evidence | Source/runtime boundary |", "|---+---+---|",
 (.needs[]|.obligationId as $id | "| "+$id+" | "+(if ($observation[0].qualifiedSlice|any(.[];.[2]==$id)) then "Checked task-local formal slice" else "Unresolved source or native-order obligation" end)+" | "+(if ($id=="CP-H" or $id=="CP-I") then "Conditional model only; no C simulation" elif $id=="CP-ORDER" then "No C-memory/platform refinement root" else "No source-simulation root" end)+" |")
end
