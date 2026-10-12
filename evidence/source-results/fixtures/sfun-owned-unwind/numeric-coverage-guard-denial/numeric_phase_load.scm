;; A -c target named probe exports probe, not the dynamic filename probe.o1.
(define module-path (##getenv "GAMBIT_SMP_PHASE_MODULE" #f))
(if (not module-path) (error "missing identified numeric module"))
(##load module-path (lambda (script path) #f) #t #t "probe" #f)
;; The upstream fixture records failed assertions and changes implicit exit codes.
;; Check that state explicitly; never turn its implicit success exit1 into a fail.
(if (or ##failed-test? (null? ##tested-procs))
    (exit 2)
    (begin
      (display "NUMERIC-PHASE:failed=#f,procedure-records=")
      (display (length ##tested-procs))
      (newline)
      (display "NATIVE-OK:numeric_phase_load\n")
      (exit 0)))
