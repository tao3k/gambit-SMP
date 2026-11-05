/* Modern C safe-shell and unwind research; no runtime admission. */
package GambitForeignShellUnwind {
 private import ScalarValues::*;
 part def ForeignShell { attribute backingKnown : Boolean; attribute layoutValid : Boolean; attribute defaultsValid : Boolean; attribute shared : Boolean; attribute initializationOwner : String; attribute canonicalControl : String; }
 requirement def SafeAdmission { subject s : ForeignShell; require constraint { not s.shared or (s.backingKnown and s.layoutValid and s.defaultsValid) } }
 part def Invocation { attribute identity : String; attribute generation : Integer; attribute originalActivation : String; attribute procedureRootRegistered : Boolean; attribute markerAllocated : Boolean; attribute resultRooted : Boolean; attribute committed : Boolean; }
 requirement def MarkerRootFirst { subject i : Invocation; require constraint { not i.markerAllocated or i.procedureRootRegistered } }
 requirement def CommitRootFirst { subject i : Invocation; require constraint { not i.committed or i.resultRooted } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FS-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/foreign_shell_unwind.qnt";
 attribute :>> subjectScope="foreign_shell_unwind:29-named-histories;safe;seed=17;100x100";
 attribute :>> premise="Two nested invocation identities, abstract shell stages and one GC scan interval; stop, physical accounting, native disposition and finalizer guard are qualified premises; not arbitrary recursion, actual malloc/free or C weak-memory execution";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FS-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/ForeignShellUnwind.lean";
 attribute :>> subjectScope="GambitSMP.ForeignShellUnwind:missingDefaultsReject;unknownLayoutReject;rawFinalizerReject;commitPreservesCanonical;secondCommitRejected;rootBeforeCommit;bodyBeforeCommit;wrongGenerationRejected;queryPreservesCustody;escapePreservesCustody;escapePreservesRoot;escapeTransfersDuty;stepPreservesCanonical;tracePreservesCanonical;unknownStopRejects;activeChildRejects;wrongActivationRejects;childDoesNotOverwriteParent;knownResultDoesNotAuthorizeDelivery";
 attribute :>> premise="19 conditional declarations: publication/commit/escape rejection, canonical-state Step/Trace preservation, invocation-slot separation; not all QNT actions or source-to-C memory simulation";
 }
 part storage : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FS-ALLOC";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ForeignShellUnwind.lean";
 attribute :>> subjectScope="FS-ALLOC:actual-source-refinement";
 attribute :>> premise="Acquire physical storage/charge receipt and a registered initialization descriptor privately; initialize link/refcount/length/header/handle and phase-defined mark state plus FOREIGN defaults before shared list admission; unknown allocator or accounting outcome retains exact backing/charge debt; never expose raw private body to scanner or release";
 }
 part inputs : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FS-INPUTS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ForeignShellUnwind.lean";
 attribute :>> subjectScope="FS-INPUTS:actual-source-refinement";
 attribute :>> premise="Register procedure, tags, arguments, ancestor/result/error root cells before every allocating entry; acquire relocated values after allocation; FOREIGN scan is opaque so dynamic tags/dependencies need permanent proof or explicit handles; RC data ownership and nonzero-processor scan/teardown closure remain imported gaps";
 }
 part marker : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FS-MARKER";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ForeignShellUnwind.lean";
 attribute :>> subjectScope="FS-MARKER:actual-source-refinement";
 attribute :>> premise="Capture and lease closure identity before any collecting/reentrant entry; replace process-global c_closure_self for supported concurrent closures with per-invocation identity; TLS alone does not handle same-thread nesting; marker belongs to original activation/processor, invalidity is permanent";
 }
 part unwind : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FS-UNWIND";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ForeignShellUnwind.lean";
 attribute :>> subjectScope="FS-UNWIND:actual-source-refinement";
 attribute :>> premise="Generated C boundary catches each supported nonlocal exit at the original owner activation; stable record pointer predates setjmp, mutable ownership/progress lives outside changed nonvolatile automatic locals; publish error/root or destination marker, stop writers, transfer initialization duty and invalidate escaped markers before propagation; never hold admission lock across allocation/callback/unwind";
 }
 part commit : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FS-COMMIT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ForeignShellUnwind.lean";
 attribute :>> subjectScope="FS-COMMIT:actual-source-refinement";
 attribute :>> premise="Completed body and result root precede one canonical pending-to-wrapper control publication carrying invocation generation and release right; field writes and notification are not commit; before commit escrow retains native right, after commit unwind cannot roll it back; authoritative query after unknown response never reexecutes production or commit";
 }
 part reclaim : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FS-RECLAIM";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ForeignShellUnwind.lean";
 attribute :>> subjectScope="FS-RECLAIM:actual-source-refinement";
 attribute :>> premise="All GC/explicit/rollback/teardown release dispatchers consult canonical right; stopped safe-shell initialization may park without owner-return wait; unknown writer/layout/root/commit cannot authorize takeover or refund; native borrowers drain before disposal, result/root/code readers and descendants before metadata/ticket reuse";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FS-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/ForeignShellUnwind.lean";
 attribute :>> subjectScope="FS-ORDER:actual-C-memory-refinement";
 attribute :>> premise="Actual C release/acquire or lock refinement for physical list/root registration, shell admission, collector root mutation, canonical control and unwind drain; raw body readers excluded until control acquisition; actual builtin setjmp ABI and generation reuse require toolchain-specific evidence";
 }
 ref part priorInitialization=GambitEscrowPublicationReentry::initialization;
 ref part priorSlot=GambitEscrowPublicationReentry::slot;
 ref part priorNesting=GambitEscrowPublicationReentry::nesting;
 ref part priorRetirement=GambitEscrowPublicationReentry::retirement;
 ref part priorOrder=GambitEscrowPublicationReentry::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=storage; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=storage; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=storage; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inputs; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inputs; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inputs; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=unwind; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=unwind; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=unwind; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=commit; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=commit; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=commit; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=storage; ref part :>> prerequisite=priorInitialization; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inputs; ref part :>> prerequisite=priorInitialization; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=inputs; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=priorNesting; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=unwind; ref part :>> prerequisite=marker; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=unwind; ref part :>> prerequisite=priorNesting; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=commit; ref part :>> prerequisite=storage; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=commit; ref part :>> prerequisite=inputs; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=commit; ref part :>> prerequisite=priorSlot; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=unwind; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=commit; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=priorRetirement; }
 part storageRoute : GambitHostRootsRefinement::Route { ref part :>> need=storage;
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1593-1709,515-535;lib/c_intf.c:5156-5223;include/gambit.h.in:6030-6043;lib/c_intf.c:1683-1711,2830-2856;lib/mem.c:3970-3987,4023-4038,4210-4251,4387-4451,4932-4935";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Acquire physical storage/charge receipt and a registered initialization descriptor privately; initialize link/refcount/length/header/handle and phase-defined mark state plus FOREIGN defaults before shared list admission; unknown allocator or accounting outcome retains exact backing/charge debt; never expose raw private body to scanner or release";
 attribute :>> failureCustodian="Escrow retains native right before canonical commit; wrapper owns after commit; original owner settles escaped initialization duties into service; unknown writer/layout/root/backing/control refuses takeover or refund; roots/code/native backing stay pinned";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part inputsRoute : GambitHostRootsRefinement::Route { ref part :>> need=inputs;
 attribute :>> sourceAnchors="lib/c_intf.c:5156-5223;include/gambit.h.in:6030-6043;lib/mem.c:3970-3987,4023-4038,4210-4251,4387-4451,4932-4935;lib/c_intf.c:6509-6564;lib/mem.c:1778-1821;lib/os_dyn.c:744-790,1045-1058;examples/tcltk/tcltk.scm:124-194,212-222,292-333";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Register procedure, tags, arguments, ancestor/result/error root cells before every allocating entry; acquire relocated values after allocation; FOREIGN scan is opaque so dynamic tags/dependencies need permanent proof or explicit handles; RC data ownership and nonzero-processor scan/teardown closure remain imported gaps";
 attribute :>> failureCustodian="Escrow retains native right before canonical commit; wrapper owns after commit; original owner settles escaped initialization duties into service; unknown writer/layout/root/backing/control refuses takeover or refund; roots/code/native backing stay pinned";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part markerRoute : GambitHostRootsRefinement::Route { ref part :>> need=marker;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6564;lib/mem.c:1778-1821;lib/os_dyn.c:744-790,1045-1058;gsc/_ptree2.scm:2931-3014,3154-3176;include/gambit.h.in:10043-10059;lib/setup.c:3276-3420,840-867;lib/_kernel.scm:1020-1072";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Capture and lease closure identity before any collecting/reentrant entry; replace process-global c_closure_self for supported concurrent closures with per-invocation identity; TLS alone does not handle same-thread nesting; marker belongs to original activation/processor, invalidity is permanent";
 attribute :>> failureCustodian="Escrow retains native right before canonical commit; wrapper owns after commit; original owner settles escaped initialization duties into service; unknown writer/layout/root/backing/control refuses takeover or refund; roots/code/native backing stay pinned";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part unwindRoute : GambitHostRootsRefinement::Route { ref part :>> need=unwind;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6564;lib/mem.c:1778-1821;gsc/_ptree2.scm:2931-3014,3154-3176;include/gambit.h.in:10043-10059;lib/setup.c:3276-3420,840-867;lib/_kernel.scm:1020-1072;include/gambit.h.in:1639-1655,9964-10007;N1570:7.13.1.1,7.13.2.1;examples/tcltk/tcltk.scm:124-194,212-222,292-333";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Generated C boundary catches each supported nonlocal exit at the original owner activation; stable record pointer predates setjmp, mutable ownership/progress lives outside changed nonvolatile automatic locals; publish error/root or destination marker, stop writers, transfer initialization duty and invalidate escaped markers before propagation; never hold admission lock across allocation/callback/unwind";
 attribute :>> failureCustodian="Escrow retains native right before canonical commit; wrapper owns after commit; original owner settles escaped initialization duties into service; unknown writer/layout/root/backing/control refuses takeover or refund; roots/code/native backing stay pinned";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part commitRoute : GambitHostRootsRefinement::Route { ref part :>> need=commit;
 attribute :>> sourceAnchors="lib/c_intf.c:5156-5223;include/gambit.h.in:6030-6043;lib/c_intf.c:1683-1711,2830-2856;gsc/_ptree2.scm:2931-3014,3154-3176;include/gambit.h.in:10043-10059;examples/tcltk/tcltk.scm:124-194,212-222,292-333;lib/c_intf.c:5283-5382;lib/os_io.c:7135-7141,10615-10644,10952-10965";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Completed body and result root precede one canonical pending-to-wrapper control publication carrying invocation generation and release right; field writes and notification are not commit; before commit escrow retains native right, after commit unwind cannot roll it back; authoritative query after unknown response never reexecutes production or commit";
 attribute :>> failureCustodian="Escrow retains native right before canonical commit; wrapper owns after commit; original owner settles escaped initialization duties into service; unknown writer/layout/root/backing/control refuses takeover or refund; roots/code/native backing stay pinned";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part reclaimRoute : GambitHostRootsRefinement::Route { ref part :>> need=reclaim;
 attribute :>> sourceAnchors="lib/c_intf.c:1683-1711,2830-2856;lib/mem.c:3970-3987,4023-4038,4210-4251,4387-4451,4932-4935;lib/setup.c:3276-3420,840-867;lib/_kernel.scm:1020-1072;examples/tcltk/tcltk.scm:124-194,212-222,292-333;lib/c_intf.c:5283-5382;lib/os_io.c:7135-7141,10615-10644,10952-10965";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="All GC/explicit/rollback/teardown release dispatchers consult canonical right; stopped safe-shell initialization may park without owner-return wait; unknown writer/layout/root/commit cannot authorize takeover or refund; native borrowers drain before disposal, result/root/code readers and descendants before metadata/ticket reuse";
 attribute :>> failureCustodian="Escrow retains native right before canonical commit; wrapper owns after commit; original owner settles escaped initialization duties into service; unknown writer/layout/root/backing/control refuses takeover or refund; roots/code/native backing stay pinned";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1593-1709,515-535;lib/c_intf.c:5156-5223;include/gambit.h.in:6030-6043;lib/c_intf.c:1683-1711,2830-2856;lib/mem.c:3970-3987,4023-4038,4210-4251,4387-4451,4932-4935;lib/c_intf.c:6509-6564;lib/mem.c:1778-1821;lib/os_dyn.c:744-790,1045-1058;gsc/_ptree2.scm:2931-3014,3154-3176;include/gambit.h.in:10043-10059;lib/setup.c:3276-3420,840-867;lib/_kernel.scm:1020-1072;include/gambit.h.in:1639-1655,9964-10007;N1570:7.13.1.1,7.13.2.1;examples/tcltk/tcltk.scm:124-194,212-222,292-333;lib/c_intf.c:5283-5382;lib/os_io.c:7135-7141,10615-10644,10952-10965";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Actual C release/acquire or lock refinement for physical list/root registration, shell admission, collector root mutation, canonical control and unwind drain; raw body readers excluded until control acquisition; actual builtin setjmp ABI and generation reuse require toolchain-specific evidence";
 attribute :>> failureCustodian="Escrow retains native right before canonical commit; wrapper owns after commit; original owner settles escaped initialization duties into service; unknown writer/layout/root/backing/control refuses takeover or refund; roots/code/native backing stay pinned";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="still-private-to-list";
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1593-1709,515-535";
 attribute :>> actualChain="Still allocator may collect, acquire physical storage then link before caller body fill; mark scratch set by setup_still_objs_to_scan";
 attribute :>> hazard="Current body-before-next-allocation rule assumes phase ordering, not independent-scanner publication";
 attribute :>> replacement="Typed safe-shell allocator: prepare charge/storage privately, initialize descriptor and defaults, then one guarded list admission";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="foreign-convert";
 attribute :>> sourceAnchors="lib/c_intf.c:5156-5223;include/gambit.h.in:6030-6043";
 attribute :>> actualChain="Three FOREIGN words tags/release_fn/ptr are written then *obj=r; null maps to false";
 attribute :>> hazard="Those four assignments do not atomically transfer disposal authority or root result";
 attribute :>> replacement="Root inputs and safe shell; canonical side control is authoritative, external pointer access requires committed state";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="foreign-read-release";
 attribute :>> sourceAnchors="lib/c_intf.c:1683-1711,2830-2856";
 attribute :>> actualChain="Pointer conversion reads tags/ptr; release reads fn, clears fn/ptr then calls arbitrary native function";
 attribute :>> hazard="A partially initialized or precommit shell must not enter either legacy path";
 attribute :>> replacement="Replace/gate pointer borrow and all release origins before safe partial shells become admissible";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="collector-and-cleanup";
 attribute :>> sourceAnchors="lib/mem.c:3970-3987,4023-4038,4210-4251,4387-4451,4932-4935";
 attribute :>> actualChain="RC data scanned, FOREIGN body opaque; still sweep/teardown releases FOREIGN, cleanup_rc frees chain";
 attribute :>> hazard="Opaque scan does not protect tags; RC addref cannot survive unconditional cleanup_rc";
 attribute :>> replacement="Root descriptors and still-domain phase ownership; release-right-aware sweep, teardown drain or physical transfer";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="marker-before-procedure";
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6564;lib/mem.c:1778-1821";
 attribute :>> actualChain="make_vector with false may allocate/collect before procedure copy; source explicitly flags missing root protection";
 attribute :>> hazard="Rooting the newly returned marker is too late to protect proc_or_false";
 attribute :>> replacement="Reserve invocation/root cells first; protect procedure then allocate and reload; failure creates no live marker";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="closure-self-global";
 attribute :>> sourceAnchors="lib/os_dyn.c:744-790,1045-1058";
 attribute :>> actualChain="Generated C closure sets global c_closure_self then converter later reads it; source TODO requests thread local";
 attribute :>> hazard="Concurrent closure identity can be overwritten; same-thread reentry also needs captured identity";
 attribute :>> replacement="Explicit captured closure token plus RC/code lease and nested record stack; raw ABI-preserving trampoline redesign remains open";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="generated-sfun";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2931-3014,3154-3176;include/gambit.h.in:10043-10059";
 attribute :>> actualChain="Scheme generator emits SFUN entry/call/conversion/error/end; END kills marker then propagates";
 attribute :>> hazard="A throw inside call/conversion bypasses lexical END; temp1..4 error reentry can nest";
 attribute :>> replacement="Scheme emits explicit exit descriptors; C guarded boundary covers normal, conversion-error and escaping continuation exits";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="call-matching";
 attribute :>> sourceAnchors="lib/setup.c:3276-3420,840-867;lib/_kernel.scm:1020-1072";
 attribute :>> actualChain="___call catches trampoline exit, rethrows nonmatching destination/error; ___run kills marker only after call returns normally";
 attribute :>> hazard="Skipped C activations need custody settlement; live outer target marker must not be invalidated";
 attribute :>> replacement="Settle only escaped records, preserve matching target and outer roots; no cross-thread or dead-frame return";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="c-nonlocal-exit";
 attribute :>> sourceAnchors="include/gambit.h.in:1639-1655,9964-10007;N1570:7.13.1.1,7.13.2.1";
 attribute :>> actualChain="C cleanup macro is lexical only; TRY restores catcher after jump; builtin setjmp may be selected";
 attribute :>> hazard="Automatic changed nonvolatile locals cannot be recovery ledger; cleanup macro is not universal finally";
 attribute :>> replacement="Stable pre-setjmp record handle, typed exit result and bounded no-callback settlement; compiler builtin semantics independently qualified";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="tcl-callback-consumer";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-194,212-222,292-333";
 attribute :>> actualChain="RC vector holds moving procedure; tcltk_call returns allocated C string to Tcl_SetResult with release_string; delete releases vector/RC";
 attribute :>> hazard="Scheme outcome, C-string delivery and Tcl ownership are separate endpoints; command delete can invalidate backing";
 attribute :>> replacement="Pin invocation/RC/code; explicit result/error adapter and string custody; arbitrary cross-Tcl continuation exits not admitted";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="rollback-origins";
 attribute :>> sourceAnchors="lib/c_intf.c:5283-5382;lib/os_io.c:7135-7141,10615-10644,10952-10965";
 attribute :>> actualChain="Conversions may directly call release_fn; message/process/accept have distinct existing failure gaps";
 attribute :>> hazard="New wrapper service cannot coexist with independent destructive rollback or reinterpret unknown as retry";
 attribute :>> replacement="Origin-specific canonical right claim and typed effects; prior three constructor defects remain open";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Safe shell";
 attribute :>> removedWork="Eliminate published uninitialized FOREIGN bodies in admitted cohort";
 attribute :>> bound="3 logical default-field initializations plus final field writes; one list-admission decision";
 attribute :>> addedCost="Metadata/phase validity and initialization lease; machine-store count not inferred";
 attribute :>> condition="Requires replacing allocator publication and guarded release/read paths; current source has no such guarantee";
 }
 part cost1 : CostRow {
 attribute :>> capability="Pre-marker roots";
 attribute :>> removedWork="Eliminate pre-allocation procedure protection gap";
 attribute :>> bound="At least 1 procedure root per callback, plus ancestor/result/error/argument/tag cells actually live";
 attribute :>> addedCost="O(d+R) live root cells for depth d and additional R cells; root scan and reload costs";
 attribute :>> condition="Current RC coverage and teardown for every processor must qualify; no C-stack conservative-root assumption";
 }
 part cost2 : CostRow {
 attribute :>> capability="Closure identity";
 attribute :>> removedWork="Remove shared closure-self identity from admitted concurrent callback path";
 attribute :>> bound="One captured closure token and code/RC lease per invocation";
 attribute :>> addedCost="Entry adaptation and stack restoration on each nested callback";
 attribute :>> condition="TLS alone is insufficient for deferred reread after same-thread reentry; ABI support not proved";
 }
 part cost3 : CostRow {
 attribute :>> capability="Canonical result";
 attribute :>> removedWork="Avoid duplicate wrapper production or rollback after lost response";
 attribute :>> bound="At most 1 successful result/right commit per invocation; zero additional production on query";
 attribute :>> addedCost="Immutable commit record, acquire read, generation checks and right-aware pointer adapter";
 attribute :>> condition="Abstract control publication count, not machine atomic count; no lost external effect recovery implied";
 }
 part cost4 : CostRow {
 attribute :>> capability="Unwind cleanup";
 attribute :>> removedWork="Cover exits that skip lexical SFUN_END and marker kill";
 attribute :>> bound="One settled record per escaped activation; work O(k) for k escaped frames";
 attribute :>> addedCost="Stable records, typed exit tags, owner-only guard, root/child/code lease drain";
 attribute :>> condition="Cannot reinstate dead C frames, silently convert continuation escape into Scheme exception or cross arbitrary library frames";
 }
 part cost5 : CostRow {
 attribute :>> capability="Collector progress";
 attribute :>> removedWork="Permit known stopped safe-shell duties to park across GC";
 attribute :>> bound="Eligible owner-return wait removed; added root/metadata scan, stop and handoff costs";
 attribute :>> addedCost="Pre-backed escrow/root budget and eventual service dispatch";
 attribute :>> condition="Unknown writer/layout/root/physical allocation still blocks this admission; no guaranteed pause bound or speedup";
 }
 part cost6 : CostRow {
 attribute :>> capability="Ownership versus reclamation";
 attribute :>> removedWork="Keep native right unique through pre/postcommit error";
 attribute :>> bound="0 refunds from unknown native disposition or lost notification";
 attribute :>> addedCost="Borrower/reader/descendant counts and code lifetime; retained failed/unknown backing";
 attribute :>> condition="No replay of release on scalar error; record retirement and actual physical free are separate";
 }
 part cost7 : CostRow {
 attribute :>> capability="Peak memory";
 attribute :>> removedWork="Single native backing/right shared by escrow and wrapper, not copied at commit";
 attribute :>> bound="Peak=max_t(H(t)+P(t)+N(t)+Q(t)); every live physical backing counted once";
 attribute :>> addedCost="P: actual pools incl shell/root/commit records; Q: retained unknown backing not already in H/P/N";
 attribute :>> condition="Current FOREIGN requests 9W logical words; when W=pointer=8, aligned_aux requests 87 bytes before allocator overhead; marker requests 71/79 bytes for 1/2 elements; no peak reduction proved";
 }
 part cost8 : CostRow {
 attribute :>> capability="Modern C shared support";
 attribute :>> removedWork="Reuse one root/init/result/exit service across native constructors and callbacks";
 attribute :>> bound="0 retired production routes today; candidate replacement families listed in source matrix";
 attribute :>> addedCost="Scheme semantics/FrameSpec emitters, modern C service and source/memory refinement required";
 attribute :>> condition="Zig adds no demonstrated incremental elimination of these correctness duties; no person-day proxy";
 }
 part cost9 : CostRow {
 attribute :>> capability="Benefit threshold";
 attribute :>> removedWork="Avoid repeated production, unsafe replay and reverse waits where admitted";
 attribute :>> bound="Positive latency benefit iff removed wait/repeated work > root+guard+publication+reclaim work on same path";
 attribute :>> addedCost="Physical extra bytes must fit reserved budget; quarantine needs a physical admission bound or may grow without bound";
 attribute :>> condition="Correctness capability established conditionally; runtime frequencies, timings and whole-round peak unmeasured";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="roots"; attribute :>> labelText="Reserve invocation + physical budget\\nprotect procedure / input roots"; }
 part node1 : DiagramNode { attribute :>> nodeId="marker"; attribute :>> labelText="Capture closure identity + original owner\\nallocate marker, reload roots"; }
 part node2 : DiagramNode { attribute :>> nodeId="private"; attribute :>> labelText="Private backing + charge receipt\\nknown layout, init lease"; }
 part node3 : DiagramNode { attribute :>> nodeId="shell"; attribute :>> labelText="Defaults before list admission\\nright-aware scan / cleanup / pointer access"; }
 part node4 : DiagramNode { attribute :>> nodeId="ready"; attribute :>> labelText="Body complete + result rooted\\nescrow still owns native right"; }
 part node5 : DiagramNode { attribute :>> nodeId="commit"; attribute :>> labelText="One canonical result / right commit\\nquery by invocation generation"; }
 part node6 : DiagramNode { attribute :>> nodeId="guard"; attribute :>> labelText="Owner exit guard\\nnormal / error / escaping continuation"; }
 part node7 : DiagramNode { attribute :>> nodeId="park"; attribute :>> labelText="Known stopped writer\\nservice retains init duty and roots"; }
 part node8 : DiagramNode { attribute :>> nodeId="gc"; attribute :>> labelText="Stable root locations; collector relocates values\\nreload before owner reentry"; }
 part node9 : DiagramNode { attribute :>> nodeId="retain"; attribute :>> labelText="Unknown stop / layout / allocation / commit\\nretain exact debt; no replay or refund"; }
 part node10 : DiagramNode { attribute :>> nodeId="dispose"; attribute :>> labelText="Native borrowers drain -> disposal\\nreaders / descendants -> metadata reclaim"; }
 part node11 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML authority -> ASCENT\\nQNT histories + Lean conditional laws"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="root before allocation"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="owner permission"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="safe before shared"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="unique initializer"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="root before commit"; }
 part edge5 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="outcome separate"; }
 part edge6 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="precommit escape"; }
 part edge7 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node5; attribute :>> labelText="postcommit query"; }
 part edge8 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="no owner wait"; }
 part edge9 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node1; attribute :>> labelText="current roots / binding"; }
 part edge10 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node9; attribute :>> labelText="unknown stop"; }
 part edge11 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node9; attribute :>> labelText="unknown backing"; }
 part edge12 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node10; attribute :>> labelText="no raw rollback"; }
 part edge13 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node10; attribute :>> labelText="known disposition only"; }
 part edge14 : DiagramEdge { ref :>> producer=node11; ref :>> consumer=node3; attribute :>> labelText="source refinement open"; }
}
