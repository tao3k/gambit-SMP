(include "../#.scm")

;; These integers are deliberately not registered GC roots and never dereferenced.
(c-declare "static unsigned long long queue_payload_before[3] = {0, 0, 0};")
(define remember-address!
  (c-lambda (int scheme-object) void
    "queue_payload_before[___arg1] = (unsigned long long)___arg2;"))
(define relocated?
  (c-lambda (int scheme-object) bool
    "___return(queue_payload_before[___arg1] != (unsigned long long)___arg2);"))

(cond-expand
 (enable-smp
  (define deliveries 0)
  (define collect? (not (member "no-gc" (command-line))))

  (define (check-payload! index payload)
    (test-assert (relocated? index payload))
    (test-eq 'moving-queue-root (vector-ref payload 0))
    (test-equal 32 (vector-length (vector-ref payload 1)))
    (test-equal 42 (vector-ref (vector-ref payload 1) 31))
    (set! deliveries (+ deliveries 1)))

  (define (enqueue-processor! index)
    (declare (not interrupts-enabled) (not inline))
    (let* ((payload (vector 'moving-queue-root (make-vector 32 42)))
           (callback
            (lambda (request)
              (test-equal '() (vector-ref request 0))
              (check-payload! index payload))))
      (remember-address! index payload)
      (##raise-high-level-interrupt (##current-processor-id)
                                   (vector '() callback))
      (void)))

  (define (enqueue-thread! target)
    (declare (not interrupts-enabled) (not inline))
    (let ((payload (vector 'moving-queue-root (make-vector 32 42))))
      (remember-address! 2 payload)
      (##thread-intr!
       target #t
       (lambda ()
         (test-eq target (current-thread))
         (check-payload! 2 payload)))
      (void)))

  (define (check-processor!)
    (declare (not interrupts-enabled))
    (set! deliveries 0)
    (enqueue-processor! 0)
    (test-equal 0 deliveries)
    (if collect? (##gc))
    (test-equal 0 deliveries)
    (##other-interrupt!)
    (test-equal 1 deliveries))

  (define (check-local!)
    (declare (not interrupts-enabled))
    (set! deliveries 0)
    (enqueue-processor! 1)
    (let ((request (##get-next-high-level-interrupt)))
      (test-assert (vector? request))
      (test-equal '() (##get-next-high-level-interrupt))
      (if collect? (##gc))
      (test-equal 0 deliveries)
      ((vector-ref request 1) request)
      (test-equal 1 deliveries)))

  (define (check-thread!)
    (declare (not interrupts-enabled))
    (set! deliveries 0)
    (let ((target (make-thread (lambda () 'target-finished))))
      (##thread-pin! target (current-processor))
      (thread-start! target)
      (enqueue-thread! target)
      (test-equal 0 deliveries)
      (if collect? (##gc))
      (test-equal 0 deliveries)
      (test-eq 'target-finished (thread-join! target))
      (test-equal 1 deliveries)))

  (check-processor!)
  (check-local!)
  (check-thread!)
  (if ##failed-test? (exit 1))
  (display "INTERRUPT-PAYLOAD-RELOCATION-OK:3\n"))
 (else (error "SMP required for moving queue payload fixture")))
