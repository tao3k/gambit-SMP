def fact($r;$v): " (fact ("+$r+" "+($v|map(@json)|join(" "))+"))";
. as $a|
(.components[]|fact("componentFact";[.id,$a.claim,"native-component-study"])),
(.needs[]|fact("needFact";[.component,.obligationId,.kind,.premise,.subjectPath,.subjectScope])),
(.methods[]|fact("methodFact";[.kind,.method,.requiredCheck])),
(.edgeGroups[]|if length==3 then fact("dependencyTripleFact";[.[0].component,.[0].obligation]+[.[]|.prerequisiteComponent,.prerequisite]) else .[]|fact("dependencyFact";[.component,.obligation,.prerequisiteComponent,.prerequisite]) end),
(.contracts[]|fact("contractFact";[.contractId,.producer.componentId,.consumer.componentId,.phaseScope,.guarantee,.rely,.failureCustodian])),
(.sourceRoutes[]|fact("sourceRouteFact";["host-roots",.need.obligationId,.sourceAnchors,.patchAnchors,.projection,.failureCustodian,.status]))
