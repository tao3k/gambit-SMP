(define-evidence (query) (sources clue factor binding) (outputs commitReady commitCovered commitMissing commitGateReady commitSourceMismatch controlFailure)
(relation clue (id document claim kind owner source))
(relation factor (id document name value))
(relation binding (name value))
;; SysML owns required gates and obligations. The caller supplies observations,
;; never authority to execute Git. Missing evidence is a reason to withhold.
;; Exact candidate tree, source manifest, profile, artifact and evidence digests
;; prevent reuse across source/profile changes; hashes do not attest truth.
(relation commitStudyFact (claim) (("header-delivery")))
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
(relation commitNeedFact (obligation gate method artifact scope) (("H-BYTES" "tests" "source-refinement" "evidence/research/header-delivery/candidate-tree.json" "all40-ordered-payloads-exactly-reconstruct490621-HEAD-baseline-bytes-only44-header-publication-paths-change") ("H-CONFIG" "tests" "native" "vendor/gambit/configure.ac" "byte-identical-flat-header-under-recorded-profile-substitutions-and-both-shipped-configure-data-maps-no-generator-upgrade") ("H-CONSUMERS" "tests" "native" "vendor/gambit/include/gambit.h.in" "GCC-C23-header-GCC-Clang-preprocessing-original-memory-object-byte-equality-and-native-frame-consumers-at3-5-25-registers") ("H-DEPENDENCIES" "tests" "native" "vendor/gambit/include/makefile.in" "unchanged-header-is-up-to-date-all40-independent-edits-rebuild-and-all40-relative-distribution-paths-preserve-bytes") ("H-TEMPLATE-CONSUMERS" "tests" "source-refinement" "vendor/gambit/include/gambit.h.in" "change-gvm-regs-changev-configure-probe-and-Windows-template-renderers-preserve-all-original-inputs-and-writes") ("H-LESSON" "learning" "source-analysis" "dev/refactoring/modern-c/header-delivery.org" "source-responsibility-retirement-cost-and-why-no-runtime-performance-or-SMP-gain-is-inferred") ("H-PROCESS" "process" "source-analysis" "dev/refactoring/modern-c/models/sysml/header-delivery.sysml" "header-unit-before-memory-unit-and-role-prototype-exact44-path-tree-with-retained-unpublished-research-and-failures") ("H-MODELS" "models" "native-model-projection" "dev/refactoring/modern-c/models/sysml/header-delivery.sysml" "actual-native-partition-projection-and-ASCENT-positive-stale-tree-wrong-artifact-missing-test-and-wrong-evidence-class-controls") ("H-QUESTIONS" "questions" "source-analysis" "dev/refactoring/modern-c/header-delivery.org" "Gambit-C-portability-tail-multishot-invariants-preserved-by-unchanged-public-bytes-organization-not-runtime-ownership-and-why-later-prototype-failures-remain-unaccepted")))
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
(relation commitArtifactFact (artifact digest) (("dev/refactoring/modern-c/header-delivery.org" "f105c63f438a9788a40436d6a20a6723f8eb92dcedd9ba3ea09af63bfce5c22d") ("dev/refactoring/modern-c/models/sysml/header-delivery.sysml" "5b2579eb2226c583c829d3bffcdfe8692d69a7058bbceabdaeee4ed5d4f60bb9") ("evidence/research/header-delivery/candidate-tree.json" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f") ("vendor/gambit/configure.ac" "03b403580ab742e11cb39a99587d321d113ea15cfded8950f0aa391fc8e53458") ("vendor/gambit/include/gambit.h.in" "27b89dae636de25ad4d03d2c1557fd8afc72bab283bfeb1fdc099dfb5b4615d3") ("vendor/gambit/include/makefile.in" "897c2fa4dc44599c414dda536cb30154237e4ba13331555613a13bfec7c71937")))
(relation commitEvidenceFact (evidence digest evidenceClass) (("native" "0fc8f3efc9b6a8645aa4571a87ee20a0110bd01f36870c1cc5758f736f8dc509" "actual") ("policy" "e45019ff0d2ed2fb746b7585837937b679a2610497be0b94e6a44f2365f89161" "actual")))
(relation commitScenarioClassFact (scenario evidenceClass) (("current" "actual")))
(relation commitSourceFact (head tree manifest profile) (("dfec5508118afef2dc9bd1ade5c928930e63c0fa" "3eea42fc9bbbfd427a39e91c9bef556964fb8097" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69")))
(relation commitCandidateFact (scenario head tree manifest profile) (("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "3eea42fc9bbbfd427a39e91c9bef556964fb8097" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69")))
(relation commitObservationFact (scenario head tree manifest profile obligation method artifact digest scope status evidence evidenceDigest) (("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "3eea42fc9bbbfd427a39e91c9bef556964fb8097" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "H-BYTES" "source-refinement" "evidence/research/header-delivery/candidate-tree.json" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f" "all40-ordered-payloads-exactly-reconstruct490621-HEAD-baseline-bytes-only44-header-publication-paths-change" "pass" "native" "0fc8f3efc9b6a8645aa4571a87ee20a0110bd01f36870c1cc5758f736f8dc509") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "3eea42fc9bbbfd427a39e91c9bef556964fb8097" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "H-CONFIG" "native" "vendor/gambit/configure.ac" "03b403580ab742e11cb39a99587d321d113ea15cfded8950f0aa391fc8e53458" "byte-identical-flat-header-under-recorded-profile-substitutions-and-both-shipped-configure-data-maps-no-generator-upgrade" "pass" "native" "0fc8f3efc9b6a8645aa4571a87ee20a0110bd01f36870c1cc5758f736f8dc509") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "3eea42fc9bbbfd427a39e91c9bef556964fb8097" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "H-CONSUMERS" "native" "vendor/gambit/include/gambit.h.in" "27b89dae636de25ad4d03d2c1557fd8afc72bab283bfeb1fdc099dfb5b4615d3" "GCC-C23-header-GCC-Clang-preprocessing-original-memory-object-byte-equality-and-native-frame-consumers-at3-5-25-registers" "pass" "native" "0fc8f3efc9b6a8645aa4571a87ee20a0110bd01f36870c1cc5758f736f8dc509") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "3eea42fc9bbbfd427a39e91c9bef556964fb8097" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "H-DEPENDENCIES" "native" "vendor/gambit/include/makefile.in" "897c2fa4dc44599c414dda536cb30154237e4ba13331555613a13bfec7c71937" "unchanged-header-is-up-to-date-all40-independent-edits-rebuild-and-all40-relative-distribution-paths-preserve-bytes" "pass" "native" "0fc8f3efc9b6a8645aa4571a87ee20a0110bd01f36870c1cc5758f736f8dc509") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "3eea42fc9bbbfd427a39e91c9bef556964fb8097" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "H-LESSON" "source-analysis" "dev/refactoring/modern-c/header-delivery.org" "f105c63f438a9788a40436d6a20a6723f8eb92dcedd9ba3ea09af63bfce5c22d" "source-responsibility-retirement-cost-and-why-no-runtime-performance-or-SMP-gain-is-inferred" "pass" "native" "0fc8f3efc9b6a8645aa4571a87ee20a0110bd01f36870c1cc5758f736f8dc509") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "3eea42fc9bbbfd427a39e91c9bef556964fb8097" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "H-PROCESS" "source-analysis" "dev/refactoring/modern-c/models/sysml/header-delivery.sysml" "5b2579eb2226c583c829d3bffcdfe8692d69a7058bbceabdaeee4ed5d4f60bb9" "header-unit-before-memory-unit-and-role-prototype-exact44-path-tree-with-retained-unpublished-research-and-failures" "pass" "native" "0fc8f3efc9b6a8645aa4571a87ee20a0110bd01f36870c1cc5758f736f8dc509") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "3eea42fc9bbbfd427a39e91c9bef556964fb8097" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "H-MODELS" "native-model-projection" "dev/refactoring/modern-c/models/sysml/header-delivery.sysml" "5b2579eb2226c583c829d3bffcdfe8692d69a7058bbceabdaeee4ed5d4f60bb9" "actual-native-partition-projection-and-ASCENT-positive-stale-tree-wrong-artifact-missing-test-and-wrong-evidence-class-controls" "pass" "policy" "e45019ff0d2ed2fb746b7585837937b679a2610497be0b94e6a44f2365f89161") ("current" "dfec5508118afef2dc9bd1ade5c928930e63c0fa" "3eea42fc9bbbfd427a39e91c9bef556964fb8097" "9f4474ba70aacca3a532c78c717d5a71439e38baa503fba89677b541a49e6e2f" "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69" "H-QUESTIONS" "source-analysis" "dev/refactoring/modern-c/header-delivery.org" "f105c63f438a9788a40436d6a20a6723f8eb92dcedd9ba3ea09af63bfce5c22d" "Gambit-C-portability-tail-multishot-invariants-preserved-by-unchanged-public-bytes-organization-not-runtime-ownership-and-why-later-prototype-failures-remain-unaccepted" "pass" "native" "0fc8f3efc9b6a8645aa4571a87ee20a0110bd01f36870c1cc5758f736f8dc509")))
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
(relation controlExpectReadyFact (scenario) ())
(relation controlExpectBlockedFact (scenario) (("current")))
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
