(include "../#.scm")

(cond-expand
 (enable-smp
  (define deliveries 0)

  ;; The target is pinned only to control the collection-before-delivery window.
  ;; Payload escapes solely through the real asynchronous interrupt request.
  (define (enqueue-payload! target)
    (declare (not interrupts-enabled) (not inline))
    (let* ((payload (vector 'thread-queue-root (make-vector 4096 'payload)))
           (callback
            (lambda ()
              (test-eq target (current-thread))
              (test-eq 'thread-queue-root (vector-ref payload 0))
              (test-equal 4096 (vector-length (vector-ref payload 1)))
              (test-eq 'payload (vector-ref (vector-ref payload 1) 4095))
              (set! deliveries (+ deliveries 1)))))
      (##thread-intr! target #t callback)
      (void)))

  (define (check-thread-queue!)
    (declare (not interrupts-enabled))
    (let ((target (make-thread (lambda () 'target-finished))))
      (##thread-pin! target (current-processor))
      (thread-start! target)
      (enqueue-payload! target)
      (test-equal 0 deliveries)
      (##gc)
      (##gc)
      (test-equal 0 deliveries)
      (test-eq 'target-finished (thread-join! target))
      (test-equal 1 deliveries)))

  (check-thread-queue!)
  (if ##failed-test? (exit 1))
  (display "INTERRUPT-THREAD-QUEUE-PAYLOAD-ROOTS-OK\n"))
 (else (error "SMP required for thread queue root fixture")))
