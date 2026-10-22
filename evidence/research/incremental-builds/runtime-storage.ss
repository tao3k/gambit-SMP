;;; Host byte/lease observations are not native correctness or execution advice.
(define-evidence (make-runtime-storage-observations)
  (sources runtime_storage_observation)
  (outputs recorded_runtime_storage)
  (relation runtime_storage_observation ((step string?) (mode string?)
    (source_content string?) (copied_files exact-integer?)))
  (relation recorded_runtime_storage (step mode source_content copied_files))
  ((recorded_runtime_storage S M I N) <-- (runtime_storage_observation S M I N)))
