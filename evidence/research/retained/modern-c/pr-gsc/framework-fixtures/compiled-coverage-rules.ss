;;; Scope derived from checked actual suite files, never invented observed steps.
(ascent-fragment
  (relation observed_suite ((suite symbol?) (mode symbol?) (inventory symbol?) (whole boolean?)))
  (relation observed_suite_file ((suite symbol?) (file string?) (sha string?)))
  (relation required_pr_fixture ((file string?) (sha string?)))
  (relation pr_missing_file ((suite symbol?) (file string?)))
  (relation pr_suite_gap ((suite symbol?)))
  (relation qualified_suite_gate ((gate symbol?) (suite symbol?)))
  ((pr_missing_file S F) <-- (observed_suite S (lit 'gsc) (lit 'unit) (lit #t))
    (required_pr_fixture F H) (not (observed_suite_file S F H)))
  ((pr_suite_gap S) <-- (pr_missing_file S F))
  ((qualified_suite_gate (lit 'complete-gsc) S) <--
    (observed_suite S (lit 'gsc) (lit 'unit) (lit #t)))
  ((qualified_suite_gate (lit 'pr-regressions-gsc) S) <--
    (observed_suite S (lit 'gsc) (lit 'unit) (lit #t)) (not (pr_suite_gap S))))
