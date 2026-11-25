(ascent-fragment
 (relation artifactNeed ((path string?) (hash string?)))
 (relation artifactSeen ((path string?) (hash string?)))
 (relation artifactLinked ((path string?)))
 ((artifactLinked P) <-- (artifactNeed P H) (artifactSeen P H))
 (relation routeNeed ((id string?) (source string?) (evidence string?) (qnt string?) (test string?) (lean string?) (lemma string?) (scope string?)))
 (relation routeSeen ((id string?) (source string?) (evidence string?) (qnt string?) (test string?) (lean string?) (lemma string?) (scope string?)))
 (relation proofWitness ((qnt string?) (test string?) (lean string?) (lemma string?)))
 (relation routeLinked ((id string?)))
 ((routeLinked I) <-- (routeNeed I S E Q T L M C) (routeSeen I S E Q T L M C)
  (artifactLinked S) (artifactLinked E) (artifactLinked Q) (artifactLinked L)
  (proofWitness Q T L M))
 (relation routeGap ((id string?)))
 ((routeGap I) <-- (routeNeed I _ _ _ _ _ _ _) (not (routeLinked I)))

 ;; Completion and a declared profile are distinct from source/log association.
 (relation benchmarkNeed ((repo string?) (head string?) (graph string?) (sdk string?) (budget string?) (cache string?) (clock string?)))
 (relation benchmarkObserved ((repo string?) (head string?) (graph string?) (sdk string?) (budget string?) (cache string?) (clock string?) (complete string?) (natural string?) (timeout string?) (verified string?)))
 (relation baselineReady ((repo string?)))
 ((baselineReady R) <-- (benchmarkNeed R H G S B C K)
  (benchmarkObserved R H G S B C K "yes" "yes" "no" "yes"))
 (relation baselineGap ((repo string?)))
 ((baselineGap R) <-- (benchmarkNeed R _ _ _ _ _ _) (not (baselineReady R)))

 (relation caseNeed ((repo string?) (kind string?)))
 (relation caseSeen ((repo string?) (kind string?) (disposition string?)))
 (relation caseMissing ((repo string?) (kind string?)))
 ((caseMissing R K) <-- (caseNeed R K) (not (caseSeen R K "matched-semantic-pass")))
 (relation candidatePairNeed ((repo string?) (before string?) (after string?)))
 (relation candidatePairSeen ((repo string?) (before string?) (after string?) (scope string?)))
 (relation performanceWitness ((repo string?) (status string?)))
 (relation candidateReady ((repo string?)))
 ((candidateReady R) <-- (baselineReady R) (not (routeGap _)) (candidatePairNeed R B A)
  (candidatePairSeen R B A "same-work-full-context") (not (caseMissing R _))
  (performanceWitness R "net-positive-or-required-nonregression"))
 (relation requested ((scope string?)))
 (relation requiredRepository ((scope string?) (repo string?)))
 (relation missingRepository ((scope string?) (repo string?)))
 ((missingRepository G R) <-- (requested G) (requiredRepository G R) (not (candidateReady R)))
 (relation optimizationAccepted ((scope string?)))
 ((optimizationAccepted G) <-- (requested G) (requiredRepository G _)
  (not (missingRepository G _)))

 ;; A safe experiment need not wait for all semantic-refinement proofs.
 ;; These bindings must come from the existing authenticated source/profile
 ;; owner, not from the mere existence of a model or a caller's status label.
 (relation measurementNeed ((repo string?) (before string?) (after string?) (profile string?)))
 (relation measurementBinding ((repo string?) (before string?) (after string?) (profile string?)))
 (relation measurementReady ((repo string?)))
 ((measurementReady R) <-- (measurementNeed R B A P) (measurementBinding R B A P))

 ;; Net-positive is weaker than the requested cold-build factor. The numeric
 ;; witness additionally requires both-arm completeness and nonregression of
 ;; every declared case, calculated from exact elapsed values outside Datalog.
 ;; Its extractor/authentication remains an explicit native refinement duty.
 (relation pairedElapsedWitness ((repo string?) (before string?) (after string?) (profile string?) (status string?)))
 (relation twofoldCandidate ((repo string?)))
 ((twofoldCandidate R) <-- (candidateReady R) (measurementReady R)
  (measurementNeed R B A P)
  (pairedElapsedWitness R B A P "twofold-all-cases-nonregressing"))
 (relation twofoldMissing ((scope string?) (repo string?)))
 ((twofoldMissing G R) <-- (requested G) (requiredRepository G R) (not (twofoldCandidate R)))
 (relation twofoldAccepted ((scope string?)))
 ((twofoldAccepted G) <-- (requested G) (requiredRepository G _)
  (not (twofoldMissing G _)))

 ;; A retained rejection blocks repeating that exact mechanism, not every redesign.
 (relation priorRejection ((variant string?) (evidence string?)))
 (relation proposedTrial ((id string?) (variant string?)))
 (relation trialBlocked ((id string?) (evidence string?)))
 ((trialBlocked I E) <-- (proposedTrial I V) (priorRejection V E) (artifactLinked E))
)
