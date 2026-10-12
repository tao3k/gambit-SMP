;; Observe enqueue completion without changing the original reuse assertions.
(define start-without-boundary thread-start!)
(set! thread-start!
  (lambda (thread)
    (display (list 'worker-start-enter (##current-processor-id)))
    (newline)
    (force-output)
    (let ((result (start-without-boundary thread)))
      (display (list 'worker-start-return (##current-processor-id)))
      (newline)
      (force-output)
      result)))
(##include "resize_still_reuse.scm")
