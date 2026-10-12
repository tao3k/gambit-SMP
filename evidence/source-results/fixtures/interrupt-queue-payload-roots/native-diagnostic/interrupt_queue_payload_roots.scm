(include "../#.scm")

(cond-expand
 (enable-smp
  (define deliveries 0)

  ;; No payload or request is returned to the caller. The callback is reachable
  ;; through the registered request; the caller holds only an integer counter.
  (define (enqueue-payload!)
    (declare (not interrupts-enabled) (not inline))
    (let* ((payload (vector 'queue-root (make-vector 4096 'payload)))
           (callback
            (lambda (request)
              (test-equal '() (vector-ref request 0))
              (test-eq 'queue-root (vector-ref payload 0))
              (test-equal 4096 (vector-length (vector-ref payload 1)))
              (test-eq 'payload (vector-ref (vector-ref payload 1) 4095))
              (set! deliveries (+ deliveries 1))))
           (request (vector '() callback)))
      (##raise-high-level-interrupt (##current-processor-id) request)
      (void)))

  (define (check-processor-queue!)
    (declare (not interrupts-enabled))
    (set! deliveries 0)
    (enqueue-payload!)
    (test-equal 0 deliveries)
    (##gc)
    (##gc)
    (test-equal 0 deliveries)
    (##other-interrupt!)
    (test-equal 1 deliveries)
    (##other-interrupt!)
    (test-equal 1 deliveries))

  (define (check-local-handoff!)
    (declare (not interrupts-enabled))
    (set! deliveries 0)
    (enqueue-payload!)
    (let ((request (##get-next-high-level-interrupt)))
      (test-assert (vector? request))
      (test-equal '() (vector-ref request 0))
      (test-equal '() (##get-next-high-level-interrupt))
      (##gc)
      (##gc)
      (test-equal 0 deliveries)
      ((vector-ref request 1) request)
      (test-equal 1 deliveries)))

  (check-processor-queue!)
  (check-local-handoff!)
  (if ##failed-test? (exit 1))
  (display "INTERRUPT-QUEUE-PAYLOAD-ROOTS-OK\n"))
 (else (error "SMP required for interrupt payload root fixture")))
