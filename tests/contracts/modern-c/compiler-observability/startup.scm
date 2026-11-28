;;; Diagnostic startup adapter for the existing compiled GSC procedures.
;;; Each wrapper delegates to the captured procedure and preserves all values.
(define f6-observe-sequence 0)
(define f6-observe-first-failure #f)
(define (f6-observe-event phase kind site)
  (set! f6-observe-sequence (+ f6-observe-sequence 1))
  (let ((port (current-error-port)))
    (display "GAMBIT-COMPILER-TRACE\tv1\t" port)
    (display phase port) (display "\t" port) (display kind port)
    (display "\t" port) (display f6-observe-sequence port)
    (display "\t0\t" port) (display site port) (newline port)
    (force-output port)))
(define (f6-observe-procedure original phase site)
  (lambda args
    ;; The native command driver installs its formal-prelude wrap-program
    ;; after startup. Observe that installed closure when compilation begins.
    (if (string=? phase "compile")
        (f6-observe-install 'c#wrap-program "wrap-program"))
    (if (string=? phase "parse")
        (f6-observe-install 'c#target.dump "c-emission"))
    (f6-observe-event phase "enter" site)
    (with-exception-catcher
     (lambda (exception)
       (if (not f6-observe-first-failure)
           (begin
             (set! f6-observe-first-failure phase)
             (f6-observe-event phase "raise" site)))
       (raise exception))
     (lambda ()
       (call-with-values
        (lambda () (apply original args))
        (lambda results
          (f6-observe-event phase "return" site)
          (apply values results)))))))
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
   (c#targ-dump "c-emission")))
