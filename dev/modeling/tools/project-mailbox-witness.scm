;;; Read the real SMP definition. Change only definition binding and one
;;; scheduling point after next3 is read. No handwritten queue implementation.
(define source (getenv "MAILBOX_SOURCE"))
(define output (getenv "MAILBOX_PROJECTION"))
(define template (getenv "MAILBOX_TEMPLATE"))
(define definition
  (call-with-input-file source
    (lambda (p)
      (let* ((top (read p)) (forms (cdr (cadr top))))
        (let loop ((fs forms))
          (cond ((null? fs) (error "SMP receive definition missing"))
                ((and (pair? (car fs)) (eq? (caar fs) 'define-prim)
                      (pair? (cadar fs))
                      (eq? (caadar fs) '##thread-mailbox-next-or-receive)) (car fs))
                (else (loop (cdr fs)))))))))
(define points 0)
(define (project tree)
  (if (not (pair? tree)) tree
      (if (and (= points 0) (eq? (car tree) 'let)
               (pair? (cdr tree))
               (equal? (cadr tree) '((next3 (macro-fifo-next next2)))))
          (begin (set! points (+ points 1))
                 (cons 'let (cons (cadr tree)
                                  (cons '(gambit#tests#smp#scheduler#interleave#handoff)
                                        (cddr tree)))))
          (cons (project (car tree)) (project (cdr tree))))))
(define projected
  (cons 'define
        (cons (cons 'gambit#tests#smp#scheduler#interleave#receive (cdadr definition))
              (project (cddr definition)))))
(if (not (= points 1)) (error "one source scheduling point required" points))
(call-with-output-file (string-append output ".source.scm")
  (lambda (p) (write (list (cons 'source source) (cons 'original definition)
                          (cons 'projected projected) (cons 'inserted-points points)) p) (newline p)))
(call-with-output-file output
  (lambda (p)
    (for-each (lambda (f) (write (list '##include f) p) (newline p))
              '("~~lib/_gambit#.scm" "~~lib/_thread#.scm" "~~lib/_fifo#.scm"))
    (write projected p) (newline p)
    (call-with-input-file template
      (lambda (in)
        (let loop ((form (read in)))
          (if (not (eof-object? form))
              (begin (write form p) (newline p) (loop (read in)))))))))
