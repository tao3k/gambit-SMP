# No admission policy: lossless native model presentation only.
def predecessors: [.predecessors | scan("[0-9]+") | tonumber];
if $view == "topology" then
 "// Generated from GerbilPhaseReadiness SysML; do not edit graph here.\nmodule gerbil_phase_topology {\n  val Nodes = Set(" +
 (.actions|map(.number|tostring)|join(", ")) + ")\n  pure def deps(n: int): Set[int] =\n" +
 (.actions|to_entries|map("    "+(if .key==0 then "if" else "else if" end)+" (n == "+(.value.number|tostring)+") "+.value.predecessors)|join("\n")) + "\n    else Set()\n}"
elif $view == "d2" then
 .actions as $a |
 "direction: right\n# Selected action families; runtimeOnly may be empty; link is a proposed combined request.\n" +
 ($a|map("node_"+.key+": "+((.labelText+"\nfamily "+(.number|tostring))|tojson))|join("\n")) + "\n" +
 ($a|map(. as $n | predecessors[] as $d | $a[]|select(.number==$d)|"node_"+.key+" -> node_"+$n.key)|join("\n")) +
 "\nnode_runtimeOnly.style.stroke-dash: 4\nnode_link.style.stroke-dash: 4\n"
elif $view == "matrix" then
 "#+TITLE: Gerbil Macro Chain Readiness, Benefits and Mechanism Learning\n#+SETUPFILE: ../../modeling/org/setup.org\n#+CATEGORY: toolchain\n\n* RESEARCH Native SysML projection\n:PROPERTIES:\n:CUSTOM_ID: gerbil-macro-matrix\n:AUTHORITY: GerbilPhaseReadiness\n:STATUS: conditional-models-source-refinement-open\n:END:\n\nDerived from [[file:models/sysml/gerbil-phase-readiness.sysml][SysML]]; see [[file:gerbil-macro-chain-design.org][the source and proof study]].\nCounts below denote model action families, never measured compiler commands.\n\n** Action families\n\n| Family | Product | Prerequisites | Source anchor | Contract |\n|---+---+---+---+---|\n" +
 (.actions|map("| "+([(.number|tostring),.labelText,.predecessors,.sourceAnchor,.contract]|join(" | "))+" |")|join("\n")) +
 "\n\n** Benefits, overhead and retirement\n\n" + .benefitRule +
 "\n\n| Case | Condition | Work boundary | Added cost | Retirement gate |\n|---+---+---+---+---|\n" +
 (.benefits|map("| "+([.caseId,.condition,.workBoundary,.overhead,.retirement]|join(" | "))+" |")|join("\n")) +
 "\n\n** Mechanism learning and Gambit/Gerbil reflection\n\n| Mechanism | Primary evidence | Reflection | Open duty |\n|---+---+---+---|\n" +
 (.learning|map("| "+([.mechanism,("[["+.primarySource+"]["+.evidence+"]]"),.reflection,.sourceDuty.obligationId]|join(" | "))+" |")|join("\n")) + "\n"
else error("unknown presentation") end
