# Native topology only. Two return edges appear in node captions. Short arrow
# labels avoid collisions; the derived Org matrix retains every full edge label.
def wrap($n): split(" ")|reduce .[] as $w ({lines:[],line:""};
 if ((.line|length)+($w|length)+1>$n and (.line|length)>0)
 then .lines+=[.line]|.line=$w else .line+=(if .line=="" then "" else " " end)+$w end)
 |(.lines+[.line])|join("\n");
def returnEdge: .consumer.nodeId=="writeOp" and .producer.nodeId!="semantic";
def shortLabel:
 if .producer.nodeId=="semantic" then "plan"
 elif .producer.nodeId=="writeOp" then (if .consumer.nodeId=="cards" then "mark" else "hint" end)
 elif .producer.nodeId=="cards" then "bitmap"
 elif .producer.nodeId=="hints" then "hints"
 elif .producer.nodeId=="cut" then "settle"
 elif .producer.nodeId=="capacity" then (if .consumer.nodeId=="pendingCopy" then "accept" else "reject" end)
 elif .producer.nodeId=="pendingCopy" then (if .consumer.nodeId=="readyCopy" then "ready" else "hold" end)
 else "finish" end;
. as $a|"direction: down",
(.barrierNodes[]|. as $node|
 ([$a.barrierEdges[]|select(returnEdge and .producer.nodeId==$node.nodeId)|"Return to "+.consumer.nodeId+": "+.labelText]|join("\n")) as $returns|
 "\(.nodeId): { label: \(((.labelText+(if $returns=="" then "" else "\n"+$returns end))|wrap(34))|@json) }"),
(.barrierEdges[]|select(returnEdge|not)|"\(.producer.nodeId) -> \(.consumer.nodeId): \((shortLabel)|@json)")
