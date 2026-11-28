if $kind=="matrix" then
 "#+TITLE: Modern C Commit Admission: Gates, Process and Questions\n#+LANGUAGE: en\n#+PROPERTY: header-args :eval never\n\n* Five gates from native SysML\n\n[[file:commit-admission.org][Policy and evidence boundary]]. Native values are projected, not re-authored.\n\n| Gate | Required meaning |\n|---+---|",
 (.gates[]|"| \(.id) | \(.purpose) |"),
 "\n* Current Process\n\n| Stage | Current status | Exit criterion |\n|---+---+---|",
 (.stages[]|"| \(.id) | \(.status) | \(.exitCriterion) |"),
 "\n* Required evidence\n\n| Requirement | Gate | Method | Artifact | Exact scope |\n|---+---+---+---+---|",
 (.needs[]|"| \(.id) | \(.gate) | \(.method) | \(.artifact) | \(.scope) |"),
 "\n* Mandatory core and amplification questions\n\n| Question | Prompt | Answer within this cut | Status | Source / paper | Falsifier |\n|---+---+---+---+---+---|",
 (.questions[]|"| \(.id) | \(.prompt) | \(.answer) | \(.status) | \(.evidence) | \(.counterexample) |")
elif $kind=="d2" then
 "direction: down\nvars: { d2-config: { layout-engine: elk } }",
 (.stages[]|"\(.id): { label: \((.id+"\n"+.status)|tojson) }"),
 (.dependencies[]|"\(.before) -> \(.after): \"exit criterion + exact evidence\""),
 "gates: { label: \"ASCENT conjunction\"",
 (.gates[]|" \(.id): \(.purpose|tojson)"),"}",
 "semantic-lifecycle-acceptance -> gates.tests",
 "source-cut -> gates.learning: \"retirement + costs + lessons\"",
 "scoped-controls -> gates.models: \"SysML / QNT / Lean + source bridge\"",
 "gates -> commit-admission: \"all five gates ready on exact source/profile\"",
 "questions: { label: \"Gambit PVM / Feeley polling / multi-shot\\nFFI / lifetime / failure / net benefit\\nUnresolved mandatory answers BLOCK\"; style.fill: \"#fff0c2\" }",
 "questions -> gates.questions",
 "source-cut -> gates.process: \"current stage + remaining dependencies\""
else error("unknown projection") end
