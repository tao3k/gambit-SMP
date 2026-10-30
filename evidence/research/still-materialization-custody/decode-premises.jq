(reduce $p[0].needs[] as $n ({};. ["@premise/"+$n.obligationId]=$n.premise)) as $dict |
walk(if type=="string" and startswith("@premise/") then
 if $dict[.] then $dict[.] else error("Unbound premise token") end else . end)
