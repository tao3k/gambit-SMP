;; Application policy; the Library owns identity, replay and frontier semantics.
(define-evidence (make-validation-progress)
  (sources progress_contract progress_active progress_cursor progress_sample
           progress_attested progress_completed watchdog_observation)
  (outputs progress_frontier progress_advanced progress_rejected
           watchdog_window watchdog_assessment)
  (include evidence-progress-fragment)
  (relation watchdog_window (seconds))
  (relation watchdog_observation (kind))
  (relation watchdog_assessment (kind))
  ;; An inactivity observation window, never a whole-run performance quota.
  (fact (watchdog_window (lit 300)))
  ((watchdog_assessment (lit "advancing")) <-- (progress_advanced _ _ _ _ _ _ _))
  ((watchdog_assessment (lit "observation-rejected")) <-- (progress_rejected _ _))
  ((watchdog_assessment (lit "no-admitted-progress-within-window")) <--
    (watchdog_observation (lit "inactivity-expired")))
  ((watchdog_assessment (lit "externally-interrupted")) <--
    (watchdog_observation (lit "external-interruption"))))
