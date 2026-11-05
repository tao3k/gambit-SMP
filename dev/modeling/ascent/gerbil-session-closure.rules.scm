;; Domain inference appended to the generic assurance query. Native SysML owns
;; roots/edges/domains/census. A reachable catalogue is not a complete source cut.
(relation supportNodeFact (node kind anchor))
(relation executionFact (caller callee))
(relation rootSupportFact (node))
(relation domainFact (domain ownership anchor))
(relation censusFact (status))
(relation supportClosure (scenario node))
(relation opaqueSupport (scenario node anchor))
(relation stateOwnership (scenario domain ownership anchor))
(relation sourceAdmissionBlocked (scenario reason))
((supportClosure S N) <-- (boundComponent (lit "build-scheduler") _)
 (scenarioFact S _) (rootSupportFact N))
((supportClosure S B) <-- (supportClosure S A) (executionFact A B))
((opaqueSupport S N A) <-- (supportClosure S N) (supportNodeFact N (lit "opaque") A))
((stateOwnership S D P A) <-- (boundComponent (lit "build-scheduler") _)
 (scenarioFact S _) (domainFact D P A))
((sourceAdmissionBlocked S (lit "incomplete-source-census")) <--
 (boundComponent (lit "build-scheduler") _) (scenarioFact S _) (censusFact (lit "false")))
