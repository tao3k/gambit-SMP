(include "table_snapshot_candidate.scm")
;; Compiled core callers can retain their original internal procedure binding.
;; Route this diagnostic explicitly to the isolated candidate implementation.
(define (table-for-each proc table)
  (candidate-gc-hash-table-for-each proc (macro-table-gcht table))
  (if (##gc-hash-table? (macro-table-hash table))
      (candidate-gc-hash-table-for-each proc (macro-table-hash table))))
(include "table_iteration_gc.scm")
