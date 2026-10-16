(include "#.scm")

(define value (vector 0))
(test-equal 1 (##vector-inc! value 0 1))
(test-equal 2 (vector-inc! value 0))
;; The compiler primitive inventory accepts this same two-argument form.
(test-equal 3 (##vector-inc! value 0))
