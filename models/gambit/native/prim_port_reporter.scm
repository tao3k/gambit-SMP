;; Diagnostic only: retain the upstream comparison and failure flag.
(include "#.scm")
(define (##failed-check message)
  (##failed-test message))
(include "prim_port.scm")
