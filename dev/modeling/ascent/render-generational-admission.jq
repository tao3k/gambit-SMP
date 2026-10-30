# Presentation only: all nodes/edges come from native SysML evaluation.
# Shorten two feedback labels without changing their endpoints or full native record.
"direction: down",
"classes: { candidate: { style.fill: \"#e9f2ff\" } }",
(.viewNodes[]|"\(.nodeId): { label: \(.labelText|@json); class: candidate }"),
(.viewEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \((.labelText|gsub("published slot inventory";"root slots")|gsub("collector relocation / epoch release";"update / unpin"))|@json)")
