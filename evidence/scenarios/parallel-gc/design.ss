;;; Design references inform Gambit obligations; they cannot admit a candidate.
(define-evidence (make-parallel-gc-review)
  (sources design source obligation mechanism control satisfies
    source_section transfer_condition model_scope transfer_premise
    composition_edge model_interface interface_check composition_binding composition_attribute composition_profile)
  (outputs comparison reference_requirement missing_requirement model_observation
    counterexample obligation_count transfer_evidence transfer_gap transfer_unbound
    transfer_premise_evidence composition_requirement composition_model_evidence
    composition_link composition_gap clue factor link inventory)
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
  (relation transfer_premise ((condition_id string?) (section_id string?)
    (finding string?) (unclosed string?)))
  ;; Domain observations introduce relational obligations, not an Agent plan.
  ;; A finite check is evidence for an interface, not a source refinement.
  (relation composition_edge ((id string?) (condition_id string?) (scope_id string?)
    (from_section string?) (to_section string?) (property string?)))
  (relation model_interface ((source_id string?) (property string?)))
  (relation interface_check ((source_id string?) (sha string?) (property string?)
    (receipt_section string?) (receipt_sha string?)))
  (relation composition_binding ((condition_id string?) (scope_id string?)
    (from_section string?) (to_section string?) (property string?)
    (from_sha string?) (to_sha string?) (model_source string?) (model_sha string?)
    (refinement_section string?) (refinement_sha string?)))
  (relation composition_attribute ((condition_id string?) (name string?) (value string?)))
  (relation composition_profile ((condition_id string?) (source_id string?)))
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
  (relation transfer_premise_evidence (condition_id section_id path sha anchor finding unclosed))
  (relation composition_requirement (condition_id scope_id from_section to_section property))
  (relation composition_capability (property))
  (relation composition_checked_interface (model property))
  (relation composition_unchecked_interface (model property))
  (relation composition_checked_property (property))
  (relation composition_model_evidence (property model_path model_sha receipt_path receipt_sha receipt_anchor))
  (relation composition_link (condition_id scope_id from_section to_section property model_path model_sha refinement_path refinement_sha))
  (relation composition_gap (condition_id scope_id from_section to_section property reason))
  (relation composition_identity (id condition_id scope_id from_section to_section property))
  (relation composition_identity_conflict (id))
  (relation clue (id digest claim polarity role source))
  (relation factor (id digest name value))
  (relation link (claim target label id digest))
  (relation inventory (name value))
  ((composition_identity_conflict I) <--
    (composition_edge I C S F T P) (composition_edge I C2 S2 F2 T2 P2)
    (if (C S F T P C2 S2 F2 T2 P2)
      (not (and (equal? C C2) (equal? S S2) (equal? F F2)
                (equal? T T2) (equal? P P2)))))
  ((composition_identity I C S F T P) <--
    (composition_edge I C S F T P) (not (composition_identity_conflict I)))
  ((composition_requirement condition scope from to property) <--
    (composition_edge _ condition scope from to property))
  ((composition_gap C S F T P (lit "ambiguous-clue-identity")) <--
    (composition_edge I C S F T P) (composition_identity_conflict I))
  ((composition_capability property) <--
    (model_interface model property) (source model _ _ _))
  ((composition_model_evidence property model_path sha receipt_path receipt_sha anchor) <--
    (model_interface model property) (source model model_path sha _)
    (interface_check model sha property receipt_section receipt_sha)
    (source_section receipt_section receipt_source anchor _)
    (source receipt_source receipt_path receipt_sha _))
  ((composition_checked_interface model property) <--
    (model_interface model property) (source model path sha _)
    (composition_model_evidence property path sha _ _ _))
  ((composition_unchecked_interface model property) <--
    (model_interface model property) (not (composition_checked_interface model property)))
  ((composition_checked_property property) <--
    (composition_capability property) (not (composition_unchecked_interface _ property)))
  ((composition_link condition scope from to property model_path sha refinement_path refinement_sha) <--
    (composition_requirement condition scope from to property)
    (composition_binding condition scope from to property from_sha to_sha model sha refinement refinement_sha)
    (composition_checked_property property)
    (source model model_path sha _)
    (composition_model_evidence property model_path sha _ _ _)
    (source_section from from_source _ _) (source from_source _ from_sha _)
    (source_section to to_source _ _) (source to_source _ to_sha _)
    (source_section refinement refinement_source _ _)
    (source refinement_source refinement_path refinement_sha _))
  ((composition_gap condition scope from to property (lit "model-interface-unbound")) <--
    (composition_requirement condition scope from to property)
    (not (composition_capability property)))
  ((composition_gap condition scope from to property (lit "model-check-unbound-or-stale")) <--
    (composition_requirement condition scope from to property)
    (composition_capability property)
    (not (composition_checked_property property)))
  ((composition_gap condition scope from to property (lit "source-composition-unbound")) <--
    (composition_requirement condition scope from to property)
    (composition_checked_property property)
    (not (composition_link condition scope from to property _ _ _ _)))
  ;; Feed the existing discovery/slicing outputs; no new CLI or Python logic.
  ((transfer_gap condition scope property reason) <--
    (composition_gap condition scope _ _ property reason))
  ((transfer_premise_evidence condition from path sha anchor property reason) <--
    (composition_gap condition _ from _ property reason)
    (source_section from source_id anchor _) (source source_id path sha _))
  ((clue I D I (lit "support") (lit "observation") Path) <--
    (composition_identity I C S F T P) (composition_gap C S F T P _)
    (composition_profile C Profile) (source Profile Path D _))
  ((factor I D (lit "scope") S) <--
    (composition_identity I C S F T P) (clue I D I _ _ _))
  ((factor I D (lit "property") P) <--
    (composition_identity I C S F T P) (clue I D I _ _ _))
  ((factor I D (lit "unresolved-premise") Reason) <--
    (composition_identity I C S F T P) (clue I D I _ _ _)
    (composition_gap C S F T P Reason))
  ((factor I D N V) <--
    (composition_identity I C _ _ _ _) (clue I D I _ _ _)
    (composition_attribute C N V))
  ((link I Source (lit "observation-source") I D) <--
    (composition_identity I C S F T P) (clue I D I _ _ _)
    (source_section F Source _ _))
  ((link I Source (lit "following-source") I D) <--
    (composition_identity I C S F T P) (clue I D I _ _ _)
    (source_section T Source _ _))
  ((link I Model (lit "checked-model-not-source-refinement") I D) <--
    (composition_identity I C S F T P) (clue I D I _ _ _)
    (model_interface Model P) (source Model Path Sha _)
    (composition_model_evidence P Path Sha _ _ _))
  ((inventory N V) <-- (factor _ _ N V))
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
  ((transfer_premise_evidence condition_id section_id path sha anchor finding unclosed) <--
    (transfer_condition condition_id _ _ _ _)
    (transfer_premise condition_id section_id finding unclosed)
    (source_section section_id source_id anchor _)
    (source source_id path sha _))
  ((transfer_unbound condition_id (lit "premise-section-missing")) <--
    (transfer_condition condition_id _ _ _ _)
    (transfer_premise condition_id section_id _ _)
    (not (source_section section_id _ _ _)))
  ((transfer_unbound condition_id (lit "premise-source-missing")) <--
    (transfer_condition condition_id _ _ _ _)
    (transfer_premise condition_id section_id _ _)
    (source_section section_id source_id _ _)
    (not (source source_id _ _ _)))
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
