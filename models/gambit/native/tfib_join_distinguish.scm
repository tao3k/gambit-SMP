;;; Staged thread-start/join on the participation runtime.
;;; Not (go 15 5000) and not native acceptance.
;;; Each line is flushed so a signal leaves the last completed stage.

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

(define (wave n repeat)
  (let ((threads (map (lambda (i) (make-thread (lambda () (tfib n))))
                      (iota repeat))))
    (for-each thread-start! threads)
    (map thread-join! threads)))

(say "STAGE leaf")
(let ((t (thread-start! (make-thread (lambda () 1)))))
  (say (number->string (thread-join! t))))

(say "STAGE overlap")
(let ((t (thread-start! (make-thread (lambda () (short-delay) 1)))))
  (short-delay)
  (say (number->string (thread-join! t))))

(say "STAGE wave-4x8")
(wave 4 8)

(say "STAGE gc")
(##gc)

(say "STAGE wave-6x20")
(wave 6 20)

(say "STAGE tfib-15")
(tfib 15)

(say "DISTINGUISH-JOIN-DONE")
