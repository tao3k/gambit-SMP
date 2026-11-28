;;; Research correspondence and open premises, never runtime admission.
;;; Existing Library owns parsing, ASCENT evaluation and Clue exchange.
(define-evidence (make-zig-native-research)
  (sources source citation claim observation attribute depends requires
    requirement witness role operation expected_item claim_item
    reserve_case arithmetic_candidate reserve_owner
    value_question consideration alternative value_review value_metric
    foreign_surface foreign_anchor)
  (outputs evidence_path dependency_path missing_requirement blocked unbound
    traceable role_contract operation_contract reserve_equations reserve_gap
    question_record question_evidence question_gap question_open_premise
    question_alternative question_metric foreign_contract foreign_correspondence
    foreign_gap clue factor link inventory)
  (explain (lambda (program result query scope)
    (hash ("status" "research-only") ("query" query) ("scope" scope)
      ("dependencies" (.ref program 'rules))
      ("gap" "Source correspondence, proposals, missing declared premises and research dependencies only. No native feasibility, retirement, speedup, proof or execution authorization is derived."))))
  (relation source ((id string?) (path string?) (sha string?)))
  (relation citation ((id string?) (source_id string?) (anchor string?) (finding string?)))
  (relation claim ((id string?) (kind string?) (statement string?)))
  (relation observation ((id string?) (claim_id string?) (citation_id string?) (polarity string?)))
  (relation attribute ((claim_id string?) (name string?) (value string?)))
  (relation depends ((child string?) (parent string?) (edge_kind string?)))
  (relation requires ((claim_id string?) (requirement_id string?)))
  (relation requirement ((id string?) (evidence_class string?) (description string?)))
  (relation witness ((requirement_id string?) (citation_id string?) (evidence_class string?)))
  (relation role ((id string?) (name string?) (anchor string?)
    (incoming string?) (frame_contract string?) (citation_id string?)))
  (relation operation ((id string?) (name string?) (obligation string?) (citation_id string?)))
  (relation expected_item ((kind string?) (id string?)))
  (relation claim_item ((claim_id string?) (kind string?) (item_id string?)))
  (relation reserve_case ((id string?) (max_parameters exact-integer?)
    (max_arguments exact-integer?) (max_frame_slots exact-integer?)
    (pair_size exact-integer?) (pair_body exact-integer?)
    (vector_body exact-integer?) (subtyped_body exact-integer?)
    (compiler_policy exact-integer?) (word_bytes exact-integer?)
    (memory_source string?) (representation_source string?)))
  (relation arithmetic_candidate ((case_id string?) (fudge exact-integer?)
    (overflow_reserve exact-integer?) (loose_finish exact-integer?)))
  (relation reserve_owner ((claim_id string?) (case_id string?)))
  ;; A question is a reviewed decision record, never an adoption theorem.
  ;; Considerations/alternatives are not prerequisite depends edges.
  (relation value_question ((id string?) (claim_id string?)
    (question string?) (decision_scope string?)))
  (relation consideration ((question_id string?) (claim_id string?) (stance string?)))
  (relation alternative ((question_id string?) (id string?) (description string?)))
  (relation value_review ((question_id string?) (status string?)
    (next_action string?) (reopen_trigger string?) (reversal_condition string?)))
  (relation value_metric ((question_id string?) (ledger_row string?) (comparator string?)))
  (relation foreign_surface ((id string?) (name string?)
    (semantic_owner string?) (product_owner string?) (disposition string?)))
  (relation foreign_anchor ((surface_id string?) (role string?) (citation_id string?)))
  (relation evidence_path (claim citation kind path sha anchor finding))
  (relation dependency_path (child ancestor))
  (relation requirement_evidence (requirement citation))
  (relation missing_requirement (requirement evidence_class description))
  (relation blocked (claim requirement))
  (relation unbound (entity reason))
  (relation traceable (claim kind))
  (relation role_contract (id name anchor incoming frame path sha source_anchor))
  (relation operation_contract (id name obligation path sha source_anchor))
  (relation reserve_equations (case compiler_policy local_fudge vm_reserve loose_finish word_bytes))
  (relation reserve_gap (case reason))
  (relation question_record (id claim question scope status next trigger reversal))
  (relation question_evidence (id claim stance citation path sha anchor finding))
  (relation question_gap (id reason))
  (relation question_open_premise (id requirement evidence_class))
  (relation question_alternative (question alternative description))
  (relation question_metric (question ledger_row comparator))
  (relation foreign_contract (surface name semantic_owner product_owner disposition))
  (relation foreign_correspondence (surface role citation path sha anchor finding))
  (relation foreign_gap (surface reason))
  (relation clue (id digest claim polarity role source))
  (relation factor (id digest name value))
  (relation link (claim target label id digest))
  (relation inventory (name value))

  ((evidence_path C E K P H A F) <--
    (claim C K _) (observation _ C E _)
    (citation E S A F) (source S P H))
  ((dependency_path C P) <-- (depends C P _) (claim C _ _) (claim P _ _))
  ((dependency_path C A) <-- (dependency_path C P) (dependency_path P A))
  ;; A static-source witness cannot satisfy a native or measured-cost premise.
  ((requirement_evidence R E) <--
    (requirement R K _) (witness R E K) (citation E S _ _) (source S _ _))
  ((missing_requirement R K D) <--
    (requirement R K D) (not (requirement_evidence R _)))
  ((blocked C R) <-- (claim C _ _) (requires C R) (missing_requirement R _ _))
  ((blocked C R) <-- (depends C P _) (blocked P R))

  ((unbound E (lit "citation-source-missing")) <--
    (citation E S _ _) (not (source S _ _)))
  ((unbound C (lit "observation-citation-missing")) <--
    (observation _ C E _) (not (citation E _ _ _)))
  ((unbound C (lit "observation-source-missing")) <--
    (observation _ C E _) (unbound E (lit "citation-source-missing")))
  ((unbound C (lit "dependency-claim-missing")) <--
    (depends C P _) (not (claim P _ _)))
  ((unbound C (lit "requirement-definition-missing")) <--
    (requires C R) (not (requirement R _ _)))
  ((unbound C (lit "dependency-unbound")) <-- (depends C P _) (unbound P _))
  ((unbound I (lit "role-row-missing")) <--
    (expected_item (lit "role") I) (not (role I _ _ _ _ _)))
  ((unbound I (lit "operation-row-missing")) <--
    (expected_item (lit "operation") I) (not (operation I _ _ _)))
  ((unbound I (lit "conflicting-role-anchor")) <--
    (role I _ A _ _ _) (role I _ B _ _ _)
    (if (A B) (not (string=? A B))))
  ((unbound I (lit "conflicting-role-contract")) <--
    (role I N _ A F _) (role I M _ B G _)
    (if (N M A B F G)
      (or (not (string=? N M)) (not (string=? A B)) (not (string=? F G)))))
  ((unbound C (lit "item-unbound")) <-- (claim_item C _ I) (unbound I _))
  ;; Check source-bound conditional arithmetic, never a native headroom proof.
  ((reserve_equations I G F R B W) <--
    (reserve_case I NP NA NF PS PB VB SB G W MS HS)
    (source MS _ _) (source HS _ _)
    (arithmetic_candidate I F R B)
    (if (NP NA NF PS PB VB SB G W F R B)
      (and (> G 0) (> W 0) (>= NA NP) (>= NF NA)
        (= F (+ (+ NF 1) SB))
        (= R (* 8 (+ (+ NP SB) (* NA (+ PS PB)))))
        (= B (+ (+ (* NA (+ PS PB)) NP) VB)))))
  ((reserve_gap I (lit "loose-finish-exceeds-local-fudge-not-a-runtime-counterexample")) <--
    (reserve_equations I _ F _ B _) (if (F B) (> B F)))
  ((unbound C (lit "arithmetic-correspondence-missing")) <--
    (reserve_owner C I) (not (reserve_equations I _ _ _ _ _)))
  ;; Traceability is deliberately independent of feasibility/completion.
  ((traceable C K) <-- (claim C K _) (evidence_path C _ _ _ _ _ _)
    (not (unbound C _)))
  ((role_contract I N A State Frame P H Loc) <--
    (role I N A State Frame E) (citation E S Loc _) (source S P H))
  ((operation_contract I N Obligation P H Loc) <--
    (operation I N Obligation E) (citation E S Loc _) (source S P H))

  ((foreign_contract I N S P D) <-- (foreign_surface I N S P D))
  ((foreign_correspondence I R E P H A F) <--
    (foreign_surface I _ _ _ _) (foreign_anchor I R E)
    (citation E S A F) (source S P H))
  ((foreign_gap I (lit "surface-row-missing")) <--
    (expected_item (lit "foreign-surface") I) (not (foreign_surface I _ _ _ _)))
  ((foreign_gap I (lit "producer-source-missing")) <--
    (foreign_surface I _ _ _ _)
    (not (foreign_correspondence I (lit "producer") _ _ _ _ _)))
  ((foreign_gap I (lit "consumer-source-missing")) <--
    (foreign_surface I _ _ _ _)
    (not (foreign_correspondence I (lit "consumer") _ _ _ _ _)))
  ((foreign_gap I (lit "anchor-role-invalid")) <--
    (foreign_anchor I R _)
    (if (R) (and (not (string=? R "producer")) (not (string=? R "consumer")))))
  ((foreign_gap I (lit "anchor-source-missing")) <--
    (foreign_anchor I _ E) (not (citation E _ _ _)))
  ((foreign_gap I (lit "anchor-source-missing")) <--
    (foreign_anchor I _ E) (citation E S _ _) (not (source S _ _)))
  ((foreign_gap I (lit "owner-or-disposition-empty")) <--
    (foreign_surface I _ S P D)
    (if (S P D) (or (string=? S "") (string=? P "") (string=? D ""))))
  ((foreign_gap I (lit "conflicting-surface-contract")) <--
    (foreign_surface I N S P D) (foreign_surface I N2 S2 P2 D2)
    (if (N S P D N2 S2 P2 D2)
      (or (not (string=? N N2)) (not (string=? S S2))
        (not (string=? P P2)) (not (string=? D D2)))))
  ((unbound I R) <-- (foreign_gap I R))

  ((question_record I C Q Scope Status Next Trigger Reversal) <--
    (value_question I C Q Scope) (claim C _ _)
    (value_review I Status Next Trigger Reversal))
  ((question_evidence I C St E P H A F) <--
    (value_question I _ _ _) (consideration I C St)
    (evidence_path C E _ P H A F))
  ((question_alternative I A D) <-- (value_question I _ _ _) (alternative I A D))
  ((question_metric I R C) <-- (value_question I _ _ _) (value_metric I R C))
  ((question_open_premise I R K) <--
    (value_question I C _ _) (blocked C R) (requirement R K _))
  ((question_gap I (lit "question-row-missing")) <--
    (expected_item (lit "value-question") I) (not (value_question I _ _ _)))
  ((question_gap I (lit "question-claim-missing")) <--
    (value_question I C _ _) (not (claim C _ _)))
  ((question_gap I (lit "review-missing")) <--
    (value_question I _ _ _) (not (value_review I _ _ _ _)))
  ((question_gap I (lit "question-source-unbound")) <--
    (value_question I C _ _) (unbound C _))
  ((question_gap I (lit "supporting-source-missing")) <--
    (value_question I _ _ _)
    (not (question_evidence I _ (lit "supports") _ _ _ _ _)))
  ((question_gap I (lit "limiting-source-missing")) <--
    (value_question I _ _ _)
    (not (question_evidence I _ (lit "limits") _ _ _ _ _)))
  ((question_gap I (lit "consideration-claim-missing")) <--
    (consideration I C _) (not (claim C _ _)))
  ((question_gap I (lit "consideration-source-missing")) <--
    (consideration I C _) (not (evidence_path C _ _ _ _ _ _)))
  ((question_gap I (lit "consideration-source-unbound")) <--
    (consideration I C _) (unbound C _))
  ((question_gap I (lit "consideration-stance-invalid")) <--
    (consideration I _ St)
    (if (St) (and (not (string=? St "supports")) (not (string=? St "limits")))))
  ((question_gap I (lit "alternative-missing")) <--
    (value_question I _ _ _) (not (alternative I _ _)))
  ((question_gap I (lit "metric-comparator-missing")) <--
    (value_question I _ _ _) (not (value_metric I _ _)))
  ((question_gap I (lit "review-field-empty")) <--
    (value_review I S N T R)
    (if (S N T R) (or (string=? S "") (string=? N "")
      (string=? T "") (string=? R ""))))
  ((question_gap I (lit "conflicting-review")) <--
    (value_review I S N T R) (value_review I S2 N2 T2 R2)
    (if (S N T R S2 N2 T2 R2)
      (or (not (string=? S S2)) (not (string=? N N2))
        (not (string=? T T2)) (not (string=? R R2)))))

  ((clue I H C Polarity (lit "observation") P) <--
    (claim C _ _) (observation I C E Polarity)
    (citation E S _ _) (source S P H))
  ((factor I H (lit "entity") (lit "zig-gambit")) <-- (clue I H _ _ _ _))
  ((factor I H (lit "scope") (lit "design-research-only")) <-- (clue I H _ _ _ _))
  ((factor I H (lit "evidence-state") K) <-- (clue I H C _ _ _) (claim C K _))
  ((factor I H N V) <-- (clue I H C _ _ _) (attribute C N V))
  ((factor I H (lit "requirement") R) <-- (clue I H C _ _ _) (requires C R))
  ((factor I H (lit "unresolved-premise") R) <-- (clue I H C _ _ _) (blocked C R))
  ((factor I H (lit "unbound") Reason) <-- (clue I H C _ _ _) (unbound C Reason))
  ((factor I H (lit "question-gap") Reason) <--
    (clue I H C _ _ _) (value_question Q C _ _) (question_gap Q Reason))
  ((factor I H (lit "ledger-metric") M) <--
    (clue I H C _ _ _) (value_question Q C _ _) (value_metric Q M _))
  ((factor I H (lit "foreign-gap") R) <--
    (clue I H C _ _ _) (claim_item C (lit "foreign-surface") S) (foreign_gap S R))
  ((link C P Edge I H) <-- (clue I H C _ _ _) (depends C P Edge))
  ;; Expose evidence considerations to Clue lineage without making an
  ;; alternative/limitation a mandatory architecture prerequisite.
  ((link C P St I H) <--
    (clue I H C _ _ _) (value_question Q C _ _) (consideration Q P St))
  ((inventory (lit "runtime-admitted") (lit "false")) <-- (claim _ _ _))
  ((inventory (lit "execution-authorized") (lit "false")) <-- (claim _ _ _)))
