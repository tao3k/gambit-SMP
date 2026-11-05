# Layout and word wrapping only; topology is native SysML ViewNode/ViewEdge data.
def wrap($n): split(" ")|reduce .[] as $w ({lines:[],line:""};
 if ((.line|length)+($w|length)+1>$n and (.line|length)>0)
 then .lines+=[.line]|.line=$w else .line+=(if .line=="" then "" else " " end)+$w end)
 |(.lines+[.line])|join("\n");
"direction: down",
(.barrierNodes[]|"\(.nodeId): { label: \((.labelText|wrap(32))|@json) }"),
(.barrierEdges[]|"\(.producer.nodeId) -> \(.consumer.nodeId): \((.labelText|wrap(26))|@json)")
