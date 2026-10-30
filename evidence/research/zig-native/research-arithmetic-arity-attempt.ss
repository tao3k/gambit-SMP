;;; Research correspondence and open premises, never runtime admission.
;;; Existing Library owns parsing, ASCENT evaluation and Clue exchange.
(define-evidence (make-zig-native-research)
  (sources source citation claim observation attribute depends requires
    requirement witness role operation expected_item claim_item
    reserve_case arithmetic_candidate reserve_owner)
  (outputs evidence_path dependency_path missing_requirement blocked unbound
    traceable role_contract operation_contract reserve_equations reserve_gap
    clue factor link inventory)
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
        (= F (+ NF 1 SB))
        (= R (* 8 (+ NP SB (* NA (+ PS PB)))))
        (= B (+ (* NA (+ PS PB)) NP VB)))))
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
  ((link C P Edge I H) <-- (clue I H C _ _ _) (depends C P Edge))
  ((inventory (lit "runtime-admitted") (lit "false")) <-- (claim _ _ _))
  ((inventory (lit "execution-authorized") (lit "false")) <-- (claim _ _ _)))
