(include "../#.scm")

(c-declare #<<end-of-code
static int cancel_flags[4] = {0, 0, 0, 0};
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
(define throw-after-cancel?
  (member "throw-after-cancel" (cdr (command-line))))
(define terminate-after-cancel?
  (member "terminate-after-cancel" (cdr (command-line))))
(define external-terminate-after-cancel?
  (member "external-terminate-after-cancel" (cdr (command-line))))
(if (> (+ (if throw-after-cancel? 1 0)
          (if terminate-after-cancel? 1 0)
          (if external-terminate-after-cancel? 1 0)) 1)
    (error "callback outcomes must be selected independently"))

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
                  (cond (external-terminate-after-cancel?
                         (announce! 2)
                         (await! 3)
                         (error "externally terminated callback resumed"))
                        (terminate-after-cancel?
                         (thread-terminate! (current-thread))
                         (error "terminated callback resumed"))
                        (throw-after-cancel?
                         (error "callback failure after requester cancellation"))
                        (else payload)))))
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
    (if external-terminate-after-cancel?
        (begin
          (await! 2)
          ;; This synchronous external request owns a second result mutex.
          (thread-terminate! target)))
    (mutex-unlock! gate)
    (cond ((or terminate-after-cancel? external-terminate-after-cancel?)
           (test-error terminated-thread-exception? (thread-join! target)))
          (throw-after-cancel?
           (test-error uncaught-exception? (thread-join! target)))
          (else (test-eq 'target-finished (thread-join! target))))
    (test-equal 1 calls)
    (test-assert (not returned?))
    (##gc)
    (test-assert (not returned?)))
  (if ##failed-test? (exit 1))
  (display "INTERRUPT-REQUESTER-CANCEL-GC-OK\n"))
 (else (error "SMP required for requester cancellation fixture")))
