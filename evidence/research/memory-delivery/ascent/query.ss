(define-evidence (query) (sources clue factor binding) (outputs commitReady commitCovered commitMissing commitGateReady commitSourceMismatch controlFailure)
(relation clue (id document claim kind owner source))
(relation factor (id document name value))
(relation binding (name value))
;; SysML owns required gates and obligations. The caller supplies observations,
;; never authority to execute Git. Missing evidence is a reason to withhold.
;; Exact candidate tree, source manifest, profile, artifact and evidence digests
;; prevent reuse across source/profile changes; hashes do not attest truth.
(relation commitStudyFact (claim) (("memory-delivery")))
(relation commitPolicyFact (digest) (("82abd0301a006aa950a235ae9a184ce166d986cc641e6c04fec23155cd6e97c0")))
(relation commitBoundStudy (claim))
(relation commitGateFact (gate purpose) (("tests" "All tests required by this source cut must finish with exact source and profile receipts; missing, timeout, unknown and failed results block") ("learning" "State what the architecture taught us, what it amplifies, its actual retirement and added costs; no inferred speedup") ("process" "Disclose the current refactoring stage, dependencies, remaining steps and acceptance boundary") ("models" "Native SysML drives ASCENT; select QNT schedules and Lean laws only for applicable semantic changes, with distinct duties and actual source-refinement boundaries") ("questions" "Answer the mandatory Gambit-paper, semantic, amplification and counterexample questions within the claimed cut; unresolved mandatory answers block")))
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
(relation commitNeedFact (obligation gate method artifact scope) (("M-BYTES" "tests" "source-refinement" "evidence/research/memory-delivery/candidate-tree.json" "all25-ordered-payloads-reconstruct207607-bytes-and-only27-allowed-paths-change") ("M-COMPILERS" "tests" "native" "vendor/gambit/lib/mem.c" "eight-GCC-Clang-preprocessing-pairs-release-object-identity-and-three-retained-matched-debug-override-failures") ("M-DEPENDENCIES" "tests" "native" "vendor/gambit/lib/makefile.in" "unchanged-plus25-independent-Make-rebuild-edges-and25-byte-identical-relative-distribution-paths") ("M-CONSUMERS" "tests" "source-refinement" "evidence/research/memory-delivery/consumers.json" "full-base-source-census-retains-version-writer-preamble-direct-mem.c-entrypoints-and-private-inclusion-paths-without-claiming-Windows-native-qualification") ("M-LESSON" "learning" "source-analysis" "dev/refactoring/modern-c/memory-delivery.org" "quantified-maintenance-partition-explicit-dependencies-added-costs-and-no-inferred-runtime-or-build-speedup") ("M-PROCESS" "process" "source-analysis" "dev/refactoring/modern-c/models/sysml/memory-delivery.sysml" "exact27-path-memory-unit-before-unaccepted-header-and-role-work-with-recoverable-original-commit-index-and-working-research") ("M-MODELS" "models" "native-model-projection" "dev/refactoring/modern-c/models/sysml/memory-delivery.sysml" "native-SysML-partition-and-ASCENT-positive-missing-test-stale-tree-wrong-artifact-wrong-evidence-class-and-model-only-controls") ("M-QUESTIONS" "questions" "source-analysis" "dev/refactoring/modern-c/memory-delivery.org" "Gambit-portable-C-tail-multishot-root-invariants-unchanged-why-organization-enables-but-does-not-prove-runtime-amplification-and-why-prototype-failures-stay-open")))
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
(relation commitArtifactFact (artifact digest) (("dev/refactoring/modern-c/memory-delivery.org" "c7dfc1a14ffcb8d562c6914d23cd8c4a59200582faeddeb6b70f7094c683b3ea") ("dev/refactoring/modern-c/models/sysml/memory-delivery.sysml" "f7f30f9aae17349ae186b5793bde0d19406e12ccd7ed13e2acd41b65230d8602") ("evidence/research/memory-delivery/candidate-tree.json" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491") ("evidence/research/memory-delivery/consumers.json" "3b8766d9382efa71ad6e24b81eeed8eaaaa3ec52f0b850d3e00aecb96f27bf52") ("vendor/gambit/lib/makefile.in" "b194c65b4833ce58e6dcbc1ef0c868330fc15f4461050b58fafd29fab8dd8db6") ("vendor/gambit/lib/mem.c" "2162993753bbb3118b3fbb5ab01da3dd65aea3ac97e0ca5713a7522dcd9c34c1")))
(relation commitEvidenceFact (evidence digest evidenceClass) (("native" "6e3e176e54fd4be74e51fe00cbe06cfa3734b2c398c2ff79ecc5b44bcdd3b776" "actual") ("policy" "40bcf69ce69b53ad1f76213105c4631318f35b7a46de09d403a5207b43fd0410" "actual")))
(relation commitScenarioClassFact (scenario evidenceClass) (("current" "actual")))
(relation commitSourceFact (head tree manifest profile) (("dfec5508118afef2dc9bd1ade5c928930e63c0fa" "e3197060cbd1f7773cf4f16c71c2a1479cd2a9d2" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69")))
(relation commitCandidateFact (scenario head tree manifest profile) (("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "e3197060cbd1f7773cf4f16c71c2a1479cd2a9d2" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69")))
(relation commitObservationFact (scenario head tree manifest profile obligation method artifact digest scope status evidence evidenceDigest) (("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "e3197060cbd1f7773cf4f16c71c2a1479cd2a9d2" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "M-BYTES" "source-refinement" "evidence/research/memory-delivery/candidate-tree.json" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491" "all25-ordered-payloads-reconstruct207607-bytes-and-only27-allowed-paths-change" "pass" "native" "6e3e176e54fd4be74e51fe00cbe06cfa3734b2c398c2ff79ecc5b44bcdd3b776") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "e3197060cbd1f7773cf4f16c71c2a1479cd2a9d2" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "M-COMPILERS" "native" "vendor/gambit/lib/mem.c" "2162993753bbb3118b3fbb5ab01da3dd65aea3ac97e0ca5713a7522dcd9c34c1" "eight-GCC-Clang-preprocessing-pairs-release-object-identity-and-three-retained-matched-debug-override-failures" "pass" "native" "6e3e176e54fd4be74e51fe00cbe06cfa3734b2c398c2ff79ecc5b44bcdd3b776") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "e3197060cbd1f7773cf4f16c71c2a1479cd2a9d2" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "M-DEPENDENCIES" "native" "vendor/gambit/lib/makefile.in" "b194c65b4833ce58e6dcbc1ef0c868330fc15f4461050b58fafd29fab8dd8db6" "unchanged-plus25-independent-Make-rebuild-edges-and25-byte-identical-relative-distribution-paths" "pass" "native" "6e3e176e54fd4be74e51fe00cbe06cfa3734b2c398c2ff79ecc5b44bcdd3b776") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "e3197060cbd1f7773cf4f16c71c2a1479cd2a9d2" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "M-CONSUMERS" "source-refinement" "evidence/research/memory-delivery/consumers.json" "3b8766d9382efa71ad6e24b81eeed8eaaaa3ec52f0b850d3e00aecb96f27bf52" "full-base-source-census-retains-version-writer-preamble-direct-mem.c-entrypoints-and-private-inclusion-paths-without-claiming-Windows-native-qualification" "pass" "native" "6e3e176e54fd4be74e51fe00cbe06cfa3734b2c398c2ff79ecc5b44bcdd3b776") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "e3197060cbd1f7773cf4f16c71c2a1479cd2a9d2" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "M-LESSON" "source-analysis" "dev/refactoring/modern-c/memory-delivery.org" "c7dfc1a14ffcb8d562c6914d23cd8c4a59200582faeddeb6b70f7094c683b3ea" "quantified-maintenance-partition-explicit-dependencies-added-costs-and-no-inferred-runtime-or-build-speedup" "pass" "native" "6e3e176e54fd4be74e51fe00cbe06cfa3734b2c398c2ff79ecc5b44bcdd3b776") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "e3197060cbd1f7773cf4f16c71c2a1479cd2a9d2" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "M-PROCESS" "source-analysis" "dev/refactoring/modern-c/models/sysml/memory-delivery.sysml" "f7f30f9aae17349ae186b5793bde0d19406e12ccd7ed13e2acd41b65230d8602" "exact27-path-memory-unit-before-unaccepted-header-and-role-work-with-recoverable-original-commit-index-and-working-research" "pass" "native" "6e3e176e54fd4be74e51fe00cbe06cfa3734b2c398c2ff79ecc5b44bcdd3b776") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "e3197060cbd1f7773cf4f16c71c2a1479cd2a9d2" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "M-MODELS" "native-model-projection" "dev/refactoring/modern-c/models/sysml/memory-delivery.sysml" "f7f30f9aae17349ae186b5793bde0d19406e12ccd7ed13e2acd41b65230d8602" "native-SysML-partition-and-ASCENT-positive-missing-test-stale-tree-wrong-artifact-wrong-evidence-class-and-model-only-controls" "pass" "policy" "40bcf69ce69b53ad1f76213105c4631318f35b7a46de09d403a5207b43fd0410") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "e3197060cbd1f7773cf4f16c71c2a1479cd2a9d2" "23ea4d1c6a9938897b0e57177cc1a2bdc31c148265172f786283a2fd7daa5491" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "M-QUESTIONS" "source-analysis" "dev/refactoring/modern-c/memory-delivery.org" "c7dfc1a14ffcb8d562c6914d23cd8c4a59200582faeddeb6b70f7094c683b3ea" "Gambit-portable-C-tail-multishot-root-invariants-unchanged-why-organization-enables-but-does-not-prove-runtime-amplification-and-why-prototype-failures-stay-open" "pass" "native" "6e3e176e54fd4be74e51fe00cbe06cfa3734b2c398c2ff79ecc5b44bcdd3b776")))
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
(relation controlExpectReadyFact (scenario) (("current")))
(relation controlExpectBlockedFact (scenario) ())
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
