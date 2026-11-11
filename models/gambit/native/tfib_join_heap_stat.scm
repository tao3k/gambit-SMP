;;; Heap statistics around small tfib(15) waves on the participation runtime.
;;; Not (go 15 5000) and not the four-file inventory.
;;; Each line is flushed. A later fatal overflow leaves the last STAT line.

(declare (standard-bindings) (block))

(define (say s)
  (display s)
  (newline)
  (force-output))

(define (iota n)
  (let loop ((i (- n 1)) (lst '()))
    (if (< i 0) lst (loop (- i 1) (cons i lst)))))

(define (busy-sleep n)
  (if (> n 0) (busy-sleep (- n 1)) #f))

(define (short-delay) (busy-sleep 6000))

(define (tfib n)
  (short-delay)
  (if (< n 2)
      1
      (let* ((x (thread-start! (make-thread (lambda () (tfib (- n 2))))))
             (y (tfib (- n 1))))
        (+ (thread-join! x) y))))

(define (go n repeat)
  (let ((threads (map (lambda (i) (make-thread (lambda () (tfib n))))
                      (iota repeat))))
    (for-each thread-start! threads)
    (map thread-join! threads)))

(define (stat tag)
  (let ((v (##process-statistics)))
    (say (string-append
          "STAT " tag
          " nb-gcs " (number->string (f64vector-ref v 6))
          " heap " (number->string (f64vector-ref v 15))
          " alloc " (number->string (f64vector-ref v 16))
          " live " (number->string (f64vector-ref v 17))
          " movable " (number->string (f64vector-ref v 18))
          " still " (number->string (f64vector-ref v 19))))))

(stat "base")
(say "STAGE go-15x4")
(go 15 4)
(stat "after-4")
(##gc)
(stat "after-4-gc")
(say "STAGE go-15x8")
(go 15 8)
(stat "after-8")
(say "STAGE go-15x16")
(go 15 16)
(stat "after-16")
(say "HEAP-STAT-DONE")
