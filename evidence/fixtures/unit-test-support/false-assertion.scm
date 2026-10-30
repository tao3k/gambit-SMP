;; Install as unit-tests/00-test/support_false.scm in the runner's fixture view.
;; This deliberately fails; it must not be admitted as a passing unit test.
(include "#.scm")
(test-eq 1 2)
