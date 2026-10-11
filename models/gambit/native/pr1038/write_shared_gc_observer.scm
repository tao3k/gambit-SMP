;; Diagnostic wrapper: retains all upstream assertions and reports real GC count.
(println "GC-BEFORE:" (f64vector-ref (##process-statistics) 6))
(include "../09-io/write_shared.scm")
(println "GC-AFTER:" (f64vector-ref (##process-statistics) 6))
