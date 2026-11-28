if $kind=="matrix" then
 "#+TITLE: Hash Index Ownership: Responsibility and Net Work\n#+LANGUAGE: en\n#+PROPERTY: header-args :eval never\n\n[[file:hash-index-ownership.org][Evidence, mechanism and qualification frontier]].\n\n| Component | Source route | Invariant | Work removed / capability | Added cost / premise |\n|---+---+---+---+---|",
 (.contracts[]|"| \(.id) | \(.route) | \(.invariant) | \(.benefit) | \(.cost) |"),
 "\n* Proof routing\n\n| Component | Obligation | Method | Artifact | Premise / open work |\n|---+---+---+---+---|",
 (.proofs[]|"| \(.component) | \(.id) | \(.method) | \(.artifact) | \(.premise) |")
elif $kind=="d2" then
 "direction: down\nvars: { d2-config: { layout-engine: elk } }",
 (.contracts[]|"\(.id): {label: \((.id+"\n"+.route)|tojson)}"),
 (.edges[]|"\(.from) -> \(.to): \"owner + invariant\""),
 "proofs: { label: \"Source-bound proof obligations\"",
 (.proofs[]|"  \(.id): {label: \((.id+"\n"+.method+"\n"+.artifact)|tojson)}"),
 "}",
 (.proofs[]|"\(.component) -> proofs.\(.id): \"required evidence\""),
 "old: {label: \"Rejected historical behavior\\nScheme equal?-hash index -> C address rehash\\n1588 enumerated; 1582 same-key lookups missing after GC\"; style.fill: \"#ffe4dd\"}",
 "old -> reference-repair: \"separate semantic owner from moved-reference flag\""
else error("unknown view") end
