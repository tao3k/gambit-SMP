(include "../#.scm")
(include "~~lib/_thread#.scm")

(cond-expand
 (enable-smp
  (define deliveries 0)

  ;; Directly populate the real current-thread queue under its source lock.
  ;; This isolates tracing, not peer-to-peer propagation or scheduling.
  (define (enqueue-payload!)
    (declare (not interrupts-enabled) (not inline))
    (let* ((payload (vector 'thread-queue-root (make-vector 4096 'payload)))
           (callback
            (lambda (request)
              (test-equal '() (vector-ref request 0))
              (test-eq 'thread-queue-root (vector-ref payload 0))
              (test-equal 4096 (vector-length (vector-ref payload 1)))
              (test-eq 'payload (vector-ref (vector-ref payload 1) 4095))
              (set! deliveries (+ deliveries 1))))
           (request (vector '() callback)))
      (macro-lock-current-thread!)
      (macro-thread-interrupts-insert-at-tail! (current-thread) request)
      (macro-unlock-current-thread!)
      (void)))

  (define (check-thread-queue!)
    (declare (not interrupts-enabled))
    (test-equal '() (macro-thread-interrupts-head (current-thread)))
    (enqueue-payload!)
    (test-equal 0 deliveries)
    (##gc)
    (##gc)
    (test-equal 0 deliveries)
    (macro-lock-current-thread!)
    (macro-thread-interrupts-remove-from-head!
     request
     (begin
       (macro-unlock-current-thread!)
       ((vector-ref request 1) request))
     (begin
       (macro-unlock-current-thread!)
       (test-assert #f)))
    (test-equal 1 deliveries)
    (test-equal '() (macro-thread-interrupts-head (current-thread)))
    (test-equal '() (macro-thread-interrupts-tail (current-thread))))

  (check-thread-queue!)
  (if ##failed-test? (exit 1))
  (display "INTERRUPT-THREAD-QUEUE-PAYLOAD-ROOTS-OK\n"))
 (else (error "SMP required for thread queue root fixture")))
