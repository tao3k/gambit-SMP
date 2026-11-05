# Presentation only: every need, source-route link and dependency is native-evaluated.
"direction: right",
"sources: { label: \"Real source routes (audited edges, not source proofs)\"",
(.sourceRoutes[] | "  \(.need.obligationId|@json): { label: \((.need.obligationId+"\n"+(.sourceAnchors|split(";")[0]))|@json) }"), "}",
"roots: { label: \"Modern C host-roots obligations\"",
(.components[]|select(.id=="host-roots")|.needs[]|"  \(.obligationId|@json): { label: \((.obligationId+"\n"+.kind)|@json) }"),
(.refinementNeeds[]|"  \(.obligationId|@json): { label: \((.obligationId+"\n"+.kind)|@json) }"), "}",
(.sourceRoutes[]|"sources.\(.need.obligationId|@json) -> roots.\(.need.obligationId|@json): open refinement"),
((.dependencies+.refinementDependencies)[]|select(.dependent.owner.componentId=="host-roots")|
"roots.\(.dependent.obligationId|@json) -> roots.\(.prerequisite.obligationId|@json): requires"),
"consumers: { label: \"Direct dependent source needs\"",
(.dependencies[]|select(.prerequisite.owner.componentId=="host-roots" and .dependent.owner.componentId!="host-roots")|
"  \(.dependent.obligationId|@json): { label: \((.dependent.owner.componentId+"\n"+.dependent.obligationId)|@json) }"), "}",
(.dependencies[]|select(.prerequisite.owner.componentId=="host-roots" and .dependent.owner.componentId!="host-roots")|
"consumers.\(.dependent.obligationId|@json) -> roots.\(.prerequisite.obligationId|@json): requires")
