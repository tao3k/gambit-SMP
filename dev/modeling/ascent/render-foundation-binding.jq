if $view == "parameters" then
 "// Generated from GerbilFoundationIdentity SysML; abstract model identities.\nmodule foundation_binding_parameters {\n  val Definition = "+(.foundation.definitionContext|tostring)+
 "\n  val Consumer = "+(.foundation.consumerContext|tostring)+
 "\n  val Alternate = "+(.foundation.alternateContext|tostring)+
 "\n  val SourceClosed = "+(.foundation.sourceFoundationClosed|tostring)+"\n}\n"
elif $view == "d2" then
 "direction: right\n# Ownership/reconstruction dependencies, not an exhaustive import graph.\n"+
 (.foundationRegions|to_entries|map("r"+(.key|tostring)+": "+((.value.labelText+"\n"+.value.ownership)|tojson))|join("\n"))+"\n"+
 (.foundationEdges|map("r"+(.producer|tostring)+" -> r"+(.consumer|tostring))|join("\n"))+"\n"
elif $view == "matrix" then
 "#+TITLE: Foundation Sharing, Reconstruction and Net Work Matrix\n#+SETUPFILE: ../../modeling/org/setup.org\n#+CATEGORY: toolchain\n\n* RESEARCH Native model projection\n:PROPERTIES:\n:CUSTOM_ID: foundation-binding-matrix\n:AUTHORITY: GerbilFoundationIdentity\n:STATUS: source-refinement-open\n:END:\n\nDerived from [[file:models/sysml/foundation-binding.sysml][SysML]]; see [[file:foundation-binding-design.org][the source and proof study]].\nClasses identify target obligations, not existing freeze certificates.\n\n| Region | Owner class | Source | Reconstruction/share rule |\n|---+---+---+---|\n"+
 (.foundationRegions|map("| "+([.key,.ownership,.sourceAnchor,.rule]|join(" | "))+" |")|join("\n"))+
 "\n\n** Actual baseline and conditional net work\n\n| Work family | Current baseline | Removed work boundary | Added cost or counterexample |\n|---+---+---+---|\n"+
 (.foundationNet|map("| "+([.key,.baseline,.avoided,.added]|join(" | "))+" |")|join("\n"))+
 "\n\n** Net work rule\n\n"+.foundation.workRule+"\n\nActual source foundation closure: "+(.foundation.sourceFoundationClosed|tostring)+".\n"
else error("unknown view") end
