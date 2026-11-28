/* Modern C research: immutable descriptors, collector-writable root values. */
package GambitEscrowPublicationReentry {
 private import ScalarValues::*;
 part def FrozenDescriptor { attribute invocationIdentity : String; attribute invocationGeneration : Integer; attribute collectionEpoch : Integer; attribute rootLocations : String; attribute shapeClosed : Boolean; attribute ownerWritersClosed : Boolean; ref escrow : GambitConstructorDebtClosure::ConstructionEscrow; }
 part def ResultCommit { attribute slotIdentity : String; attribute bodyReady : Boolean; attribute rooted : Boolean; attribute committed : Boolean; attribute queryReaders : Integer; ref releaseRight : GambitReleaseProducerAdmission::ReleaseRight; }
 requirement def ResultRootBeforeCommit { subject r : ResultCommit; require constraint { not r.committed or (r.bodyReady and r.rooted) } }
 part def ReentryGate { attribute active : Boolean; attribute traceCurrent : Boolean; attribute scanPins : Integer; attribute markerValid : Boolean; attribute rootsReloaded : Boolean; }
 requirement def ReentryLaw { subject g : ReentryGate; require constraint { not g.active or (g.traceCurrent and g.scanPins == 0 and g.markerValid and g.rootsReloaded) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EP-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/escrow_publication_reentry.qnt";
 attribute :>> subjectScope="escrow_publication_reentry:33-named-histories;safe;seed=17;100x100";
 attribute :>> premise="Two invocation identities and two callback levels, one abstract scan lease; valid shell, stopped initialization writer, independent native-only completion and current owner/ABI are premises; no C weak-memory execution or arbitrary callback depth";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EP-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/EscrowPublicationReentry.lean";
 attribute :>> subjectScope="GambitSMP.EscrowPublicationReentry:writerRejectsPublication;incompleteViewRejects;scanPinRejectsReentry;staleEpochRejects;staleGenerationRejects;relocationPreservesDescriptor;reloadedValueCurrent;uninitializedRejects;unrootedRejects;oldTokenRejects;commitConserves;retireConserves;stepConserves;traceConserves;otherInvocationUnaffected;sameInvocationReadsCommitted;readerBlocksRetirement;borrowerBlocksRetirement;childBlocksRetirement;unknownInitKeepsDuty;invalidMarkerCannotReturn;secondCommitRejected";
 attribute :>> premise="22 conditional declarations: publication/reentry rejection, root-location/value distinction, custody Step/Trace, distinct result-slot update and reader/borrower/child retirement gates; not complete QNT/C simulation";
 }
 part freeze : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EP-FREEZE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/EscrowPublicationReentry.lean";
 attribute :>> subjectScope="EP-FREEZE:actual-source-refinement";
 attribute :>> premise="Close managed writer/admission authority and capture every pre-close root/escrow before release-publishing an immutable descriptor view; root cell values are collector-writable under scan ownership; acquire a separate current-epoch trace receipt, never infer it from view publication";
 }
 part slot : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EP-SLOT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/EscrowPublicationReentry.lean";
 attribute :>> subjectScope="EP-SLOT:actual-source-refinement";
 attribute :>> premise="One result slot and invocation generation per actual call, independent of GC epoch; late native-only stores add no managed root and may not overwrite committed slots; body initialization/root registration precede canonical custody commit, and query cannot replay production or allocate a duplicate wrapper";
 }
 part initialization : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EP-INIT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/EscrowPublicationReentry.lean";
 attribute :>> subjectScope="EP-INIT:actual-source-refinement";
 attribute :>> premise="Publish a valid rooted FOREIGN shell with safe default fields or keep private storage unexposed before list admission; exact native duty stays in escrow until canonical commit; partial initialization requires known stopped writer, safe shell and rooted inputs; arbitrary linked/uninitialized current C state is not recoverable by assertion";
 }
 part nesting : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EP-NEST";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/EscrowPublicationReentry.lean";
 attribute :>> subjectScope="EP-NEST:actual-source-refinement";
 attribute :>> premise="Every nested callback has its own reserved record/result slot, protected procedure before marker allocation and a complete ancestor chain; respect same-owner C stack, processor marker and invalidation; child errors/delete cannot free active marker/RC/code/native dependencies";
 }
 part reentry : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EP-REENTRY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/EscrowPublicationReentry.lean";
 attribute :>> subjectScope="EP-REENTRY:actual-source-refinement";
 attribute :>> premise="After full round seal, acquire current epoch/generation and root relocation result, drain scan leases and restore original context/processor binding before writer authority, marker access or managed result delivery; invalid marker/stale frame cannot be revived";
 }
 part retirement : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EP-RETIRE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/EscrowPublicationReentry.lean";
 attribute :>> subjectScope="EP-RETIRE:actual-source-refinement";
 attribute :>> premise="Canonical resource authority transfers at one known commit while root coverage overlaps; native borrowers drain before destructive disposal, receipt/root/code readers and descendants drain before metadata/ticket reuse; result observers do not pin collector view buffers; unknown outcome retains exact custody";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EP-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/EscrowPublicationReentry.lean";
 attribute :>> subjectScope="EP-ORDER:actual-C-memory-refinement";
 attribute :>> premise="Actual C11 release/acquire or lock refinement for writer gate, immutable descriptor publication, trace receipt, canonical slot/custody commit and reentry; root relocation is authorized mutation, not a seqlock excuse for data races; ABI/platform mapping and reclamation wrap remain open";
 }
 ref part priorCut=GambitConstructorDebtClosure::cut;
 ref part priorEscrow=GambitConstructorDebtClosure::escrow;
 ref part priorUnknown=GambitConstructorDebtClosure::unknown;
 ref part priorReentry=GambitConstructorDebtClosure::reentry;
 ref part priorProgress=GambitConstructorDebtClosure::progress;
 ref part priorFailures=GambitConstructorDebtClosure::failures;
 ref part priorOrder=GambitConstructorDebtClosure::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=slot; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=slot; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=slot; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=initialization; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=initialization; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=initialization; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=nesting; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=nesting; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=nesting; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=priorEscrow; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=priorProgress; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=priorCut; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=slot; ref part :>> prerequisite=priorUnknown; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=slot; ref part :>> prerequisite=priorEscrow; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=slot; ref part :>> prerequisite=freeze; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=initialization; ref part :>> prerequisite=slot; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=initialization; ref part :>> prerequisite=freeze; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=initialization; ref part :>> prerequisite=priorFailures; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=nesting; ref part :>> prerequisite=freeze; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=nesting; ref part :>> prerequisite=priorEscrow; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=nesting; ref part :>> prerequisite=priorReentry; }
 part dependency33 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=freeze; }
 part dependency34 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=nesting; }
 part dependency35 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=priorReentry; }
 part dependency36 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=priorProgress; }
 part dependency37 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=slot; }
 part dependency38 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=initialization; }
 part dependency39 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=nesting; }
 part dependency40 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=priorUnknown; }
 part freezeRoute : GambitHostRootsRefinement::Route { ref part :>> need=freeze;
 attribute :>> sourceAnchors="lib/c_intf.c:5156-5223;lib/mem.c:1593-1667;lib/mem.c:1487-1500,1677-1709;lib/mem.c:4023-4038,4210-4251;lib/mem.c:684-825,3970-3987;lib/c_intf.c:6509-6564;include/gambit.h.in:10325-10385";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Close managed writer/admission authority and capture every pre-close root/escrow before release-publishing an immutable descriptor view; root cell values are collector-writable under scan ownership; acquire a separate current-epoch trace receipt, never infer it from view publication";
 attribute :>> failureCustodian="Canonical escrow/root/result record retains its exact right; unknown stop/body/root/custody refuses permission; collector view and result-reader leases are separate; native disposition and all relevant readers precede reclaim";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part slotRoute : GambitHostRootsRefinement::Route { ref part :>> need=slot;
 attribute :>> sourceAnchors="lib/c_intf.c:5156-5223;lib/mem.c:1593-1667;lib/c_intf.c:1683-1711,5186-5190;lib/setup.c:3276-3390;examples/tcltk/tcltk.scm:124-194,212-222;lib/os_io.c:7135-7141,10615-10644,10952-10965;lib/_io.scm:7166-7203,8395-8446,9685-9730";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="One result slot and invocation generation per actual call, independent of GC epoch; late native-only stores add no managed root and may not overwrite committed slots; body initialization/root registration precede canonical custody commit, and query cannot replay production or allocate a duplicate wrapper";
 attribute :>> failureCustodian="Canonical escrow/root/result record retains its exact right; unknown stop/body/root/custody refuses permission; collector view and result-reader leases are separate; native disposition and all relevant readers precede reclaim";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part initializationRoute : GambitHostRootsRefinement::Route { ref part :>> need=initialization;
 attribute :>> sourceAnchors="lib/c_intf.c:5156-5223;lib/mem.c:1593-1667;lib/mem.c:1487-1500,1677-1709;lib/c_intf.c:1683-1711,5186-5190;lib/mem.c:4023-4038,4210-4251;lib/os_io.c:7135-7141,10615-10644,10952-10965;lib/_io.scm:7166-7203,8395-8446,9685-9730";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Publish a valid rooted FOREIGN shell with safe default fields or keep private storage unexposed before list admission; exact native duty stays in escrow until canonical commit; partial initialization requires known stopped writer, safe shell and rooted inputs; arbitrary linked/uninitialized current C state is not recoverable by assertion";
 attribute :>> failureCustodian="Canonical escrow/root/result record retains its exact right; unknown stop/body/root/custody refuses permission; collector view and result-reader leases are separate; native disposition and all relevant readers precede reclaim";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part nestingRoute : GambitHostRootsRefinement::Route { ref part :>> need=nesting;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6564;lib/setup.c:3276-3390;lib/_kernel.scm:1020-1072;lib/c_intf.c:6551-6564;include/gambit.h.in:10043-10059;lib/setup.c:853-867;examples/tcltk/tcltk.scm:124-194,212-222;examples/tcltk/tcltk.scm:292-333;lib/mem.c:684-703";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Every nested callback has its own reserved record/result slot, protected procedure before marker allocation and a complete ancestor chain; respect same-owner C stack, processor marker and invalidation; child errors/delete cannot free active marker/RC/code/native dependencies";
 attribute :>> failureCustodian="Canonical escrow/root/result record retains its exact right; unknown stop/body/root/custody refuses permission; collector view and result-reader leases are separate; native disposition and all relevant readers precede reclaim";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part reentryRoute : GambitHostRootsRefinement::Route { ref part :>> need=reentry;
 attribute :>> sourceAnchors="lib/mem.c:684-825,3970-3987;lib/setup.c:3276-3390;lib/_kernel.scm:1020-1072;lib/c_intf.c:6551-6564;include/gambit.h.in:10043-10059;lib/setup.c:853-867;include/gambit.h.in:10325-10385";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="After full round seal, acquire current epoch/generation and root relocation result, drain scan leases and restore original context/processor binding before writer authority, marker access or managed result delivery; invalid marker/stale frame cannot be revived";
 attribute :>> failureCustodian="Canonical escrow/root/result record retains its exact right; unknown stop/body/root/custody refuses permission; collector view and result-reader leases are separate; native disposition and all relevant readers precede reclaim";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part retirementRoute : GambitHostRootsRefinement::Route { ref part :>> need=retirement;
 attribute :>> sourceAnchors="lib/c_intf.c:1683-1711,5186-5190;lib/mem.c:4023-4038,4210-4251;lib/mem.c:684-825,3970-3987;lib/_kernel.scm:1020-1072;lib/c_intf.c:6551-6564;examples/tcltk/tcltk.scm:124-194,212-222;examples/tcltk/tcltk.scm:292-333;lib/mem.c:684-703;lib/os_io.c:7135-7141,10615-10644,10952-10965;lib/_io.scm:7166-7203,8395-8446,9685-9730";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Canonical resource authority transfers at one known commit while root coverage overlaps; native borrowers drain before destructive disposal, receipt/root/code readers and descendants drain before metadata/ticket reuse; result observers do not pin collector view buffers; unknown outcome retains exact custody";
 attribute :>> failureCustodian="Canonical escrow/root/result record retains its exact right; unknown stop/body/root/custody refuses permission; collector view and result-reader leases are separate; native disposition and all relevant readers precede reclaim";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="lib/c_intf.c:5156-5223;lib/mem.c:1593-1667;lib/mem.c:1487-1500,1677-1709;lib/c_intf.c:1683-1711,5186-5190;lib/mem.c:4023-4038,4210-4251;lib/mem.c:684-825,3970-3987;lib/c_intf.c:6509-6564;lib/setup.c:3276-3390;lib/_kernel.scm:1020-1072;lib/c_intf.c:6551-6564;include/gambit.h.in:10043-10059;lib/setup.c:853-867;include/gambit.h.in:10325-10385;examples/tcltk/tcltk.scm:124-194,212-222;examples/tcltk/tcltk.scm:292-333;lib/mem.c:684-703;lib/os_io.c:7135-7141,10615-10644,10952-10965;lib/_io.scm:7166-7203,8395-8446,9685-9730";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Actual C11 release/acquire or lock refinement for writer gate, immutable descriptor publication, trace receipt, canonical slot/custody commit and reentry; root relocation is authorized mutation, not a seqlock excuse for data races; ABI/platform mapping and reclamation wrap remain open";
 attribute :>> failureCustodian="Canonical escrow/root/result record retains its exact right; unknown stop/body/root/custody refuses permission; collector view and result-reader leases are separate; native disposition and all relevant readers precede reclaim";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="foreign-allocation-pause";
 attribute :>> sourceAnchors="lib/c_intf.c:5156-5223;lib/mem.c:1593-1667";
 attribute :>> actualChain="Native pointer precedes FOREIGN allocation; still allocation may invoke GC before wrapper exists";
 attribute :>> hazard="C stack result is not a canonical rooted slot; caller completion cannot be GC closure gate";
 attribute :>> replacement="Pre-reserved escrow/result/root record before native production and allocation entry";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="still-link-and-body";
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1677-1709";
 attribute :>> actualChain="Allocator links still object, sets refcount/length/header; caller fills body before next allocation";
 attribute :>> hazard="List publication precedes full body initialization; an independent scanner/sweep cannot assume body ready";
 attribute :>> replacement="Valid default shell before shared admission plus canonical initialization state; exact source change and ordering required";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="foreign-fields-and-release";
 attribute :>> sourceAnchors="lib/c_intf.c:1683-1711,5186-5190";
 attribute :>> actualChain="Write tags, release_fn, ptr then *obj; release_foreign clears fields before calling arbitrary function";
 attribute :>> hazard="Field stores are not a multi-location custody commit; early legacy cleanup can dispose escrow-owned payload";
 attribute :>> replacement="Canonical ReleaseRight consulted by GC/explicit dispatch; root-before-commit; retain C raw-pointer borrow contract";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="foreign-scan-and-still-root";
 attribute :>> sourceAnchors="lib/mem.c:4023-4038,4210-4251";
 attribute :>> actualChain="FOREIGN scan skips payload; still refcount!=0 seeds scan list";
 attribute :>> hazard="Opaque scan does not prove safe finalization or pin managed dependencies; refcount one only covers current collector protocol";
 attribute :>> replacement="Separate shell validity, dependency roots and native disposal authority; scanner reads initialized descriptor locations";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="rc-registration-and-mutation";
 attribute :>> sourceAnchors="lib/mem.c:684-825,3970-3987";
 attribute :>> actualChain="RC per-PSTATE list, header data assignment and mark_array relocation; cleanup_rc frees chain unconditionally";
 attribute :>> hazard="Frozen root values are not immutable; naked RC link/data mutation can race independent scanning or teardown";
 attribute :>> replacement="Stable root cells, exclusive collector write authority and drained physical list transfer";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="marker-allocation-before-root";
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6564";
 attribute :>> actualChain="make_vector allocates marker before copying proc_or_false; explicit TODO says it may have been collected";
 attribute :>> hazard="Depth counter and post-allocation marker root cannot protect procedure before allocation GC";
 attribute :>> replacement="Protect procedure and ancestor/result records first; admit child with its own ticket before marker allocation";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="call-and-marker-match";
 attribute :>> sourceAnchors="lib/setup.c:3276-3390";
 attribute :>> actualChain="___call creates return-to-C frame, saves stack marker, executes trampoline and checks unwind destination";
 attribute :>> hazard="Shared result slot or parent reentry while child is live violates real C-stack matching";
 attribute :>> replacement="Per-invocation frame chain/result identity; LIFO owner return and exact marker checks";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="processor-and-dead-marker";
 attribute :>> sourceAnchors="lib/_kernel.scm:1020-1072;lib/c_intf.c:6551-6564";
 attribute :>> actualChain="Return handler checks processor and marker validity; kill marker sets false and decrements still refcount";
 attribute :>> hazard="Root preservation cannot authorize returning to an invalid C frame or another processor";
 attribute :>> replacement="Current binding/marker lifetime required in reentry; dead marker stays invalid";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="sfun-error-reentry";
 attribute :>> sourceAnchors="include/gambit.h.in:10043-10059;lib/setup.c:853-867";
 attribute :>> actualChain="SFUN conversion errors store temp1..4 and can call Scheme error handler again before marker kill/error propagation";
 attribute :>> hazard="Nested error callbacks can allocate/exit; post-notification success does not settle parent custody";
 attribute :>> replacement="Per-frame error/result roots and explicit unwind cleanup; no shared singleton escrow or implicit early refund";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="cfun-register-reload";
 attribute :>> sourceAnchors="include/gambit.h.in:10325-10385";
 attribute :>> actualChain="CFUN context writes and reloads GVM state; error handler uses processor temps";
 attribute :>> hazard="Permit alone without fresh relocated roots/fp/hp/binding is insufficient";
 attribute :>> replacement="Consume whole-round permit then acquire/reload original owner context before managed work";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="tcl-real-callback";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-194,212-222";
 attribute :>> actualChain="scheme_call_cmd reads RC-held vector, invokes tcltk_call, passes allocated C string to Tcl release_string callback";
 attribute :>> hazard="Managed return, native C string ownership and Tcl result lifetime have distinct endpoints";
 attribute :>> replacement="Distinct Scheme/rooted result slot and native result custody; no cross-library exception equivalence assumed";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="tcl-register-delete";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:292-333;lib/mem.c:684-703";
 attribute :>> actualChain="Allocate RC and still vector; assign procedure and RC data; delete releases vector/RC";
 attribute :>> hazard="Delete/cleanup can race in-flight callback; addref does not defeat cleanup_rc";
 attribute :>> replacement="Invocation leases, child/reader drain and physical owner transfer before teardown; imported Tcl semantics remain open";
 }
 part caller12 : CallerRow {
 attribute :>> callerId="three-constructor-origins";
 attribute :>> sourceAnchors="lib/os_io.c:7135-7141,10615-10644,10952-10965;lib/_io.scm:7166-7203,8395-8446,9685-9730";
 attribute :>> actualChain="Message consumed before conversion; process error mapping/dev ownership gap; client wrapped but server cleaned on failure";
 attribute :>> hazard="A late result or unknown cleanup cannot become EINTR/EAGAIN or another native invocation";
 attribute :>> replacement="Bind exact origin/payload/generation to canonical slot; prior three source correction gates preserved";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Freeze versus relocation";
 attribute :>> removedWork="Freeze root locations/meaning and writer authority while collector updates values";
 attribute :>> bound="O(M+R) descriptor registration/scan for M live records and R dependency/result cells";
 attribute :>> addedCost="Publication gate, stable cells and distinct trace receipt";
 attribute :>> condition="No non-atomic copy/retry of concurrently written root values; actual C race freedom unresolved";
 }
 part cost1 : CostRow {
 attribute :>> capability="Result identity";
 attribute :>> removedWork="Separate per-invocation generation from collection epoch";
 attribute :>> bound="One native result slot, at most one wrapper/custody commit per modeled invocation";
 attribute :>> addedCost="O(M) slots and identity checks; result query cannot reexecute native work";
 attribute :>> condition="Current-generation native-only late results allowed across GC epochs; stale invocation results rejected";
 }
 part cost2 : CostRow {
 attribute :>> capability="Nested callbacks";
 attribute :>> removedWork="Separate parent/child records instead of singleton owner result";
 attribute :>> bound="Depth d requires d protected invocation/frame records; bounded model uses two levels";
 attribute :>> addedCost="Root/marker/result/error cells and code/native leases per level";
 attribute :>> condition="Arbitrary recursive depth needs bounded reservation/backpressure before callback entry; no proof from a depth integer alone";
 }
 part cost3 : CostRow {
 attribute :>> capability="Safe FOREIGN shell";
 attribute :>> removedWork="Allow qualified stopped partial initialization to coexist with GC";
 attribute :>> bound="Three logical safe default fields before publication plus final field writes and canonical metadata";
 attribute :>> addedCost="Extra default initialization/root pin; old direct release dispatch must be replaced";
 attribute :>> condition="Logical field assignments, not machine-store counts; opaque scan alone does not protect against cleanup";
 }
 part cost4 : CostRow {
 attribute :>> capability="Canonical ownership";
 attribute :>> removedWork="Transfer one release right while source/target root coverage overlaps";
 attribute :>> bound="One authoritative custody/result commit in abstract model; no duplicate credit charge";
 attribute :>> addedCost="Side metadata or explicit right handle plus lookup and C-FFI borrow validation";
 attribute :>> condition="Existing FOREIGN layout/FFI compatibility requires source proof; no measured lookup cost or automatic ABI preservation";
 }
 part cost5 : CostRow {
 attribute :>> capability="GC view reuse";
 attribute :>> removedWork="Keep observer result pins separate from collector view leases";
 attribute :>> bound="One active round with one builder/published view permits bounded view buffers if every scanner drains";
 attribute :>> addedCost="Pre-backed view storage and completion receipts; canonical result slots remain pinned";
 attribute :>> condition="External observer cannot hold GC view indefinitely; actual worker/late-claim closure is imported, not proved by buffer count";
 }
 part cost6 : CostRow {
 attribute :>> capability="Native disposal versus record reclaim";
 attribute :>> removedWork="Drain native borrowers before destructive release; drain result readers/children before ticket reuse";
 attribute :>> bound="Zero permitted disposal while borrowed; zero refund from unknown outcome or delivery ACK";
 attribute :>> addedCost="Borrow/query/descendant/code-root lease bookkeeping";
 attribute :>> condition="A scalar release error may already have freed storage; typed disposition still required";
 }
 part cost7 : CostRow {
 attribute :>> capability="Conditional critical path";
 attribute :>> removedWork="Remove owner-return dependency without waiting for observers during GC";
 attribute :>> bound="Eligible saved reverse wait minus freeze/scan/trace/reload costs";
 attribute :>> addedCost="Independent scanning, trace publication, owner reload and admission costs";
 attribute :>> condition="No finite bound on arbitrary native effects, no measured pause reduction or fairness proof";
 }
 part cost8 : CostRow {
 attribute :>> capability="Peak memory";
 attribute :>> removedWork="Reuse one record/right through escrow and wrapper phases";
 attribute :>> bound="Peak=max_t(heap+physical view/slot/receipt pools+unique native/root backing+quarantine)";
 attribute :>> addedCost="Safe shells, stable result cells and delayed unknown outcomes may raise peak";
 attribute :>> condition="No sum of independent maxima or refund on slot commit; no whole-round peak reduction proved";
 }
 part cost9 : CostRow {
 attribute :>> capability="Unknown partial state";
 attribute :>> removedWork="Retain exact record when stop/body/root/custody is uncertain";
 attribute :>> bound="Native outcome query creates zero additional invocation; unknown stop cannot authorize initialization takeover";
 attribute :>> addedCost="Potentially indefinite retained native allocation, shell, roots and ticket";
 attribute :>> condition="Only known safe shell/input roots/stopped writer permits GC cut; arbitrary linked half-object remains unsupported";
 }
 part cost10 : CostRow {
 attribute :>> capability="Shared modern C support";
 attribute :>> removedWork="Scheme emits semantic/frame/origin metadata; modern C owns shared escrow service";
 attribute :>> bound="One set of gate/slot/right/lease support reused across accept/process/message and callback adapters";
 attribute :>> addedCost="Source corrections, root ABI and C-memory refinement remain necessary";
 attribute :>> condition="No incremental Zig runtime-work saving established; no production path retired";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="admit"; attribute :>> labelText="Protect inputs + per-invocation record\\nreserve result/root/right slots"; }
 part node1 : DiagramNode { attribute :>> nodeId="freeze"; attribute :>> labelText="Close managed writers and admission\\npublish immutable descriptor set"; }
 part node2 : DiagramNode { attribute :>> nodeId="scan"; attribute :>> labelText="Collector owns root-cell relocation\\ncurrent trace receipt + scan-pin drain"; }
 part node3 : DiagramNode { attribute :>> nodeId="late"; attribute :>> labelText="Late native-only result\\nexact invocation generation; no managed edge"; }
 part node4 : DiagramNode { attribute :>> nodeId="init"; attribute :>> labelText="Known safe FOREIGN shell\\nescrow retains native disposal authority"; }
 part node5 : DiagramNode { attribute :>> nodeId="commit"; attribute :>> labelText="Body ready + result rooted\\ncanonical slot / ReleaseRight commit"; }
 part node6 : DiagramNode { attribute :>> nodeId="nested"; attribute :>> labelText="Child callback record before marker allocation\\ncomplete parent chain, distinct result slot"; }
 part node7 : DiagramNode { attribute :>> nodeId="reenter"; attribute :>> labelText="Current whole-round seal + binding\\nconsume view; reload relocated roots"; }
 part node8 : DiagramNode { attribute :>> nodeId="deliver"; attribute :>> labelText="Original owner / top live marker\\nquery canonical result then deliver once"; }
 part node9 : DiagramNode { attribute :>> nodeId="reclaim"; attribute :>> labelText="Borrowers drain -> native disposal\\nreaders/children drain -> record/ticket reuse"; }
 part node10 : DiagramNode { attribute :>> nodeId="retain"; attribute :>> labelText="Unknown stop / root / body / handoff\\nretain custody; refuse this permission"; }
 part node11 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nsource and C-memory refinement open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="root/procedure protected before possible GC"; }
 part edge1 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node1; attribute :>> labelText="ancestor descriptors included"; }
 part edge2 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="view publication is not trace completion"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node2; attribute :>> labelText="root topology unchanged"; }
 part edge4 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node7; attribute :>> labelText="trace current; no active scanner"; }
 part edge5 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node4; attribute :>> labelText="fresh root values / owner authority"; }
 part edge6 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node1; attribute :>> labelText="only with known stopped writer / safe shell"; }
 part edge7 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="unique initialization owner"; }
 part edge8 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node8; attribute :>> labelText="root coverage precedes ownership publication"; }
 part edge9 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node8; attribute :>> labelText="LIFO C-stack marker permission"; }
 part edge10 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node5; attribute :>> labelText="capture native result before conversion"; }
 part edge11 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node9; attribute :>> labelText="ACK is not free"; }
 part edge12 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node10; attribute :>> labelText="unknown progress or invalid shell"; }
 part edge13 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node10; attribute :>> labelText="stale epoch / generation / marker"; }
 part edge14 : DiagramEdge { ref :>> producer=node11; ref :>> consumer=node5; attribute :>> labelText="conditional atomic abstraction only"; }
}
