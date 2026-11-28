(ascent-fragment
  (relation observed_step (step status capability))
  (relation required_step (step))
  (relation collection_step (step status))
  ((collection_step Step Status) <--
    (required_step Step) (observed_step Step Status (lit "gambit.gate2-collect"))))
