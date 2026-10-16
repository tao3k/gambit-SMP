;;; Atomic diagnostic: unchanged upstream recursion and delay, host-sized roots.
;;; This is not the complete 5,000-root stress qualification.
(declare (standard-bindings) (block))

(define (positive-environment name)
  (let* ((text (getenv name #f))
         (value (and text (string->number text))))
    (if (not (and value (integer? value) (exact? value) (> value 0)))
        (error "positive host or workload parameter required" name))
    value))

(define processors (positive-environment "GAMBIT_SMP_AVAILABLE_CPUS"))
(define roots (* processors (positive-environment "GAMBIT_SMP_TFIB_ROOTS_PER_CPU")))
(if (not (= (positive-environment "GAMBIT_SMP_EXPECTED_PROCESSORS")
            (##current-vm-processor-count)))
    (error "framework processor population mismatch"))

(define (busy-sleep n) (if (> n 0) (busy-sleep (- n 1)) #f))
(define (short-delay) (busy-sleep 6000))

(define (tfib n)
  (short-delay)
  (if (< n 2)
      1
      (let* ((x (thread-start! (make-thread (lambda () (tfib (- n 2))))))
             (y (tfib (- n 1))))
        (+ (thread-join! x) y))))

(define (range i j)
  (let loop ((j (- j 1)) (lst '()))
    (if (< j i) lst (loop (- j 1) (cons j lst)))))

(define (go n repeat)
  (let ((threads (map (lambda (i) (make-thread (lambda () (tfib n))))
                      (range 0 repeat))))
    (for-each thread-start! threads)
    (map thread-join! threads)))

(define answers (go 15 roots))
(if (not (and (= (length answers) roots)
              (let loop ((rest answers))
                (or (null? rest)
                    (and (= (car rest) 987) (loop (cdr rest)))))))
    (error "atomic tfib result inventory or value mismatch"))
(display "TFIB-ATOMIC-COMPLETE\n")
