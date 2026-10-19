;;; Design references inform Gambit obligations; they cannot admit a candidate.
(define-evidence (make-parallel-gc-review)
  (sources design source obligation mechanism control satisfies
    source_section transfer_condition model_scope)
  (outputs comparison reference_requirement missing_requirement model_observation
    counterexample obligation_count transfer_evidence transfer_gap transfer_unbound)
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
  (relation source_section ((id string?) (source_id string?) (anchor string?) (observation string?)))
  (relation transfer_condition ((id string?) (axis string?) (reference_section string?)
    (gambit_section string?) (requirement string?)))
  (relation model_scope ((condition_id string?) (path string?) (sha string?)
    (coverage string?) (gap string?)))
  (relation comparison (axis gambit_choice reference reference_choice gambit_source reference_source))
  (relation reference_requirement (obligation_id reference reference_choice source_id))
  (relation missing_requirement (candidate obligation_id requirement))
  (relation model_observation (obligation_id control_id receipt))
  (relation counterexample (obligation_id control_id receipt))
  (relation obligation_count (count))
  (relation transfer_evidence (condition_id reference gambit_path gambit_sha gambit_anchor
    reference_path reference_sha reference_anchor requirement model_path model_sha coverage gap))
  (relation transfer_gap (condition_id reference requirement gap))
  (relation transfer_unbound (condition_id reason))
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
  ;; Reference correspondence exposes prerequisites, never satisfies or actions.
  ((transfer_evidence condition_id reference gambit_path gambit_sha gambit_anchor
      reference_path reference_sha reference_anchor requirement model_path model_sha coverage gap) <--
    (transfer_condition condition_id axis reference_section gambit_section requirement)
    (mechanism axis reference)
    (design reference axis _ reference_source)
    (source_section reference_section reference_source reference_anchor _)
    (source reference_source reference_path reference_sha _)
    (design (lit "gambit-baseline") axis _ gambit_source)
    (source_section gambit_section gambit_source gambit_anchor _)
    (source gambit_source gambit_path gambit_sha _)
    (model_scope condition_id model_path model_sha coverage gap))
  ((transfer_gap condition_id reference requirement gap) <--
    (transfer_evidence condition_id reference _ _ _ _ _ _ requirement _ _ _ gap))
  ((transfer_unbound condition_id (lit "reference-section-missing")) <--
    (transfer_condition condition_id _ reference_section _ _)
    (not (source_section reference_section _ _ _)))
  ((transfer_unbound condition_id (lit "gambit-section-missing")) <--
    (transfer_condition condition_id _ _ gambit_section _)
    (not (source_section gambit_section _ _ _)))
  ((transfer_unbound condition_id (lit "reference-source-missing")) <--
    (transfer_condition condition_id _ reference_section _ _)
    (source_section reference_section source_id _ _)
    (not (source source_id _ _ _)))
  ((transfer_unbound condition_id (lit "gambit-source-missing")) <--
    (transfer_condition condition_id _ _ gambit_section _)
    (source_section gambit_section source_id _ _)
    (not (source source_id _ _ _)))
  ((transfer_unbound condition_id (lit "model-scope-missing")) <--
    (transfer_condition condition_id _ _ _ _)
    (not (model_scope condition_id _ _ _ _)))
  ((transfer_unbound condition_id (lit "reference-design-missing")) <--
    (transfer_condition condition_id axis reference_section _ _)
    (source_section reference_section source_id _ _)
    (not (design _ axis _ source_id)))
  ((transfer_unbound condition_id (lit "gambit-design-missing")) <--
    (transfer_condition condition_id axis _ gambit_section _)
    (source_section gambit_section source_id _ _)
    (not (design (lit "gambit-baseline") axis _ source_id)))
  ((transfer_unbound condition_id (lit "mechanism-association-missing")) <--
    (transfer_condition condition_id axis reference_section _ _)
    (source_section reference_section source_id _ _)
    (design reference axis _ source_id)
    (not (mechanism axis reference)))
  ((obligation_count count) <--
    (aggregate count gerbil-ascent-count () (obligation id axis requirement))))
