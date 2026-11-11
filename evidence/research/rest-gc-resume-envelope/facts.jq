def fact($r;$v): " (fact ("+$r+" "+($v|map(@json)|join(" "))+"))";
. as $a|
(.components[]|fact("componentFact";[.id,$a.claim,"native-component-study"])),
(.needs|group_by(.component)[]|. as $ns|range(0;length;3) as $i|$ns[$i:$i+3] as $g|if ($g|length)==3 then fact("needTripleFact";[$g[0].component]+[$g[]|.obligationId,.kind,.premise,.subjectPath,.subjectScope]) else $g[]|fact("needFact";[.component,.obligationId,.kind,.premise,.subjectPath,.subjectScope]) end),
(.methods[]|fact("methodFact";[.kind,.method,.requiredCheck])),
(.edgeGroups[]|if length==5 then fact("dependencyQuintFact";[.[0].component,.[0].obligation]+[.[]|.prerequisiteComponent,.prerequisite]) elif length>=3 then fact("dependencyTripleFact";[.[0].component,.[0].obligation]+[.[:3][]|.prerequisiteComponent,.prerequisite]), (. [3:][]|fact("dependencyFact";[.component,.obligation,.prerequisiteComponent,.prerequisite])) else .[]|fact("dependencyFact";[.component,.obligation,.prerequisiteComponent,.prerequisite]) end),
(.contracts[]|fact("contractFact";[.contractId,.producer.componentId,.consumer.componentId,.phaseScope,.guarantee,.rely,.failureCustodian])),
(.sourceRoutes|map(.+{component:(.need.owner.componentId//"host-roots")})|group_by([.component,.status])[]|. as $routes|range(0;length;2) as $i|$routes[$i:$i+2] as $g|
 if ($g|length)==2 then fact("sourceRoutePairFact";[$g[0].component,$g[0].status]+[$g[]|.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian])
 else $g[]|fact("sourceRouteFact";[.component,.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status]) end)
