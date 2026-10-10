;; Targeted public-API check, not a replacement for the full table suite.
(define (require-equal expected actual)
  (if (not (equal? expected actual)) (error "table decode mismatch" expected actual)))

(define (text-roundtrip object)
  (with-input-from-string
    (with-output-to-string ""
      (lambda ()
        (output-port-readtable-set! (current-output-port)
          (readtable-sharing-allowed?-set
            (output-port-readtable (current-output-port)) 'serialize))
        (write object)))
    read))

(define (check roundtrip format predicate comparison force-gc?)
  (write (list 'CASE format comparison 'forced-gc force-gc?))
  (newline)
  (force-output)
  (let ((keys (vector 'alpha 123 #f #\a "heap-key" '(1 2) '#(3 4)))
        (table (make-table test: predicate init: 'missing)))
    (do ((i 0 (+ i 1))) ((= i (vector-length keys)))
      (table-set! table (vector-ref keys i) (+ i 100)))
    (let* ((copy (roundtrip (vector keys table)))
           (copy-keys (vector-ref copy 0))
           (copy-table (vector-ref copy 1)))
      (if force-gc? (do ((i 0 (+ i 1))) ((= i 5)) (##gc)))
      (require-equal 7 (table-length copy-table))
      (do ((i 0 (+ i 1))) ((= i 7))
        (let ((actual (table-ref copy-table (vector-ref copy-keys i))))
          (if (not (equal? (+ i 100) actual))
              (error "table decode mismatch" format comparison force-gc? i
                     actual (table->list copy-table) copy-keys))))
      (table-set! copy-table 'alpha 'updated)
      (require-equal 'updated (table-ref copy-table 'alpha))
      (table-set! copy-table 123)
      (require-equal 'missing (table-ref copy-table 123))
      (do ((i 0 (+ i 1))) ((= i 100)) (table-set! copy-table (+ i 1000) i))
      (do ((i 0 (+ i 1))) ((= i 100))
        (require-equal i (table-ref copy-table (+ i 1000)))))))

(for-each
  (lambda (roundtrip format)
    (for-each
      (lambda (predicate comparison)
        (check roundtrip format predicate comparison #f)
        (check roundtrip format predicate comparison #t))
      (list eq? eqv? equal?) (list 'eq 'eqv 'equal)))
  (list text-roundtrip (lambda (object) (u8vector->object (object->u8vector object))))
  (list 'text 'binary))
(display "NATIVE-OK:table_decode\n")
