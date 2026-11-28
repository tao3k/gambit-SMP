# Native evaluated proof dependencies and route endpoints, not runtime wait edges.
def detail($id): ($id|startswith("RC-")) or (["HR-RC","HR-S","HR-M","HR-DH","HR-DI"]|index($id))!=null;
"direction: right",
"sources: { label: \"Retained-domain source routes; refinement open\"",
(.sourceRoutes[]|select(.need.obligationId|startswith("RC-"))|"  \(.need.obligationId|@json): { label: \((.need.obligationId+"\n"+(.sourceAnchors|split(";")[0]))|@json) }"),"}",
"roots: { label: \"Modern C retained-root obligations\"",
(((.components[]|select(.id=="host-roots")|.needs[]),.refinementNeeds[])|select(detail(.obligationId))|"  \(.obligationId|@json): { label: \((.obligationId+"\n"+.kind)|@json) }"),"}",
(.sourceRoutes[]|select(.need.obligationId|startswith("RC-"))|"sources.\(.need.obligationId|@json) -> roots.\(.need.obligationId|@json): open refinement"),
((.dependencies+.refinementDependencies)[]|select(.dependent.owner.componentId=="host-roots" and detail(.dependent.obligationId) and detail(.prerequisite.obligationId))|
"roots.\(.dependent.obligationId|@json) -> roots.\(.prerequisite.obligationId|@json): requires"),
"consumers: { label: \"Five dependent source needs\"",
(.dependencies[]|select(.prerequisite.owner.componentId=="host-roots" and .dependent.owner.componentId!="host-roots")|"  \(.dependent.obligationId|@json): { label: \((.dependent.owner.componentId+"\n"+.dependent.obligationId)|@json) }"),"}",
(.dependencies[]|select(.prerequisite.owner.componentId=="host-roots" and .dependent.owner.componentId!="host-roots")|"consumers.\(.dependent.obligationId|@json) -> roots.\(.prerequisite.obligationId|@json): requires")
