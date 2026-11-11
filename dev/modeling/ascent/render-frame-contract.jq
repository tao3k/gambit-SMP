# Structure comes from native SysML evaluation. No independent component map.
if $kind=="matrix" then
 "#+TITLE: Implemented Frame Contract: Retirement and Cost\n#+LANGUAGE: en\n#+PROPERTY: header-args :eval never\n\n* SysML projection\n\n[[file:frame-contract-realization.org][Code, native evidence and remaining cohort obligations]].\n\n| Cut | Real source route | Retired responsibility | Benefit | Added cost / boundary |\n|---+---+---+---+---|",
 (.rows[]|"| \(.label) | \(.sourceRoute) | \(.retirement) | \(.benefit) | \(.addedCost) |"),
 "\n* Exact proof scopes\n\n| Obligation | Method | Scope | Claim boundary |\n|---+---+---+---|",
 (.needs[]|"| \(.obligation) | \(.method) | \(.scope) | \(.premise) |"),
 "\n* Component use\n\n| Component | Obligation |\n|---+---|",
 (.uses[]|"| \(.component) | \(.need) |")
elif $kind=="d2" then
 "direction: down\nvars: { d2-config: { layout-engine: elk } }",
 (.rows[]|"\(.componentId): { label: \((.label+"\n"+.owner.moduleId)|tojson) }"),
 (.edges[]|"\(.from) -> \(.to): \(.label|tojson)"),
 "sysml: { label: \"Native SysML -> shared ASCENT DSL\" }",
 "proof: { label: \"QNT arithmetic + Lean packing laws\" }",
 "open: { label: \"Whole compiler/runtime bootstrap\\nGenerational GC / scheduler / FFI closure OPEN\"; style.fill: \"#fff0c2\" }",
 "sysml -> proof: \"exact artifact / digest / method / scope\"",
 "proof -> open: \"cannot widen a checked slice\"",
 "producer -> sysml: \"source binding\"",
 "consumer -> sysml: \"configured\\nnative controls\""
else error("unknown kind") end
