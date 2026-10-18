;; Routing is registered data. It neither schedules work nor qualifies evidence.
(define-evidence (make-history-storage)
  (sources)
  (outputs location)
  (relation location (path) '((".state/reasoning/history.sqlite3"))))
