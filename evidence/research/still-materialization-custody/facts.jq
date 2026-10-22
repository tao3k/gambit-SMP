def fact($r;$v): " (fact ("+$r+" "+($v|map(@json)|join(" "))+"))";
def premise($a): if $a.compactPremises then ("@premise/"+.obligationId) else .premise end;
. as $a|
(.components[]|fact("componentFact";[.id,$a.claim,"native-component-study"])),
(.needs|group_by(.component)[]|. as $ns|range(0;length;3) as $i|$ns[$i:$i+3] as $g|if ($g|length)==3 then fact("needTripleFact";[$g[0].component]+[$g[]|.obligationId,.kind,premise($a),.subjectPath,.subjectScope]) else $g[]|fact("needFact";[.component,.obligationId,.kind,premise($a),.subjectPath,.subjectScope]) end),
(.methods[]|fact("methodFact";[.kind,.method,.requiredCheck])),
(.dependencies|group_by(.component)[]|. as $es|range(0;length;5) as $i|$es[$i:$i+5] as $g|
 if ($g|length)==5 then fact("dependencyOwnerQuintFact";[$g[0].component]+[$g[]|.obligation,.prerequisiteComponent,.prerequisite])
 else $g[]|fact("dependencyFact";[.component,.obligation,.prerequisiteComponent,.prerequisite]) end),
(.contracts[]|fact("contractFact";[.contractId,.producer.componentId,.consumer.componentId,.phaseScope,.guarantee,.rely,.failureCustodian])),
(.sourceRoutes|map(.+{component:(.need.owner.componentId//"host-roots")})|group_by([.component,.status])[]|. as $routes|range(0;length;2) as $i|$routes[$i:$i+2] as $g|
 if ($g|length)==2 then fact("sourceRoutePairFact";[$g[0].component,$g[0].status]+[$g[]|.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian])
 else $g[]|fact("sourceRouteFact";[.component,.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status]) end)
