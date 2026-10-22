;;; Separate a 5000-thread trivial join from one (go 15 32) wave.
;;; Not the four-file inventory. Flushed lines leave the last completed stage.
;;; A one-second statistics thread runs during the depth-15 wave.

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

(define (go-value repeat)
  (let ((threads (map (lambda (i) (make-thread (lambda () 1)))
                      (iota repeat))))
    (for-each thread-start! threads)
    (map thread-join! threads)))

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
          " live " (number->string (f64vector-ref v 17))))))

(define (watch)
  (let loop ((i 0))
    (stat (number->string i))
    (thread-sleep! 1)
    (loop (+ i 1))))

(say "STAGE trivial-5000")
(go-value 5000)
(say "STAGE trivial-done")
(say "STAGE go-15x4")
(go 15 4)
(say "STAGE go-15x32")
(thread-start! (make-thread watch))
(go 15 32)
(say "BURST-DONE")
