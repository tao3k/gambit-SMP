;;; Diagnostic startup adapter for the existing compiled GSC procedures.
;;; Each wrapper delegates to the captured procedure and preserves all values.
(define f6-observe-sequence 0)
(define f6-observe-first-failure #f)
(define f6-observe-enabled? #t)
(define f6-observe-clock (make-u64vector 1 0))
(define f6-observe-frequency
  (begin (##get-monotonic-time-frequency! f6-observe-clock 0)
         (u64vector-ref f6-observe-clock 0)))
(define (f6-observe-now)
  (##get-monotonic-time! f6-observe-clock 0)
  (u64vector-ref f6-observe-clock 0))
(define (f6-observe-record phase kind first second site)
  (set! f6-observe-sequence (+ f6-observe-sequence 1))
  (let ((port (current-error-port)))
    (display "GAMBIT-COMPILER-TRACE\tv1\t" port)
    (display phase port) (display "\t" port) (display kind port)
    (display "\t" port) (display first port)
    (display "\t" port) (display second port)
    (display "\t" port) (display site port) (newline port)
    (force-output port)))
(define (f6-observe-event phase kind site)
  (f6-observe-record phase kind (+ f6-observe-sequence 1) 0 site))
(define f6-observe-snapshot (lambda () #f))
(define (f6-observe-procedure original phase site)
  (lambda args
   (if (not f6-observe-enabled?) (apply original args)
    (begin
    ;; The native command driver installs its formal-prelude wrap-program
    ;; after startup. Observe that installed closure when compilation begins.
    (if (or (string=? phase "compile") (string=? phase "compiler-entry"))
        (f6-observe-install 'c#wrap-program "wrap-program"))
    (if (string=? phase "parse")
        (f6-observe-install 'c#target.dump "c-emission"))
    (f6-observe-snapshot)
    (f6-observe-event phase "enter" site)
    (let ((started (f6-observe-now)) (call-id f6-observe-sequence))
     (define (elapsed)
       (f6-observe-record phase "elapsed-ns"
        (quotient (* (- (f6-observe-now) started) 1000000000)
                  f6-observe-frequency) call-id site)
       (f6-observe-snapshot))
     (with-exception-catcher
     (lambda (exception)
       (if (not f6-observe-first-failure)
           (begin
             (set! f6-observe-first-failure phase)
             (f6-observe-event phase "raise" site)))
       (elapsed)
       (raise exception))
     (lambda ()
       (call-with-values
        (lambda () (apply original args))
        (lambda results
          (f6-observe-event phase "return" site)
          (elapsed)
          (apply values results))))))))))
(define (f6-observe-install symbol phase)
  (let ((site (symbol->string symbol)))
    (with-exception-catcher
     (lambda (exception) (f6-observe-event phase "unavailable" site))
     (lambda ()
       (if (procedure? (eval symbol))
           (begin
             (eval (list 'set! symbol
                         (list 'f6-observe-procedure symbol phase site)))
             (f6-observe-event phase "installed" site))
           (f6-observe-event phase "unavailable" site))))))
(for-each
 (lambda (entry) (f6-observe-install (car entry) (cadr entry)))
 '((c#cf "compiler-entry")
   (c#compile-program "compile")
   (c#compile-frontend "frontend")
   (c#read-source "read-source")
   (c#wrap-program "wrap-program")
   (c#parse-program "parse")
   (c#normalize-program "normalize")
   (c#compile-parsed-program "gvm")
   (c#make-bbs "gvm-bbs")
   (c#purify-procs "gvm-purify")
   (c#targ-dump "c-emission")))
