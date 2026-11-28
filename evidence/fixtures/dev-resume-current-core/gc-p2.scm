;;; A two-processor smoke diagnostic, not a barrier or allocation census.
(declare (standard-bindings) (block))

(if (not (= (##current-vm-processor-count) 1))
    (error "expected single initial processor"))
(if (not (= (##current-vm-resize-ready ##startup-processor! 2) 0))
    (error "two-processor startup failed"))
(if (not (= (##current-vm-processor-count) 2))
    (error "two-processor cohort not observed"))

(define (check actual expected)
  (if (not (equal? actual expected))
      (error "GC or continuation result mismatch" actual expected)))

(define worker
  (make-thread
   (lambda ()
     (let ((x 40))
       (let ((read-x (lambda () x)))
         (##gc)
         (set! x (+ x 2))
         (##gc)
         (read-x))))))
(thread-start! worker)
(check (thread-join! worker) 42)

(check
 (eval
  '(let ((saved #f) (round 0) (seen '()))
     (let ((x 10))
       (call-with-current-continuation (lambda (k) (set! saved k) #f))
       (set! seen (cons x seen))
       (set! x (+ x 1))
       (cond ((= round 0) (set! round 1) (##gc) (saved #f))
             ((= round 1) (set! round 2) (##gc) (saved #f))
             (else (reverse seen))))))
 '(10 11 12))

(display "CURRENT-CORE-P2-GC-CONTINUATION-SMOKE-PASS\n")
