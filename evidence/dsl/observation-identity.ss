(ascent-fragment
  (relation observed_step (step status capability))
  (relation required_step (step))
  (relation identity_step (step status))
  ((identity_step Step Status) <--
    (required_step Step) (observed_step Step Status (lit "gambit.observation-identity"))))
