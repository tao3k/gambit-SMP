if $kind=="matrix" then
 "#+TITLE: Modern C Frame Consumers: Benefit and Cost\n#+LANGUAGE: en\n#+PROPERTY: header-args :eval never\n\n* Native SysML projection\n\n[[file:frame-consumers.org][Source changes, bootstrap evidence and limits]].\n\n| Cut | Source route | Retired responsibility | Benefit | Added cost / limit |\n|---+---+---+---+---|",
 (.rows[]|"| \(.label) | \(.sourceRoute) | \(.retirement) | \(.benefit) | \(.addedCost) |"),
 "\n* Relation to the new architecture\n\nThis cut realizes a frame/root sub-contract. Inherited fixes are validation baseline, not modernization benefit. Source divergence alone proves neither replacement nor failure.\n\n| Cut | Existing architecture decision | Required replacement | Old responsibility to retire | Whole obligation |\n|---+---+---+---+---|",
 (.rows[]|"| \(.componentId) | \(.target.decisionId) | \(.target.replacement) | \(.target.retirement) | \(.target.obligation) |"),
 "\n* Scoped obligations\n\n| Obligation | Method | Scope | Premise / limit |\n|---+---+---+---|",
 (.needs[]|"| \(.obligation) | \(.method) | \(.scope) | \(.premise) |"),
 "\n* Component obligations\n\n| Component | Obligation |\n|---+---|",(.uses[]|"| \(.component) | \(.need) |")
elif $kind=="d2" then
 "direction: down\nvars: { d2-config: { layout-engine: elk } }",
 (.rows[]|"\(.componentId): { label: \((.label+"\n"+.owner.moduleId)|tojson) }"),
 (.edges[]|"\(.from) -> \(.to): \(.label|tojson)"),
 "baseline: { label: \"Bazel profile + retained SMP failures\\nValidation constraints; no inherited 8/12\"; style.fill: \"#e7efff\" }",
 "target: { label: \"Existing whole-runtime architecture\\nNew owners + old-owner retirement\\nNot cumulative patch copying\"; style.fill: \"#e5f6e9\" }",
 "baseline -> target: \"legal behavior and counterexamples\"",
 "target -> build: \"realize and qualify the new contract\"",
 "proof: { label: \"SysML -> shared ASCENT DSL\\nQNT stream / Lean prefix laws\\nexact artifact + digest + scope\" }",
 "open: { label: \"Whole GC / FFI / scheduler refinement OPEN\\nNo general SMP acceptance\"; style.fill: \"#fff0c2\" }",
 "roots -> proof: \"finite and universal slices\"",
 "proof -> open: \"no scope widening\""
else error("unknown projection") end
