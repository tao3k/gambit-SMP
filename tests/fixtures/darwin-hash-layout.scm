;; GC must preserve the hash/test owner's layout and immediate key tags.
;; Run with the source-built GSI and the declared single-processor compiler
;; budget. This control does not qualify concurrent mutation of one table.
(define (numbers n)
  (let loop ((n n) (xs '()))
    (if (= n 0) xs (loop (- n 1) (cons (- n 1) xs)))))

(define keys
  (append (numbers 40)
          (map (lambda (n) (string->symbol (number->string n))) (numbers 40))
          (list #f #t '() #\x -1 4294967294)))

(define (check label test hash)
  (let ((table (if hash
                   (make-table size: 101 test: test hash: hash)
                   (make-table size: 101 test: test))))
    (for-each (lambda (key) (table-set! table key 123)) keys)
    ;; A second collection detects immediate keys retagged by the first one.
    (##gc)
    (##gc)
    (for-each
     (lambda (key)
       (if (not (eqv? (table-ref table key #f) 123))
           (begin (write (list 'HASH-LAYOUT-FAIL label key))
                  (newline)
                  (exit 1))))
     keys)
    (for-each (lambda (key) (table-set! table key 456)) keys)
    (##gc)
    (for-each
     (lambda (key) (if (not (eqv? (table-ref table key #f) 456)) (exit 1)))
     keys)
    (write (list 'HASH-LAYOUT-PASS label (length keys)))
    (newline)))

(check 'equal equal? #f)
(check 'custom equal? (lambda (key) 17))
(check 'eq eq? #f)
(display "DARWIN-HASH-LAYOUT-PASS\n")
