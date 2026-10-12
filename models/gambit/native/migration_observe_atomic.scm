;; Compile this helper with the exact tested runtime before loading it in gsi.
;; Unlike an interpreted declaration, this protects the post-return ID read.
(define (smp-atomic-migrate-and-observe target)
  (declare (not interrupts-enabled))
  (##thread-migrate-to! target)
  (##current-processor-id))
