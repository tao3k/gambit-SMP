;; Diagnostic regression workload, not an instrumented rollover witness.
;; The campaign supplies host capacity and source-derived stack depth.
(define (require condition message)
  (if (not condition) (error message)))

(define (positive-environment name)
  (let* ((text (getenv name #f))
         (value (and text (string->number text))))
    (require (and value (integer? value) (exact? value) (> value 0)) name)
    value))

(define processors (positive-environment "GAMBIT_SMP_AVAILABLE_CPUS"))
(define depth (positive-environment "GAMBIT_SMP_CONTINUATION_DEPTH"))
(define gate (make-mutex))
(define parked (make-condition-variable))
(define released (make-condition-variable))
(define arrived 0)
(define release? #f)

(define (park!)
  (mutex-lock! gate)
  (set! arrived (+ arrived 1))
  (condition-variable-signal! parked)
  (let wait ()
    (if (not release?)
        (begin
          (mutex-unlock! gate released)
          (mutex-lock! gate)
          (wait))))
  (mutex-unlock! gate)
  0)

(define (retained-stack remaining identity)
  (let ((payload (vector identity remaining)))
    (if (= remaining 0)
        (park!)
        ;; Work after the recursive return prevents a tail-call stack collapse.
        (let ((answer (retained-stack (- remaining 1) identity)))
          (require (= (vector-ref payload 0) identity) "retained owner corruption")
          (require (= (vector-ref payload 1) remaining) "retained depth corruption")
          (+ answer 1)))))

(require (>= processors 2) "parallel GC requires at least two available CPUs")
(##current-vm-resize ##startup-processor! processors)
(require (= (##current-vm-processor-count) processors) "processor cohort mismatch")

(define workers
  (let build ((index 0))
    (if (= index processors)
        '()
        (let ((worker
                (make-thread
                  (lambda ()
                    (require (= (processor-id (current-processor)) index)
                             "worker processor mismatch")
                    (retained-stack depth index)))))
          (##thread-pin! worker (##processor index))
          (cons worker (build (+ index 1)))))))

(for-each thread-start! workers)
(mutex-lock! gate)
(let wait ()
  (if (< arrived processors)
      (begin
        (mutex-unlock! gate parked)
        (mutex-lock! gate)
        (wait))))
(mutex-unlock! gate)

;; Workers retain their saved stacks while the coordinator initiates collection.
(##gc)
(##gc)

(mutex-lock! gate)
(set! release? #t)
(condition-variable-broadcast! released)
(mutex-unlock! gate)
(for-each
  (lambda (worker)
    (require (= (thread-join! worker) depth) "continuation result corruption"))
  workers)
(##current-vm-resize ##startup-processor! 1)
(require (= (##current-vm-processor-count) 1) "processor cohort did not drain")
(display "CONTINUATION-SAVED-STACK-PUBLIC:PASS\n")
