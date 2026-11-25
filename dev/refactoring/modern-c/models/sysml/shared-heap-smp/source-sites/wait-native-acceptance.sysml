/* Native acceptance source refinement; no new QNT/Lean transition model. */
package GambitSharedHeapSmpWaitNativeAcceptance {
 private import GambitSharedHeapSmp::*;
 part acceptWaitWithdrawal:SourceSite {
  attribute :>> id="acceptWaitWithdrawal";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##thread-lock-remove-btq-toq! thread proc arg1)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Interrupt propagation removes existing BTQ and TOQ membership before making the target runnable; a service wake is not a terminal mutex grant.";
  attribute :>> required="Bind each known withdrawal and next arm to the same logical wait/shot; prove no live old arm before rearm and preserve original deadline.";
  attribute :>> gap="No production arm receipt or independent canonical queue membership probe is qualified.";
  ref part :>> question=cutSource;
 }
 part acceptWaitTimeout:SourceSite {
  attribute :>> id="acceptWaitTimeout";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##mutex-lock-out-of-line! mutex absrel-timeout new-owner)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Slow entry computes timeout with locks released, rechecks ownership, and only then captures for a real wait.";
  attribute :>> required="Cover both public fast bypass and the second immediate branch after wait entry; keep evaluated absolute deadline through service and fallback.";
  attribute :>> gap="Public immediate mutex tests alone do not execute the generated wait corridor.";
  ref part :>> question=cutSource;
 }
 part acceptWaitCaptureRoute:SourceSite {
  attribute :>> id="acceptWaitCaptureRoute";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##thread-continuation-capture thread)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Thread continuation capture interrupts the target and captures in a service lambda; it is not an inert view of the untouched blocked wait.";
  attribute :>> required="Classify service/capture observer effects and arm withdrawal explicitly; use no capture/reflection hook in the eligible no-escape cost cohort.";
  attribute :>> gap="Existing callback-k tests cannot establish normal production wait reentry or eligible alpha.";
  ref part :>> question=cutSource;
 }
 part acceptWaitPbtScope:SourceSite {
  attribute :>> id="acceptWaitPbtScope";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-transfer.scm";
  attribute :>> anchor="(define (transfer-trial commands fault?)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Current eight histories exercise a serial DEV RC record via overridden trial; they do not interleave production queue conversion.";
  attribute :>> required="Reuse trial/signature/shrink with typed production observations; add service-withdraw/rearm and terminal-result scenarios and preserve same failure signature.";
  attribute :>> gap="Production adapter, topology-preserving replay ingress and branch-complete native oracle are absent.";
  ref part :>> question=cutSource;
 }
 part normalWaitAcceptanceClause:AdapterClause {
  attribute :>> id="normalWaitAcceptanceClause";
  attribute :>> kind="validation";
  attribute :>> rule="Observe actual wait entry, queue state, selected outcome, repaired return frame, public result and natural Thread join without invoking an escape before production wait return. Immediate public bypass is a separate control.";
  attribute :>> missing="Production static/late-landing fixtures and independent operand/slot oracle remain absent. DEV generic normal-return fixture requires a bound cached cohort and cannot qualify current vendor HEAD.";
  attribute :>> acceptance="Existing five-gate acceptance, real generated branches and complete normal result/GC/exit oracle; preserve original topology and budgets";
  ref part :>> adapter=freezeAdapter; ref part :>> site=acceptWaitTimeout;
 }
 part normalWaitAcceptance:SourceCase {
  attribute :>> id="normalWaitAcceptance";
  attribute :>> precondition="Qualified source/generator/runtime cohort, declared logical wait/shot/arm, controlled legal scheduling witnesses and no extra heap or census budget";
  attribute :>> argument="Observe actual wait entry, queue state, selected outcome, repaired return frame, public result and natural Thread join without invoking an escape before production wait return. Immediate public bypass is a separate control.";
  attribute :>> conclusion="One complete native acceptance design is specified; no production native pass or architectural retirement is inferred";
  attribute :>> missing="Production static/late-landing fixtures and independent operand/slot oracle remain absent. DEV generic normal-return fixture requires a bound cached cohort and cannot qualify current vendor HEAD.";
  attribute :>> acceptance="Cases and independent observations in the existing request-service design; whole five-gate and original-load closure remain required";
  attribute :>> formalBoundary="Existing interrupt_request_lifecycle waitServiceEntry/waitRepark/waitControlSafe own temporal cardinality; Lean alone owns slots/aliases/intervals. These source/native oracle premises add no duplicate proof.";
  attribute :>> counterexample="A double-restore callback exits before the old queue path, or a public immediate lock test never enters the generated wait corridor.";
  ref part :>> clause=normalWaitAcceptanceClause; ref part :>> entrySite=acceptWaitTimeout; ref part :>> exitSite=settlementRootRestore;
 }
 part normalWaitAcceptanceDependency:CaseDependency { attribute :>> condition="Production same-wait generator/root/fallback/exit adapter required before native closure"; ref part :>> dependent=normalWaitAcceptance; ref part :>> prerequisite=sameWaitImplementation; }
 part lateFallbackAcceptanceClause:AdapterClause {
  attribute :>> id="lateFallbackAcceptanceClause";
  attribute :>> kind="validation";
  attribute :>> rule="Separate logical wait, user shot and physical arm. A terminal result is consumed once. A known removed arm plus unsatisfied durable predicate may authorize one fresh arm; UNKNOWN and query alone may not. Keep original deadline and no request service replay.";
  attribute :>> missing="Concrete arm settlement/query, bounded preknown identity and queue/outcome probes are not implemented.";
  attribute :>> acceptance="Existing five-gate acceptance, real generated branches and complete normal result/GC/exit oracle; preserve original topology and budgets";
  ref part :>> adapter=freezeAdapter; ref part :>> site=acceptWaitWithdrawal;
 }
 part lateFallbackAcceptance:SourceCase {
  attribute :>> id="lateFallbackAcceptance";
  attribute :>> precondition="Qualified source/generator/runtime cohort, declared logical wait/shot/arm, controlled legal scheduling witnesses and no extra heap or census budget";
  attribute :>> argument="Separate logical wait, user shot and physical arm. A terminal result is consumed once. A known removed arm plus unsatisfied durable predicate may authorize one fresh arm; UNKNOWN and query alone may not. Keep original deadline and no request service replay.";
  attribute :>> conclusion="One complete native acceptance design is specified; no production native pass or architectural retirement is inferred";
  attribute :>> missing="Concrete arm settlement/query, bounded preknown identity and queue/outcome probes are not implemented.";
  attribute :>> acceptance="Cases and independent observations in the existing request-service design; whole five-gate and original-load closure remain required";
  attribute :>> formalBoundary="Existing interrupt_request_lifecycle waitServiceEntry/waitRepark/waitControlSafe own temporal cardinality; Lean alone owns slots/aliases/intervals. These source/native oracle premises add no duplicate proof.";
  attribute :>> counterexample="Cumulative inserts exceed one legitimately, but two live arms or deadline reset are accepted; alternatively legitimate rearm is incorrectly forbidden.";
  ref part :>> clause=lateFallbackAcceptanceClause; ref part :>> entrySite=acceptWaitWithdrawal; ref part :>> exitSite=settlementPhysicalRegistration;
 }
 part lateFallbackAcceptanceDependency:CaseDependency { attribute :>> condition="Production same-wait generator/root/fallback/exit adapter required before native closure"; ref part :>> dependent=lateFallbackAcceptance; ref part :>> prerequisite=sameWaitImplementation; }
 part waitExitAcceptanceClause:AdapterClause {
  attribute :>> id="waitExitAcceptanceClause";
  attribute :>> kind="validation";
  attribute :>> rule="After actual normal return or supported abnormal exit, ACK drops transfer custody only; cached dispatcher locals, user captured frames, result/query consumers and next-round root obligations drain independently. Fresh user shots receive fresh physical authority.";
  attribute :>> missing="Production cached-action drain, owner exit/next-round root observations and no-escape fallback acceptance remain unqualified.";
  attribute :>> acceptance="Existing five-gate acceptance, real generated branches and complete normal result/GC/exit oracle; preserve original topology and budgets";
  ref part :>> adapter=freezeAdapter; ref part :>> site=settlementCachedAction;
 }
 part waitExitAcceptance:SourceCase {
  attribute :>> id="waitExitAcceptance";
  attribute :>> precondition="Qualified source/generator/runtime cohort, declared logical wait/shot/arm, controlled legal scheduling witnesses and no extra heap or census budget";
  attribute :>> argument="After actual normal return or supported abnormal exit, ACK drops transfer custody only; cached dispatcher locals, user captured frames, result/query consumers and next-round root obligations drain independently. Fresh user shots receive fresh physical authority.";
  attribute :>> conclusion="One complete native acceptance design is specified; no production native pass or architectural retirement is inferred";
  attribute :>> missing="Production cached-action drain, owner exit/next-round root observations and no-escape fallback acceptance remain unqualified.";
  attribute :>> acceptance="Cases and independent observations in the existing request-service design; whole five-gate and original-load closure remain required";
  attribute :>> formalBoundary="Existing interrupt_request_lifecycle waitServiceEntry/waitRepark/waitControlSafe own temporal cardinality; Lean alone owns slots/aliases/intervals. These source/native oracle premises add no duplicate proof.";
  attribute :>> counterexample="ACK permits early root release, join is treated as proof no captured references remain, or an observer-induced nested wait is mistaken for the target wait.";
  ref part :>> clause=waitExitAcceptanceClause; ref part :>> entrySite=settlementCachedAction; ref part :>> exitSite=settlementThreadExit;
 }
 part waitExitAcceptanceDependency:CaseDependency { attribute :>> condition="Production same-wait generator/root/fallback/exit adapter required before native closure"; ref part :>> dependent=waitExitAcceptance; ref part :>> prerequisite=sameWaitImplementation; }

 part acceptWaitMarginalCost:SourceSite {
  attribute :>> id="acceptWaitMarginalCost";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##mutex-wait! mutex timeout new-owner)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Checked Scheme captures and creates recursive resume once on real wait entry; subsequent resume calls reuse wait via THREAD_PARK. This is source behavior, not a matched native allocation count.";
  attribute :>> required="Separate slow entries, eligible eliminated captures/closures, service rearms and GC materialization/scans. Compare to current modern-C, not repeated capture assumed from an older repair path.";
  attribute :>> gap="Current-producer native subpopulation counts, valid allocation deltas and original-load net-benefit/peak remain absent; N_rearm cannot multiply capture savings.";
  ref part :>> question=cutSource;
 }

 part waitNativeFlow:Flow { ref part :>> producer=control; ref part :>> consumer=execution; attribute :>> contract="Repair9: normal wait return without early escape, selected terminal outcome or authorized same-wait rearm, then natural completion and independently drained root users"; }
 part waitNormalOverlay:SourceSite {
  attribute :>> id="waitNormalOverlay";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-restore.scm";
  attribute :>> anchor="(define (normal-wait-trial commands fault?)";
  attribute :>> role="request-service-design";
  attribute :>> observed="DEV fixture uses actual mutex wait/grant, completed interrupt service and full GC, then natural worker join; RC transfer/query/ACK and held-reader retirement remain test-owned.";
  attribute :>> required="Bind actual native output to cached compiler/archive/mem identities; distinguish public post-service waiting witness from canonical whole-queue proof and production conversion.";
  attribute :>> gap="No emitted S/late general landing, production arm/query receipt or complete canonical BTQ/TOQ observer is implemented.";
  ref part :>> question=cutSource;
 }
 part waitNormalReplay:SourceSite {
  attribute :>> id="waitNormalReplay";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-restore.scm";
  attribute :>> anchor="COMPLETION-WAIT-NORMAL-SHRINK";
  attribute :>> role="request-service-design";
  attribute :>> observed="Existing in-process trial/signature/shrink is reused for real-worker histories; topology is inherited from map R=3/W=2 rather than the generic p1 child.";
  attribute :>> required="Require pass for all positive histories, explicit invalid guards, same-signature shrink of actual early RC retirement, and preserved natural-result/winding/GC assertions.";
  attribute :>> gap="Controlled schedules and serial fixture record do not prove arbitrary C concurrency, latest vendor cohort or all nine candidate branches.";
  ref part :>> question=cutSource;
 }
 part exitRootClose:SourceSite {
  attribute :>> id="exitRootClose";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="___HIDDEN ___BOOL rc_can_close";
  attribute :>> role="request-service-design";
  attribute :>> observed="Existing cleanup refuses non-FAL primary/array roots, root borrows, joined rounds and scan leases; byte-only RC owners may detach after closure.";
  attribute :>> required="Target installation and actual source-owner clear must precede PSTATE cleanup; a borrowed or nonempty source refuses, rather than silently losing its scanner.";
  attribute :>> gap="No production S/intent transfer receipt is signed by these cleanup predicates.";
  ref part :>> question=cutSource;
 }
 part exitStillTransfer:SourceSite {
  attribute :>> id="exitStillTransfer";
  attribute :>> artifact="vendor/gambit/lib/_mem/still-sweep.inc";
  attribute :>> anchor="void ___lifecycle_handoff";
  attribute :>> role="request-service-design";
  attribute :>> observed="The current handoff concatenates still chains and accounting. It does not move an RC registration to another domain.";
  attribute :>> required="Keep source/target RC homes separate; install target, scan overlap, ACK/clear by the real source writer, then close/join and drain byte owner.";
  attribute :>> gap="Still-only native payload control is not a moving-frame/denv or arbitrary root-transfer proof.";
  ref part :>> question=cutSource;
 }
 part exitVmClose:SourceSite {
  attribute :>> id="exitVmClose";
  attribute :>> artifact="vendor/gambit/lib/_setup/vm-lifecycle.inc";
  attribute :>> anchor="static ___BOOL cleanup_vm_owned";
  attribute :>> role="request-service-design";
  attribute :>> observed="VM cleanup requires current owner, single remaining processor and quiet resize; nonempty or borrowed RC roots refuse before destruction.";
  attribute :>> required="Retain source VM on unknown/unqualified root export; healthy VM roots remain owned independently. Cross-VM moving SCM pointer export requires a separate admitted domain contract.";
  attribute :>> gap="No arbitrary shared moving graph may be transplanted into another VM by copying a root pointer.";
  ref part :>> question=cutSource;
 }
 part exitOverlayConsumers:SourceSite {
  attribute :>> id="exitOverlayConsumers";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-exit.h";
  attribute :>> anchor="static int wait_exit_stopped";
  attribute :>> role="request-service-design";
  attribute :>> observed="DEV adapter observes real resize join/data-close fields and detached byte-domain state; separate VM helper uses public setup/cleanup and actual RC roots.";
  attribute :>> required="Bind native outcomes to exact cached profile and source versions; preserve failed controller-placement precondition; current producer and production query/ACK remain separate.";
  attribute :>> gap="Controlled still-payload/VM refusal and reclamation checks do not implement static fallback, concurrent intent settlement or unknown-join recovery.";
  ref part :>> question=cutSource;
 }

 part lateLandingPublish:AdapterClause {
  attribute :>> id="lateLandingPublish";
  attribute :>> kind="publication";
  attribute :>> rule="A typed static retry and materialized general landing consume the same W/U/A and selected outcome. Installed target roots precede published status/ACK; query never invokes either landing. Known withdrawal plus predicate check may authorize a new arm, UNKNOWN may not.";
  attribute :>> missing="Semantic S/PointId lowering, normal/RETI materialization, production rooted intent/lookup/pin and C atomic/lock refinement are absent";
  attribute :>> acceptance="One same-cohort campaign covers target install/freeze, lost responses, grant versus rearm, exposure/GC, actual source exit and last-user release without duplicate action or physical live arm";
  ref part :>> adapter=freezeAdapter; ref part :>> site=settlementParkEmission;
 }
 part postRegistrationLanding:SourceCase {
  attribute :>> id="postRegistrationLanding";
  attribute :>> precondition="Preknown scoped key and source loan; admitted semantic snapshot and code/layout identity; complete canonical roots; bounded existing activation metadata; explicit sharing/VM boundary";
  attribute :>> argument="After checks repair roots and decode exact S, select terminal normal/exception landing or qualified pending-wait rearm. Materialize general frames under the same logical state before exposing them; never call an unqualified generic park as if the original wait had not registered. Target install and status commit precede source ACK; querying is observation only. Actual source writer closure, known join and last users gate retirement; cross-VM pointer transfer remains unadmitted.";
  attribute :>> conclusion="A complete static-entry/general-landing/query-ACK/exit implementation contract is specified, with independent native foundation controls; no production implementation or whole-gate proof follows";
  attribute :>> missing="Production S and exposure materialization; bounded resident intent and generation/pin reuse; concrete C publication/locks; moving frame/denv and unknown-join closure; original workload/cost acceptance";
  attribute :>> acceptance="Existing map/normal-wait/PBT plus actual PSTATE/VM foundation controls; generated late-landing branch matrix and current producer required before qualification";
  attribute :>> formalBoundary="Existing QNT owns temporal partial/unknown settlement and live-arm cardinality; existing Lean alone owns slot/alias/relocation/interval laws. Concrete source relations and C publication remain adapters, not duplicate proofs.";
  attribute :>> counterexample="Bare SCM is put in another VM root; source scanner is destroyed before installed target; a lost receipt replays generic registration; ACK frees a cached code/root user; still-chain handoff is mistaken for RC-root transfer";
  ref part :>> clause=lateLandingPublish; ref part :>> entrySite=settlementParkEmission; ref part :>> exitSite=exitRootClose;
 }
 part lateLandingDependency:CaseDependency { attribute :>> condition="Eligible semantic/frame/root and same-wait fallback/settlement prerequisites remain necessary"; ref part :>> dependent=postRegistrationLanding; ref part :>> prerequisite=sameWaitImplementation; }
 part lateLandingExitFlow:Flow { ref part :>> producer=roots; ref part :>> consumer=retirement; attribute :>> contract="Repair9: install protected target before source ACK; real source close and join permit byte-only drain, not arbitrary cross-VM pointer export or final cached-user release"; }
}
