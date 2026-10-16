;;; Protocol transfer is a research obligation, never runtime admission.
(define-evidence (make-gc-transfer-review)
  (sources source verified_source design applicability candidate observation test
    shape_class resweep_profile run_observation source_anchor)
  (outputs repair_obligation collector_specific missing_binding
    recorded_counterexample required_test unproven performance_required
    shape_coverage resweep_evidence recorded_run source_test_correspondence)
  (explain
    (lambda (program result query scope)
      (hash ("status" "research-obligations-only") ("query" query)
            ("scope" scope) ("dependencies" (.ref program 'rules))
            ("gap" "Source facts and finite counterexamples are not native correctness, causal review, runtime authorization or matched performance"))))
  (relation source ((id string?) (path string?) (sha string?)))
  ;; Host verifies actual bytes; a declared digest alone does not establish this.
  (relation verified_source ((id string?) (sha string?)))
  (relation design ((id string?) (implementation string?) (contract string?) (source_id string?)))
  (relation applicability ((contract string?) (target string?) (kind string?)))
  (relation candidate ((id string?) (implementation string?) (source_id string?)))
  (relation observation ((id string?) (contract string?) (kind string?) (source_id string?) (pointer string?)))
  (relation test ((contract string?) (fixture string?) (scope string?)))
  (relation shape_class ((shape string?) (source_id string?) (scope string?)))
  (relation resweep_profile ((id string?) (source_id string?) (owners exact-integer?) (bounces exact-integer?) (rounds exact-integer?)))
  (relation run_observation ((id string?) (candidate string?) (contract string?) (kind string?) (source_id string?) (pointer string?)))
  (relation source_anchor ((contract string?) (source_id string?) (location string?) (fixture string?) (boundary string?)))
  (relation bound (id))
  (relation missing_binding (id))
  (relation repair_obligation (candidate contract design source candidate_source))
  (relation collector_specific (candidate contract design))
  (relation recorded_counterexample (candidate contract observation source pointer))
  (relation required_test (candidate contract fixture scope))
  (relation unproven (candidate contract boundary))
  (relation performance_required (candidate contract))
  (relation shape_coverage (candidate shape source scope))
  (relation resweep_evidence (candidate profile owners bounces rounds source))
  (relation recorded_run (candidate contract run kind source pointer))
  (relation source_test_correspondence (candidate contract location fixture boundary))
  ((bound id) <-- (source id path sha) (verified_source id sha))
  ((missing_binding id) <-- (source id path sha) (not (bound id)))
  ((repair_obligation current contract design_id source_id candidate_source) <--
    (candidate current target candidate_source) (bound candidate_source)
    (design design_id reference contract source_id) (bound source_id)
    (applicability contract target (lit "portable-protocol")))
  ((collector_specific current contract design_id) <--
    (candidate current target candidate_source) (bound candidate_source)
    (design design_id reference contract source_id) (bound source_id)
    (applicability contract target (lit "collector-specific")))
  ((recorded_counterexample current contract observation_id source_id pointer) <--
    (repair_obligation current contract _ _ _)
    (observation observation_id contract (lit "finite-counterexample") source_id pointer)
    (bound source_id))
  ((required_test current contract fixture scope) <--
    (repair_obligation current contract _ _ _) (test contract fixture scope))
  ((unproven current contract (lit "native-correctness")) <--
    (repair_obligation current contract _ _ _))
  ((unproven current contract (lit "source-refinement")) <--
    (repair_obligation current contract _ _ _))
  ((performance_required current contract) <--
    (repair_obligation current contract _ _ _))
  ((shape_coverage current shape source_id scope) <--
    (candidate current target candidate_source) (bound candidate_source)
    (shape_class shape source_id scope) (bound source_id))
  ((resweep_evidence current profile owners bounces rounds source_id) <--
    (candidate current target candidate_source) (bound candidate_source)
    (resweep_profile profile source_id owners bounces rounds) (bound source_id))
  ((recorded_run current contract run kind source_id pointer) <--
    (repair_obligation current contract _ _ _)
    (run_observation run current contract kind source_id pointer) (bound source_id))
  ((source_test_correspondence current contract location fixture boundary) <--
    (repair_obligation current contract _ _ _)
    (source_anchor contract source_id location fixture boundary) (bound source_id)))
