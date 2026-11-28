/* Source/native refinement of existing obligations; no new proof kernel. */
package GambitSharedHeapSmpEnvironmentQualification {
 private import GambitSharedHeapSmp::*;
 part environmentAllocate:SourceSite {
  attribute :>> id="environmentAllocate";
  attribute :>> artifact="vendor/gambit/lib/_eval.scm";
  attribute :>> anchor="(define ##cprc-prc-req1";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Accepted ordinary one-argument entry creates parent/proc/arg1 RTE before heap-limit check and body execution. The entry hook may execute user code through an exec closure.";
  attribute :>> required="Keep parent, self, argument and code in exact roots before allocation or collection; hook and exception paths cannot use an unrooted transient environment.";
  attribute :>> gap="No deferred or reusable RTE implementation is qualified.";
  ref part :>> question=aliasSource;
 }
 part environmentRepresentation:SourceSite {
  attribute :>> id="environmentRepresentation";
  attribute :>> artifact="vendor/gambit/lib/_eval#.scm";
  attribute :>> anchor="(##define-macro (macro-make-rte rte . lst)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="RTE is an ordinary vector with parent in slot0; generic reads and writes use vector operations.";
  attribute :>> required="Distinguish logical lexical locations from relocation addresses; changing storage requires every consumer to resolve the same canonical environment.";
  attribute :>> gap="Literal frontier140 rows is not full dynamic or FFI writer closure.";
  ref part :>> question=aliasSource;
 }
 part environmentStore:SourceSite {
  attribute :>> id="environmentStore";
  attribute :>> artifact="vendor/gambit/lib/_eval.scm";
  attribute :>> anchor="(define ##cprc-loc-set";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Lexical set traverses parent links and writes the selected environment slot; boxed path mutates the box.";
  attribute :>> required="Preserve aliasing among escaped closures, reflection and multiple continuation shots; do not reuse an earlier invocation location for a later call.";
  attribute :>> gap="No qualified single-materialization identity publication or complete writer adapter exists.";
  ref part :>> question=aliasSource;
 }
 part environmentProcedureExposure:SourceSite {
  attribute :>> id="environmentProcedureExposure";
  attribute :>> artifact="vendor/gambit/lib/_repl.scm";
  attribute :>> anchor="(define-prim (##interp-procedure-rte x)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Reflection reads closure slot3 as the interpreter environment.";
  attribute :>> required="Before exposing a closure, publish a rooted canonical environment compatible with reflection; rewriting only macro-make-rte cannot retire this reader.";
  attribute :>> gap="Raw layout consumer still depends on concrete vector identity.";
  ref part :>> question=aliasSource;
 }
 part environmentContinuationExposure:SourceSite {
  attribute :>> id="environmentContinuationExposure";
  attribute :>> artifact="vendor/gambit/lib/_repl.scm";
  attribute :>> anchor="(define-prim (##interp-continuation-rte cont)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Continuation reflection obtains rte from continuation-locals.";
  attribute :>> required="Each shot resolves repaired roots and the same mutable lexical locations; no one-shot consumption or automatic cloning of locations.";
  attribute :>> gap="Actual capture, reflection, serialization and native aliases require a complete source adapter.";
  ref part :>> question=aliasSource;
 }
 part environmentSubproblem:SourceSite {
  attribute :>> id="environmentSubproblem";
  attribute :>> artifact="vendor/gambit/lib/_eval.scm";
  attribute :>> anchor="(define ##subproblem-apply1";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Environment-map declaration and first-argument retain code/rte through non-tail application and stepping.";
  attribute :>> required="Preserve precise active-frame roots, callback escape and dynamic-wind on normal and exceptional exit; capture cannot silently resurrect retired storage.";
  attribute :>> gap="Required root/alias premises belong to existing CS-BRIDGE and CS-WRITERS; C conformance remains open.";
  ref part :>> question=aliasSource;
 }
 part environmentGeneratedAllocation:SourceSite {
  attribute :>> id="environmentGeneratedAllocation";
  attribute :>> artifact="vendor/gambit/lib/_eval.c";
  attribute :>> anchor="___DEF_GLBL(___L15__23__23_cprc_2d_prc_2d_req1)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="The emitted ordinary path initializes a three-slot vector from R4/R3/R1, places the result in R1, then CHECK_HEAP6 and body dispatch move it to R2.";
  attribute :>> required="Bind source code/rte/argument roles to actual liveness and checkpoint descriptors; generated text alone does not prove every root or permission.";
  attribute :>> gap="No alternative generated environment entry/root layout is implemented.";
  ref part :>> question=aliasSource;
 }
 part environmentFrameGenerator:SourceSite {
  attribute :>> id="environmentFrameGenerator";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-3.scm";
  attribute :>> anchor="(define (targ-make-frame-spec kind fs link gc-map)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="FrameSpec validates actual frame size, structural link and gc-map bounds after liveness.";
  attribute :>> required="Transient environments must use an explicit existing FrameSpec coordinate map at every allocating or user-code cut, never a raw C stack address.";
  attribute :>> gap="No actual FrameSpec mapping for the proposed transient environment is supplied.";
  ref part :>> question=aliasSource;
 }
 part environmentGcScan:SourceSite {
  attribute :>> id="environmentGcScan";
  attribute :>> artifact="vendor/gambit/lib/_mem/object-scanning.inc";
  attribute :>> anchor="mark_array (work, body+___CLO_FREEVARS, words-___CLO_FREEVARS);";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Closure free variables and generic vector payloads are scanned and repaired through mark_array.";
  attribute :>> required="A new representation must enumerate canonical slots and preserve shared targets; eliminating vector allocation does not eliminate its root or scan obligations.";
  attribute :>> gap="No root-task adapter for transient slots or mature writer coverage is qualified.";
  ref part :>> question=aliasSource;
 }
 part environmentSerialize:SourceSite {
  attribute :>> id="environmentSerialize";
  attribute :>> artifact="vendor/gambit/lib/_system.scm";
  attribute :>> anchor="(write-u8 (closure-tag))";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Closure serialization resolves code identity, registers the closure in the sharing table and recursively serializes its closed fields.";
  attribute :>> required="Materialize before exposure to raw closed-field traversal; preserve graph sharing and original native success/refusal.";
  attribute :>> gap="Interpreter environment serialization under the proposed representation has no native comparison.";
  ref part :>> question=aliasSource;
 }
 part environmentDeserialize:SourceSite {
  attribute :>> id="environmentDeserialize";
  attribute :>> artifact="vendor/gambit/lib/_system.scm";
  attribute :>> anchor="((fx= x (closure-tag))";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Deserialization allocates/registers a shell before recursively filling closed fields; code lookup checks system version and resolves parent/subprocedure.";
  attribute :>> required="Preserve shell identity through recursive graphs and partial initialization; incomplete reconstruction cannot publish a reusable completed environment.";
  attribute :>> gap="No proposed transient/materialization reconstruction adapter exists.";
  ref part :>> question=aliasSource;
 }
 part environmentForeignBorrow:SourceSite {
  attribute :>> id="environmentForeignBorrow";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="const ___SCMOBJ *___borrow_rc_root";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Native root borrowing has a distinct lifetime from owning an allocation and source registration.";
  attribute :>> required="Freeze/close must settle active writers and native root borrows; materialize or retain generic representation before unmanaged pointer exposure. Unknown borrows keep custody, not success.";
  attribute :>> gap="No complete arbitrary external alias or FFI-writer census; optimized admission must not infer coverage from this function alone.";
  ref part :>> question=aliasSource;
 }
 part environmentNativeControl:SourceSite {
  attribute :>> id="environmentNativeControl";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-serdes.scm";
  attribute :>> anchor="(define (environment-alias-case)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="The retained eager control passed a real interpreted map capture, lexical set!, shared reflective environment, two GC/restores and exact winding. Eight native alias PBT histories pass; actual closure slot3 substitution shrinks to alias/collect/observe under checked R3/W2. Original test prefix and15 prior PASS lines remain unchanged.";
  attribute :>> required="Run under the frozen GCC/C23 cohort and actual R3/W2; classify eager-control evidence separately from absent optimized implementation.";
  attribute :>> gap="This is ordinary eager and logical source-substitution evidence only. It does not suppress an actual GC repair, qualify current dirty HEAD, measure alpha_elim, or implement production materialization/UNKNOWN settlement.";
  ref part :>> question=aliasSource;
 }
 part environmentAcceptancePlan:SourceSite {
  attribute :>> id="environmentAcceptancePlan";
  attribute :>> artifact="dev/refactoring/modern-c/stress-environment-handoff.org";
  attribute :>> anchor="#+NAME: environment-native-scenarios";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="The joined implementation packet declares nine scenarios, exact independent oracles, existing formal ownership, bounded native controls and lifetime-partition cost accounting.";
  attribute :>> required="Implement all source/root/exposure consumers as one runtime-owned lowering before claiming eliminated allocation. Native generic controls do not certify absent optimized entry, UNKNOWN settlement or missed-repair hooks.";
  attribute :>> gap="Current decision is NO-GO for a cheap constructor-only replacement. Whole candidate producer/stress, eligibility and matched costs remain OPEN.";
  ref part :>> question=aliasSource;
 }
 part environmentHeapHandler:SourceSite {
  attribute :>> id="environmentHeapHandler";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="* This is the heap-limit handler.  It is invoked by the ___CHECK_HEAP(n,m)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Heap-limit slow path saves all GVM registers and actual return address before check-heap; the internal return handler later pops repaired registers.";
  attribute :>> required="Saved environment authority belongs to the internal frame and its root task, not whichever value remains in bank R1 after the callee starts.";
  attribute :>> gap="Implicit suspension/capture and a projected-environment body interface still need a whole adapter.";
  ref part :>> question=aliasSource;
 }
 part environmentLabelDescriptor:SourceSite {
  attribute :>> id="environmentLabelDescriptor";
  attribute :>> artifact="vendor/gambit/lib/_eval.c";
  attribute :>> anchor=",___DEF_LBL_RET_AT(___H__23__23_cprc_2d_prc_2d_req1,___IFD(___RETI,0,0,0x3fL),6)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Label6 has an internal-return descriptor with stored_fs0, link0 and bitmap0x3f; CHECK_HEAP second argument4096 is unused in the macro implementation.";
  attribute :>> required="Use the actual descriptor and configured stack geometry; distinguish saved R0 link from ordinary environment/code/self/parent slots.";
  attribute :>> gap="One descriptor and ordinary eager control do not prove all generated checkpoints or virtual-environment consumers.";
  ref part :>> question=aliasSource;
 }
 part environmentBankSource:SourceSite {
  attribute :>> id="environmentBankSource";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-origins.inc";
  attribute :>> anchor="___BOOL ___root_task_scan_bank";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Bank scanner uses task.origin.source.bank and source register/saved/cache ranges; stack task separately consumes internal frame coordinates.";
  attribute :>> required="Do not infer source from collector carrier or treat live bank words as all suspended caller registers; preserve both actual source views.";
  attribute :>> gap="No proposed transient representation or its complete root union has been implemented.";
  ref part :>> question=aliasSource;
 }
 part environmentPhysicalCut:SourceSite {
  attribute :>> id="environmentPhysicalCut";
  attribute :>> artifact="dev/refactoring/modern-c/tests/environment-frame-cut.c";
  attribute :>> anchor="_Static_assert(CUT_REG(1) == 2";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="GCC/C23 syntax-only control checks eight configured relationships: five registers, saved R0 structural slot1, environment slot2, bounds and label6 live bits for R1..R4.";
  attribute :>> required="Bind descriptor literals to generated source hashes and configured headers; a candidate projection may reuse these existing saved words only while values remain valid Scheme roots.";
  attribute :>> gap="This is local configured layout evidence, not whole candidate scan/restore correctness or global peak reduction.";
  ref part :>> question=aliasSource;
 }
 part environmentHookControl:SourceSite {
  attribute :>> id="environmentHookControl";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-serdes.scm";
  attribute :>> anchor="(define (environment-hook-case)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="A real req1 code-node hook can retain exec past entry return and run it repeatedly; the native control distinguishes fresh parameter locations from multi-shot sharing and tests arity checking inside exec.";
  attribute :>> required="Count valid environment constructions U separately from entries and exec attempts. Preserve hook-before-arity order; query of a lost materialization return must not create another lexical environment.";
  attribute :>> gap="This tests the eager source behavior; candidate hook lowering, exact generated closure geometry and whole-workload U remain unqualified.";
  ref part :>> question=aliasSource;
 }
 part environmentSerdeControl:SourceSite {
  attribute :>> id="environmentSerdeControl";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-serdes.scm";
  attribute :>> anchor="(define (environment-serde-case)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Same-VM control exercises explicit code/resource resolution, native default refusal, partial graph reconstruction failure, resolver close and a second reconstructed map continuation shot after source roots are explicitly cleared.";
  attribute :>> required="Retain decoded graph sharing, mutable-location independence from the original graph, exact dynamic-wind and protected target roots. Closed resolver refuses late reconstruction.";
  attribute :>> gap="A local synchronous resolver is not production intent query/ACK or a cross-VM code lifetime; partial decode does not prove candidate recovery.";
  ref part :>> question=aliasSource;
 }
 part environmentCompiledOwner:SourceSite {
  attribute :>> id="environmentCompiledOwner";
  attribute :>> artifact="vendor/gambit/tests/run-unit-tests.scm";
  attribute :>> anchor="(define (compiler-runtime-options)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Official gsc/C mode compiles _test.o1 then loads it through GSI; the compiler is p1 while executed topology is independently selected. Input files are sorted by the runner.";
  attribute :>> required="Freeze the compiled-family source, runtime population, ordering and original budget in its existing acceptance owner; a standalone executable is not this consumer.";
  attribute :>> gap="Current runner differs from HEAD and the working smp workflow is absent from HEAD. No stress-gsc manifest or complete source-bound compiled-family admission is supplied here.";
  ref part :>> question=aliasSource;
 }
 part environmentCodeDispatch:SourceSite {
  attribute :>> id="environmentCodeDispatch";
  attribute :>> artifact="vendor/gambit/lib/_eval#.scm";
  attribute :>> anchor="(##define-macro (macro-code-run c)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Code dispatch calls code-vector slot1 with code/rte. macro-make-cprc requests environment-map, and its continuation reenables interrupts. RTE parent/read/write macros use actual vector operations.";
  attribute :>> required="Lower supported code consumers with exact generated root maps and callback/implicit-capture coverage, or materialize before generic dispatch. Public Scheme names and arity behavior remain.";
  attribute :>> gap="No qualified projected operator set exists. If every eligible dispatch materializes, E=0 and physical allocation saving is nonpositive before added costs.";
  ref part :>> question=aliasSource;
 }
 part environmentLocalsDescriptor:SourceSite {
  attribute :>> id="environmentLocalsDescriptor";
  attribute :>> artifact="vendor/gambit/lib/_repl.scm";
  attribute :>> anchor="(define-prim (##subprocedure-locals";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Continuation-locals delegates to subprocedure-locals, which decodes descriptor slot indices and reads continuation-ref; procedure RTE reflection separately reads closure slot3.";
  attribute :>> required="Update actual introspection metadata together with projected root maps; a surviving referent does not identify the right frame coordinate or materialized location.";
  attribute :>> gap="No projected descriptors, exact source adapter or production materialization query/install/ACK are implemented.";
  ref part :>> question=aliasSource;
 }
 part environmentHookWriter:SourceSite {
  attribute :>> id="environmentHookWriter";
  attribute :>> artifact="vendor/gambit/lib/_repl.scm";
  attribute :>> anchor="(define-prim (##interp-procedure-entry-hook-set! proc hook)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="The hook setter uses macro-code-set!. trace/untrace and break/unbreak install/remove hooks; existing default hooks also have mutable settings without pointer replacement. interp-procedure-code exposes the raw code vector.";
  attribute :>> required="Guard actual execute and all escape/reentry boundaries using complete writer coverage and real exclusion/publication. Code/hook pointer equality or an entry-time ticket cannot establish future eligibility. Preserve debugging effects and ordinary fallback.";
  attribute :>> gap="No candidate code exposure/invalidation adapter, settings-writer closure or C memory-order witness exists. The existing setter alone is not an atomic generation receipt.";
  ref part :>> question=aliasSource;
 }
 part environmentReturnIdentity:SourceSite {
  attribute :>> id="environmentReturnIdentity";
  attribute :>> artifact="vendor/gambit/lib/setup.c";
  attribute :>> anchor="___SCMOBJ ___subprocedure_parent_name";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Kernel subprocedure-parent-name delegates to setup.c, which selects lowlevel-label name or ordinary parent-intro label metadata. serialize-subprocedure! rejects a missing parent name.";
  attribute :>> required="Map actual rejected serialized returns to generated label/parent metadata and retained code lifetime; code pointer identity alone is not a serialization admission witness.";
  attribute :>> gap="The official-hook DEV refinement builds but exits70 twice before its hook case at the earlier wait serializer. Exact previous-source rebuild reproduces the prior accepted binary and passes; the later original-image observation identifies the named saved R0 payload. The capture-path difference between builds remains UNKNOWN.";
  ref part :>> question=aliasSource;
 }
 part environmentPrintedReturn:SourceSite {
  attribute :>> id="environmentPrintedReturn";
  attribute :>> artifact="vendor/gambit/lib/_io.scm";
  attribute :>> anchor="(define-prim (##wr-sn we obj type name)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Opaque return printing routes through wr-return/wr-opaque to wr-sn, which writes object->serial-number. The printed number is not a subprocedure index or PointId.";
  attribute :>> required="Correlate the real rejected value with admitted parent/module/subprocedure metadata and code lifetime, independently of its printer serial.";
  attribute :>> gap="Exact-image evidence maps the refused return to thread-execute-and-end subprocedure1 and saved R0 at slot9. Candidate code-lifetime and slot-repair coverage remain OPEN.";
  ref part :>> question=boundarySource;
 }
 part environmentCodecSlot:SourceSite {
  attribute :>> id="environmentCodecSlot";
  attribute :>> artifact="vendor/gambit/lib/_system.scm";
  attribute :>> anchor="(define (serialize-cont-frame! cont)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Continuation codec serializes the return using serialize-subprocedure!, handles continuation-link specially, and passes other live slots to the generic codec. Missing-parent and unsupported-payload paths share the same error text.";
  attribute :>> required="Distinguish GC slot coverage from codec admission; classify code/structural fields and loaded code lifetime without changing native refusal or duplicating QNT/Lean obligations.";
  attribute :>> gap="Original-image evidence identifies continuation-ref at serializer label188 reading the live non-link saved R0 slot9. Candidate codec admission and lifetime handling remain OPEN.";
  ref part :>> question=boundarySource;
 }
 part environmentObserverFidelity:SourceSite {
  attribute :>> id="environmentObserverFidelity";
  attribute :>> artifact="dev/refactoring/modern-c/tests/environment-code-identity.c";
  attribute :>> anchor="___SCMOBJ ___subprocedure_parent_name (___SCMOBJ proc)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="DEV overlay leaves the name result unchanged but logs only missing names. One linked variant passes, an original-order variant fails without such a trace; encoder instrumentation also changes reproduction. Cached, configured-rebuilt and archived setup.o match byte-for-byte.";
  attribute :>> required="Bind actual configured macros and exact objects; require original-failure reproduction plus calibrated call/slot coverage before admitting observer evidence. Logging is not a throughput subject or runtime implementation.";
  attribute :>> gap="The earlier compiled observers captured no rejected value. The hardware observation supplies independent original-image coordinates and leaves candidate acceptance OPEN.";
  ref part :>> question=boundarySource;
 }
 part environmentSavedThreadReturn:SourceSite {
  attribute :>> id="environmentSavedThreadReturn";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="This is the stack-limit handler.  It is invoked by the ___POLL(n)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Original-image POLL638 has RETI(8,0,0x3f03), fs17 and link1. The handler saves registers and the poll return. The heap continuation-ref at serializer label188 reads slot9/body9 containing named thread-execute-and-end subprocedure1. Saved R0 is a live non-link slot here.";
  attribute :>> required="Use generated coordinates and keep saved code, chain and ordinary codec roles distinct. Preserve native refusal and retain source/code custody through definitive outcome, install and ACK. Thread exit and last user require independent witnesses.";
  attribute :>> gap="Production projected FrameSpec, code lifetime, writer closure, real missed-repair negative, same-operation settlement and complete native/cost acceptance remain OPEN.";
  ref part :>> question=boundarySource;
 }
 part environmentJoinedReplay:SourceSite {
  attribute :>> id="environmentJoinedReplay";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-restore.scm";
  attribute :>> anchor="wait-frame lost ACK";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="The DEV map wait replay installs a target before ACK, queries a suppressed ACK response, keeps a reader across owner join and performs two real restores separated by GC. The exact failed image emits the wait restore and PBT markers before refusing the later serialization case. The standalone restore executable has a historical source binding.";
  attribute :>> required="Bind each observation to its own image. Require projected live saved R0 at logical slot9/body9 independently of chain slot1. Reject omitted, mislabeled or wrong-code entries. In the production candidate inject omission, delayed reads and lost ACK at the actual cuts and preserve the generic codec refusal.";
  attribute :>> gap="A dropped observation row exercises the acceptance oracle only. No production projected slot, reader admission, or same-operation ACK adapter is present. All five joint gates remain OPEN.";
  ref part :>> question=boundarySource;
 }
 part environmentProjectionProducer:SourceSite {
  attribute :>> id="environmentProjectionProducer";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-3.scm";
  attribute :>> anchor="(define (targ-make-frame-spec kind fs link gc-map)";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="Existing FrameSpec freezes physical liveness before inline or out-of-line return-label emission.";
  attribute :>> required="Bind slot roles to the emitted return label. Compare logical9/body9 and chain1 using the frozen raw frame and legacy descriptor before repair and again before both shots. A permanent saved label cannot witness forwarding.";
  attribute :>> gap="Production projection and real omitted-slot injection remain OPEN.";
  ref part :>> question=boundarySource;
 }
 part environmentReaderPinCut:SourceSite {
  attribute :>> id="environmentReaderPinCut";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="const ___SCMOBJ *___borrow_rc_root";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="RC borrow is current-PSTATE and domain confined. Cleanup refuses live borrows and scan leases.";
  attribute :>> required="Pin by operation identity before pointer acquisition. Install in a surviving scan domain before actual source exit, reload after its claimed scan, refuse stale readers and retire once after drain.";
  attribute :>> gap="DEV reader flag and Scheme join do not qualify production reader admission or native cleanup.";
  ref part :>> question=boundarySource;
 }
 part environmentAckCut:SourceSite {
  attribute :>> id="environmentAckCut";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-transfer.h";
  attribute :>> anchor="static int wait_transfer_ack";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="DEV source release occurs on state2 to state3. The response can be suppressed and queried.";
  attribute :>> required="Acquire a published target installation, then settle ACK once by VM lifetime, activation generation and wait ordinal. Inject loss after committed ACK before response. Unknown settlement retains record and root custody.";
  attribute :>> gap="Production same-operation commit, query and lost-ACK cut remain OPEN.";
  ref part :>> question=boundarySource;
 }
 part environmentJointOverlay:SourceSite {
  attribute :>> id="environmentJointOverlay";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-joint-overlay.patch";
  attribute :>> anchor="joint_wait_scan_epoch";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="DEV generation34 held the native target borrow across Scheme join, observed target RC scan DONE at epoch24 with R=3 and W=2, checked slot9 reference-row omission, and completed two shots and once-only releases.";
  attribute :>> required="Confirm target RC task DONE at the post-join epoch under R=3 and W=2. Preserve the original refusal and distinguish the slot9 reference-row omission from production metadata injection.";
  attribute :>> gap="Production FrameSpec, stale-generation admission, native source exit and production ACK are OPEN. Native replay outcomes are independently bound by receipt.";
  ref part :>> question=boundarySource;
 }
 part environmentLiveSlotOverlay:SourceSite {
  attribute :>> id="environmentLiveSlotOverlay";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-live-slot-overlay.patch";
  attribute :>> anchor="define (project-live-wait-slot9";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="DEV fixture builds a projection from live waiting-frame reads, roots the slot value separately, and attempts the old generation after fixed-record reuse.";
  attribute :>> required="Bind outcomes to the same wait generation, RC task epoch, slot role and exact executable. Preserve native refusal and distinguish the fixture frame from the original saved thread return.";
  attribute :>> gap="Production FrameSpec emission, source PSTATE exit, reader admission and ACK settlement remain OPEN.";
  ref part :>> question=boundarySource;
 }
 part environmentStrictPollOverlay:SourceSite {
  attribute :>> id="environmentStrictPollOverlay";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-poll-overlay.patch";
  attribute :>> anchor="poll-descriptor-matches?";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="The strict DEV replay rejects fallback to an ordinary live slot and requires the internal descriptor and saved thread-return identity.";
  attribute :>> required="Bind the leased GCC/C23 build inputs and real poll provenance. Retain separate outcomes for missing capture, native codec refusal, and same-wait scan, ACK and restore.";
  attribute :>> gap="Exact poll capture in the joint candidate, full toolchain byte closure, and all production gates remain OPEN.";
  ref part :>> question=boundarySource;
 }
 part environmentInjectedPollOverlay:SourceSite {
  attribute :>> id="environmentInjectedPollOverlay";
  attribute :>> artifact="dev/refactoring/modern-c/tests/completion-wait-injected-poll.patch";
  attribute :>> anchor="dev_wait_arm";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="DEV fixture arms an interrupt at an emitted POLL and correlates the captured internal frame with the recorded poll label and incoming R0.";
  attribute :>> required="Under the configured build lease inspect the emitted arm and POLL, then require a real saved R0 hit before admitting same-wait omission and replay. Preserve exact original refusal.";
  attribute :>> gap="Source patch alone supplies no native result. Production FrameSpec, source PSTATE exit and ACK settlement remain OPEN.";
  ref part :>> question=boundarySource;
 }
 part family6CursorReceipt:SourceSite {
  attribute :>> id="family6CursorReceipt";
  attribute :>> artifact="dev/refactoring/modern-c/models/sysml/stress-gsi-cursor-handoff.sysml";
  attribute :>> anchor="attribute family6Authority";
  attribute :>> role="environment-source-refinement";
  attribute :>> observed="The DEV cursor contract links source ownership, publication, generated reload, and the first complete write. Repair 9 read and modern TFIB write remain separately attributed.";
  attribute :>> required="Require a same-subject release, publication, reload and write trace with independent allocation coverage. A censored run needs progress and phase accounting before cost attribution.";
  attribute :>> gap="Native producer and consumer refinement, full allocation coverage and original p2/p1 family completion remain OPEN.";
  ref part :>> question=boundarySource;
 }
 part environmentQualificationClause:AdapterClause {
  attribute :>> id="environmentQualificationClause"; attribute :>> kind="validation";
  attribute :>> rule="One source-bound environment/root/exposure delivery must preserve logical lexical identity across hook, reflective alias, multi-shot restore, GC movement and exceptional exit before removing ordinary environment allocations.";
  attribute :>> missing="No qualified transient storage/root map, materialization commit/query adapter, complete dynamic/native alias census or same-subject whole stress evidence.";
  attribute :>> acceptance="Keep exact canonical baselines, unchanged original GSI stress populations and300/295-second whole/inner limits, and the GSC family own frozen recipe; native graph identity and slot oracle plus uninstrumented matched cost and peak are separate gates. Any diagnostic observer must reproduce the exact original failure and qualify its observation cut; passing modified images or opaque printer serials are insufficient.";
  ref part :>> adapter=aliasAdapter; ref part :>> site=environmentAllocate;
 }
 part environmentQualification:SourceCase {
  attribute :>> id="environmentQualification";
  attribute :>> precondition="Runtime owner selects exact source/compiler/profile/generated C/artifact subject; declare exposure boundary and preserve complete root/census/heap budgets.";
  attribute :>> argument="Each valid req1 execute creates one fresh three-field environment. The entry hook precedes the arity check: an entry may execute zero or many times; invalid arity creates no ordinary environment. Repeated exec needs fresh locations, while repeated continuation shots share an existing location. Avoidable allocation can be claimed only for calls whose environment remains unexposed for the complete required lifetime. Exposed calls retain one canonical rooted materialization; partial or UNKNOWN materialization keeps source custody and forbids slot reuse. Closure and continuation observers must agree after movement and multiple restores. Cost uses disjoint closed lifetimes U=E+L+I: E never materializes, L defers then materializes once and I uses the immediate path. With D extra physical allocations and H metadata bytes, the configured three-slot traffic saving is32*(E-D)-H. UNKNOWN lifetimes cannot count as E; alpha_defer=(E+L)/U is not alpha_elim=E/U.";
  attribute :>> conclusion="A complete source-adapter and native acceptance unit is specified. Neither literal coverage, component primitive success nor SDK validation proves an optimized environment or stress-family completion.";
  attribute :>> missing="Implement and qualify rooted transient representation, escape detection, exact alias-preserving materialization, GC rewrite/reentry and last-observer retirement as one runtime-owned responsibility. Measure eligible fraction rather than infer it from allocation-counter proximity.";
  attribute :>> acceptance="Ordinary/tail and non-tail calls; retained mutable closure; capture then mutate then restore twice across GC; reflective procedure/continuation access; hook retention and exception; serializer success/refusal and admitted native aliases; materialization result loss and late exit. Rerun unchanged original whole GSI/GSC stress in order on the selected producer. Compare allocation, scanned words, pause, throughput and physical peak without widening budgets.";
  attribute :>> formalBoundary="Existing shared_heap_cut/RC freeze QNT owns freeze, pin, phase and reload ordering; it does not by itself model canonical materialization query/ACK identity. Establish a refinement to a qualified existing transfer owner or keep that prerequisite OPEN. RelocationSlots Lean alone owns total source-slot rewrites, injective live forwarding and alias observations. C adapters must supply actual coordinates and memory-order premises; no second QNT or Lean proof is added.";
  attribute :>> counterexample="Tail-reusing one vector changes an escaped closure captured in an earlier iteration; copying its environment per continuation shot breaks set! sharing; preserving referent liveness while missing one alias still leaves a stale slot. A near allocation-statistic match is not proof of whole-TFIB speedup.";
  ref part :>> clause=environmentQualificationClause; ref part :>> entrySite=environmentAllocate; ref part :>> exitSite=environmentContinuationExposure;
 }
}
