. as $p | if $view == "parameters" then
 def qlist: "List("+(explode|map(tostring)|join(", "))+")";
 "// Native SysML cases; this is a finite selected reader relation, not Gambit execution.\nmodule ebnf_cursor_parameters {\n  val SourceWitnessDerived = "+(.cursorConfig.sourceWitnessDerived|tostring)+
 "\n  val ActualAdapterAdmitted = "+(.cursorConfig.actualAdapterAdmitted|tostring)+
 "\n  val CaseCount = "+(.cursorCases|length|tostring)+"\n"+
 (["lexerKind","legacyDatum","coherentDatum"]|map(. as $a|"  val "+$a+" = Map("+($p.cursorCases|to_entries|map((.key|tostring)+" -> "+(.value[$a]|tostring))|join(", "))+")")|join("\n"))+"\n"+
 (["prefix","suffix"]|map(. as $a|"  val "+$a+" = Map("+($p.cursorCases|to_entries|map((.key|tostring)+" -> "+(.value[$a]|qlist))|join(", "))+")")|join("\n"))+"\n}\n"
elif $view == "d2" then
 "direction: down\n# Protocol/observation ownership; full native adaptation remains open.\n"+
 (.cursorNodes|to_entries|map("n"+(.key|tostring)+": "+((.value.key+"\n"+.value.ownership)|tojson))|join("\n"))+"\n"+
 (.cursorEdges|map("n"+(.producer|tostring)+" -> n"+(.consumer|tostring))|join("\n"))+"\n"
elif $view == "matrix" then
 "#+TITLE: Cursor Handoff Witnesses, Contracts and Net Work\n#+SETUPFILE: ../../modeling/org/setup.org\n#+CATEGORY: toolchain\n\n* RESEARCH Native projection\n:PROPERTIES:\n:CUSTOM_ID: ebnf-cursor-handoff-matrix\n:AUTHORITY: EbnfCursorHandoff\n:STATUS: source-and-conditional-models\n:END:\n\nDerived from [[file:models/sysml/ebnf-cursor-handoff.sysml][SysML]]; see [[file:ebnf-cursor-handoff-design.org][source derivation and limits]].\n\n| Case | Prefix / suffix | Legacy / coherent datum code | Scope | Reason |\n|---+---+---+---+---|\n"+
 (.cursorCases|map("| "+([.key,((.prefix|tojson)+" / "+(.suffix|tojson)),((.legacyDatum|tostring)+" / "+(.coherentDatum|tostring)),.scope,.reasoning]|join(" | "))+" |")|join("\n"))+
 "\n\n** Handoff and custody\n\n| Node | Class | Source | Rule |\n|---+---+---+---|\n"+
 (.cursorNodes|map("| "+([.key,.ownership,.anchor,.rule]|join(" | "))+" |")|join("\n"))+
 "\n\n** Qualification\n\n| Gate | Qualified | Obligation |\n|---+---+---|\n"+
 (.cursorGates|map("| "+([.key,(.qualified|tostring),.rule]|join(" | "))+" |")|join("\n"))+
 "\n\n** Net work\n\n| Family | Potential removed work | Mechanism | Added cost / limit |\n|---+---+---+---|\n"+
 (.cursorBenefits|map("| "+([.key,.removed,.mechanism,.added]|join(" | "))+" |")|join("\n"))+
 "\n\nSource witness derived: "+(.cursorConfig.sourceWitnessDerived|tostring)+"; native reproduced: "+(.cursorConfig.nativeWitnessReproduced|tostring)+"; actual adapter admitted: "+(.cursorConfig.actualAdapterAdmitted|tostring)+".\nDatum codes: -1 not an ACTION boundary, 0 EOF, 1 (T 42), 2 (quote (T 42)), 3 symbol T, 4 symbol value, 5 (quote value). Equal datum codes do not prove complete source equivalence.\n"
else error("unknown view") end
