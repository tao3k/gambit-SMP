(ascent-fragment
 ;; Scenario-Driven Verification Tool Routing (Families 8/12..12/12)
 ;;
 ;; Design Principle:
 ;;   No tool has static global precedence over another. Instead, ASCENT
 ;;   declarative Datalog rules match each verification obligation's structural
 ;;   features (weak-memory C11 atomics, bounded vs full-runtime scope, protocol
 ;;   interleavings, binary wire traces, GC/continuation/FFI roots, unbounded
 ;;   algebraic invariants) against each verification tool's exact capability
 ;;   envelope and host availability. Reasoning tooling (LLM + ASCENT) uses the
 ;;   resulting `routeExecutable`, `routeNeedsInstall`, and `routeUncovered`
 ;;   relations to compose the optimal multi-engine verification plan per target.

 ;; Input relations:
 ;;   obligation(id, family, summary)
 ;;   obligationFeature(id, feature)
 ;;     features: "weak-memory-c11" | "bounded-c-fn" | "full-runtime-c" |
 ;;               "protocol-interleaving" | "lock-graph" | "wire-trace" |
 ;;               "unbounded-law" | "concurrent-adt" | "gc-roots-or-cc" |
 ;;               "ffi-or-multi-vm"
 ;;   toolCapability(tool, feature, rationale)
 ;;   toolInstalled(tool)

 (relation obligation ((id string?) (family string?) (summary string?)))
 (relation obligationFeature ((id string?) (feature string?)))
 (relation toolCapability ((tool string?) (feature string?) (rationale string?)))
 (relation toolInstalled ((tool string?)))

 ;; Derived routing relations
 (relation routeCandidate ((obligation string?) (tool string?) (feature string?) (rationale string?)))
 (relation routeExecutable ((obligation string?) (tool string?) (feature string?) (rationale string?)))
 (relation routeNeedsInstall ((obligation string?) (tool string?) (feature string?) (rationale string?)))
 (relation obligationCovered ((obligation string?)))
 (relation obligationUncovered ((obligation string?) (family string?)))
 (relation multiEngineRequired ((obligation string?)))

 ;; Feature-driven tool match (symmetric, no static precedence)
 ((routeCandidate O T F R) <--
  (obligation O _ _)
  (obligationFeature O F)
  (toolCapability T F R))

 ;; Partition candidates by current host installation state
 ((routeExecutable O T F R) <--
  (routeCandidate O T F R)
  (toolInstalled T))

 ((routeNeedsInstall O T F R) <--
  (routeCandidate O T F R)
  (not (toolInstalled T)))

 ;; Coverage check: an obligation is covered iff at least one executable route exists
 ((obligationCovered O) <--
  (routeExecutable O _ _ _))

 ((obligationUncovered O Fam) <--
  (obligation O Fam _)
  (not (obligationCovered O)))

 ;; Flag obligations whose structural features span distinct verification engines
 ;; (e.g. both weak-memory C11 AND full-runtime GC/FFI), requiring joint evidence.
 ((multiEngineRequired O) <--
  (routeCandidate O T1 _ _)
  (routeCandidate O T2 _ _)
  (if (T1 T2) (not (equal? T1 T2))))
)
