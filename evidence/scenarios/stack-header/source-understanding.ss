;;; Agent interpretation is retained data, never evidence that it was understood.
(define-evidence (make-source-block-clues)
  (sources observation attribute edge reference understanding
    impact_node impact_dependency impact_declaration impact_witness)
  (outputs clue factor link inventory summary_current summary_changed
    impact_path impact_affected impact_boundary impact_unresolved impact_gap summary_reusable)
  (relation observation ((id string?) (claim string?) (polarity string?) (source string?)))
  (relation attribute ((id string?) (name string?) (value string?)))
  (relation edge ((id string?) (target string?) (label string?)))
  (relation reference ((id string?) (path string?) (digest string?)))
  (relation clue (id digest claim polarity role source))
  (relation factor (id digest name value))
  (relation link (claim target label id digest))
  (relation inventory (name value))
  ((clue I D C P (lit "observation") Path) <--
    (observation I C P S) (reference S Path D))
  ((factor I D N V) <-- (observation I _ _ R) (reference R _ D) (attribute I N V))
  ((link C Target Label I D) <-- (observation I C _ R) (reference R _ D) (edge I Target Label))
  ((inventory N V) <-- (factor _ _ N V))
  (relation understanding ((id string?) (raw string?) (claim string?)
    (summary string?) (reference string?) (reviewed_digest string?)))
  (relation summary_current (id))
  (relation summary_changed (id))
  (relation impact_node ((id string?) (reference string?) (reviewed_digest string?)))
  (relation impact_dependency ((consumer string?) (dependency string?) (kind string?)))
  (relation impact_declaration ((id string?) (scope string?) (count integer?)))
  (relation impact_witness ((id string?) (scope string?) (reference string?) (reviewed_digest string?)))
  (relation impact_count (id count))
  (relation impact_path (origin consumer))
  (relation impact_changed (id))
  (relation impact_affected (consumer origin))
  (relation impact_boundary (id reason))
  (relation impact_unresolved (consumer boundary reason))
  (relation impact_gap (consumer missing kind))
  (relation summary_reusable (id))
  ((impact_count I N) <-- (impact_declaration I _ _)
    (aggregate N gerbil-ascent-count () (impact_dependency I Dependency Kind)))
  ((impact_path I I) <-- (impact_node I _ _))
  ((impact_path D C) <-- (impact_dependency C D _))
  ((impact_path D C) <-- (impact_path D B) (impact_dependency C B _))
  ((impact_changed I) <-- (impact_node I R Expected) (reference R _ Current)
    (if (Expected Current) (not (equal? Expected Current))))
  ((impact_affected C D) <-- (impact_changed D) (impact_path D C))
  ((impact_boundary I (lit "missing-byte-observation")) <--
    (impact_node I R _) (not (reference R _ _)))
  ((impact_boundary I (lit "undeclared-footprint")) <--
    (impact_node I _ _) (not (impact_declaration I _ _)))
  ((impact_boundary I (lit "inventory-count-mismatch")) <--
    (impact_declaration I Scope _) (impact_count I N) (not (impact_declaration I Scope N)))
  ((impact_boundary I (lit "missing-current-scope-witness")) <--
    (impact_declaration I Scope _) (not (impact_scope_checked I Scope)))
  (relation impact_scope_checked (id scope))
  ((impact_scope_checked I Scope) <--
    (impact_witness I Scope R D) (reference R _ D))
  ((impact_boundary C (lit "unregistered-dependency")) <--
    (impact_dependency C D _) (not (impact_node D _ _)))
  ((impact_gap C D Kind) <-- (impact_dependency C D Kind) (not (impact_node D _ _)))
  ((impact_unresolved C B Reason) <--
    (impact_path B C) (impact_boundary B Reason))
  ((summary_reusable U) <-- (understanding U Raw _ _ R D)
    (summary_current U) (impact_node Raw R D) (not (impact_affected Raw _))
    (not (impact_unresolved Raw _ _)))
  ((summary_current U) <-- (understanding U _ _ _ R D) (reference R _ D))
  ((summary_changed U) <-- (understanding U _ _ _ R D) (not (reference R _ D)))
  ((clue U D C (lit "support") (lit "hypothesis") (lit "agent:source-review")) <--
    (understanding U _ C _ _ D))
  ((factor U D (lit "understanding-summary") Text) <-- (understanding U _ _ Text _ D))
  ((factor U D (lit "source-correspondence") (lit "reviewed-bytes-current")) <--
    (understanding U _ _ _ _ D) (summary_current U))
  ((factor U D (lit "source-correspondence") (lit "changed-or-unavailable-review")) <--
    (understanding U _ _ _ _ D) (summary_changed U))
  ((factor U D (lit "impact-scope") (lit "conditional-declared-footprint-current")) <--
    (understanding U _ _ _ _ D) (summary_reusable U))
  ((factor U D (lit "impact-origin") Origin) <--
    (understanding U Raw _ _ _ D) (impact_affected Raw Origin))
  ((factor U D (lit "impact-unknown") Reason) <--
    (understanding U Raw _ _ _ D) (impact_unresolved Raw _ Reason))
  ((factor U D (lit "impact-boundary") Boundary) <--
    (understanding U Raw _ _ _ D) (impact_unresolved Raw Boundary _))
  ((factor U D (lit "impact-missing-dependency") Missing) <--
    (understanding U Raw _ _ _ D) (impact_path Boundary Raw) (impact_gap Boundary Missing _))
  ((link C Missing (lit "unclosed-impact-reference") U D) <--
    (understanding U Raw C _ _ D) (impact_path Boundary Raw) (impact_gap Boundary Missing _))
  ((factor U D (lit "impact-unknown") (lit "undeclared-root")) <--
    (understanding U Raw _ _ _ D) (not (impact_node Raw _ _)))
  ((factor U D (lit "impact-unknown") (lit "summary-origin-mismatch")) <--
    (understanding U Raw _ _ R D) (impact_node Raw _ _) (not (impact_node Raw R D)))
  ((factor U D N V) <-- (understanding U Raw _ _ _ D) (attribute Raw N V)
    (if (N) (not (equal? N "source-text"))))
  ((link C RawClaim (lit "reviewed-source-block") U D) <--
    (understanding U Raw C _ _ D) (observation Raw RawClaim _ _)))
