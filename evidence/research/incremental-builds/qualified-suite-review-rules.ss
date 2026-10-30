;;; Additional bounded Make transport; original policy remains unchanged.
(ascent-fragment
  ((matching_regime R) <-- (scoped_single_file R F)
    (budget_regime R (lit 'whole-sequential) (lit 'upstream-make)))
  ((matching_regime R) <-- (scoped_single_file R F)
    (budget_regime R (lit 'whole-parallel) (lit 'upstream-make))))
