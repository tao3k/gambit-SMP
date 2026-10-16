;;; Design references inform Gambit obligations; they cannot admit a candidate.
(define-evidence (make-parallel-gc-review)
  (sources design source obligation mechanism control satisfies)
  (outputs comparison reference_requirement missing_requirement model_observation
    counterexample obligation_count)
  (explain
    (lambda (program result query scope)
      (hash ("status" "recorded-only") ("query" query) ("scope" scope)
            ("dependencies" (.ref program 'rules))
            ("gap" "Finite controls and reference designs are not Gambit source refinement, native acceptance, performance or execution authorization"))))
  (relation design ((implementation string?) (axis string?) (choice string?) (source_id string?)))
  (relation source ((id string?) (path string?) (sha string?) (scope string?)))
  (relation obligation ((id string?) (axis string?) (requirement string?)))
  (relation mechanism ((axis string?) (reference string?)))
  (relation control ((id string?) (obligation_id string?) (outcome string?) (receipt string?)))
  ;; Only independently admitted same-candidate evidence may supply satisfies.
  ;; Finite model observations never derive it.
  (relation satisfies ((candidate string?) (obligation_id string?) (evidence_id string?)))
  (relation comparison (axis gambit_choice reference reference_choice gambit_source reference_source))
  (relation reference_requirement (obligation_id reference reference_choice source_id))
  (relation missing_requirement (candidate obligation_id requirement))
  (relation model_observation (obligation_id control_id receipt))
  (relation counterexample (obligation_id control_id receipt))
  (relation obligation_count (count))
  ((comparison axis gambit_choice reference reference_choice gambit_source reference_source) <--
    (design (lit "gambit-baseline") axis gambit_choice gambit_source)
    (mechanism axis reference)
    (design reference axis reference_choice reference_source)
    (source gambit_source _ _ _) (source reference_source _ _ _))
  ((reference_requirement obligation_id reference reference_choice source_id) <--
    (obligation obligation_id axis requirement) (mechanism axis reference)
    (design reference axis reference_choice source_id) (source source_id _ _ _))
  ((missing_requirement (lit "unbound-current-candidate") obligation_id requirement) <--
    (obligation obligation_id axis requirement)
    (not (satisfies (lit "unbound-current-candidate") obligation_id _)))
  ((model_observation obligation_id control_id receipt) <--
    (obligation obligation_id _ _) (control control_id obligation_id (lit "finite-pass") receipt))
  ((counterexample obligation_id control_id receipt) <--
    (obligation obligation_id _ _) (control control_id obligation_id (lit "decoded-counterexample") receipt))
  ((obligation_count count) <--
    (aggregate count gerbil-ascent-count () (obligation id axis requirement))))
