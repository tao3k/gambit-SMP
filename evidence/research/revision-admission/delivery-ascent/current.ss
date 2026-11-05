(define-evidence (query) (sources clue factor binding) (outputs commitDeliveryEligible commitDeliveryDependencyOpen commitDeliveryPartitionRequired commitReady commitCovered)
(relation clue (id document claim kind owner source))
(relation factor (id document name value))
(relation binding (name value))
;; SysML owns required gates and obligations. The caller supplies observations,
;; never authority to execute Git. Missing evidence is a reason to withhold.
;; Exact candidate tree, source manifest, profile, artifact and evidence digests
;; prevent reuse across source/profile changes; hashes do not attest truth.
(relation commitStudyFact (claim))
(relation commitPolicyFact (digest))
(relation commitBoundStudy (claim))
(relation commitGateFact (gate purpose))
;; Delivery planning is separate from commit admission. SysML routes complete
;; responsibility cuts and their dependencies. Eligibility is only a review
;; order: none of these relations can manufacture commitCovered/commitReady.
(relation commitDeliveryStepFact (step scope exitCriterion excludes status) (("organization" "C23 baseline and lossless private header/memory organization; unchanged public namespaces and generated semantics" "Exact reconstruction and complete build-input/distribution closure; current bootstrap and applicable header/frame consumers; no semantic changes hidden in a mechanical split" "New collector, CFFI policy, scheduler and frontend optimization" "source-present-unpartitioned") ("role-ownership" "VM-owned execution, root-participant and collector-work storage with complete real accessor/caller migration under the existing synchronous adapter" "Old carrier payload fields removed; admitted synchronous root/frame/RC consumers coherent; storage controls, real multi-shot map/GC and scoped W/R observations on the exact submitted tree" "Independent worker threads, live context migration, general owner-death recovery and a redesigned foreign interface" "source-present-unpartitioned") ("round-ownership" "Closed root census, unique copy/scan authority, physical worker/context capacity and one restoration outcome for the admitted synchronous round" "Complete concrete capacity/copy/scan handoff and unchanged multi-shot restoration; finite schedules and source refinement discharge their distinct premises" "Generational skipping, arbitrary worker death and universal foreign writers" "source-present-unpartitioned") ("lifecycle" "Membership/resize/exit ownership and explicit per-VM retirement to global reclamation; known success versus retained failure or unknown result" "No ignored refusal can grant free; real admitted owners, concurrent registry access and scoped join/cleanup histories; retained debt remains attributable without claiming recovery" "Forced cleanup of an arbitrary native owner and complete CFFI resource-service redesign" "source-present-unpartitioned") ("foreign-ownership" "Foreign roots/borrows, blocking participation, nested callbacks, exception/continuation exits and owner-affine release as a complete service replacement" "Actual supported producer/consumer inventory and root/exit/resource custody close; ungoverned aliases are explicitly rejected or covered" "Changing Scheme multi-shot semantics or declaring unsupported native aliases safe" "later-service-cut") ("generations" "Generational allocation, promotion and remembered edges including continuation/denv/FFI writers; independent worker service only after its lifecycle prerequisites" "Writer-complete admitted classes, overflow/failure ownership, physical promotion reserve and measured work-versus-barrier/peak-memory benefit" "Assuming copying alone implies generations or copying OCaml's one-shot control restriction" "later-collector-cut") ("whole-smp-qualification" "Compose accepted cuts against the twelve SMP dimensions, current Gerbil integration and declared progress/scalability workloads" "Exact-source complete campaign plus safety/progress/benefit evidence; historical patch success is problem evidence, not inherited acceptance" "Using this programme exit as the unconditional requirement for every earlier structural commit" "programme-acceptance")))
(relation commitDeliveryDependencyFact (predecessor successor) (("organization" "role-ownership") ("role-ownership" "round-ownership") ("round-ownership" "lifecycle") ("lifecycle" "foreign-ownership") ("foreign-ownership" "generations") ("generations" "whole-smp-qualification")))
(relation commitDeliveryAcceptedFact (step) ())
(relation commitDeliveryDependencyOpen (step predecessor))
(relation commitDeliveryEligible (step))
(relation commitDeliveryPartitionRequired (step))
((commitDeliveryDependencyOpen S P) <--
 (commitDeliveryDependencyFact P S) (not (commitDeliveryAcceptedFact P)))
((commitDeliveryEligible S) <-- (commitDeliveryStepFact S _ _ _ _)
 (not (commitDeliveryAcceptedFact S))
 (not (commitDeliveryDependencyOpen S _)))
((commitDeliveryPartitionRequired S) <--
 (commitDeliveryStepFact S _ _ _ (lit "source-present-unpartitioned")))
(relation commitNeedFact (obligation gate method artifact scope))
;; Native SysML projects each generation contract to its existing obligation.
;; This readback reports evidence coverage; it does not prove the invariant.
(relation commitBoundaryFact (boundary obligation invariant))
(relation commitBoundaryCovered (scenario boundary obligation))
;; Concrete ownership refinements are projected from native SysML. The route
;; preserves existing model premises; evidence availability is not their proof.
(relation commitOwnershipRouteFact (boundary model receipt premise obligation))
(relation commitOwnershipEvidenceMissing (scenario boundary obligation))
;; Required language/ownership semantics and replaceable representations are
;; different SysML facts. A missing migration check is not an old-ABI demand.
(relation commitMigrationFact (boundary obligation category preserved replaceable admission))
(relation commitMigrationMissing (scenario boundary obligation))
;; Source type/table/caller concordance is a narrower observation than the
;; complete root/exit obligation. It must not discharge that obligation.
(relation commitMigrationObservationFact (scenario head tree manifest profile boundary evidence digest status))
(relation commitMigrationSourceObserved (scenario boundary))
;; A checked schedule plus selected native controls is deliberately narrower
;; than M-REFINE. The protocol joins the SysML-selected model bytes and actual
;; observation packet; it supplies no whole-C refinement or retirement fact.
(relation commitProtocolFact (boundary model))
(relation commitProtocolObservationFact (scenario head tree manifest profile boundary model modelDigest evidence evidenceDigest status))
(relation commitProtocolObserved (scenario boundary))
(relation commitArtifactFact (artifact digest))
(relation commitEvidenceFact (evidence digest evidenceClass))
(relation commitScenarioClassFact (scenario evidenceClass))
(relation commitSourceFact (head tree manifest profile))
(relation commitCandidateFact (scenario head tree manifest profile))
(relation commitObservationFact (scenario head tree manifest profile obligation method artifact digest scope status evidence evidenceDigest))
(relation commitScenario (scenario))
(relation commitBoundCandidate (scenario head tree manifest profile))
(relation commitCovered (scenario obligation))
(relation commitMissing (scenario gate obligation))
(relation commitGateBlocked (scenario gate))
(relation commitGateReady (scenario gate))
(relation commitGateUnready (scenario gate))
(relation commitSourceMismatch (scenario))
(relation commitBlocked (scenario))
(relation commitReady (scenario))
(relation commitQuestion (claim))
(relation question (claim))
(relation controlExpectReadyFact (scenario))
(relation controlExpectBlockedFact (scenario))
(relation controlFailure (scenario))
((commitBoundStudy C) <-- (commitStudyFact C) (clue I D C _ _ _)
 (factor I D (lit "target-model-bundle-sha256") H) (binding (lit "target-model-bundle-sha256") H)
 (factor I D (lit "native-output-sha256") N) (binding (lit "native-output-sha256") N)
 (factor I D (lit "planner-dsl-sha256") P) (binding (lit "planner-dsl-sha256") P)
 (commitPolicyFact P))
((commitScenario S) <-- (commitBoundStudy _) (commitCandidateFact S _ _ _ _))
((commitBoundCandidate S H T M P) <-- (commitScenario S)
 (commitCandidateFact S H T M P) (commitSourceFact H T M P))
((commitCovered S O) <-- (commitBoundCandidate S H T M P)
 (commitNeedFact O _ K A Scope) (commitArtifactFact A Digest)
 (commitObservationFact S H T M P O K A Digest Scope (lit "pass") E EH)
 (commitScenarioClassFact S Class) (commitEvidenceFact E EH Class))
((commitMissing S G O) <-- (commitScenario S) (commitNeedFact O G _ _ _)
 (not (commitCovered S O)))
((commitBoundaryCovered S B O) <-- (commitBoundaryFact B O _)
 (commitNeedFact O _ _ _ _) (commitCovered S O))
((commitGateBlocked S G) <-- (commitMissing S G _))
((commitGateReady S G) <-- (commitScenario S) (commitGateFact G _)
 (commitNeedFact _ G _ _ _) (not (commitGateBlocked S G)))
((commitGateUnready S G) <-- (commitScenario S) (commitGateFact G _)
 (not (commitGateReady S G)))
((commitSourceMismatch S) <-- (commitScenario S) (not (commitBoundCandidate S _ _ _ _)))
((commitBlocked S) <-- (commitGateUnready S _))
((commitBlocked S) <-- (commitSourceMismatch S))
((commitReady S) <-- (commitBoundCandidate S _ _ _ _) (commitGateFact _ _)
 (not (commitBlocked S)))
((commitQuestion C) <-- (commitBoundStudy C))
((question C) <-- (commitBoundStudy C))
((controlFailure S) <-- (controlExpectReadyFact S) (not (commitReady S)))
((controlFailure S) <-- (controlExpectBlockedFact S) (commitReady S))

((commitOwnershipEvidenceMissing S B O) <-- (commitScenario S)
 (commitOwnershipRouteFact B _ _ _ O) (not (commitCovered S O)))

((commitMigrationMissing S B O) <-- (commitScenario S)
 (commitMigrationFact B O _ _ _ _) (not (commitCovered S O)))

((commitMigrationSourceObserved S B) <-- (commitBoundCandidate S H T M P)
 (commitMigrationFact B _ (lit "migration") _ _ _)
 (commitMigrationObservationFact S H T M P B E EH (lit "source-concordant"))
 (commitScenarioClassFact S Class) (commitEvidenceFact E EH Class))

((commitProtocolObserved S B) <-- (commitBoundCandidate S H T M P)
 (commitProtocolFact B Model) (commitArtifactFact Model MH)
 (commitProtocolObservationFact S H T M P B Model MH E EH
   (lit "schedule-and-native-controls-observed"))
 (commitScenarioClassFact S Class) (commitEvidenceFact E EH Class))

)
