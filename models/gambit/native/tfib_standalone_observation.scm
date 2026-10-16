;;; Same workload as the pinned upstream tfib_stress.scm, with final checks.
;;; Processor population is selected by the framework, not this fixture.

(declare (standard-bindings) (block))

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

(define answers (go 15 5000))
(if (not (and (= (length answers) 5000)
              (let loop ((rest answers))
                (or (null? rest)
                    (and (= (car rest) 987) (loop (cdr rest)))))))
    (error "tfib result inventory or value mismatch"))
(display "TFIB-WORKLOAD-COMPLETE\n")
