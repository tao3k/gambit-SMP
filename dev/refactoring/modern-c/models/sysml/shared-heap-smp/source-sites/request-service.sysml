/* Existing-owner source refinement; conditional arguments, no native satisfaction. */
package GambitSharedHeapSmpRequestServiceSources {
 private import GambitSharedHeapSmp::*;
 part modernRequestAuthority:SourceSite {
  attribute :>> id="modernRequestAuthority";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##thread-intr-service! request)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Published32028f5d already creates one immutable target/thunk/completion request, claims queued->running under the completion mutex, and commits result/returned before unlock. A completed multi-shot suffix cannot republish. The running/nonrunning routes are transports, not two semantic request identities.";
  attribute :>> required="Refine private construction, published acceptance, claim, initial thunk invocation, terminal outcome and consumer closure separately. Reuse this owner; do not build another request registry. Keep normal result, abandonment, exception presence/value and unsupported live escape distinct. At-most-one initial dispatch/terminal publication does not forbid legitimate repeated user effects after continuation restore.";
  attribute :>> gap="Actual interleaving/memory-order and all exceptional suffix evidence remain open; existing state checks alone do not prove liveness or original-load capacity.";
  ref part :>> question=cutSource;
 }
 part modernWaitFrameBoundary:SourceSite {
  attribute :>> id="modernWaitFrameBoundary";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim ##thread-park!";
  attribute :>> role="request-service-design";
  attribute :>> observed="SMP join/sleep/mutex wait entries capture a reusable logical wait and clear only that internal wait denv; native C can lower thread-park directly, while the portable fallback copies a continuation wrapper and grafts. thread-resume-execution drains service then invokes the saved wait resume thunk.";
  attribute :>> required="Prove the full wait suffix, current effective denv, user captures, timeout identity, BTQ/TOQ registration and nested resumes survive every park/service/repark. Count actual inline versus fallback paths and initial captures separately. User continuations remain multi-shot; old internal wait state is not generic authority to execute a request.";
  attribute :>> gap="Neither all wait transitions nor denv/cross-logical-thread continuation suffixes are qualified by one map replay. Do not report zero total capture/GC work from the native park prefix.";
  ref part :>> question=cutSource;
 }
 part modernParkPublication:SourceSite {
  attribute :>> id="modernParkPublication";
  attribute :>> artifact="vendor/gambit/include/_gambit/gvm_operations.h.in";
  attribute :>> anchor="#define ___THREAD_PARK";
  attribute :>> role="request-service-design";
  attribute :>> observed="THREAD_PARK reinstalls the wait frame in stack-break and Thread.cont, changes FP and R0, and performs no allocator or frame-payload copy inside that prefix. The emitter supports arities2..5 after end-of-block checks; those checks may still collect before the prefix.";
  attribute :>> required="Map complete roots/FrameSpec before entry and at the registration callback; no unpublished moving C local may cross collection. Preserve logical continuation frame sharing and current denv. Certify root publication before queue locks and distinguish zero payload copy in this prefix from initial capture, collector materialization and user restores.";
  attribute :>> gap="Published _thread.c selects PARK5/4/2 in join/sleep/mutex respectively. That establishes emitted selection only: all legal collecting cuts, register roots, frame maps and whole-repark allocation still require native qualification.";
  ref part :>> question=cutSource;
 }
 part modernTransportCustody:SourceSite {
  attribute :>> id="modernTransportCustody";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___EXP_FUNC(___SCMOBJ,___get_next_high_level_interrupt_pstate)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Processor enqueue writes intrusive slot0 under PRIMLOCK; dequeue transfers the head and clears slot0 before returning. Thread routing also uses slot0. Current ticket-grant polling uses ordered acquire and release unlock, unlike the historical volatile-only finding.";
  attribute :>> required="Maintain exclusive membership: private, one physical queue, mapped claimed invocation or retained terminal consumer. A popped node needs a live mapped root before reroute/GC; publication and detach transfer custody once. Preserve the selected GCC/C23 acquire/release backend and every T/P/V lock edge. Two audited transport queues may remain; neither owns semantic completion.";
  attribute :>> gap="Do not reapply the old lock patch or infer native weak-memory correctness from a macro name. Complete source/runtime cohort and concurrent publish/take/GC evidence remain open.";
  ref part :>> question=cutSource;
 }
 part modernWakeDisposition:SourceSite {
  attribute :>> id="modernWakeDisposition";
  attribute :>> artifact="vendor/gambit/lib/os_io.c";
  attribute :>> anchor="void ___device_select_abort";
  attribute :>> role="request-service-design";
  attribute :>> observed="The current native abort transport still ignores POSIX write and Win32 SetEvent outcomes. Durable pending state and transport return are distinct from completed Scheme request service.";
  attribute :>> required="Before a park can be indefinite, prove either effective wake/coalescing or an independently qualified backend return path; preserve original absolute deadlines. Recheck durable runnable/control state on every normal native return. Classify EINTR/EAGAIN/hard failure and retain a live custodian without inventing success; source adapters remain platform-specific.";
  attribute :>> gap="No universal wait-return bound or safe arbitrary C unwind follows. This is a remaining implementation seam, not evidence that a failed write caused Repair19.";
  ref part :>> question=cutSource;
 }
 part modernServiceExitRoots:SourceSite {
  attribute :>> id="modernServiceExitRoots";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##thread-end-locked! thread exception? result)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Thread end records exception presence separately, clears thread control/environment fields, abandons owned blocked queues and wakes joiners. Continuation scanning separately decodes actual context frames; retained native/root metadata has different owners.";
  attribute :>> required="Before clearing any service/wait/request root, provide its last use or successor rooted owner, including captured user suffixes. Normal reply, target abandonment, escaped-live invocation and unknown native stop have distinct custody. Root-transfer ACK/result-consumer/query-pin retirement does not substitute for the request reply or physical thread join.";
  attribute :>> gap="Complete native/nonlocal/catcher closure is not proven. UNKNOWN raw writers may block their affected shared collection cut; metadata-only retention must not masquerade as raw quiescence.";
  ref part :>> question=cutSource;
 }
 part repair9ClosedLoopBound:SourceSite {
  attribute :>> id="repair9ClosedLoopBound";
  attribute :>> artifact="vendor/gambit/tests/unit-tests/06-thread/thread_interrupt2_stress.scm";
  attribute :>> anchor="(define iterations 1000000)";
  attribute :>> role="request-service-design";
  attribute :>> observed="The original fixture has ten synchronous senders per target, G=floor((p+1)/2) independent groups and one million iterations per sender. At p11 this gives at most60 created nonterminal requests under the single-outstanding/no-nested-action premises and60 million requested calls per subtest. Some targets have a1000-second sleep/mutex timeout.";
  attribute :>> required="Conditional bound: created=preaccept refusal+accepted and accepted=terminal+retained outstanding; after scope settlement outstanding<=10G for this fixture. For an armed target with R_i remaining calls and delta_i usable lifetime, completion requires service of R_i within delta_i, not merely at-most-once safety. If all10 million remain at1000-second arm, the necessary rate exceeds10000 calls/s per target plus scheduling margin. All six subtests call flood, giving360 million requested calls at p11. For original whole-fixture budget B the aggregate necessary rate is360000000/B; the historical3600-second example implies100000/s before other work, without changing the actual native recipe. Measure actual arm, remaining work, subtest and target exit reason.";
  attribute :>> gap="The whole-loader3232.7-second time cannot locate a target deadline or prove its expiry. Pre-arm service and scheduling affect R_i. The120000-request sample is not an extrapolated deadline proof; the bound is fixture-specific, not universal constant memory.";
  ref part :>> question=cutSource;
 }
 part modernParkEmitter:SourceSite {
  attribute :>> id="modernParkEmitter";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-2.scm";
  attribute :>> anchor="(targ-jump-inline \"##thread-park!\"";
  attribute :>> role="request-service-design";
  attribute :>> observed="The C emitter performs end-of-block checks, stack adjustment and THREAD_PARK emission for the supported arities, declaring FP/register effects. Published GSC and current dirty generators are different evidence subjects.";
  attribute :>> required="Bind every actual generated park site and liveness map to the same generator/header/runtime cohort; retain fallback and portable C behavior for unsupported paths. Native C cuts must observe publication/repaired roots at the actual emitted sites, not a substituted fixture.";
  attribute :>> gap="Source selection and a successful old GSI do not qualify a changed dirty emitter or stack header; current PR qualification is source-period bound.";
  ref part :>> question=cutSource;
 }
 part requestServiceFlow0:Flow { ref part :>> producer=messages; ref part :>> consumer=control; attribute :>> contract="Repair9: one request owner; reusable wait suffix and distinct mapped service activation"; }
 part requestServiceFlow1:Flow { ref part :>> producer=control; ref part :>> consumer=roots; attribute :>> contract="Repair9: publish wait/service/request slots before park, GC and nonlocal exit"; }
 part requestServiceFlow2:Flow { ref part :>> producer=roots; ref part :>> consumer=collector; attribute :>> contract="Repair9: R frozen sources survive W worker scan, repair and whole-round closure"; }
 part requestServiceFlow3:Flow { ref part :>> producer=collector; ref part :>> consumer=execution; attribute :>> contract="Repair9: repaired roots and exact resume authority precede wait/service reentry"; }
 part requestServiceFlow4:Flow { ref part :>> producer=messages; ref part :>> consumer=retirement; attribute :>> contract="Repair9: terminal reply is not result consumption, last use or physical join"; }
 part requestServiceFlow5:Flow { ref part :>> producer=retirement; ref part :>> consumer=roots; attribute :>> contract="Repair9: retained unknown work and successor roots remain in the next GC cut"; }
 part requestServiceFlow6:Flow { ref part :>> producer=qualification; ref part :>> consumer=messages; attribute :>> contract="Repair9: original closed-loop counts, armed target deadlines and matched capacity/peak"; }

 part modernCaptureMaterialization:SourceSite {
  attribute :>> id="modernCaptureMaterialization";
  attribute :>> artifact="vendor/gambit/include/_gambit/gvm_operations.h.in";
  attribute :>> anchor="#define ___CONTINUATION_CAPTURE";
  attribute :>> role="request-service-design";
  attribute :>> observed="CONTINUATION_CAPTURE constructs a stack continuation wrapper referencing the current frame and denv. THREAD_SAVE is itself a fixed nonallocating root/control prefix; kernel continuation-copy allocates a shallow wrapper. They do not prove a deep heap copy per callback.";
  attribute :>> required="The candidate benefit is explicit frame selection and bounded live internal suffixes, not merely fewer macro calls. Retired work F_i must be measured on the actual old path; if it already drops service frames F_i may be zero. Preserve live user suffixes and exact root maps through lazy materialization and repeated GC.";
  attribute :>> gap="No historical-growing-chain or continuation-only allocation claim follows from static definitions; per-epoch frame/slot identities and live-space comparisons remain native obligations.";
  ref part :>> question=cutSource;
 }
 part modernGeneratedParkSites:SourceSite {
  attribute :>> id="modernGeneratedParkSites";
  attribute :>> artifact="vendor/gambit/lib/_thread.c";
  attribute :>> anchor="___JUMP_THREAD_PARK5(___JUMPNOTSAFE)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Published32028 _thread.c has exactly three emitted park sites: join PARK5, sleep PARK4 and mutex PARK2. Their resume closures retain wait plus operation-specific values; initial capture/closure allocation and CHECK_HEAP precede repark. Mutex's supplied-current-thread branch instead calls wait-register5 directly.";
  attribute :>> required="Qualify both mutex branches, each initial capture/closure check and the physical registration/return consumers. Bind generated bytes, emitter, primitive declaration, frame decoder and selected native backend to one cohort. Static site count is not execution coverage.";
  attribute :>> gap="No native park-site trace or complete regeneration equality is supplied by byte equality with the published generated file. Changed generator/header cohorts require fresh acceptance.";
  ref part :>> question=cutSource;
 }
 part modernServiceReturnSlots:SourceSite {
  attribute :>> id="modernServiceReturnSlots";
  attribute :>> artifact="vendor/gambit/lib/_thread.c";
  attribute :>> anchor="___DEF_LBL_RET_AT(___H__23__23_thread_2d_intr_2d_service_21_,";
  attribute :>> role="request-service-design";
  attribute :>> observed="Service return RETN(fs5,link1,gcmap0x7) has ordinary slots1/3=request/completion and structural slot2; eight-word aligned frame space is not eight object roots. Callback result initially lives in R1; temporary returned-STK(-4) is not a marked ordinary slot. Normal and slow-unlock exits pop the active service frame.";
  attribute :>> required="Prove selected lock/store suffix has no hidden collection between result spill and rooted publication, or supply a changed safe-point/root map. Never add an illegal injected GC and call it an existing failure. Popping FP removes an active edge, not captured aliases or all register/cache roots.";
  attribute :>> gap="Result liveness at every legal native safe point, complete alias closure and absence of hidden collecting macro behavior remain native/source adapter premises.";
  ref part :>> question=cutSource;
 }
 part modernDispatcherReturnSlots:SourceSite {
  attribute :>> id="modernDispatcherReturnSlots";
  attribute :>> artifact="vendor/gambit/lib/_thread.c";
  attribute :>> anchor="#define ___PH_PROC ___H__23__23_thread_2d_resume_2d_execution_21_";
  attribute :>> role="request-service-design";
  attribute :>> observed="Dispatcher saves return label and resume thunk before dispatch; RETN(fs5,link0,gcmap0x3) excludes structural slot1 and traces resume thunk in ordinary slot2. Return restores them and pops8 words before the loop; empty queue tail-calls resume. A self-recursive wait closure is legitimate bounded state, not a growing service history.";
  attribute :>> required="Track structural ancestry separately from closure free variables and Thread.resume-thunk. Tail retention ends only after every traced path is gone; valid user capture or result alias must continue to retain its suffix. Normal queue drain, timeout completion and nonlocal exit need distinct observations.";
  attribute :>> gap="Actual old/new frame-depth, copied-byte and complete-root oracle evidence is missing; a recursive closure or raw stack word alone is not a leak witness.";
  ref part :>> question=cutSource;
 }
 part modernParkRootConsumer:SourceSite {
  attribute :>> id="modernParkRootConsumer";
  attribute :>> artifact="vendor/gambit/lib/_mem/continuation-roots.inc";
  attribute :>> anchor="___HIDDEN void mark_continuation";
  attribute :>> role="request-service-design";
  attribute :>> observed="Context scan decodes active frames to stack_break, marks ordinary root runs and follows the captured break chain. Captured materialization copies frame payload, while object scanning traces ordinary slots and structural link separately. RootTask uses source context rather than executor identity.";
  attribute :>> required="Publish a complete stable context before independent worker scan and reload repaired roots before reuse; preserve unique copy and private frontier custody. Distinguish frame payload copying from tracing dead words. A root frozen before detach may legitimately retain the frame for that round.";
  attribute :>> gap="W<R publication, all legal cut roots and last frozen-reader release need native witnesses; source traversal does not establish unreachability or physical reuse.";
  ref part :>> question=cutSource;
 }
 part modernParkOtherRootPaths:SourceSite {
  attribute :>> id="modernParkOtherRootPaths";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-origins.inc";
  attribute :>> anchor="___HIDDEN void mark_registers";
  attribute :>> role="request-service-design";
  attribute :>> observed="RootOrigins also scan context registers, saved values, type cache and processor Scheme object. Thread control/environment fields, closures, user captures, request results, RC/still roots and private collector work can retain a detached suffix independently of FP.";
  attribute :>> required="Complete traced-graph absence is the frame-retirement predicate. After writers/aliases and frozen/private last users settle, an eligible completed full collection can demonstrate non-copy and reusable space; OS RSS release is separate. UNKNOWN retains its affected roots and is not zero debt.";
  attribute :>> gap="No source-only whole-root absence or fixed-one-GC reclamation theorem is claimed; retained native aliases and earlier frozen views must be qualified or remain open.";
  ref part :>> question=cutSource;
 }
 part requestServiceFlow7:Flow { ref part :>> producer=control; ref part :>> consumer=retirement; attribute :>> contract="Repair9: active detach is not graph absence; captured user suffixes keep their lifetime"; }
 part requestServiceFlow8:Flow { ref part :>> producer=retirement; ref part :>> consumer=collector; attribute :>> contract="Repair9: complete root absence and last frozen/private reader precede reuse; capacity remains independently gated"; }
 part serviceRegisterWriters:SourceSite {
  attribute :>> id="serviceRegisterWriters";
  attribute :>> artifact="vendor/gambit/include/_gambit/gvm_registers.h.in";
  attribute :>> anchor="#define ___PSR0";
  attribute :>> role="request-service-design";
  attribute :>> observed="SET_Rn writes a host local or context home according to MAX_LOCAL_GVM_REGS; R_Rn/W_Rn reload/spill. Generated procedure resource masks select R_ALL/W_ALL. Kernel sync-op, native select and allocating paths publish RA plus W_ALL, then reload R_ALL. RootOrigins scans every context register, not a per-frame register liveness subset.";
  attribute :>> required="Follow generated writes through selected spills to scanned homes and repaired reload. Only generator-proven dead values may become VOID at a legal complete-root publication; preserve live R0/code, R4/closure and pending arguments. Bounded register count does not bound the graph pinned by a stale value.";
  attribute :>> gap="No native last-use/dead-register witness or eliminated byte count exists. A SET_Rn in a host local does not prove the scanned home changed; leave unknown writes rooted.";
  ref part :>> question=cutSource;
 }
 part serviceTemporaryRootWriters:SourceSite {
  attribute :>> id="serviceTemporaryRootWriters";
  attribute :>> artifact="vendor/gambit/include/_gambit/temporary_roots.h.in";
  attribute :>> anchor="#define ___GC_RESTORE1";
  attribute :>> role="request-service-design";
  attribute :>> observed="GC_SAVE1/2/3 publish saved[]; GC_RESTORE1/2/3 reload relocated values and already overwrite the used cells with VOID. Kernel make-frame is one actual SAVE1/RESTORE1 consumer. Paired temporary roots are existing cleanup, not newly eliminated retention.";
  attribute :>> required="Normal and exceptional consumers must restore or transfer root custody once. Keep scanner updates distinct from logical rebinding; never clear a value still borrowed or needed on exceptional return.";
  attribute :>> gap="Complete exceptional SAVE/RESTORE coverage is not inferred from macro definitions; zero claimed saving for already-balanced pairs.";
  ref part :>> question=cutSource;
 }
 part serviceResumeWriterLifecycle:SourceSite {
  attribute :>> id="serviceResumeWriterLifecycle";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##thread-wait-return! current-thread result)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Scoped source census finds17 SMP and10 non-SMP resume-thunk store forms, plus both thread-init macro arms. SMP join/sleep/mutex registration install the wait closure; completion/timeout/unlock/signal replace it with semantic actions. Thread-end clears cont/denv/caches but does not itself clear resume-thunk.";
  attribute :>> required="Retain per-operation BTQ/TOQ and outcome semantics, startup closure and dispatcher-cached thunk. A reachable ended Thread may retain its last resume closure; retire that edge only after no legal resume/observer/borrow needs it. This is per-Thread conditional retention, not a proved per-request growing chain.";
  attribute :>> gap="Store census is not reflection/FFI closure. Non-SMP and startup arms cannot be credited as SMP execution. Alias/exception/continuation last-use proof and native retention evidence remain open.";
  ref part :>> question=cutSource;
 }
 part serviceRcWriterLifecycle:SourceSite {
  attribute :>> id="serviceRcWriterLifecycle";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="static ___BOOL store_rc_root";
  attribute :>> role="request-service-design";
  attribute :>> observed="Register/store/borrow use owner-domain gating and RC mutex; primary rebinding is constrained by borrows and argument spans require an SFUN activation. mark_rc traces every linked node primary cell and typed span, without filtering refcount. Release unlinks only when refcount and root_borrows are both zero.";
  attribute :>> required="Follow actual marker setup, SFUN span and Tcl command construction/pin/delete consumers. A data_rc snapshot or RC refcount is not a movable-root borrow. Clearing a still-borrowed cell or losing a failed/unknown native scope cannot establish graph absence; retain custody through actual settlement.";
  attribute :>> gap="No evidence that ordinary inc! calls allocate one RC bank each. Raw extension writes, partial native exits and frozen source last users remain adapter obligations, not eliminated work.";
  ref part :>> question=cutSource;
 }
 part serviceSfunRootConsumers:SourceSite {
  attribute :>> id="serviceSfunRootConsumers";
  attribute :>> artifact="vendor/gambit/lib/_c_intf/sfun-entry.inc";
  attribute :>> anchor="___EXP_FUNC(___SCMOBJ,___begin_sfun)";
  attribute :>> role="request-service-design";
  attribute :>> observed="begin_sfun allocates/borrows an initialized RC span except the admitted no-argument PERM fast path; generated SFUN_ARG stores typed arguments. end_sfun clears the marker then lifecycle_marker_abort returns the bank borrow and releases its owner before IDLE. Failure before accepted borrow uses a distinct release path.";
  attribute :>> required="Map native extent exit and nested/nonlocal return to this same owner before root retirement. Preserve parent pre-registration roots and the difference between accepted borrow and allocation-only failure; unknown outcome retains the scope.";
  attribute :>> gap="Definitions do not qualify every generated bridge/catcher or prove no raw alias. Ordinary Scheme interrupt service is not SFUN and must not inherit per-request bank costs.";
  ref part :>> question=cutSource;
 }
 part serviceUserContinuationWriters:SourceSite {
  attribute :>> id="serviceUserContinuationWriters";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="(define-prim (##continuation-set! cont i val)";
  attribute :>> role="request-service-design";
  attribute :>> observed="call/cc reifies cont in a returned Scheme closure; make-continuation/copy install or share frame/denv. Reflection setters write heap or stack frame slots; continuation-next! changes wrapper frame/denv. A shallow wrapper copy retains shared ancestry, and changing one wrapper cannot clear every alias.";
  attribute :>> required="Preserve multi-shot, dynamic-wind, denv, frame identity and rooted user results. Close actual reflection/serialization/FFI mutation adapters before any graph-absence or mature-scan skip claim; do not delete legitimate user captures for the original noncapturing fixture's bound.";
  attribute :>> gap="User graph reachability is input-dependent. No independent alias oracle or writer coverage proof is supplied by locating these setters; existing Lean slot laws and QNT histories retain their separate owners.";
  ref part :>> question=cutSource;
 }
 part requestServiceFlow9:Flow { ref part :>> producer=execution; ref part :>> consumer=roots; attribute :>> contract="Repair9: generated last use, host spill, complete frozen homes and repaired reload form one root publication"; }
 part requestServiceFlow10:Flow { ref part :>> producer=control; ref part :>> consumer=qualification; attribute :>> contract="Repair9: count actual wait restarts M separately from360 million requests N; subtract required captures, barriers and live user aliases"; }
 part serviceCompletionWaitCosts:SourceSite {
  attribute :>> id="serviceCompletionWaitCosts";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(macro-mutex-lock-anonymously! completion #f)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Every synchronous thread-intr waits for its completion mutex after publication. All six original subtests therefore have sender-side lock fast/slow paths, not just target wait costs. A contended mutex-wait captures once and allocates a five-free-variable resume closure before its CHECK_HEAP.";
  attribute :>> required="Split E/M into sender, target and harness episodes/restarts; count unblocked fast completions separately. Under the original no-nested-user-action premises sender logical episodes can approach N, while target episodes need not. Charge real closure setup and GC exposure even if no frame is materialized.";
  attribute :>> gap="No measured contended fraction or episode/restart histogram exists. New initial wait cost cannot be assumed constant per target or omitted from the360 million request comparison.";
  ref part :>> question=cutSource;
 }
 part serviceMaterializationLedger:SourceSite {
  attribute :>> id="serviceMaterializationLedger";
  attribute :>> artifact="vendor/gambit/lib/_mem/continuation-roots.inc";
  attribute :>> anchor="___COVER_MARK_CAPTURED_CONTINUATION_ALREADY_COPIED;";
  attribute :>> role="request-service-design";
  attribute :>> observed="Under frame-access ownership, an already-forwarded stack frame repairs another root without payload copy; first materialization reserves, fills fs+2 words under the asserted one-word header/extra slot layout, installs forwarding, publishes scanning and commits. frame_links_ increments on BOTH branches. Census mode instead dispatches to census_capture.";
  attribute :>> required="Distinguish source claims, alias repair links, committed first materializations, existing heap-frame copies/scans and census. Attribute by round plus physical source identity; multi-shot incarnations and address reuse are distinct. Complete publication/commit or retained UNKNOWN, never infer unique copies from frame_links_.";
  attribute :>> gap="No per-epoch exclusive native frame/census ledger exists. fs+2 describes initialized destination words, not full arena padding/reservation, peak or all GC work; census and heap budget remain unchanged.";
  ref part :>> question=cutSource;
 }
 part serviceTerminalThunkDisposition:SourceSite {
  attribute :>> id="serviceTerminalThunkDisposition";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##thread-check-timeouts!)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Timeout delivery replaces resume-thunk with timeout-action; mutex unlock/signal installs locked/abandoned actions; wait-return uses void. End itself leaves resume-thunk unchanged. Thus normal timeout/unlock does not imply an ended Thread still holds a wait closure; a terminate-while-parked path may retain one if no intervening writer replaced it.";
  attribute :>> required="Record the last writer and actual value category at exit: startup closure, reusable wait, outcome action or user alias. Link any residual graph to a rooted ended Thread and later eligible GC. Separate post-flood termination retention from in-flood repeated materialization; never credit post-completion savings to earlier deadlines.";
  attribute :>> gap="Source paths provide conditional candidates, not observed prevalence or bytes. Outcome functions do not directly capture the wait chain, but other fields/registers/results may still retain it.";
  ref part :>> question=cutSource;
 }
 part serviceOriginalScenarioCosts:SourceSite {
  attribute :>> id="serviceOriginalScenarioCosts";
  attribute :>> artifact="vendor/gambit/tests/unit-tests/06-thread/thread_interrupt2_stress.scm";
  attribute :>> anchor="(define (test5)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Original tests1..6 cover yield, sleep1000, untimed mutex, mutex1000, untimed condvar loop and timed condvar loop. At p11 each contributes60 million calls. Sleep/mutex wait operations use selected parks; yield and condition waits retain distinct THREAD_SAVE/interrupted-wait behavior. Mutex acquisition/reacquisition inside condition loops can also take the mutex park path. Senders use completion waiting in all six.";
  attribute :>> required="Keep all six populations and target lifetime semantics. Tests2/4 have single timed target waits; test6 can legitimately rearm a new condvar wait in its loop. Include sender/harness join/lock costs and classify the first inactive target by subtest rather than assigning every failure to one1000-second lifetime.";
  attribute :>> gap="No original full-load arm/restart/GC/exit matched witness exists. Short map/PBT and one wait subtype cannot close the full file or original stress family.";
  ref part :>> question=cutSource;
 }
 part requestServiceFlow11:Flow { ref part :>> producer=messages; ref part :>> consumer=control; attribute :>> contract="Repair9: completion fast/slow waiting creates sender episodes across all six populations, not only target waits"; }
 part requestServiceFlow12:Flow { ref part :>> producer=collector; ref part :>> consumer=qualification; attribute :>> contract="Repair9: census, first materialization, forwarded alias repair and heap-frame scans have separate work counts"; }
 part requestServiceFlow13:Flow { ref part :>> producer=retirement; ref part :>> consumer=qualification; attribute :>> contract="Repair9: last resume writer and ended-Thread live window determine whether retained work is real and deadline-relevant"; }
 part senderCompletionFastLease:SourceSite {
  attribute :>> id="senderCompletionFastLease";
  attribute :>> artifact="vendor/gambit/lib/_thread.c";
  attribute :>> anchor="___DEF_SLBL(4,___L4__23__23_thread_2d_intr_21_)";
  attribute :>> role="request-service-design";
  attribute :>> observed="After propagate returns at L4, synchronous completion acquires M and checks not-abandoned. The immediate branch sets not-owned, unlocks, then L8 locks M again for request.state/result and unlock/handoff. It reaches neither CAPTURE4 nor ALLOC_CLO5. L15 calls anonymous out-of-line locking and returns at L5 to the same consumer.";
  attribute :>> required="Candidate private completion operation fuses successful anonymous acquisition with guarded result observation and the existing acquired-lock unlock/handoff. Keep complete roots, physical mutex state, terminal outcome and error behavior; returned state alone cannot replace mutex acquisition. General public mutex operations remain.";
  attribute :>> gap="One lock-pair elimination is a source-level candidate, not measured saving or a qualified atomic contraction. Abandoned owner and slow unlock/other admitted observers must refine the original contract.";
  ref part :>> question=cutSource;
 }
 part senderCompletionSlowEntry:SourceSite {
  attribute :>> id="senderCompletionSlowEntry";
  attribute :>> artifact="vendor/gambit/lib/_thread.c";
  attribute :>> anchor="#define ___PH_PROC ___H__23__23_mutex_2d_lock_2d_out_2d_of_2d_line_21_";
  attribute :>> role="request-service-design";
  attribute :>> observed="Anonymous wrapper tail-calls the general helper with new-owner false. Completion timeout false becomes true/no-timeout without timeout conversion. Helper structurally has available/abandoned immediate branches. For this exact no-timeout/no-owner path M stays held from L4 through wrapper/helper: cooperative writes cannot make unavailable become normally available there; abandoned immediate remains. The real completion race begins after releasing M before mutex-wait capture; re-registration may then finish without suspension.";
  attribute :>> required="Partition fast no-setup, abandoned helper-immediate, setup-race and ever-registered episodes; count repeated registrations separately. Preserve ownership/abandonment and no lost wake; do not equate slow helper entry with capture, registration or suspension. Native probe sites are actual labels and selected descriptors, not primitive-name counts.";
  attribute :>> gap="No occurrence fractions or paired costs measured. Retrying or spinning until completion would change the scheduler/wait contract and is not this proposal.";
  ref part :>> question=cutSource;
 }
 part senderCompletionClosureOperands:SourceSite {
  attribute :>> id="senderCompletionClosureOperands";
  attribute :>> artifact="vendor/gambit/lib/_thread.c";
  attribute :>> anchor="#define ___PH_PROC ___H__23__23_mutex_2d_wait_21_";
  attribute :>> role="request-service-design";
  attribute :>> observed="Mutex-wait emits CAPTURE4, clears only internal wait denv, ALLOC_CLO5 and five setup stores, then CHECK_HEAP. Free operands are mutex, new-owner, self resume, timeout and wait. Self-call optional current-thread selects direct register5 or PARK2. This is once per logical episode, not per service action or each repark.";
  attribute :>> required="For a proven internal completion wait specialize timeout/no-owner and replace dynamic resume closure with static entry plus precise frame operands. Dynamic wait/request data must still be rooted. Do not claim defunctionalization removes allocation if the replacement is another per-episode heap environment.";
  attribute :>> gap="No current static frame-resume backend exists. FrameSpec lowering, descriptor access and complete canonical-root binding must be implemented/qualified before any closure byte saving; generic fallback remains for unqualified cases.";
  ref part :>> question=cutSource;
 }
 part senderCompletionFrameBinding:SourceSite {
  attribute :>> id="senderCompletionFrameBinding";
  attribute :>> artifact="vendor/gambit/include/_gambit/gvm_operations.h.in";
  attribute :>> anchor="#define ___THREAD_RESTORE";
  attribute :>> role="request-service-design";
  attribute :>> observed="RESTORE moves Thread.cont.frame to the break chain and clears that wrapper field before service resume. Consequently a static callback cannot recover its state by blindly rereading Thread.cont or a cached C stack pointer. Existing THREAD_PARK needs an explicit rooted continuation operand.";
  attribute :>> required="Proposed generated completion wait uses immutable/logically versioned frame operands and static PointId, with a movable canonical root binding for each active physical wait. Bind before service exposure; scan/repair through existing root ownership and reload after GC. Retain initial capture until direct-frame rooting is independently qualified; no one-shot continuation restriction or one reusable payload slot shared by all shots.";
  attribute :>> gap="Root binding lookup, nested/cross-context incarnation, module descriptor lifetime, nonlocal exit and metadata reuse remain implementation prerequisites. No O(1) lookup or zero capture follows from current headers.";
  ref part :>> question=cutSource;
 }
 part senderCompletionBatchAccounting:SourceSite {
  attribute :>> id="senderCompletionBatchAccounting";
  attribute :>> artifact="vendor/gambit/lib/_thread.c";
  attribute :>> anchor="#define ___PH_PROC ___H__23__23_thread_2d_resume_2d_execution_21_";
  attribute :>> role="request-service-design";
  attribute :>> observed="Resume host saves its resume thunk, dispatches one queue node, pops its eight-word return frame, loops and only tail-invokes resume when the queue is empty. Many request services can occur before one resume/repark; M is not N. A competing target owns request execution, while sender wait only observes completion.";
  attribute :>> required="Keep existing queue/service policy and at-most-one initial dispatch. Count drain lengths, empty observations and per-role resume/registration outcomes. Static wait design removes only the internal callable environment/indirection it replaces, not requested user actions or essential queue work.";
  attribute :>> gap="No batch/restart histogram exists for the original360 million calls. A large batch is a counterexample to N-fold repark savings, not permission to delay callers with a new batching policy.";
  ref part :>> question=cutSource;
 }
 part requestServiceFlow14:Flow { ref part :>> producer=messages; ref part :>> consumer=retirement; attribute :>> contract="Repair9: fuse private fast completion acquisition/result/physical unlock under one qualified lease; no state-only shortcut"; }
 part requestServiceFlow15:Flow { ref part :>> producer=control; ref part :>> consumer=execution; attribute :>> contract="Repair9: proposed static completion resume PointId uses frame operands, not a fresh callable environment per episode"; }
 part requestServiceFlow16:Flow { ref part :>> producer=execution; ref part :>> consumer=roots; attribute :>> contract="Repair9: canonical wait-frame binding survives Thread.cont restore, GC relocation and multi-shot incarnation before static resume"; }
}
