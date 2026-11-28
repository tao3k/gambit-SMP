/* Modern C activation, marker and managed root-pin research; no runtime admission. */
package GambitActivationMarkerRetirement {
 private import ScalarValues::*;
 part def ActivationControl { attribute stateTag : String; attribute generation : Integer; attribute currentReturn : Integer; attribute cPopped : Boolean; attribute dutyAccepted : Boolean; }
 requirement def PopGate { subject a : ActivationControl; require constraint { not a.cPopped or (a.stateTag == "Closed" and a.currentReturn == -1 and a.dutyAccepted) } }
 part def PhysicalWriteGate { attribute rootHeld : Boolean; attribute stopped : Boolean; attribute permit : Boolean; attribute publishedView : Boolean; attribute canClear : Boolean; }
 requirement def ClearGate { subject g : PhysicalWriteGate; require constraint { not g.canClear or (g.rootHeld and g.stopped and g.permit and not g.publishedView) } }
 part def PinRelease { attribute profileTag : String; attribute operationIdentity : String; attribute outcomeKnown : Boolean; attribute quarantineRoot : Boolean; }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AR-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/activation_marker_retirement.qnt";
 attribute :>> subjectScope="activation_marker_retirement:37-named-histories;safe;managed+legacy;seed=17;each100x100";
 attribute :>> premise="One activation generation, two transport deliveries, one active published/scanning view; original owner, complete stable roots, native stop/layout and managed typed-allocation admission are premises; neither C weak memory nor arbitrary collector/continuation execution is simulated";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AR-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/ActivationMarkerRetirement.lean";
 attribute :>> subjectScope="GambitSMP.ActivationMarkerRetirement:committedReturnRejectsClose;closedAdmissionRejectsCommit;wrongOwnerRejectsCommit;releaseConserves;releasedOnceRejectsRetry;stepConserves;traceConserves;unclaimedViewRejectsWrite;unknownWriterRejectsWrite;borrowerRejectsWrite;unrootedWriteRejected;legacyObservationsEqual;legacyOutcomesDiffer;noTotalOutcomeDecoder;clearIsIdempotent;unknownDebitRejectsRetirement;readerRejectsRetirement;freshTransportUnaffected";
 attribute :>> premise="18 conditional declarations: close/commit exclusion, pin release/query Step/Trace conservation, write/reclaim rejection and indistinguishable legacy debit outcomes; not all QNT actions or C source/GC simulation";
 }
 part claims : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AR-CLAIM";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ActivationMarkerRetirement.lean";
 attribute :>> subjectScope="AR-CLAIM:actual-source-refinement";
 attribute :>> premise="Only original owner arbiter commits a return through one activation control; queue/reserve is revocable and never grants direct C jump; closing and commit are mutually exclusive; consuming a committed return leaves live activation eligible for a fresh legal Scheme return, while duplicate transport receipt/old generation cannot repeat delivery";
 }
 part closing : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AR-CLOSE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ActivationMarkerRetirement.lean";
 attribute :>> subjectScope="AR-CLOSE:actual-source-refinement";
 attribute :>> premise="Close admission before guard pop, revoke uncommitted reservations without waiting for requester ACK, preserve already committed target until owner matching consumption; transfer backed roots/init/physical duty before Closed publication; external close request is not permission to destroy C activation; no owner/claim/GC reverse wait";
 }
 part clearing : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AR-CLEAR";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ActivationMarkerRetirement.lean";
 attribute :>> subjectScope="AR-CLEAR:actual-source-refinement";
 attribute :>> premise="Clear marker only under valid root/heap write permit after published and claimed view obligations, object borrowers and prior writer drain, with new object-borrow admission closed at logical closing; do not hold permit while waiting for external borrower; unknown clear is replayable only as same false store with known stopped writer, valid shape and exact root-backed identity; no unknown decrement replay";
 }
 part pinLedger : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AR-PIN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ActivationMarkerRetirement.lean";
 attribute :>> subjectScope="AR-PIN:actual-source-refinement";
 attribute :>> premise="Managed marker cohort uses typed allocation with raw initial still-refcount zero and canonical registered root pin before admission; root ledger owns one idempotent release receipt, never raw --; every raw refcount writer/reader and opaque access must reject or be migrated for that cohort; legacy initial-one bridge retains root/debt on unknown debit and cannot infer outcome from scalar count";
 }
 part scanDomain : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AR-SCAN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ActivationMarkerRetirement.lean";
 attribute :>> subjectScope="AR-SCAN:actual-source-refinement";
 attribute :>> premise="Root descriptor/index and epoch view must cover pending marker and quarantine before GC setup; counter-zero managed markers enter still mark queue through explicit root trace; no marker write/root unregister during published-but-unclaimed or claimed view; physical collection follows actual root/heap reachability and completed phase, not pin receipt or C pop";
 }
 part retirement : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AR-RECLAIM";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ActivationMarkerRetirement.lean";
 attribute :>> subjectScope="AR-RECLAIM:actual-source-refinement";
 attribute :>> premise="Distinguish C activation right, object/root borrow, metadata reader and independent committed result custody; acquire metadata protection during registry lookup; managed discriminator/key remains lifetime-stable in captured marker after metadata removal, so managed missing identity rejects late return without stale pointer while legacy classification remains unchanged; drain all required pins before record/generation reuse, preserve captured continuation roots and already committed results; no root/credit refund from unknown legacy debit";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AR-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/ActivationMarkerRetirement.lean";
 attribute :>> subjectScope="AR-ORDER:actual-C-memory-refinement";
 attribute :>> premise="Actual C race freedom and release/acquire/lock refinement for lookup+pin, activation reservation/return commit/closing control, backed handoff, phase-scoped marker clear, pin-ledger release and generation reuse; changing raw -- to atomic does not add per-operation identity or memory reclamation proof";
 }
 ref part priorTransport=GambitOwnerExitGuard::transport;
 ref part priorRoots=GambitOwnerExitGuard::rootCustody;
 ref part priorDuty=GambitOwnerExitGuard::duty;
 ref part priorBridge=GambitOwnerExitGuard::bridge;
 ref part priorOrder=GambitOwnerExitGuard::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=claims; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=claims; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=claims; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=closing; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=closing; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=closing; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=clearing; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=clearing; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=clearing; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=pinLedger; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=pinLedger; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=pinLedger; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scanDomain; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scanDomain; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scanDomain; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=claims; ref part :>> prerequisite=priorTransport; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=closing; ref part :>> prerequisite=claims; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=closing; ref part :>> prerequisite=priorDuty; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=clearing; ref part :>> prerequisite=closing; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=clearing; ref part :>> prerequisite=scanDomain; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=pinLedger; ref part :>> prerequisite=clearing; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=pinLedger; ref part :>> prerequisite=priorRoots; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scanDomain; ref part :>> prerequisite=priorRoots; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=closing; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=pinLedger; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=priorDuty; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=claims; ref part :>> prerequisite=priorBridge; }
 part claimsRoute : GambitHostRootsRefinement::Route { ref part :>> need=claims;
 attribute :>> sourceAnchors="lib/_kernel.scm:1020-1072,1824-1849;lib/setup.c:3276-3390;include/gambit.h.in:10043-10059;lib/_kernel.scm:149-178;lib/_thread.scm:3127-3151;lib/_kernel.scm:1838-1849;gsc/_ptree2.scm:2902-3030,3145-3187;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Only original owner arbiter commits a return through one activation control; queue/reserve is revocable and never grants direct C jump; closing and commit are mutually exclusive; consuming a committed return leaves live activation eligible for a fresh legal Scheme return, while duplicate transport receipt/old generation cannot repeat delivery";
 attribute :>> failureCustodian="Original owner serializes close/return; accepted service retains exact marker/root/physical duty before C pop; managed release queried by identity; legacy debit unknown retains root/debt; metadata reader never grants C jump or physical marker access";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part closingRoute : GambitHostRootsRefinement::Route { ref part :>> need=closing;
 attribute :>> sourceAnchors="lib/c_intf.c:6551-6564;lib/_kernel.scm:1020-1072,1824-1849;lib/setup.c:3276-3390;include/gambit.h.in:10043-10059;lib/_kernel.scm:149-178;lib/mem.c:684-703,4432-4451,4932-4935;gsc/_ptree2.scm:2902-3030,3145-3187;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Close admission before guard pop, revoke uncommitted reservations without waiting for requester ACK, preserve already committed target until owner matching consumption; transfer backed roots/init/physical duty before Closed publication; external close request is not permission to destroy C activation; no owner/claim/GC reverse wait";
 attribute :>> failureCustodian="Original owner serializes close/return; accepted service retains exact marker/root/physical duty before C pop; managed release queried by identity; legacy debit unknown retains root/debt; metadata reader never grants C jump or physical marker access";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part clearingRoute : GambitHostRootsRefinement::Route { ref part :>> need=clearing;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/mem.c:1487-1500,1677-1709,1778-1821;lib/c_intf.c:6551-6564;lib/mem.c:1441-1484,1730-1739;lib/mem.c:4210-4251,6780-6810;lib/mem.c:3625-3651,3970-3987,4023-4038,6844-6865";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Clear marker only under valid root/heap write permit after published and claimed view obligations, object borrowers and prior writer drain, with new object-borrow admission closed at logical closing; do not hold permit while waiting for external borrower; unknown clear is replayable only as same false store with known stopped writer, valid shape and exact root-backed identity; no unknown decrement replay";
 attribute :>> failureCustodian="Original owner serializes close/return; accepted service retains exact marker/root/physical duty before C pop; managed release queried by identity; legacy debit unknown retains root/debt; metadata reader never grants C jump or physical marker access";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part pinLedgerRoute : GambitHostRootsRefinement::Route { ref part :>> need=pinLedger;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/mem.c:1487-1500,1677-1709,1778-1821;lib/c_intf.c:6551-6564;lib/mem.c:1441-1484,1730-1739;lib/mem.c:4210-4251,6780-6810;lib/mem.c:3625-3651,3970-3987,4023-4038,6844-6865;lib/mem.c:684-703,4432-4451,4932-4935";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Managed marker cohort uses typed allocation with raw initial still-refcount zero and canonical registered root pin before admission; root ledger owns one idempotent release receipt, never raw --; every raw refcount writer/reader and opaque access must reject or be migrated for that cohort; legacy initial-one bridge retains root/debt on unknown debit and cannot infer outcome from scalar count";
 attribute :>> failureCustodian="Original owner serializes close/return; accepted service retains exact marker/root/physical duty before C pop; managed release queried by identity; legacy debit unknown retains root/debt; metadata reader never grants C jump or physical marker access";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part scanDomainRoute : GambitHostRootsRefinement::Route { ref part :>> need=scanDomain;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/mem.c:1487-1500,1677-1709,1778-1821;lib/mem.c:1441-1484,1730-1739;lib/mem.c:4210-4251,6780-6810;lib/mem.c:3625-3651,3970-3987,4023-4038,6844-6865;lib/mem.c:4387-4427,6917-6935;lib/mem.c:684-703,4432-4451,4932-4935";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Root descriptor/index and epoch view must cover pending marker and quarantine before GC setup; counter-zero managed markers enter still mark queue through explicit root trace; no marker write/root unregister during published-but-unclaimed or claimed view; physical collection follows actual root/heap reachability and completed phase, not pin receipt or C pop";
 attribute :>> failureCustodian="Original owner serializes close/return; accepted service retains exact marker/root/physical duty before C pop; managed release queried by identity; legacy debit unknown retains root/debt; metadata reader never grants C jump or physical marker access";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part retirementRoute : GambitHostRootsRefinement::Route { ref part :>> need=retirement;
 attribute :>> sourceAnchors="lib/_kernel.scm:1020-1072,1824-1849;lib/setup.c:3276-3390;lib/_thread.scm:3127-3151;lib/_kernel.scm:1838-1849;lib/mem.c:3625-3651,3970-3987,4023-4038,6844-6865;lib/mem.c:4387-4427,6917-6935;lib/mem.c:684-703,4432-4451,4932-4935;gsc/_ptree2.scm:2902-3030,3145-3187;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Distinguish C activation right, object/root borrow, metadata reader and independent committed result custody; acquire metadata protection during registry lookup; managed discriminator/key remains lifetime-stable in captured marker after metadata removal, so managed missing identity rejects late return without stale pointer while legacy classification remains unchanged; drain all required pins before record/generation reuse, preserve captured continuation roots and already committed results; no root/credit refund from unknown legacy debit";
 attribute :>> failureCustodian="Original owner serializes close/return; accepted service retains exact marker/root/physical duty before C pop; managed release queried by identity; legacy debit unknown retains root/debt; metadata reader never grants C jump or physical marker access";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/mem.c:1487-1500,1677-1709,1778-1821;lib/c_intf.c:6551-6564;lib/mem.c:1441-1484,1730-1739;lib/_kernel.scm:1020-1072,1824-1849;lib/setup.c:3276-3390;include/gambit.h.in:10043-10059;lib/_kernel.scm:149-178;lib/_thread.scm:3127-3151;lib/_kernel.scm:1838-1849;lib/mem.c:4210-4251,6780-6810;lib/mem.c:3625-3651,3970-3987,4023-4038,6844-6865;lib/mem.c:4387-4427,6917-6935;lib/mem.c:684-703,4432-4451,4932-4935;gsc/_ptree2.scm:2902-3030,3145-3187;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Actual C race freedom and release/acquire/lock refinement for lookup+pin, activation reservation/return commit/closing control, backed handoff, phase-scoped marker clear, pin-ledger release and generation reuse; changing raw -- to atomic does not add per-operation identity or memory reclamation proof";
 attribute :>> failureCustodian="Original owner serializes close/return; accepted service retains exact marker/root/physical duty before C pop; managed release queried by identity; legacy debit unknown retains root/debt; metadata reader never grants C jump or physical marker access";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="marker-create-pin";
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/mem.c:1487-1500,1677-1709,1778-1821";
 attribute :>> actualChain="make_sfun_stack_marker creates 1/2 element still vector with refcount one; alloc_scmobj links before caller fills body";
 attribute :>> hazard="Managed ledger cannot simply be bolted on and then decrement old pin twice";
 attribute :>> replacement="Typed marker allocator/root admission replaces initial legacy pin for new cohort; old allocation remains legacy-only";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="marker-kill";
 attribute :>> sourceAnchors="lib/c_intf.c:6551-6564";
 attribute :>> actualChain="kill writes vector[0]=false then still_obj_refcount_dec";
 attribute :>> hazard="Logical C activation invalidity, heap write and native pin drop are currently coupled";
 attribute :>> replacement="Close native activation first; accepted cleanup duty owns later permitted physical clear and profile-specific pin release";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="raw-still-counter";
 attribute :>> sourceAnchors="lib/mem.c:1441-1484,1730-1739";
 attribute :>> actualChain="Still refcount inc/dec/read are plain field accesses; release_scmobj invokes decrement for still objects";
 attribute :>> hazard="Void decrement has no operation receipt; scalar count cannot identify which owner released";
 attribute :>> replacement="Gate raw exports for managed cohort; canonical root-pin ledger; legacy uncertain debit quarantines exact root/duty";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="return-handler";
 attribute :>> sourceAnchors="lib/_kernel.scm:1020-1072,1824-1849";
 attribute :>> actualChain="Return handler routes wrong processor, tests marker false, writes all GVM state and throws to ___call";
 attribute :>> hazard="Check-then-jump can race a future independent close; changing routing order alters Scheme hooks/errors";
 attribute :>> replacement="Preserve route order, then original-owner claim commit against authoritative activation state and exact rooted destination";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="matching-frame";
 attribute :>> sourceAnchors="lib/setup.c:3276-3390";
 attribute :>> actualChain="___call rethrows nonmatching destination and consumes matching fp/R0 only on its own marker";
 attribute :>> hazard="Closing a committed target early or consuming stale packet can destroy live C stack semantics";
 attribute :>> replacement="ReturnCommitted pins real activation until original owner consumes; close request deferred, not blocked remote holder";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="same-marker-error-loop";
 attribute :>> sourceAnchors="include/gambit.h.in:10043-10059;lib/_kernel.scm:149-178";
 attribute :>> actualChain="SFUN error loops call ___call again with same marker before END invalidation";
 attribute :>> hazard="One return ever per activation would break existing reentrant conversion handling";
 attribute :>> replacement="Deduplicate delivery instance only; fresh legal Scheme invocation while activation Open is preserved";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="processor-route";
 attribute :>> sourceAnchors="lib/_thread.scm:3127-3151;lib/_kernel.scm:1838-1849";
 attribute :>> actualChain="Hook migrates Scheme thread to marker processor; logical C activation still belongs to original native owner";
 attribute :>> hazard="A queued request/processor id is not an OS-thread longjmp capability";
 attribute :>> replacement="Stable activation generation, owner/lineage dispatch and tombstone rejection; arbitrary native-stack migration not admitted";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="still-gc-setup";
 attribute :>> sourceAnchors="lib/mem.c:4210-4251,6780-6810";
 attribute :>> actualChain="GC setup seeds still queue when refcount nonzero, otherwise mark=-1; scan list follows mark links";
 attribute :>> hazard="Managed raw count zero needs independent registered root enumeration before weak/finish closure";
 attribute :>> replacement="Typed root-domain scan adapter; publication/claim/trace/drain receipts protect descriptor and object storage";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="explicit-root-mark";
 attribute :>> sourceAnchors="lib/mem.c:3625-3651,3970-3987,4023-4038,6844-6865";
 attribute :>> actualChain="mark_array can enqueue unmarked still objects with CAS in SMP; RC data roots scanned only in P0 branch; FOREIGN payload opaque";
 attribute :>> hazard="Existing mark mechanism helps but root-domain completeness/nonzero RC ownership are not supplied";
 attribute :>> replacement="Reuse still mark primitive with full processor/root coverage; independent root writer authority and typed marker layout proof";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="sweep-physical-lifetime";
 attribute :>> sourceAnchors="lib/mem.c:4387-4427,6917-6935";
 attribute :>> actualChain="Sweep frees objects whose mark remains -1 and recomputes still accounting";
 attribute :>> hazard="Pin release or lost receipt cannot authorize eager object free before real heap/continuation reachability";
 attribute :>> replacement="Keep service/quarantine strong root through safe known cleanup; captured closed marker may remain heap-reachable";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="teardown-lifetime";
 attribute :>> sourceAnchors="lib/mem.c:684-703,4432-4451,4932-4935";
 attribute :>> actualChain="Teardown frees still objects and RC chain unconditionally";
 attribute :>> hazard="Refcount/pin alone does not survive VM teardown; readers can retain control and distinct results";
 attribute :>> replacement="Drain or physical domain transfer before teardown; metadata-only readers separate from marker/code/native borrowers";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="real-generated-callbacks";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-3030,3145-3187;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> actualChain="Generator creates static/dynamic SFUN entries; actual host/Tcl/function callbacks consume results and retain external resources";
 attribute :>> hazard="Raw ABI/private marker exposure and native-library continuation legality remain real admission limits";
 attribute :>> replacement="Scheme emits activation/transport identities and root/borrow descriptors; modern C service shared, qualified legacy bridge retained";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Return/close arbitration";
 attribute :>> removedWork="Avoid wait for uncommitted external request holder before C pop";
 attribute :>> bound="One owner-local commit decision per return delivery; one close-admission decision per activation exit";
 attribute :>> addedCost="Registry protection, generation and delivery-receipt lookup";
 attribute :>> condition="Reservation revocable; committed owner return must actually consume before close; no wall-clock wait bound proved";
 }
 part cost1 : CostRow {
 attribute :>> capability="Continuation semantics";
 attribute :>> removedWork="Preserve repeated legal return into still-live activation";
 attribute :>> bound="At most 1 delivery per transport id; potentially multiple fresh ids per live activation";
 attribute :>> addedCost="Per-delivery receipts and alias/late-message discipline";
 attribute :>> condition="Transport id is not continuation identity; no blanket one-return lifetime restriction";
 }
 part cost2 : CostRow {
 attribute :>> capability="Marker physical clear";
 attribute :>> removedWork="Separate logical Closed from collector-writable heap mutation";
 attribute :>> bound="One known successful false state; uncertain idempotent clear may repeat same assignment after qualified stop";
 attribute :>> addedCost="Root/write permit, published-view drain and object-borrow gates";
 attribute :>> condition="No implication of atomicity, safe signal recovery or source proof from idempotence";
 }
 part cost3 : CostRow {
 attribute :>> capability="Managed pin ledger";
 attribute :>> removedWork="Retire raw still -- for qualified managed marker cohort";
 attribute :>> bound="One logical root-pin release receipt per marker; 0 raw refcount decrement on new managed path";
 attribute :>> addedCost="Typed marker allocation, root-domain trace and canonical ledger update";
 attribute :>> condition="Initial raw count zero only with complete strong-root admission and all raw refcount/opaque access paths migrated";
 }
 part cost4 : CostRow {
 attribute :>> capability="Legacy debit unknown";
 attribute :>> removedWork="Keep GC safe without guessing or replaying decrement";
 attribute :>> bound="0 extra raw debit after unknown; exact strong root/duty retained";
 attribute :>> addedCost="Potential indefinite marker/procedure graph retention and budget exhaustion";
 attribute :>> condition="Same visible count can represent applied/not-applied histories with other writers; generic recovery remains unresolved";
 }
 part cost5 : CostRow {
 attribute :>> capability="GC publication window";
 attribute :>> removedWork="Exclude both unclaimed and active scanners from mutation";
 attribute :>> bound="Published view blocks permit before worker claim; permit blocks new view until bounded update ends";
 attribute :>> addedCost="Epoch/view state, scan/root leases and stopped-writer receipts";
 attribute :>> condition="A zero active-scanner count alone is insufficient; unknown in-flight managed writer still blocks this permission";
 }
 part cost6 : CostRow {
 attribute :>> capability="Reader separation";
 attribute :>> removedWork="Allow closed marker collection while metadata observer remains";
 attribute :>> bound="Metadata readers keep control record only; object borrowers retain root and block physical clear";
 attribute :>> addedCost="Two distinct lease classes and root/record retirement policies";
 attribute :>> condition="Existing raw marker readers must be audited; missing identity/generation maps closed, not freed-pointer access";
 }
 part cost7 : CostRow {
 attribute :>> capability="GC and continuation reuse";
 attribute :>> removedWork="Reuse still-object marking for counter-zero explicit roots";
 attribute :>> bound="Existing mark_array still CAS path can enqueue rooted marker; no new object collector needed for this fact";
 attribute :>> addedCost="New root enumeration/phase integration and late-return validation";
 attribute :>> condition="Captured continuation is an independent heap root; pin receipt never proves object dead";
 }
 part cost8 : CostRow {
 attribute :>> capability="Peak memory";
 attribute :>> removedWork="Count one physical backing through activation/service/quarantine ownership";
 attribute :>> bound="Peak=max_t(H+P+N+Q); no refund at close, receipt ACK or ledger release";
 attribute :>> addedCost="Deferred marker/procedure retention, delivery records and quarantine may increase peak";
 attribute :>> condition="Bounded slot count alone does not bound retained procedure graph; require heap/native budgets; no peak reduction proved";
 }
 part cost9 : CostRow {
 attribute :>> capability="Modern C architecture";
 attribute :>> removedWork="Share control/root/permit/receipt support and remove implicit ownership coupling";
 attribute :>> bound="0 production paths retired today; conditional retirement of raw marker kill/debit plus ungated return check for managed cohort";
 attribute :>> addedCost="Scheme generator, kernel, allocator, GC root adapter and C memory refinement all required";
 attribute :>> condition="Positive latency gain only if avoided waits/replay/retention outweigh new arbitration/trace/lease costs; no incremental Zig benefit or measured speedup";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="entry"; attribute :>> labelText="Typed marker + stable root admission\\nactivation generation / transport identity"; }
 part node1 : DiagramNode { attribute :>> nodeId="reserve"; attribute :>> labelText="Queue / reserve return intent\\nmetadata protection; revocable"; }
 part node2 : DiagramNode { attribute :>> nodeId="arbiter"; attribute :>> labelText="Original-owner activation arbiter\\ncommit return OR close admission"; }
 part node3 : DiagramNode { attribute :>> nodeId="returning"; attribute :>> labelText="ReturnCommitted -> matching consume\\nfresh legal return may use same marker"; }
 part node4 : DiagramNode { attribute :>> nodeId="closed"; attribute :>> labelText="Close reservations + accept backed duty\\npublish Closed before C pop"; }
 part node5 : DiagramNode { attribute :>> nodeId="view"; attribute :>> labelText="Published / scanning root view\\nphysical permit mutually exclusive"; }
 part node6 : DiagramNode { attribute :>> nodeId="clear"; attribute :>> labelText="Root + stopped writer + heap permit\\nclear marker; reconcile only idempotent store"; }
 part node7 : DiagramNode { attribute :>> nodeId="ledger"; attribute :>> labelText="Managed root-pin release receipt\\nnew cohort has no raw --"; }
 part node8 : DiagramNode { attribute :>> nodeId="legacy"; attribute :>> labelText="Legacy raw decrement unknown\\nretain exact root and duty; never replay"; }
 part node9 : DiagramNode { attribute :>> nodeId="gc"; attribute :>> labelText="Root-domain tracing + actual heap reachability\\ncaptured continuation may retain closed marker"; }
 part node10 : DiagramNode { attribute :>> nodeId="retire"; attribute :>> labelText="Object borrow / metadata readers separate\\nrecord reuse after exact pin drain"; }
 part node11 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nsource / C-memory refinements open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="protect before lookup use"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="intent is not jump right"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="return commits first"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node2; attribute :>> labelText="consume before close"; }
 part edge4 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node4; attribute :>> labelText="closing commits first"; }
 part edge5 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node6; attribute :>> labelText="accepted duty"; }
 part edge6 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="drain before permit"; }
 part edge7 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="managed profile"; }
 part edge8 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node8; attribute :>> labelText="legacy profile"; }
 part edge9 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node9; attribute :>> labelText="release is not free"; }
 part edge10 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node9; attribute :>> labelText="quarantine strong root"; }
 part edge11 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node10; attribute :>> labelText="real reachability / readers"; }
 part edge12 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node10; attribute :>> labelText="late receipt read"; }
 part edge13 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node10; attribute :>> labelText="tombstone rejects late return"; }
 part edge14 : DiagramEdge { ref :>> producer=node11; ref :>> consumer=node2; attribute :>> labelText="conditional model only"; }
}
