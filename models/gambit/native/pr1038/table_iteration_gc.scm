(include "../#.scm")

;; A read-only callback may trigger moving GC and a lazy physical rehash.
;; It does not add, remove or replace any logical table entry.
(define keys
  (let loop ((n 32) (result '()))
    (if (= n 0) result (loop (- n 1) (cons (cons n n) result)))))
(define source (make-table test: eq?))
(for-each (lambda (key) (table-set! source key (car key))) keys)
(define visited '())
(table-for-each
 (lambda (key value)
   (##gc)
   (test-equal value (table-ref source key))
   (set! visited (cons key visited)))
 source)
(test-equal (length keys) (length visited))
(for-each
 (lambda (key)
   (test-equal 1 (length (filter (lambda (seen) (eq? seen key)) visited))))
 keys)
