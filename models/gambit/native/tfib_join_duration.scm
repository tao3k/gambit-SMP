;;; Same (go 15 5000) body as tests/unit-tests/06-thread/tfib_stress.scm.
;;; One flushed line before the call and one after. Not the four-file suite.
;;; A startup fault would leave only the start line.

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

(display "TFIB-5000-START")
(newline)
(force-output)
(go 15 5000)
(display "TFIB-5000-DONE")
(newline)
(force-output)
