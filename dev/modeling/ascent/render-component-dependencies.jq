# View serialization of native-evaluated SysML only; no method or proof policy.
"direction: right",
(.components[] | .id as $c | "\($c|@json): {", "  label: \($c|@json)",
 (.needs[] | "  \(.obligationId|@json): { label: \((.obligationId+"\n"+.kind)|@json) }"), "}"),
(.dependencies[] | "\(.dependent.owner.componentId|@json).\(.dependent.obligationId|@json) -> \(.prerequisite.owner.componentId|@json).\(.prerequisite.obligationId|@json): requires")
