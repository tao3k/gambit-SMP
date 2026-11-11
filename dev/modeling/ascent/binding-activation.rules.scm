(ascent-fragment
 ;; Needs and their states come from strict SDK evaluation of SysML.
 ;; This query reports closure; it cannot attest C correctness or grant a REV.
 (relation activationScenario ((id string?)))
 (relation activationNeed ((id string?) (modelHash string?) (state string?)))
 (relation activationObservation ((scenario string?) (id string?) (modelHash string?) (state string?)))
 (relation activationBound ((scenario string?) (id string?)))
 (relation activationClosed ((id string?)))
 (relation activationGap ((scenario string?) (id string?) (reason string?)))
 (relation activationReady ((scenario string?)))
 ((activationBound S I) <-- (activationNeed I H T) (activationObservation S I H T))
 ((activationGap S I (lit "missing-or-stale-model-observation")) <--
  (activationScenario S) (activationNeed I _ _) (not (activationBound S I)))
 ((activationClosed I) <-- (activationNeed I _ (lit "CLOSED")))
 ((activationGap S I T) <-- (activationScenario S) (activationNeed I _ T)
  (not (activationClosed I)))
 ((activationReady S) <-- (activationScenario S) (not (activationGap S _ _)))
)
