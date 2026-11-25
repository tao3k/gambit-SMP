;; SysML selects cases. Observations bind actual source/native identity;
;; coverage is not a proof that a native observer or source premise is true.
(ascent-fragment
 (relation source ((tree string?) (profile string?)))
 (relation observed ((tree string?) (profile string?)))
 (relation requiredCase ((id string?)))
 (relation nativeCase ((id string?) (tree string?) (profile string?)))
 (relation requiredPremise ((id string?)))
 (relation sourcePremise ((id string?)))
 (relation parentClaim ((id string?)))
 (relation unknownRollback ((id string?)))
 (relation gap ((id string?) (reason string?)))
 (relation ready ((tree string?)))
 ((gap T "unbound-native-identity") <-- (source T P) (not (observed T P)))
 ((gap C "missing-required-case") <-- (source T P) (requiredCase C) (not (nativeCase C T P)))
 ((gap C "missing-source-premise") <-- (requiredPremise C) (not (sourcePremise C)))
 ((gap C "parent-not-closed") <-- (parentClaim C))
 ((gap C "unknown-is-not-returned-refusal") <-- (unknownRollback C))
 ((ready T) <-- (source T P) (observed T P) (not (gap _ _))))
