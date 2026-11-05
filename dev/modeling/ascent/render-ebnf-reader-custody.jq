if $view == "parameters" then
 "// Native SysML projection. Synthetic admission is distinct from source admission.\nmodule ebnf_reader_parameters {\n  val ActualAdmitted = "+(.readerConfig.actualAdmitted|tostring)+
 "\n  val ConsumerCount = "+(.readerConfig.consumerCount|tostring)+
 "\n  val DepthLimit = "+(.readerConfig.depthLimit|tostring)+"\n}\n"
elif $view == "d2" then
 "direction: down\n# Capture and custody spine; no whole-program closure assertion.\n"+
 (.readerRegions|to_entries|map("r"+(.key|tostring)+": "+((.value.labelText+"\n"+.value.ownership)|tojson))|join("\n"))+"\n"+
 (.readerEdges|map("r"+(.producer|tostring)+" -> r"+(.consumer|tostring))|join("\n"))+"\n"
elif $view == "matrix" then
 "#+TITLE: EBNF Reader Sharing, Custody and Net Work\n#+SETUPFILE: ../../modeling/org/setup.org\n#+CATEGORY: toolchain\n\n* RESEARCH Native projection\n:PROPERTIES:\n:CUSTOM_ID: ebnf-reader-custody-matrix\n:AUTHORITY: EbnfReaderCustody\n:STATUS: source-refinement-open\n:END:\n\nDerived from [[file:models/sysml/ebnf-reader-custody.sysml][SysML]]; see [[file:ebnf-reader-custody-design.org][source and proof study]]. Candidates are not freeze receipts.\n\n| Region | Ownership | Source | Rule |\n|---+---+---+---|\n"+
 (.readerRegions|map("| "+([.key,.ownership,.anchor,.rule]|join(" | "))+" |")|join("\n"))+
 "\n\n** Admission gates\n\n| Gate | Qualified | Obligation |\n|---+---+---|\n"+
 (.readerGates|map("| "+([.key,(.qualified|tostring),.rule]|join(" | "))+" |")|join("\n"))+
 "\n\n** Work and added cost\n\n| Family | Avoided work boundary | Mechanism | Added cost / limit |\n|---+---+---+---|\n"+
 (.readerBenefits|map("| "+([.key,.removed,.mechanism,.added]|join(" | "))+" |")|join("\n"))+
 "\n\nActual reader admission: "+(.readerConfig.actualAdmitted|tostring)+". Existing module/grammar reuse is baseline. Net work must subtract ownership, identity, root retention and capability validation; independent-port parallel span is separate from work reduction.\n"
else error("unknown view") end
