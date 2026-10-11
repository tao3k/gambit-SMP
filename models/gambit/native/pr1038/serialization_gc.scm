(include "serialization.scm")

;; Reuse the exact upstream text roundtrip while another processor requests GC.
;; All keys remain strongly rooted; concurrent mutation is not under test.
(let ((keys (make-vector 32))
      (table (make-table test: eq? init: 'missing)))
  (let add ((i 0))
    (if (< i (vector-length keys))
        (let ((key (vector i)))
          (vector-set! keys i key)
          (table-set! table key (+ i 100))
          (add (+ i 1)))))
  (let ((worker
         (make-thread
          (lambda ()
            (let collect ((i 0))
              (if (< i 64)
                  (begin (##gc) (thread-yield!) (collect (+ i 1)))
                  'collected))))))
    (if (> (##current-vm-processor-count) 1)
        (begin
          (##thread-pin! (current-thread) (##processor 0))
          (##thread-pin! worker (##processor 1))))
    (thread-start! worker)
    (let roundtrip ((round 0))
      (if (< round 40)
          (let* ((copy (text-roundtrip (vector keys table)))
                 (copy-keys (vector-ref copy 0))
                 (copy-table (vector-ref copy 1)))
            (test-equal 32 (table-length copy-table))
            (let check ((i 0))
              (if (< i (vector-length keys))
                  (begin
                    (test-equal (+ i 100) (table-ref copy-table (vector-ref copy-keys i)))
                    (check (+ i 1)))))
            (roundtrip (+ round 1)))))
    (test-equal 'collected (thread-join! worker))
    (if (> (##current-vm-processor-count) 1)
        (##thread-pin! (current-thread) #f))))
