(define-evidence (query) (sources) (outputs dxNativeReady dxActualReusePermit dxM8Retired dxFullBuildGain dxCheckReusable dxSharedCompiledReady)
;; SysML owns the question inventory; source-bound configuration observations
;; identify a difference, never a new speedup or a completed M8 retirement.
(relation dxQuestion (id status))
(relation dxClosedStatus (status) (("closed")))
(relation dxOpen (id))
((dxOpen I) <-- (dxQuestion I S) (not (dxClosedStatus S)))
(relation dxEvidenceIdentity (digest))
(relation dxConfigured (digest id macroPolicy))
(relation dxRetained (digest id macroPolicy))
(relation dxMacroPolicyDifference (current retained))
((dxMacroPolicyDifference C R) <-- (dxEvidenceIdentity H)
 (dxConfigured H C "absent") (dxRetained H R "enabled"))
;; Actual paired full-build acceptance is a separate, presently absent fact.
(relation dxFullBuildGain (source))

;; These are projected dependencies owned by SysML. They are not permission
;; to reuse a concrete output: the stable read/effect snapshot remains separate.
(relation dxArtifactInput (role input))
(relation dxArtifactEdge (upstream downstream))
(relation dxChangedInput (input))
(relation dxKnownArtifactInput (input))
((dxKnownArtifactInput I) <-- (dxArtifactInput _ I))
(relation dxUnmappedInput (input))
((dxUnmappedInput I) <-- (dxChangedInput I) (not (dxKnownArtifactInput I)))
(relation dxProjectedInvalidation (role))
((dxProjectedInvalidation R) <-- (dxChangedInput I) (dxArtifactInput R I))
((dxProjectedInvalidation D) <-- (dxProjectedInvalidation U) (dxArtifactEdge U D))
(relation dxActualReusePermit (role))
(relation dxM8Retired (source))

;; Constructor coverage is source/test evidence, separate from native admission.
(relation dxCtorLaw (aspect text))
(relation dxCtorSource (digest))
(relation dxCtorWitness (aspect digest))
(relation dxCtorSourceCovered (aspect))
((dxCtorSourceCovered A) <-- (dxCtorLaw A _) (dxCtorSource H) (dxCtorWitness A H))
(relation dxCtorOpen (aspect))
((dxCtorOpen A) <-- (dxCtorLaw A _) (not (dxCtorSourceCovered A)))

;; Explicit native-stage product consumption is separate from general Scheme
;; cache freshness and from full M8/legacy retirement.
(relation dxNativeStage (id demand))
(relation dxNativeGuard (id guard))
(relation dxNativeReady (id))
((dxNativeReady I) <-- (dxNativeStage I "reuse-explicit-artifact")
 (dxNativeGuard I "authenticated-producer")
 (dxNativeGuard I "current-scheme-equal")
 (dxNativeGuard I "generation-entry-disabled")
 (dxNativeGuard I "generated-bytes-stable")
 (dxNativeGuard I "rebuilt-consumer-tested")
 (dxNativeGuard I "independent-regeneration-equal"))

;; Selected existing-Make controls, not general cache freshness or M8 retirement.
;; SysML explicitNativeStage owns these distinct evidence requirements.
(relation dxIncrementalReady (id))
((dxIncrementalReady I) <-- (dxNativeStage I "reuse-explicit-artifact")
 (dxNativeGuard I "same-workspace")
 (dxNativeGuard I "authenticated-generation")
 (dxNativeGuard I "same-config-no-processes")
 (dxNativeGuard I "zero-core-generation")
 (dxNativeGuard I "nochange-zero-native")
 (dxNativeGuard I "cleaf-only-consumers")
 (dxNativeGuard I "fixtures-pass")
 (dxNativeGuard I "budgets-preserved"))

;; Reuse is bounded by the SysML policy lifetime. Retained observations,
;; unresolved fixture compilations and fresh SMP samples are not live permits.
(relation dxCheckPolicy (check lifetime status) (("configuration-proof" "qualified-task-profile" "selected-reuse") ("leased-tree-identity" "live-recipe-lease" "selected-reuse") ("completed-step" "retained-observation" "retained-only") ("fixture-compilation" "same-recipe-compiled-artifact" "same-recipe-only") ("smp-execution" "actual-execution" "fresh-required") ("framework-controls" "qualified-test-context" "conditional")))
(relation dxCheckPrior (case check key) (("selected" "fixture-compilation" "46ceab16f4eb58e9f39329bdca36fe249d87511a14814bd714d2c5d9b5e7ab79")))
(relation dxCheckCurrent (case check key) (("selected" "fixture-compilation" "46ceab16f4eb58e9f39329bdca36fe249d87511a14814bd714d2c5d9b5e7ab79")))
(relation dxCheckLiveScope (case check lifetime) (("selected" "fixture-compilation" "same-recipe-compiled-artifact")))
(relation dxCheckReusable (case check))
((dxCheckReusable C K) <-- (dxCheckPolicy K L "selected-reuse")
 (dxCheckPrior C K H) (dxCheckCurrent C K H) (dxCheckLiveScope C K L))

;; A same-recipe compiled fixture needs its actual producer and native guards,
;; even when the artifact key matches. This is not a compiler-purity theorem.
(relation dxSharedGuard (id guard) (("selected" "direct-live-producer") ("selected" "source-and-artifact-match") ("selected" "toolchain-match") ("selected" "original-cwd-match") ("selected" "successful-compile") ("selected" "three-compiles-five-executions") ("selected" "same-workspace-budgets")))
(relation dxSharedCompiledReady (id))
((dxSharedCompiledReady I) <--
 (dxSharedGuard I "direct-live-producer")
 (dxSharedGuard I "source-and-artifact-match")
 (dxSharedGuard I "toolchain-match")
 (dxSharedGuard I "original-cwd-match")
 (dxSharedGuard I "runtime-match")
 (dxSharedGuard I "successful-compile")
 (dxSharedGuard I "three-compiles-five-executions")
 (dxSharedGuard I "same-workspace-budgets"))
((dxCheckReusable C "fixture-compilation") <-- (dxSharedCompiledReady C)
 (dxCheckPolicy "fixture-compilation" L "same-recipe-only")
 (dxCheckPrior C "fixture-compilation" H) (dxCheckCurrent C "fixture-compilation" H)
 (dxCheckLiveScope C "fixture-compilation" L))

)
