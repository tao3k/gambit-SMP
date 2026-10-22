;; Generic assurance DSL. Native SysML supplies component/need/method/artifact facts.
;; Transport appends facts before this definition's final line; no policy in jq.
;; Qualified means exact source-bound scoped receipt, never native permission.
(define-evidence (query)
 (sources clue factor binding)
 (outputs question modelRequired qualifiedSlice missingModel pendingCheck nextAction openPremise unmetDependency dependencyCycle unroutedNeed)
 (include clue-selection-schema)
 (relation question (claim))
 (relation componentFact (component claim sysmlSource))
 (relation needFact (component obligation kind premise))
 (relation methodFact (kind method requiredCheck))
 (relation dependencyFact (component dependent prerequisite))
 (relation dependsOn (component dependent prerequisite))
 (relation receiptMatched (scenario component obligation))
 (relation unmetDependency (scenario component dependent prerequisite))
 (relation dependencyCycle (component obligation))
 (relation blockedCheck (scenario component obligation))
 (relation knownKind (kind))
 (relation unroutedNeed (scenario component obligation kind))
 (relation scenarioFact (scenario scope))
 (relation artifactFact (scenario component method artifact digest))
 (relation receiptFact (scenario component method artifact digest check status))
 (relation boundComponent (component claim))
 (relation modelRequired (scenario component obligation method requiredCheck premise))
 (relation qualifiedSlice (scenario component obligation method artifact check))
 (relation missingModel (scenario component obligation method))
 (relation pendingCheck (scenario component obligation method artifact check))
 (relation nextAction (scenario component obligation action method subject))
 (relation openPremise (scenario component obligation premise))
 ((boundComponent C K) <--
  (componentFact C K S) (clue I D K _ _ _)
  (factor I D (lit "target-model-bundle-sha256") B) (binding (lit "target-model-bundle-sha256") B)
  (factor I D (lit "native-output-sha256") N) (binding (lit "native-output-sha256") N)
  (factor I D (lit "planner-dsl-sha256") P) (binding (lit "planner-dsl-sha256") P))
 ((modelRequired S C O M K P) <--
  (boundComponent C _) (scenarioFact S _)
  (needFact C O T P) (methodFact T M K))
 ((knownKind T) <-- (methodFact T _ _))
 ((unroutedNeed S C O T) <-- (boundComponent C _) (scenarioFact S _)
  (needFact C O T _) (not (knownKind T)))
 ((dependsOn C O P) <-- (dependencyFact C O P))
 ((dependsOn C O P) <-- (dependsOn C O X) (dependencyFact C X P))
 ((dependencyCycle C O) <-- (dependsOn C O O))
 ((qualifiedSlice S C O M A K) <--
  (modelRequired S C O M K _) (artifactFact S C M A H)
  (receiptFact S C M A H K (lit "pass")))
 ((receiptMatched S C O) <-- (qualifiedSlice S C O _ _ _))
 ((unmetDependency S C O P) <-- (boundComponent C _) (scenarioFact S _)
  (dependsOn C O P) (not (receiptMatched S C P)))
 ((blockedCheck S C O) <-- (unmetDependency S C O _))
 ((blockedCheck S C O) <-- (scenarioFact S _) (dependencyCycle C O))
 ((missingModel S C O M) <--
  (modelRequired S C O M _ _) (not (artifactFact S C M _ _)))
 ((pendingCheck S C O M A K) <--
  (modelRequired S C O M K _) (artifactFact S C M A _)
  (not (qualifiedSlice S C O M A K)))
 ((nextAction S C O (lit "construct-model") M (lit "model-source")) <--
  (missingModel S C O M))
 ((nextAction S C O (lit "perform-scoped-check") M K) <--
  (pendingCheck S C O M _ K) (not (blockedCheck S C O)))
 ((nextAction S C O (lit "resolve-prerequisite") M P) <--
  (modelRequired S C O M _ _) (unmetDependency S C O P))
 ((nextAction S C O (lit "define-method-policy") (lit "Unassigned") T) <--
  (unroutedNeed S C O T))
 ((nextAction S C O (lit "repair-dependency-cycle") M O) <--
  (modelRequired S C O M _ _) (dependencyCycle C O))
 ((openPremise S C O P) <--
  (modelRequired S C O M _ P) (missingModel S C O M))
 ((openPremise S C O P) <--
  (modelRequired S C O M K P) (pendingCheck S C O M _ K))
 ((question K) <-- (boundComponent _ K))
)
