;;; Scenario definitions loaded through Python/C ABI; no downstream imports or compile.
(def review-decision-rules
  (ascent-fragment
    ((Need C P) <-- (Requires C P))
    ((Need C Q) <-- (Need C P) (ClaimDepends P Q))
    ((HasRequirement C) <-- (Requires C P))
    ((Missing C P) <-- (Need C P) (not (Claim P)))
    ((Relevant C F I Report) <-- (Candidate C S CI) (Failure F S I Report))
    ((KnownFailure C F Report) <-- (Relevant C F I Report))
    ((CausalEvidence C F R) <-- (Cause C F R) (Reusable R P))
    ((HasCause C F) <-- (CausalEvidence C F R))
    ((Denial C (lit 'unchanged-failed-inputs)) <-- (Candidate C S I) (Failure F S I Report))
    ((Denial C (lit 'missing-causal-evidence)) <-- (Relevant C F I Report) (not (HasCause C F)))
    ((Denial C (lit 'missing-premise)) <-- (Missing C P))
    ((Denial C (lit 'missing-requirement-set)) <-- (Candidate C S I) (not (HasRequirement C)))
    ((DeniedCandidate C) <-- (Denial C Reason))
    ((Decision C (lit 'DENY)) <-- (Candidate C S I) (DeniedCandidate C))
    ((Decision C (lit 'REVIEW_REQUIRED)) <-- (Candidate C S I) (not (DeniedCandidate C)))
  ))
