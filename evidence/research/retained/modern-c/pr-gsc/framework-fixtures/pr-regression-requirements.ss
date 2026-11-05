;;; Versioned qualification scope, separate from generic coverage inference.
;;; This list is not a claim that every possible SMP regression is covered.
(ascent-fragment
  ((required_pr_fixture (lit "06-thread/thread_interrupt_ended.scm") (lit "5034a9937f3ac8df8dddf5182d48a08b0cac095bd239355b97de638768b73a6d")) <--
    (observed_suite S (lit 'gsc) (lit 'unit) (lit #t)))
  ((required_pr_fixture (lit "09-io/pipe_concurrent.scm") (lit "760513881622cd51bbf258eebd8ac09562ef85e4f84330c33fbc1020df366f93")) <--
    (observed_suite S (lit 'gsc) (lit 'unit) (lit #t)))
  ((required_pr_fixture (lit "10-tables/serialization_gc.scm") (lit "6d1e709df3fde6dce5d99a34d9309d49434d45440924c8b1e5f47c9144de7741")) <--
    (observed_suite S (lit 'gsc) (lit 'unit) (lit #t)))
  ((required_pr_fixture (lit "10-tables/serialization.scm") (lit "ef42cdb7b317e44baf7cd435438383447ca462284f95f63b46aa867f45c17baa")) <--
    (observed_suite S (lit 'gsc) (lit 'unit) (lit #t)))
  ((required_pr_fixture (lit "12-os/process_spawn.scm") (lit "eba139d1aa995cc78e53891d5bcf93fd7ce33eff08f6080f52efb78a8f5c98c7")) <--
    (observed_suite S (lit 'gsc) (lit 'unit) (lit #t)))
  ((required_pr_fixture (lit "diagnostic/table_iteration_gc.scm") (lit "57f8cea541700c6f22b281961f9d360976fc5167c50e376e4217127175d1f997")) <--
    (observed_suite S (lit 'gsc) (lit 'unit) (lit #t))))
