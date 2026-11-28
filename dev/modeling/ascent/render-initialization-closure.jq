if $view == "parameters" then
 "// Generated from GerbilInitializationClosure SysML; no source qualification implied.\nmodule initialization_parameters {\n  val GateCount = "+(.initConfig.gateCount|tostring)+
 "\n  val ConsumerCount = "+(.initConfig.consumerCount|tostring)+
 "\n  val ObservedClosure = "+(.initConfig.observedClosure|tostring)+
 "\n  val NodeCount = "+(.initNodes|length|tostring)+
 "\n  val ReaderBody = "+(.initNodes|map(.key)|index("readerBody")|tostring)+
 "\n  val CallerDeps = Map("+(. as $p|[range(0;(.initNodes|length)) as $n|($n|tostring)+" -> Set("+([$p.initEdges[]|select(.producer==$n)|.consumer|tostring]|join(", "))+")"]|join(", "))+")\n}\n"
elif $view == "d2" then
 "direction: right\n# Concrete caller spine; opaque/capture edges remain open.\n"+
 (.initNodes|to_entries|map("n"+(.key|tostring)+": "+((.value.key+"\n"+.value.kind)|tojson))|join("\n"))+"\n"+
 (.initEdges|map("n"+(.producer|tostring)+" -> n"+(.consumer|tostring))|join("\n"))+"\n"
elif $view == "matrix" then
 "#+TITLE: Initialization Closure, Freeze Gates and Net Work\n#+SETUPFILE: ../../modeling/org/setup.org\n#+CATEGORY: toolchain\n\n* RESEARCH Native projection\n:PROPERTIES:\n:CUSTOM_ID: initialization-closure-matrix\n:AUTHORITY: GerbilInitializationClosure\n:STATUS: source-closure-open\n:END:\n\nDerived from [[file:models/sysml/initialization-closure.sysml][SysML]]; see [[file:initialization-closure-design.org][the source and model study]].\n\n| Node | Class | Source | Obligation |\n|---+---+---+---|\n"+
 (.initNodes|map("| "+([.key,.kind,.anchor,.rule]|join(" | "))+" |")|join("\n"))+
 "\n\n** Freeze gates\n\n| Gate | Qualified | Requirement |\n|---+---+---|\n"+
 (.initGates|map("| "+([.key,(.qualified|tostring),.rule]|join(" | "))+" |")|join("\n"))+
 "\n\n** Work and cost boundaries\n\n| Family | Potential removed work | Mechanism | Added work / boundary |\n|---+---+---+---|\n"+
 (.initBenefits|map("| "+([.key,.removed,.mechanism,.added]|join(" | "))+" |")|join("\n"))+
 "\n\nObserved source closure: "+(.initConfig.observedClosure|tostring)+".\nNet work requires actual avoided baseline repetitions to exceed validation, maps, overlays, owner handoff and pin/drain; necessary stateful initialization is retained. Parallel span is a separate quantity.\n"
else error("unknown view") end
