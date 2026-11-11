# Display fields only. Exact qualification artifact/digest/check/scope stay literal.
.nativePremiseDictionary=($native[0].needs|map({key:.obligationId,value:.premise})|from_entries) |
.nativeRouteDictionary=($native[0].sourceRoutes|map({key:.need.obligationId,value:.})|from_entries) |
.modelRequired |= map(.[2] as $id | .[7] = $native[0].needs[([ $native[0].needs[].obligationId ]|index($id))].premise) |
.sourceRoute |= map(.[0] as $id | .[1] = ($native[0].sourceRoutes[]|select(.need.obligationId==$id)|.sourceAnchors) | .[2]=($native[0].sourceRoutes[]|select(.need.obligationId==$id)|.failureCustodian))
