# Proof dependency projection; not the runtime wait graph.
.dependencies as $deps |
[$deps[]|select((.component=="host-roots" and (.obligation|startswith("FZ-"))) or (.prerequisite|startswith("FZ-")))] as $edges |
([$edges[]|{id:.obligation,owner:.component},{id:.prerequisite,owner:.prerequisiteComponent}]|unique_by(.id)) as $nodes |
"direction: right",
($nodes[]|"\(.id|@json): { label: \((.id+"\n"+.owner)|@json) }"),
($edges[]|"\(.obligation|@json) -> \(.prerequisite|@json): requires")
