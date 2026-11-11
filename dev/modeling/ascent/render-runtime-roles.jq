if $kind=="matrix" then
 "#+TITLE: Modern C Runtime Roles: Replacement and Cost\n#+LANGUAGE: en\n#+PROPERTY: header-args :eval never\n\n* Native SysML projection\n\n[[file:runtime-role-realization.org][Source, evidence and boundaries]]. This is a synchronous source realization, not admission of independent GC carriers. Reference repair patches are not imported.\n\n| Role | Real source path | Retired responsibility | Benefit | Added cost / remaining boundary |\n|---+---+---+---+---|",
 (.rows[]|"| \(.label) | \(.sourceRoute) | \(.retirement) | \(.benefit) | \(.addedCost) |"),
 "\n* Proof and native scope\n\n| Obligation | Method | Exact scope | Premises / limit |\n|---+---+---+---|",
 (.needs[]|"| \(.obligation) | \(.method) | \(.scope) | \(.premise) |"),
 "\n* Component dependencies\n\n| Component | Required obligation |\n|---+---|",(.uses[]|"| \(.component) | \(.need) |")
elif $kind=="d2" then
 "direction: down\nvars: { d2-config: { layout-engine: elk } }",
 (.rows[]|"\(.componentId): { label: \((.label+"\n"+.owner.moduleId)|tojson) }"),
 (.edges[]|"\(.from) -> \(.to): \(.label|tojson)"),
 "reference: { label: \"Bazel configuration + SMP failures\\nReference constraints; no patch imports\"; style.fill: \"#e7efff\" }",
 "proof: { label: \"SysML -> ASCENT\\nQNT phase histories / Lean root and receipt laws\" }",
 "open: { label: \"Source-generated cohort / whole C refinement\\nIndependent carriers / native lifetime OPEN\"; style.fill: \"#fff0c2\" }",
 "reference -> participant: \"behavioral constraints\"",
 "participant -> proof: \"scope + artifact digest\"",
 "proof -> open: \"no promotion from local controls\""
else error("unknown projection") end
