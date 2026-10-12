;; A -c target named probe exports probe, not the dynamic filename probe.o1.
(define module-path (##getenv "GAMBIT_SMP_PHASE_MODULE" #f))
(if (not module-path) (error "missing identified numeric module"))
(##eval '(define ##failed-test? 'numeric-module-not-executed))
;; Fault control: module was not executed.
;; The upstream fixture records failed assertions and changes implicit exit codes.
;; Check that state explicitly; never turn its implicit success exit1 into a fail.
(if (not (eq? ##failed-test? #f))
    (exit 2)
    (begin
      (display "NUMERIC-PHASE:failed=#f,procedure-records=")
      (display (length ##tested-procs))
      (newline)
      (display "NATIVE-OK:numeric_phase_load\n")
      (exit 0)))
