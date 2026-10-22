;;; Ramp of the original tfib(15) join tree. Not the four-file inventory.
;;; repeat 5000 is the retained stress and is not launched here.
;;; Flushed stage lines leave the last count that returned.

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

(say "STAGE go-15x4")
(go 15 4)
(say "STAGE go-15x32")
(go 15 32)
(say "STAGE go-15x256")
(go 15 256)
(say "STAGE go-15x1024")
(go 15 1024)
(say "SCALE-DONE")
