;;; Optional source-bound reasoning windows, never a workflow scheduler.
(define-evidence (make-modeling-guidance)
  (sources focus obligation signal assessment model model_revision method source
           proposal proposal_change proposal_attribute model_assumption scope_review
           checkpoint_context checkpoint_claim checkpoint_receipt_source related
           requirement dependency contract receipt completed_outcome verified
           support_declaration support_witness required_command
           binding required_binding current_binding command command_observation
           prerequisite quiescent material available withdrawn)
  (outputs recommendations model_gaps revision_gaps unbound actions
           applicability_gaps assumption_deltas current_scope_review
           checkpoint_observation checkpoint_dependency checkpoint_reason
           historical_complete applicable reusable unclosed invalidated_by
           clue factor link inventory)
  (include evidence-checkpoint-exchange-fragment)
  (relation checkpoint_context (focus claim))
  (relation related (claim target label))
  ((checkpoint_source S Path H) <-- (source S Path H))
  (explain (lambda (program result query scope)
    (hash ("status" "recorded-only") ("dependencies" (.ref program 'rules))
      ("gap" "Optional reasoning windows, not a complete action universe. No attempt/read-count thresholds or mandatory order. Declared reviews are not proof admission, retry eligibility or execution authority."))))
  (relation focus ((id string?) (candidate_source string?) (candidate_sha string?)))
  (relation obligation ((focus string?) (id string?) (kind string?)))
  (relation signal ((focus string?) (obligation string?) (kind string?) (source string?)))
  (relation assessment ((focus string?) (obligation string?) (model string?) (status string?) (source string?)))
  (relation model ((id string?) (source string?)))
  (relation model_revision ((model string?) (checked_sha string?) (report_source string?)))
  (relation method ((kind string?) (tool string?) (question string?)))
  (relation source ((id string?) (path string?) (sha string?)))
  (relation proposal ((focus string?) (id string?) (source string?)))
  (relation proposal_attribute ((proposal string?) (name string?) (value string?)))
  (relation proposal_change ((focus string?) (proposal string?) (model string?)
    (witness string?) (dimension string?) (value string?)))
  (relation model_assumption ((model string?) (dimension string?) (value string?)
    (source string?)))
  (relation scope_review ((focus string?) (proposal string?) (model string?)
    (dimension string?) (value string?) (model_sha string?) (proposal_sha string?)
    (assumption_sha string?) (source string?)))
  (relation current_scope_review (focus proposal model dimension value))
  (relation applicability_gaps (focus proposal model witness dimension value path sha))
  (relation assumption_deltas (focus proposal model witness dimension expected actual
    assumption_path assumption_sha proposal_path proposal_sha))
  (relation clue (id digest claim polarity role source))
  (relation factor (id digest name value))
  (relation link (claim target label id digest))
  (relation inventory (name value))
  (relation current_focus (focus))
  (relation need (focus obligation action reason evidence))
  (relation recommendations (focus obligation action tool question reason path sha))
  (relation model_gaps (focus obligation model status path sha))
  (relation revision_gaps (focus obligation model checked_sha current_sha report_path report_sha))
  (relation unbound (focus obligation kind source))
  (relation actions (id query reason))
  ;; Projection only: the Library owns completion, invalidation and reuse.
  ((clue I H C Polarity (lit "observation") Path) <--
    (current_focus F) (checkpoint_context F C)
    (checkpoint_observation I H C Polarity Path _ _ _ _))
  ((factor I H (lit "requirement") R) <--
    (checkpoint_observation I H C _ _ R _ _ _) (checkpoint_context F C) (current_focus F))
  ((factor I H (lit "scope") Scope) <--
    (checkpoint_observation I H C _ _ _ Scope _ _) (checkpoint_context F C) (current_focus F))
  ((factor I H (lit "evidence-state") State) <--
    (checkpoint_observation I H C _ _ _ _ State _) (checkpoint_context F C) (current_focus F))
  ((factor I H (lit "receipt") E) <--
    (checkpoint_observation I H C _ _ _ _ _ E) (checkpoint_context F C) (current_focus F))
  ((factor I H (lit "outcome") Outcome) <--
    (checkpoint_observation I H C _ _ R _ _ E) (receipt E R _ Outcome)
    (checkpoint_context F C) (current_focus F))
  ((factor I H N V) <--
    (checkpoint_observation I H C _ _ _ _ _ _) (proposal_attribute C N V)
    (checkpoint_context F C) (current_focus F))
  ((factor I H (lit "reason") Reason) <--
    (checkpoint_observation I H C _ _ _ _ _ E) (checkpoint_reason C E _ Reason)
    (checkpoint_context F C) (current_focus F))
  ((factor I H (lit "reason") Reason) <--
    (checkpoint_observation I H C _ _ _ _ (lit "unclosed") _)
    (checkpoint_reason C _ _ Reason) (checkpoint_context F C) (current_focus F))
  ((factor I H (lit "sourceLock") CH) <--
    (checkpoint_observation I H C _ _ _ _ _ _) (checkpoint_context F C) (focus F _ CH)
    (current_focus F))
  ((link C Parent (lit "evidence-dependency") I H) <--
    (checkpoint_observation I H C _ _ _ _ _ _) (checkpoint_dependency C Parent)
    (checkpoint_context F C) (current_focus F))
  ;; Related evidence is a caller-declared reference, not a proof dependency.
  ((link C T Label I H) <-- (clue I H C _ _ _) (related C T Label))
  ((current_focus F) <-- (focus F C H) (source C _ H))
  ;; A receipt for unchanged model bytes is not a review of changed premises.
  ;; This records a bound scope review, never proof/native admission or an order.
  ((current_scope_review F P M D V) <-- (current_focus F)
    (proposal F P PS) (source PS _ PH)
    (model M MS) (source MS _ MH)
    (model_revision M MH Checked) (source Checked _ _)
    (model_assumption M D V AS) (source AS _ AH)
    (scope_review F P M D V MH PH AH Review) (source Review _ _))
  ((applicability_gaps F P M I D V Path H) <-- (current_focus F)
    (proposal F P PS) (source PS Path H)
    (proposal_change F P M I D V)
    (not (current_scope_review F P M D V)))
  ((assumption_deltas F P M I D Expected Actual AP AH PP PH) <--
    (current_focus F) (proposal F P PS) (source PS PP PH)
    (proposal_change F P M I D Actual)
    (model_assumption M D Expected AS) (source AS AP AH)
    (if (Expected Actual) (not (string=? Expected Actual))))
  ;; Each declared witness has its own identity: factors from different gaps
  ;; must not be conjoined into an invented model/source correspondence.
  ((clue I H I (lit "counter")
    (lit "observation") Path) <-- (applicability_gaps _ _ _ I _ _ Path H))
  ((factor I H (lit "model") M) <-- (applicability_gaps _ _ M I _ _ _ H))
  ((factor I H (lit "category") (lit "model-applicability-unresolved")) <--
    (applicability_gaps _ _ _ I _ _ _ H))
  ((factor I H (lit "proposal") P) <-- (applicability_gaps _ P _ I _ _ _ H))
  ((factor I H (lit "dimension") D) <-- (applicability_gaps _ _ _ I D _ _ H))
  ((factor I H (lit "proposed-value") V) <-- (applicability_gaps _ _ _ I _ V _ H))
  ((factor I H (lit "model-source-sha") MH) <-- (applicability_gaps _ _ M I _ _ _ H)
    (model M MS) (source MS _ MH))
  ((factor I H (lit "model-source-path") Path) <-- (applicability_gaps _ _ M I _ _ _ H)
    (model M MS) (source MS Path _))
  ((factor I H (lit "sourceLock") CHash) <-- (applicability_gaps F _ _ I _ _ _ H)
    (focus F _ CHash))
  ((factor I H N V) <-- (applicability_gaps _ P _ I _ _ _ H)
    (proposal_attribute P N V))
  ((factor I H (lit "expected-value") Expected) <--
    (assumption_deltas F P M I D Expected V _ _ _ H)
    (applicability_gaps F P M I D V _ H))
  ((link I P
    (lit "declared-change-has-no-current-model-scope-review") I H) <--
    (applicability_gaps _ P _ I _ _ _ H))
  ;; Bound reviews must be visible through the same Clue exchange as proposals.
  ((clue O H O (lit "counter") (lit "observation") Path) <--
    (model_gaps _ O _ _ Path H))
  ((factor O H (lit "category") (lit "model-coverage-review")) <--
    (model_gaps _ O _ _ _ H))
  ((factor O H (lit "model") M) <-- (model_gaps _ O M _ _ H))
  ((factor O H (lit "status") Status) <-- (model_gaps _ O _ Status _ H))
  ((factor O H (lit "sourceLock") CHash) <-- (model_gaps F O _ _ _ H)
    (focus F _ CHash))
  ((factor O H (lit "proposal") P) <-- (model_gaps F O M _ _ H)
    (proposal_change F P M _ _ _))
  ((link O P (lit "source-bound-model-review") O H) <--
    (model_gaps F O M _ _ H) (proposal_change F P M _ _ _))
  ((inventory N V) <-- (factor _ _ N V))
  ((need F O (lit "review-model-fit")
    (lit "Bound investigation window reports repeated inspection without a discriminating observation; review abstraction and missing evidence, not an automatic timeout") S)
    <-- (current_focus F) (signal F O (lit "non-discriminating-inspection") S) (source S _ _))
  ((need F O (lit "model-protocol")
    (lit "Protocol or ownership transitions remain unclear; expose state, actions, invariants and falsifiers") S)
    <-- (current_focus F) (signal F O (lit "protocol-unclear") S) (source S _ _))
  ((need F O (lit "refine-model")
    (lit "Execution contradicts the selected abstraction; retain the failure and repair assumptions or coverage before reusing its conclusions") S)
    <-- (current_focus F) (assessment F O M (lit "refuted-by-execution") S)
        (model M MS) (source MS _ _) (source S _ _)
        (not (revision_gaps F O M _ _ _ _)))
  ((need F O (lit "extend-model")
    (lit "Selected model does not represent this obligation; add the missing mechanism and negative controls") S)
    <-- (current_focus F) (assessment F O M (lit "insufficient") S)
        (model M MS) (source MS _ _) (source S _ _)
        (not (revision_gaps F O M _ _ _ _)))
  ((need F O (lit "establish-source-correspondence")
    (lit "Model/source correspondence is not established; map actual actions, roots and memory assumptions rather than expanding unrelated state") S)
    <-- (current_focus F) (assessment F O M (lit "unmapped") S)
        (model M MS) (source MS _ _) (source S _ _)
        (not (revision_gaps F O M _ _ _ _)))
  ((need F O (lit "investigate-unbounded-proof")
    (lit "Finite checking cannot discharge an unbounded source theorem; state explicit induction/refinement/fairness premises") S)
    <-- (current_focus F) (obligation F O (lit "unbounded-refinement"))
        (assessment F O M (lit "finite-only") S)
        (model M MS) (source MS _ _) (source S _ _)
        (not (revision_gaps F O M _ _ _ _)))
  ((need F O (lit "collect-discriminating-evidence")
    (lit "Competing explanations need a separating observation; a formal model alone cannot establish empirical causality") S)
    <-- (current_focus F) (signal F O (lit "evidence-underdetermined") S) (source S _ _))
  ((revision_gaps F O M Old Current Path H) <-- (current_focus F)
    (assessment F O M _ Review) (source Review _ _)
    (model M MS) (source MS _ Current)
    (model_revision M Old Checked) (source Checked Path H)
    (if (Old Current) (not (string=? Old Current))))
  ((need F O (lit "review-model-delta")
    (lit "Selected source changed since the bound model observation; inspect the delta and reassess coverage instead of recycling old conclusions") S)
    <-- (revision_gaps F O M _ _ _ _) (model_revision M _ S))
  ((recommendations F O A Tool Question Reason Path H) <--
    (need F O A Reason S) (obligation F O Kind) (method Kind Tool Question) (source S Path H))
  ((model_gaps F O M Status Path H) <-- (current_focus F)
    (assessment F O M Status S) (source S Path H)
    (if (Status) (not (string=? Status "covered")))
    (not (revision_gaps F O M _ _ _ _)))
  ((model_gaps F O M (lit "revision-unreviewed") Path H) <--
    (revision_gaps F O M _ _ Path H))
  ((unbound F O Kind S) <-- (signal F O Kind S) (not (source S _ _)))
  ((unbound F O Status S) <-- (assessment F O _ Status S) (not (source S _ _)))
  ((actions (lit "inspect-modeling-options") (lit "recommendations")
    (lit "Source-bound modeling and evidence options; selection is not an authorized model run"))
    <-- (recommendations _ _ _ _ _ _ _ _))
  ((actions (lit "inspect-model-coverage-gaps") (lit "model_gaps")
    (lit "Inspect the selected model's coverage before extrapolating to source correctness"))
    <-- (model_gaps _ _ _ _ _ _))
  ((actions (lit "inspect-unbound-guidance") (lit "unbound")
    (lit "Missing observation provenance cannot establish an investigation stall or coverage conclusion"))
    <-- (unbound _ _ _ _))
  ((actions (lit "inspect-model-revision-gaps") (lit "revision_gaps")
    (lit "Old model receipt identity is retained; changed model bytes are not an old PASS"))
    <-- (revision_gaps _ _ _ _ _ _ _)))
