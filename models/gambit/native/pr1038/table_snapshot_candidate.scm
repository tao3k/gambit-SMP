;; Candidate protocol only: no runtime binary or release admission.
(##include "~~lib/_gambit#.scm")
(c-declare "#include <string.h>")

(define candidate-copy-fields
  (c-lambda (scheme-object scheme-object) scheme-object #<<end-of-code
memmove(___BODY_AS(___arg2, ___tVECTOR),
        ___BODY_AS(___arg1, ___tSUBTYPED),
        ___HD_WORDS(___HEADER(___arg1)) * ___WS);
___result = ___arg2;
end-of-code
))

(define (##gc-hash-table-snapshot gcht)
  (##declare (not interrupts-enabled))
  (let ((snapshot (##make-vector (##gc-hash-table-length gcht))))
    (candidate-copy-fields gcht snapshot)))

(define (candidate-gc-hash-table-for-each proc gcht)
  (if (##gc-hash-table? gcht)
      (let ((snapshot (##gc-hash-table-snapshot gcht)))
        (let loop ((i (macro-gc-hash-table-key0)))
          (if (##fx< i (##vector-length snapshot))
              (let ((key (##vector-ref snapshot i)))
                (if (and (##not (##eq? key (macro-unused-obj)))
                         (##not (##eq? key (macro-deleted-obj))))
                    (proc key (##vector-ref snapshot (##fx+ i 1))))
                (loop (##fx+ i 2))))))))

(define ##gc-hash-table-for-each candidate-gc-hash-table-for-each)

(define (##gc-hash-table-search proc gcht)
  (if (##gc-hash-table? gcht)
      (let ((snapshot (##gc-hash-table-snapshot gcht)))
        (let loop ((i (macro-gc-hash-table-key0)))
          (and (##fx< i (##vector-length snapshot))
               (let ((key (##vector-ref snapshot i)))
                 (or (and (##not (##eq? key (macro-unused-obj)))
                          (##not (##eq? key (macro-deleted-obj)))
                          (proc key (##vector-ref snapshot (##fx+ i 1))))
                     (loop (##fx+ i 2)))))))
      #f))

(define (##gc-hash-table-foldl f base proc gcht)
  (if (##gc-hash-table? gcht)
      (let ((snapshot (##gc-hash-table-snapshot gcht)))
        (let loop ((i (macro-gc-hash-table-key0)) (base base))
          (if (##fx< i (##vector-length snapshot))
              (let ((key (##vector-ref snapshot i)))
                (loop (##fx+ i 2)
                      (if (and (##not (##eq? key (macro-unused-obj)))
                               (##not (##eq? key (macro-deleted-obj))))
                          (f base (proc key (##vector-ref snapshot (##fx+ i 1))))
                          base)))
              base)))
      base))

(define (##explode-gc-hash-table gcht)
  (let ((snapshot (##gc-hash-table-snapshot gcht)))
    (let loop ((i (macro-gc-hash-table-key0)) (key-vals '()))
      (if (##fx< i (##vector-length snapshot))
          (let ((key (##vector-ref snapshot i)))
            (loop (##fx+ i 2)
                  (if (and (##not (##eq? key (macro-unused-obj)))
                           (##not (##eq? key (macro-deleted-obj))))
                      (##cons (##cons key (##vector-ref snapshot (##fx+ i 1))) key-vals)
                      key-vals)))
          (##vector (##fxarithmetic-shift-right
                     (##fx- (##vector-length snapshot) (macro-gc-hash-table-key0)) 1)
                    (macro-gc-hash-table-flags snapshot)
                    (macro-gc-hash-table-count snapshot)
                    (macro-gc-hash-table-min-count snapshot)
                    (macro-gc-hash-table-free snapshot)
                    key-vals)))))
