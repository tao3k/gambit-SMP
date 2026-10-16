;;; Positive catalog composition only; no retry or runtime admission.
(def (make-composition-program dependencies)
  (ascent
    (relation protocol_dependency (child parent) dependencies)
    (relation composition_path (child parent))
    ((composition_path C P) <-- (protocol_dependency C P))
    ((composition_path C P) <-- (protocol_dependency C M) (composition_path M P))))

(define-evidence (make-composition-review dependencies)
  (make-composition-program dependencies))

(def (open-composition-actor dependencies workers)
  (gerbil-ascent-open-actor-session (make-composition-program dependencies) workers: workers))

(def (composition-rows result)
  ((.ref result 'rows-of) 'composition_path))

(def (run-composition-actor session)
  (composition-rows ((.ref session '.run))))

(def (run-composition-reference dependencies)
  (composition-rows (gerbil-ascent-evaluate-program (make-composition-program dependencies))))

(def (replace-composition-source session dependencies)
  ((.ref session '.replace-source!) 'protocol_dependency dependencies))

(def (close-composition-actor session)
  (gerbil-ascent-session-close! session))
