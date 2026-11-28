;; Axis 1 (DEV Refactory) multi-layer formal convergence assurance rules.
;; Evaluates Quint, Lean 4, GenMC (RC11), CBMC + Z3, and OpenSysML v2 observations
;; without claiming native runtime admission ahead of campaign execution.
(ascent-fragment
 (relation required_step ((step symbol?)))
 (relation observed_step ((step symbol?) (status string?) (capability string?)))
 (relation c_verdict ((step symbol?) (contract string?) (branch string?) (verdict string?) (scope string?)))
 (relation c_reachability ((step symbol?) (contract string?) (branch string?) (witness string?) (status string?)))
 (relation c_source ((step symbol?) (path string?) (sha string?)))
 (relation obligation_need ((id string?) (step symbol?) (capability string?)))
 (relation checked ((id string?)))
 (relation open_obligation ((id string?)))
 (relation bound_c_cut ((step symbol?) (contract string?) (branch string?) (verdict string?) (path string?) (sha string?)))
 (relation qualified_counterexample ((id string?)))

 ;; Formal model and theorem-prover obligations
 ((obligation_need (lit "axis1-dmem1-c1-c2-quint-laws") (lit (quote axis1-contracts)) (lit "quint.observe")) <-- (required_step (lit (quote axis1-contracts))))
 ((obligation_need (lit "worker-owned-cache-lean-refinement") (lit (quote worker-cache-lean)) (lit "lean.check")) <-- (required_step (lit (quote worker-cache-lean))))
 ((obligation_need (lit "write-group-plan-lean-refinement") (lit (quote write-group-plan-lean)) (lit "lean.check")) <-- (required_step (lit (quote write-group-plan-lean))))
 ((obligation_need (lit "family6-spinlock-fastpath-quint-laws") (lit (quote family6-spinlock-fastpath-quint)) (lit "quint.observe")) <-- (required_step (lit (quote family6-spinlock-fastpath-quint))))
 ((obligation_need (lit "family6-spinlock-fastpath-lean-refinement") (lit (quote family6-spinlock-fastpath-lean)) (lit "lean.check")) <-- (required_step (lit (quote family6-spinlock-fastpath-lean))))
 ((obligation_need (lit "frame-contract-lean-geometry") (lit (quote frame-geometry)) (lit "lean.check")) <-- (required_step (lit (quote frame-geometry))))
 ((obligation_need (lit "rest-native-observation-lean") (lit (quote rest-refinement)) (lit "lean.check")) <-- (required_step (lit (quote rest-refinement))))
 ((obligation_need (lit "rest-frame-publication-56-histories") (lit (quote frame-history)) (lit "quint.observe")) <-- (required_step (lit (quote frame-history))))
 ((obligation_need (lit "default-section-leases-quint") (lit (quote section-leases)) (lit "quint.observe")) <-- (required_step (lit (quote section-leases))))
 ((obligation_need (lit "emission-view-correspondence-quint") (lit (quote emission-correspondence)) (lit "quint.observe")) <-- (required_step (lit (quote emission-correspondence))))
 ((obligation_need (lit "rest-soft-grant-envelope-quint") (lit (quote rest-envelope)) (lit "quint.observe")) <-- (required_step (lit (quote rest-envelope))))
 ((obligation_need (lit "rest-section-claim-states-quint") (lit (quote section-states)) (lit "quint.observe")) <-- (required_step (lit (quote section-states))))
 ((obligation_need (lit "smp-rest-record-lifetime-quint") (lit (quote source-lifetime)) (lit "quint.observe")) <-- (required_step (lit (quote source-lifetime))))
 ((obligation_need (lit "stack-authority-revisions-quint") (lit (quote authority-revisions)) (lit "quint.observe")) <-- (required_step (lit (quote authority-revisions))))
 ((obligation_need (lit "rest-argument-cursor-quint") (lit (quote argument-cut)) (lit "quint.observe")) <-- (required_step (lit (quote argument-cut))))
 ((obligation_need (lit "sysml-63-model-architecture-projection") (lit (quote contract-model)) (lit "sysml.project")) <-- (required_step (lit (quote contract-model))))

 ((checked Id) <-- (obligation_need Id Step Cap) (observed_step Step (lit "PASS") Cap))

 ;; Source-bound C verifications (GenMC RC11 + CBMC)
 ((checked (lit "genmc-rc11-copy-gate-publication")) <--
   (c_verdict (lit (quote copy-gate)) (lit "concurrency/copy-gate") (lit "two-carriers") (lit "VERIFIED") _))
 ((checked (lit "cbmc-group-demand-local-admission")) <--
   (c_verdict (lit (quote local-admission)) (lit "allocation-grant/group-demand") (lit "local-admission") (lit "VERIFIED") _))
 ((checked (lit "cbmc-group-demand-fast-span")) <--
   (c_verdict (lit (quote fast-span)) (lit "allocation-grant/group-demand") (lit "local-admission") (lit "VERIFIED") _))
 ((checked (lit "cbmc-rest-path-demand-footprint")) <--
   (c_verdict (lit (quote demand-source)) (lit "allocation-grant/rest-demand") (lit "path-footprint") (lit "VERIFIED") _))
 ((checked (lit "cbmc-rest-ready-delivery-settlement")) <--
   (c_verdict (lit (quote ready-delivery)) (lit "rest-activation/settlement") (lit "ready-delivery") (lit "VERIFIED") _)
   (c_verdict (lit (quote ready-to-delivery)) (lit "rest-activation/settlement") (lit "ready-delivery") (lit "VERIFIED") _))

 ((qualified_counterexample (lit "fast-budget-differs-from-full-batch-demand")) <--
   (c_reachability (lit (quote demand-control)) (lit "allocation-grant/rest-demand")
     (lit "path-footprint") (lit "control.fast-equals-full") (lit "REACHED")))
 ((qualified_counterexample (lit "grant-alone-does-not-discharge-writer-custody")) <--
   (c_reachability (lit (quote ready-writer-control)) (lit "rest-activation/settlement")
     (lit "ready-delivery") (lit "control.grant-does-not-discharge-writer") (lit "REACHED")))

 ((bound_c_cut Step Contract Branch Verdict Path Sha) <--
   (c_verdict Step Contract Branch Verdict _)
   (c_source Step Path Sha))

 ((open_obligation Id) <-- (obligation_need Id _ _) (not (checked Id)))
)
