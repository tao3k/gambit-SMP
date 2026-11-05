def identity: [.component,.obligationId];
def closure($edges):
 . as $now | (.+[$edges[]|select([.component,.obligation] as $k|$now|index([$k]))|[.prerequisiteComponent,.prerequisite]]|unique) as $next|
 if $now==$next then . else $next|closure($edges) end;
. as $full | (if $cut=="runtime" then ["gc-work","host-roots","continuation","gc-synchronous-publication","resource-exit"] else ["build-planner","build-scheduler","build-publisher"] end) as $owners|
([.needs[]|select(.component as $c|$owners|index($c))|identity]|unique|closure($full.dependencies)) as $keys|
.needs|=map(select(identity as $k|$keys|index([$k])))|
.dependencies|=map(select([.component,.obligation] as $k|$keys|index([$k])))|
.components|=map(select(.id as $c|$keys|map(.[0])|index($c)))|
.sourceRoutes|=map(select([(.need.owner.componentId//"host-roots"),.need.obligationId] as $k|$keys|index([$k])))|
.edgeGroups=[.dependencies|group_by([.component,.obligation])[]|. as $g|range(0;length;5) as $i|$g[$i:$i+5]]|
.scope={id:$cut,completeOwnerComponents:$owners,ancestorClosed:true,globalCompleteClaim:false}
