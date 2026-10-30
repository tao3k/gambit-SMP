if $kind=="matrix" then
 "#+TITLE: Bootstrap Cohort: Boundaries, Work and Proof Frontier\n#+LANGUAGE: en\n#+PROPERTY: header-args :eval never\n\n* Native SysML projection\n\n[[file:bootstrap-cohort.org][Native attempts and interpretation]].\n\n| Boundary | Actual route | Required invariant | Work / capability enabled | Added cost / premise |\n|---+---+---+---+---|",
 (.boundaries[]|"| \(.id) | \(.route) | \(.invariant) | \(.benefit) | \(.cost) |"),
 "\n* Model and evidence obligations\n\n| Component | Obligation | Method | Artifact | Scope / unresolved premise |\n|---+---+---+---+---|",
 (.obligations[]|"| \(.boundary) | \(.id) | \(.method) | \(.artifact) | \(.premise) |")
elif $kind=="d2" then
 "direction: down\nvars: { d2-config: { layout-engine: elk } }",
 (.boundaries[]|"\(.id): { label: \((.id+"\n"+.route)|tojson) }"),
 (.edges[]|"\(.from) -> \(.to): \"contract + byte-bound result\""),
 "models: { label: \"Component proof obligations (SysML authority)\"",
 (.obligations[]|"  \(.id): { label: \((.id+"\n"+.method+"\n"+.artifact)|tojson) }"),
 "}",
 (.obligations[]|"\(.boundary) -> models.\(.id): \"requires exact scope + evidence\""),
 "old: { label: \"Old generated C + new runtime header\\nREJECTED: 4 modules, 29 field accesses\"; style.fill: \"#ffe4dd\" }",
 "old -> inventory: \"regenerate; no carrier compatibility aliases\"",
 "proof: { label: \"SysML -> ASCENT\\nQNT coverage / argv / self-pass counterexamples\\nLean concrete-source refinement OPEN\" }",
 "semantics -> proof: \"actual oracle result required\"",
 "gate: { label: \"Five conjunctive commit gates\\nNo native result from model-only evidence\"; style.fill: \"#fff0c2\" }",
 "proof -> gate"
else error("unknown projection") end
