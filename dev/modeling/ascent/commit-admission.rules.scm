;; SysML owns required gates and obligations. The caller supplies observations,
;; never authority to execute Git. Missing evidence is a reason to withhold.
;; Exact candidate tree, source manifest, profile, artifact and evidence digests
;; prevent reuse across source/profile changes; hashes do not attest truth.
(relation commitStudyFact (claim))
;; Independent branch test observations. A source-bound case PASS is not a
;; semantic requirement count, patch-line credit or commit permission.
(relation branchQualificationPlanFact (plan revision source profile))
(relation branchQualificationCaseFact (plan case))
(relation branchQualificationProducerFact (producer revision source profile overlay))
(relation branchQualificationFrozenProducerFact (plan producer))
(relation branchQualificationObservedFact (plan producer case scenario kind status exit timeout quiescent complete))
(relation branchQualificationBound (plan producer))
(relation branchQualificationPass (scenario case kind))
(relation branchQualificationFailure (scenario case kind))
(relation branchQualificationExpectPassFact (scenario))
(relation branchQualificationExpectBlockedFact (scenario))
(relation branchQualificationControlFailure (scenario reason))
((branchQualificationBound P A) <--
 (branchQualificationPlanFact P R S F)
 (branchQualificationProducerFact A R S F (lit "false"))
 (branchQualificationFrozenProducerFact P A))
((branchQualificationPass X C K) <--
 (branchQualificationBound P A) (branchQualificationCaseFact P C)
 (branchQualificationObservedFact P A C X K (lit "PASS") (lit "0")
   (lit "false") (lit "true") (lit "true")))
((branchQualificationFailure X C K) <--
 (branchQualificationBound P A) (branchQualificationCaseFact P C)
 (branchQualificationObservedFact P A C X K (lit "FAIL") _ _ _ _))
((branchQualificationControlFailure X (lit "expected-pass")) <--
 (branchQualificationExpectPassFact X) (not (branchQualificationPass X _ _)))
((branchQualificationControlFailure X (lit "unexpected-pass")) <--
 (branchQualificationExpectBlockedFact X) (branchQualificationPass X _ _))
;; Native SysML routes a comparison to an existing semantic milestone label.
;; Support for original cases is distinct from eligibility for whole-gate
;; review. Neither relation awards a numeric milestone or supplies commitReady.
;; Caller truth and native provenance still require independent source review.
(relation milestoneReviewFact (claim source gate evidenceClass))
(relation milestoneReviewInputsFact (claim sameRecipes sameFixtures sameLimits))
(relation milestoneReviewOutcomeFact (claim passed fullGate appliesToPublished branchCoverageEstablished))
(relation milestoneReviewSupport (claim source gate evidenceClass))
(relation milestoneReviewEligible (claim source gate evidenceClass))
(relation milestoneReviewExpectSupportFact (claim))
(relation milestoneReviewExpectEligibleFact (claim))
(relation milestoneReviewExpectBlockedFact (claim))
(relation milestoneReviewControlFailure (claim reason))
((milestoneReviewSupport C S G K) <--
 (milestoneReviewFact C S G K)
 (milestoneReviewInputsFact C (lit "true") (lit "true") _)
 (milestoneReviewOutcomeFact C (lit "true") _ _ _))
((milestoneReviewEligible C S G K) <--
 (milestoneReviewSupport C S G K)
 (milestoneReviewInputsFact C _ _ (lit "true"))
 (milestoneReviewOutcomeFact C _ (lit "true") (lit "true") (lit "true")))
((milestoneReviewControlFailure C (lit "expected-support")) <--
 (milestoneReviewExpectSupportFact C) (not (milestoneReviewSupport C _ _ _)))
((milestoneReviewControlFailure C (lit "expected-eligible")) <--
 (milestoneReviewExpectEligibleFact C) (not (milestoneReviewEligible C _ _ _)))
((milestoneReviewControlFailure C (lit "unexpected-eligibility")) <--
 (milestoneReviewExpectBlockedFact C) (milestoneReviewEligible C _ _ _))
(relation commitPolicyFact (digest))
(relation commitBoundStudy (claim))
(relation commitGateFact (gate purpose))
;; Delivery planning is separate from commit admission. SysML routes complete
;; responsibility cuts and their dependencies. Eligibility is only a review
;; order: none of these relations can manufacture commitCovered/commitReady.
(relation commitDeliveryStepFact (step scope exitCriterion excludes status))
(relation commitDeliveryDependencyFact (predecessor successor))
(relation commitDeliveryAcceptedFact (step))
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
