# Native SysML owns edges and state inventory; no source readiness is inferred here.
if $view == "topology" then
 . as $m |
 "// Generated from GerbilSessionClosure SysML.\nmodule gerbil_session_topology {\n  val Nodes = Set(" +
 (.supports|map(.number|tostring)|join(", "))+")\n  val Roots = "+.supportRoots+
 "\n  val ObservedCensus = "+(.observedCensus|tostring)+"\n  pure def calls(n: int): Set[int] =\n" +
 (.supports|to_entries|map(.value as $n | "    "+(if .key==0 then "if" else "else if" end)+" (n == "+($n.number|tostring)+") Set("+
 ([$m.supportEdges[]|select(.kind=="exec" and .producer==$n.number)|.consumer|tostring]|join(", "))+")")|join("\n"))+
 "\n    else Set()\n  val Required = Nodes.fold(Roots, (found, _) =>\n    found.union(found.fold(Set(), (out, n) => out.union(calls(n)))))\n}\n"
elif $view == "d2" then
 . as $m |
 "direction: right\n# Execution-support catalogue, not a complete discovered source call graph.\n"+
 (.supports|map("n"+(.number|tostring)+": "+((.key+"\n"+.kind)|tojson)+
 (if .kind=="opaque" then "\nn"+(.number|tostring)+".style.stroke: red" else "" end))|join("\n"))+"\n"+
 (.supportEdges|map("n"+(.producer|tostring)+" -> n"+(.consumer|tostring)+": "+.kind+
 (if .kind=="emit" then " {style.stroke-dash: 4}" else "" end))|join("\n"))+"\n"
elif $view == "matrix" then
 "#+TITLE: Gerbil Execution Support and Session Ownership Matrix\n#+SETUPFILE: ../../modeling/org/setup.org\n#+CATEGORY: toolchain\n\n* RESEARCH Native model projection\n:PROPERTIES:\n:CUSTOM_ID: session-closure-matrix\n:AUTHORITY: GerbilSessionClosure\n:STATUS: source-census-and-state-isolation-open\n:END:\n\nDerived from [[file:models/sysml/gerbil-session-closure.sysml][SysML]]; [[file:gerbil-session-closure-design.org][source and formal explanation]].\n\n** Support catalogue\n\n| Group | Class | Source anchor | Work | Boundary |\n|---+---+---+---+---|\n"+
 (.supports|map("| "+([.key,.kind,.sourceAnchor,.work,.limit]|join(" | "))+" |")|join("\n"))+
 "\n\n** State ownership, actual reuse and retirement costs\n\n| Domain | Source anchor | Current state | Target ownership | Benefit and cost boundary |\n|---+---+---+---+---|\n"+
 (.domains|map("| "+([.key,.sourceAnchor,.stateText,.ownership,.benefit]|join(" | "))+" |")|join("\n"))+
 "\n\n** Source-specific reuse candidates\n\n| Candidate | Source | Removed work | Positive condition | Added cost or counterexample |\n|---+---+---+---+---|\n"+
 (.opportunities|map("| "+([.key,.sourceAnchor,.candidate,.condition,.cost]|join(" | "))+" |")|join("\n"))+
 "\n\n** Net work rule\n\n"+.sessionWorkRule+"\n\nObserved source census complete: "+(.observedCensus|tostring)+".\nNo whole-source or runtime admission is asserted.\n"
else error("unknown view") end
