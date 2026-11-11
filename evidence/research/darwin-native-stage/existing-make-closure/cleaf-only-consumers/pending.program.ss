(define-evidence (query) (sources) (outputs dxNativeReady dxActualReusePermit dxM8Retired dxFullBuildGain dxIncrementalReady)
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
(relation dxNativeStage (id demand) (("selected" "reuse-explicit-artifact")))
(relation dxNativeGuard (id guard) (("selected" "same-workspace") ("selected" "authenticated-generation") ("selected" "same-config-no-processes") ("selected" "zero-core-generation") ("selected" "nochange-zero-native") ("selected" "fixtures-pass") ("selected" "budgets-preserved")))
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

)
