(include "../#.scm")

(c-declare #<<end-of-code
static int cancel_flags[2] = {0, 0};
static unsigned long long cancel_payload_before = 0;
end-of-code
)
(define announce!
  (c-lambda (int) void
    "__atomic_store_n(&cancel_flags[___arg1], 1, __ATOMIC_RELEASE);"))
(define announced?
  (c-lambda (int) bool
    "___return(__atomic_load_n(&cancel_flags[___arg1], __ATOMIC_ACQUIRE) != 0);"))
(define remember-address!
  (c-lambda (scheme-object) void
    "cancel_payload_before = (unsigned long long)___arg1;"))
(define relocated?
  (c-lambda (scheme-object) bool
    "___return(cancel_payload_before != (unsigned long long)___arg1);"))
(define returned? #f)
(define calls 0)

(define (await! flag)
  (let loop ()
    (if (not (announced? flag)) (begin (thread-yield!) (loop)))))

(define (await-requester-blocked! requester target)
  (declare (not inline))
  (let loop ()
    (let ((state (thread-state requester)))
      (if (and (thread-state-waiting? state)
               (mutex? (thread-state-waiting-for state)))
          (begin
            (test-eq target (mutex-state (thread-state-waiting-for state)))
            (test-eq target (mutex-specific (thread-state-waiting-for state)))
            (void))
          (begin (thread-yield!) (loop))))))

(cond-expand
 (enable-smp
  (if (< (##current-vm-processor-count) 2)
      (error "cancellation/GC fixture requires distinct processors"))
  (let* ((home (current-processor))
         (peer-id (modulo (+ (##current-processor-id) 1)
                          (##current-vm-processor-count)))
         (gate (make-mutex))
         (target (make-thread
                  (lambda ()
                    (mutex-lock! gate)
                    (mutex-unlock! gate)
                    'target-finished)))
         (requester
          (make-thread
           (lambda ()
             (##thread-intr!
              target #f
              (lambda ()
                (set! calls (+ calls 1))
                (let ((payload (make-vector 32 42)))
                  (remember-address! payload)
                  (##gc)
                  (test-assert (relocated? payload))
                  (announce! 0)
                  (await! 1)
                  (test-equal 32 (vector-length payload))
                  (test-equal 42 (vector-ref payload 31))
                  payload)))
             (set! returned? #t)))))
    (mutex-lock! gate)
    (##thread-pin! target (##processor peer-id))
    (##thread-pin! requester home)
    (thread-start! target)
    (thread-start! requester)
    (await! 0)
    (await-requester-blocked! requester target)
    (test-assert (not returned?))
    (thread-terminate! requester)
    (test-error terminated-thread-exception? (thread-join! requester))
    (test-assert (not returned?))
    ;; The receiver still owns the executing callback after its waiter exits.
    (##gc)
    (announce! 1)
    (mutex-unlock! gate)
    (test-eq 'target-finished (thread-join! target))
    (test-equal 1 calls)
    (test-assert (not returned?))
    (##gc)
    (test-assert (not returned?)))
  (if ##failed-test? (exit 1))
  (display "INTERRUPT-REQUESTER-CANCEL-GC-OK\n"))
 (else (error "SMP required for requester cancellation fixture")))
