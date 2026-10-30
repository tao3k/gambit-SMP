# Input is evaluated native SysML, never an independently authored component map.
if $kind=="matrix" then
  "#+TITLE: Map Multishot Joint Architecture Matrix\n#+LANGUAGE: en\n#+PROPERTY: header-args :eval never\n\n* Native SysML projection\n:PROPERTIES:\n:AUTHORITY: GambitMapMultishot\n:STATUS: DESIGN; NOT-NATIVE-ADMITTED\n:END:\n\nGenerated from models/sysml/map-multishot-composition.sysml by native evaluation.\nSee [[file:map-multishot-composition.org][the witness, equations and evidence limits]].\n\n| Boundary | Contract | Replacement and retirement | Work removed | Added cost | Admission premise |\n|---+---+---+---+---+---|",
  (.rows[]|"| \(.componentId) (\(.owner.moduleId)) | \(.contract) | \(.replacement); RETIRE: \(.retirement) | \(.benefit) | \(.addedCost) | \(.premise) |"),
  "\n* Exact proof scopes\n\n| Obligation | Method | Scope | Premise / still open beyond checked slice |\n|---+---+---+---|",
  (.needs[]|"| \(.obligation) | \(.method) | \(.scope) | \(.premise) |"),
  "\n* Component to obligation use\n\n| Component | Obligation |\n|---+---|",
  (.uses[]|"| \(.component) | \(.need) |")
elif $kind=="d2" then
  "direction: down\nvars: { d2-config: { layout-engine: elk } }\n",
  (.rows[]|"\(.componentId): { label: \((.label+"\n"+(.contract|split(" + ")|join("\n")))|tojson) }"),
  (.edges[]|"\(.from) -> \(.to): \(.contract|tojson)"),
  "proof: { label: \"SysML -> ASCENT -> QNT / Lean\\nFinite custody checked; source simulation OPEN\"; style.fill: \"#fff0c2\" }",
  "control -> proof: \"multiple shots / no heap rollback\"",
  "heap -> proof: \"barrier closure / relocation\"",
  "foreign -> proof: \"roots / unwind / outcome lifetime\""
else error("unknown projection kind") end
