;; Source witnesses for checklist 7 and 9. A supplied allocator request
;; and a valid Scheme handler arrival are different evidence boundaries.
(ascent-fragment
 (relation observed_step ((step symbol?) (status string?) (capability string?)))
 (relation c_verdict ((step symbol?) (contract string?) (branch string?) (verdict string?) (scope string?)))
 (relation c_source ((step symbol?) (path string?) (sha string?)))
 (relation c_property ((step symbol?) (property string?) (status string?) (file string?) (line string?) (description string?)))
 (relation c_reachability ((step symbol?) (contract string?) (branch string?) (witness string?) (status string?)))
 (relation implementation_cut ((step symbol?) (source string?) (sha string?) (verdict string?) (scope string?)))
 (relation winner_order ((winner string?) (step symbol?) (source string?) (sha string?)))
 (relation repair_target ((step symbol?) (source string?) (sha string?) (obligation string?)))
 ((implementation_cut S P H V D) <--
   (c_verdict S _ _ V D) (c_source S P H)
   (observed_step S (lit "PASS") _))
 ((winner_order (lit "carrier-0") S (lit "vendor/gambit/lib/_mem/heap-sections.inc") H) <--
   (implementation_cut S (lit "vendor/gambit/lib/_mem/heap-sections.inc") H (lit "COUNTEREXAMPLE") _)
   (c_property S _ (lit "FAILURE") _ _ (lit "carriers[1].result == 1")))
 ((winner_order (lit "carrier-1") S (lit "vendor/gambit/lib/_mem/heap-sections.inc") H) <--
   (implementation_cut S (lit "vendor/gambit/lib/_mem/heap-sections.inc") H (lit "COUNTEREXAMPLE") _)
   (c_property S _ (lit "FAILURE") _ _ (lit "carriers[0].result == 1")))
 ((repair_target S (lit "vendor/gambit/lib/_kernel.scm") H
     (lit "refuse-failed-reload-before-destination-shortage-and-publish-current-fp")) <--
   (implementation_cut S (lit "vendor/gambit/lib/_kernel.scm") H (lit "REACHABILITY") _)
   (c_reachability S (lit "rest-source/custody") (lit "post-gc-entry")
     (lit "control.failed-root-reload-must-not-enter-extension") (lit "REACHED")))
 ((repair_target S (lit "vendor/gambit/lib/_mem/heap-sections.inc") H
     (lit "follow-validated-break-link-and-retain-old-pin-through-last-use")) <--
   (implementation_cut S (lit "vendor/gambit/lib/_mem/heap-sections.inc") H (lit "VERIFIED") _)
   (c_property S _ (lit "SUCCESS") _ _
     (lit "___rest_chain_reads == 1 && ___rest_chain_gates == 1 && old_gates == 0")))
 ((repair_target S (lit "vendor/gambit/lib/_mem/heap-sections.inc") H
     (lit "preserve-carrier-and-half-until-publication-then-observe-legal-arrivals")) <--
   (implementation_cut S (lit "vendor/gambit/lib/_mem/heap-sections.inc") H (lit "VERIFIED") _)
   (c_property S _ (lit "SUCCESS") _ _ (lit "ps->heap_limit == storage[2]+HALF-___MSECTION_FUDGE")))
 ((repair_target (lit (quote concurrent-prefix-counters)) (lit "vendor/gambit/lib/_mem/heap-sections.inc") H
     (lit "isolate-walk-observation-counters-from-concurrent-carriers")) <--
   (implementation_cut (lit (quote concurrent-prefix-counters)) (lit "vendor/gambit/lib/_mem/heap-sections.inc") H (lit "COUNTEREXAMPLE") _)
   (c_property (lit (quote concurrent-prefix-counters)) (lit "genmc.safety") (lit "FAILURE") _ _ (lit "Non-atomic race")))
)
