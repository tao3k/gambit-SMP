(include "../#.scm")

(c-declare "static unsigned long long callback_payload_before = 0;")
(define remember-address!
  (c-lambda (scheme-object) void
    "callback_payload_before = (unsigned long long)___arg1;"))
(define relocated?
  (c-lambda (scheme-object) bool
    "___return(callback_payload_before != (unsigned long long)___arg1);"))

(cond-expand
 (enable-smp
  (define calls 0)

  (define (check-case exceptional?)
    (declare (not interrupts-enabled))
    (set! calls 0)
    (let ((target (make-thread (lambda () 'target-finished))))
      (##thread-pin! target (current-processor))
      (thread-start! target)
      (let ((callback
             (lambda ()
               (test-eq target (current-thread))
               (set! calls (+ calls 1))
               ;; Created inside the callback, not captured by its caller.
               (let ((payload (make-vector 32 42)))
                 (remember-address! payload)
                 (##gc)
                 (test-assert (relocated? payload))
                 (test-equal 32 (vector-length payload))
                 (test-equal 42 (vector-ref payload 31))
                 (if exceptional? (raise 'callback-failure) payload)))))
        (if exceptional?
            (begin
              (test-error abandoned-mutex-exception?
                          (##thread-intr! target #f callback))
              (test-error uncaught-exception? (thread-join! target)))
            (let ((result (##thread-intr! target #f callback)))
              (test-assert (vector? result))
              (test-equal 32 (vector-length result))
              (test-equal 42 (vector-ref result 31))
              (test-eq 'target-finished (thread-join! target)))))
      (test-equal 1 calls)))

  (check-case #f)
  (check-case #t)
  (if ##failed-test? (exit 1))
  (display "INTERRUPT-CALLBACK-GC-EXIT-OK:2\n"))
 (else (error "SMP required for callback GC/exit fixture")))
