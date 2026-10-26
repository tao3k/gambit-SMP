;;; Full multi-shot continuation; GC separates each restoration and wind pair.
(define saved #f)
(define shot 0)
(define events '())
(define payload (vector (make-string 256 #\p)))
(define (record event) (set! events (cons event events)))
(define (exercise)
  (let ((answer
         (dynamic-wind
          (lambda () (record 'enter))
          (lambda ()
            (call-with-current-continuation
             (lambda (k) (set! saved k) 'first)))
          (lambda () (record 'leave)))))
    (if (not (= (string-length (vector-ref payload 0)) 256))
        (error "resume root lost"))
    (cond ((= shot 0) (set! shot 1) (##gc) (saved 'second))
          ((= shot 1) (set! shot 2) (##gc) (saved 'third))
          (else
           (if (not (and (eq? answer 'third)
                         (equal? (reverse events)
                                 '(enter leave enter leave enter leave))))
               (error "multi-shot winding mismatch" answer events))
           (display "WIND-RESUME-GC-PASS shots=3\n")))))
(exercise)
