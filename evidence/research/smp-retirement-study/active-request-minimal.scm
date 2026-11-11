;; Evidence fixture only. Not executed by this audit. Use the same frozen B.
;; SMP_ACTIVE_CASE=yield|nested|migrate. Existing focused outer cap:30 seconds.
(define test-case (or (getenv "SMP_ACTIVE_CASE" #f) "yield"))
(define flags (vector #f #f #f #f)) ;; stop,A-entered,B-done,A-returned
(define counts (vector 0 0))
(define a-value #f)
(define a-error #f)
(define (set-flag! i) (##vector-cas! flags i #t #f))
(define (flag? i) (eq? (##vector-cas! flags i #t #t) #t))
(define (event x) (write x) (newline) (force-output))
(define (await i) (let loop () (if (not (flag? i)) (begin (thread-yield!) (loop)))))
(define target
  (make-thread
   (lambda () (let loop () (if (not (flag? 0)) (begin (thread-yield!) (loop)))))
   'active-target))
(define (thunk-a)
  (##vector-inc! counts 0 1)
  (event (list 'A-ENTER (vector-ref counts 0)))
  (if (not (= (vector-ref counts 0) 1)) (error "duplicate runtime invocation of A"))
  (set-flag! 1)
  (cond ((equal? test-case "nested") (await 2))
        ((equal? test-case "migrate")
         ;; Only with original p11 topology; both IDs must be admitted.
         (##thread-migrate-to! 1)
         (thread-yield!)
         (##thread-migrate-to! 0))
        (else (thread-yield!) (thread-yield!)))
  41)
(define sender-a
  (make-thread
   (lambda ()
     (with-exception-catcher
      (lambda (e) (set! a-error e) (set-flag! 3))
      (lambda ()
        (set! a-value (thread-interrupt! target thunk-a))
        (set-flag! 3))))
   'active-sender))
(with-exception-catcher
 (lambda (e) (event (list 'CONTROL-FAIL e)) (exit 70))
 (lambda ()
   (if (not (or (equal? test-case "yield") (equal? test-case "nested")
                (equal? test-case "migrate")))
       (error "unsupported fixture case" test-case))
   (thread-start! target)
   (thread-start! sender-a)
   (await 1)
   (if (equal? test-case "nested")
       (let ((b-value
              (thread-interrupt!
               target
               (lambda ()
                 (##vector-inc! counts 1 1)
                 (event (list 'B-ENTER (vector-ref counts 1)))
                 (set-flag! 2)
                 42))))
         (if (not (= b-value 42)) (error "wrong B result" b-value))))
   (await 3)
   (if a-error (error "sender A failed" a-error))
   (if (not (and (= a-value 41) (= (vector-ref counts 0) 1)
                 (= (vector-ref counts 1) (if (equal? test-case "nested") 1 0))))
       (error "wrong result or invocation counts" a-value counts))
   (event (list 'COUNTERS-OK test-case a-value counts))
   (set-flag! 0)
   ;; Cleanup failures are reported, never swallowed to turn a partial control green.
   (thread-join! sender-a)
   (thread-join! target)
   (event (list 'CONTROL-PASS test-case))
   (exit 0)))
