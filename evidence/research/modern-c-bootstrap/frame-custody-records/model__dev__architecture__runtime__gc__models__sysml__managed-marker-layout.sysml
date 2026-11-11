/* Controlled marker research for modern C. No runtime admission. */
package GambitManagedMarkerLayout {
 private import ScalarValues::*;
 part def MarkerLayout { attribute subtypeCandidate : Integer; attribute rootWords : Integer; attribute keyBytes : Integer; attribute stillPrefixWords : Integer; attribute wordBytes : Integer; attribute bodyBytes : Integer; attribute objectBytes : Integer; attribute allocatorExtra : Integer; attribute allocatorRequest : Integer; attribute deltaFromSmp : Integer; }
 part layout32 : MarkerLayout { attribute :>> subtypeCandidate=16; attribute :>> rootWords=2; attribute :>> keyBytes=24; attribute :>> stillPrefixWords=6; attribute :>> wordBytes=4; attribute :>> bodyBytes=rootWords*wordBytes+keyBytes; attribute :>> objectBytes=stillPrefixWords*wordBytes+bodyBytes; attribute :>> allocatorExtra=11; attribute :>> allocatorRequest=objectBytes+allocatorExtra; attribute :>> deltaFromSmp=keyBytes; }
 part layout64 : MarkerLayout { attribute :>> subtypeCandidate=16; attribute :>> rootWords=2; attribute :>> keyBytes=24; attribute :>> stillPrefixWords=6; attribute :>> wordBytes=8; attribute :>> bodyBytes=rootWords*wordBytes+keyBytes; attribute :>> objectBytes=stillPrefixWords*wordBytes+bodyBytes; attribute :>> allocatorExtra=15; attribute :>> allocatorRequest=objectBytes+allocatorExtra; attribute :>> deltaFromSmp=keyBytes; }
 part def MarkerAdmission { attribute listVisible : Boolean; attribute initialized : Boolean; attribute rootPublished : Boolean; attribute rawCount : Integer; }
 requirement def PublicationLaw { subject a : MarkerAdmission; require constraint { not a.listVisible or (a.initialized and a.rootPublished and a.rawCount==0) } }
 part def ScanOrder { attribute allSetup : Boolean; attribute rootTraceStarted : Boolean; attribute exactDescriptor : Boolean; }
 requirement def RootTraceLaw { subject g : ScanOrder; require constraint { not g.rootTraceStarted or (g.allSetup and g.exactDescriptor) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ML-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/managed_marker_layout.qnt";
 attribute :>> subjectScope="managed_marker_layout:27-named-histories;safe;processor1;seed=17;100x100";
 attribute :>> premise="One managed marker, exact abstract key, processor-one owner, one closed GC view; admitted atomic root/list publication, complete descriptor, native owner/stop and view exclusion are premises; no C weak-memory execution or complete collector simulation";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ML-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/ManagedMarkerLayout.lean";
 attribute :>> subjectScope="GambitSMP.ManagedMarkerLayout:radixPositive;decodeEncode;encodingInjective;rootZeroCovered;rootOneCovered;noRawKeyScanned;admissionSafe;unknownRetainsCustody;stepPreserves;tracePreserves;explicitRootNeedsNoCount;lateResetBreaksScan;missingRecordRejectsReturn;closedRecordRejectsReturn;wrongOwnerRejectsReturn;bodyBytes64;bodyBytes32;payloadDelta";
 attribute :>> premise="18 conditional declarations: bounded three-limb key injectivity, two-root/raw-key disjointness, admission/query Step/Trace, scan ordering and return gates; no complete QNT action or source simulation";
 }
 part layout : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ML-LAYOUT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ManagedMarkerLayout.lean";
 attribute :>> subjectScope="ML-LAYOUT:actual-source-refinement";
 attribute :>> premise="Dedicated subtype candidate 16 with exact body size 2*wordBytes+24, two SCMOBJ cells then immutable raw key bytes; ordinary vector and FOREIGN are excluded representations; explicit scan case marks only cells zero and one; generated C and Scheme subtype tables, predicates, diagnostic walkers, size checks and module admission agree; candidate is not installed or globally ABI-certified";
 }
 part identity : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ML-IDENTITY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ManagedMarkerLayout.lean";
 attribute :>> subjectScope="ML-IDENTITY:actual-source-refinement";
 attribute :>> premise="Immutable key is VM incarnation, activation slot and slot generation, each a bounded nonzero 64-bit component; all three decoded bytewise before protected registry lookup; no pointer identity, no wrap/reuse while any delayed observer can exist, exhaustion rejects; registry miss after managed classification is Closed, never legacy fallback; live original owner/thread and transport identity remain separate";
 }
 part admission : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ML-ADMIT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ManagedMarkerLayout.lean";
 attribute :>> subjectScope="ML-ADMIT:actual-source-refinement";
 attribute :>> premise="Root explicit proc argument or frozen RC closure data before any allocation; pre-reserve root/control storage; private fully initialized still body starts raw refcount zero and mark -1; one no-safepoint/non-escaping publication gate commits still membership plus root enumeration before exposing marker; failure before commit retains inputs/private duty, unknown commit queries canonical service with backed roots; no unsafe public alloc_scmobj shortcut";
 }
 part scanDomain : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ML-SCAN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ManagedMarkerLayout.lean";
 attribute :>> subjectScope="ML-SCAN:actual-source-refinement";
 attribute :>> premise="Freeze all root-domain membership before all still-list setup, then global setup completion before root trace CAS, then typed body scan before strong/weak/sweep closure; enumerate every processor and constructor/quarantine root, including published but unclaimed views; still refcount zero does not eliminate explicit roots; root slot relocations are written back; no setup reset after any cross-processor mark";
 }
 part access : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ML-ACCESS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ManagedMarkerLayout.lean";
 attribute :>> subjectScope="ML-ACCESS:actual-source-refinement";
 attribute :>> premise="Replace direct marker VECTORELEM reads/writes, raw refcount operations, generic release and unchecked construction/subtype mutation for managed markers; preserve wrong-processor hook before closed-return error; guard CFUN/SFUN/kernel/setup frame consumers and global-state function table/module ABI; serialization or unsafe raw FFI exposure rejects managed cohort unless separately specified; no C sandbox claim";
 }
 part lifetime : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ML-LIFETIME";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ManagedMarkerLayout.lean";
 attribute :>> subjectScope="ML-LIFETIME:actual-source-refinement";
 attribute :>> premise="Captured frame keeps closed marker/key independently of activation metadata; permitted procedure clear never changes key or routing cell; release service root after view/object-borrow drain, but GC alone frees unreachable marker; no direct free at record retirement; drain/transfer VM root domain before unconditional cleanup still/RC; invalid raw pointer is never classified by dereference";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ML-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/ManagedMarkerLayout.lean";
 attribute :>> subjectScope="ML-ORDER:actual-C-memory-refinement";
 attribute :>> premise="C release/acquire or common lock covers input/root freeze, body/header/list/root commit and setup-before-mark; immutable fields still require lifetime-safe object borrow; registry lookup protects metadata before use; root slots cannot race relocation/clear; no atomics on a counter substitute for descriptor completeness or original-thread nonlocal jump legality";
 }
 ref part priorClaims=GambitActivationMarkerRetirement::claims;
 ref part priorClear=GambitActivationMarkerRetirement::clearing;
 ref part priorPin=GambitActivationMarkerRetirement::pinLedger;
 ref part priorRetire=GambitActivationMarkerRetirement::retirement;
 ref part priorOrder=GambitActivationMarkerRetirement::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=layout; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=layout; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=layout; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=identity; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=identity; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=identity; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scanDomain; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scanDomain; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scanDomain; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=access; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=access; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=access; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=identity; ref part :>> prerequisite=layout; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=identity; ref part :>> prerequisite=priorClaims; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=layout; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=priorPin; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scanDomain; ref part :>> prerequisite=admission; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=access; ref part :>> prerequisite=identity; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=access; ref part :>> prerequisite=priorClear; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=scanDomain; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=priorRetire; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=priorPin; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=access; ref part :>> prerequisite=priorClaims; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=priorClear; }
 part layoutRoute : GambitHostRootsRefinement::Route { ref part :>> need=layout;
 attribute :>> sourceAnchors="include/gambit.h.in:2875-2950;lib/_gambit#.scm:31-72;lib/sys.scm:1533-1573;lib/mem.c:1487-1500,1560-1709;lib/_kernel.scm:38-73;lib/mem.c:4020-4180;lib/_system.scm:3570-3615,3750-3788;lib/_io.scm:10650-10725,12120-12140;gsc/_t-c-2.scm:3442,3841;lib/mem.c:4387-4451,4932-4935;include/gambit.h.in:13224-13230";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Dedicated subtype candidate 16 with exact body size 2*wordBytes+24, two SCMOBJ cells then immutable raw key bytes; ordinary vector and FOREIGN are excluded representations; explicit scan case marks only cells zero and one; generated C and Scheme subtype tables, predicates, diagnostic walkers, size checks and module admission agree; candidate is not installed or globally ABI-certified";
 attribute :>> failureCustodian="Constructor retains input/private duty until canonical admission; accepted root service retains marker/control through uncertain reply; GC view owns scan tasks until closed; no raw counter replay, registry-miss fallback or premature root refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part identityRoute : GambitHostRootsRefinement::Route { ref part :>> need=identity;
 attribute :>> sourceAnchors="lib/_kernel.scm:1020-1072,1824-1849;lib/_thread.scm:3127-3151;lib/_kernel.scm:149-178;include/gambit.h.in:10043-10059;lib/setup.c:3276-3420;gsc/_ptree2.scm:2902-3030,3145-3187;lib/_system.scm:3570-3615,3750-3788;lib/_io.scm:10650-10725,12120-12140;gsc/_t-c-2.scm:3442,3841;lib/mem.c:4387-4451,4932-4935;include/gambit.h.in:13224-13230";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Immutable key is VM incarnation, activation slot and slot generation, each a bounded nonzero 64-bit component; all three decoded bytewise before protected registry lookup; no pointer identity, no wrap/reuse while any delayed observer can exist, exhaustion rejects; registry miss after managed classification is Closed, never legacy fallback; live original owner/thread and transport identity remain separate";
 attribute :>> failureCustodian="Constructor retains input/private duty until canonical admission; accepted root service retains marker/control through uncertain reply; GC view owns scan tasks until closed; no raw counter replay, registry-miss fallback or premature root refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part admissionRoute : GambitHostRootsRefinement::Route { ref part :>> need=admission;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/mem.c:1778-1821;lib/mem.c:1487-1500,1560-1709;lib/_kernel.scm:38-73;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:702-825;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Root explicit proc argument or frozen RC closure data before any allocation; pre-reserve root/control storage; private fully initialized still body starts raw refcount zero and mark -1; one no-safepoint/non-escaping publication gate commits still membership plus root enumeration before exposing marker; failure before commit retains inputs/private duty, unknown commit queries canonical service with backed roots; no unsafe public alloc_scmobj shortcut";
 attribute :>> failureCustodian="Constructor retains input/private duty until canonical admission; accepted root service retains marker/control through uncertain reply; GC view owns scan tasks until closed; no raw counter replay, registry-miss fallback or premature root refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part scanDomainRoute : GambitHostRootsRefinement::Route { ref part :>> need=scanDomain;
 attribute :>> sourceAnchors="lib/mem.c:3625-3651,4210-4251;lib/mem.c:4020-4180;lib/mem.c:3969-3987,6780-6865,7003-7031;lib/setup.c:3276-3420;gsc/_ptree2.scm:2902-3030,3145-3187;lib/mem.c:4387-4451,4932-4935;include/gambit.h.in:13224-13230;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:702-825";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Freeze all root-domain membership before all still-list setup, then global setup completion before root trace CAS, then typed body scan before strong/weak/sweep closure; enumerate every processor and constructor/quarantine root, including published but unclaimed views; still refcount zero does not eliminate explicit roots; root slot relocations are written back; no setup reset after any cross-processor mark";
 attribute :>> failureCustodian="Constructor retains input/private duty until canonical admission; accepted root service retains marker/control through uncertain reply; GC view owns scan tasks until closed; no raw counter replay, registry-miss fallback or premature root refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part accessRoute : GambitHostRootsRefinement::Route { ref part :>> need=access;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/mem.c:1778-1821;lib/_kernel.scm:1020-1072,1824-1849;lib/_thread.scm:3127-3151;lib/_kernel.scm:149-178;include/gambit.h.in:10043-10059;lib/setup.c:3276-3420;gsc/_ptree2.scm:2902-3030,3145-3187;lib/c_intf.c:6551-6564;lib/mem.c:1441-1484,1730-1739;lib/_system.scm:3570-3615,3750-3788;lib/_io.scm:10650-10725,12120-12140;gsc/_t-c-2.scm:3442,3841;lib/mem.c:4387-4451,4932-4935;include/gambit.h.in:13224-13230;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Replace direct marker VECTORELEM reads/writes, raw refcount operations, generic release and unchecked construction/subtype mutation for managed markers; preserve wrong-processor hook before closed-return error; guard CFUN/SFUN/kernel/setup frame consumers and global-state function table/module ABI; serialization or unsafe raw FFI exposure rejects managed cohort unless separately specified; no C sandbox claim";
 attribute :>> failureCustodian="Constructor retains input/private duty until canonical admission; accepted root service retains marker/control through uncertain reply; GC view owns scan tasks until closed; no raw counter replay, registry-miss fallback or premature root refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part lifetimeRoute : GambitHostRootsRefinement::Route { ref part :>> need=lifetime;
 attribute :>> sourceAnchors="lib/mem.c:3625-3651,4210-4251;lib/setup.c:3276-3420;gsc/_ptree2.scm:2902-3030,3145-3187;lib/c_intf.c:6551-6564;lib/mem.c:1441-1484,1730-1739;lib/_system.scm:3570-3615,3750-3788;lib/_io.scm:10650-10725,12120-12140;gsc/_t-c-2.scm:3442,3841;lib/mem.c:4387-4451,4932-4935;include/gambit.h.in:13224-13230;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:702-825";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Captured frame keeps closed marker/key independently of activation metadata; permitted procedure clear never changes key or routing cell; release service root after view/object-borrow drain, but GC alone frees unreachable marker; no direct free at record retirement; drain/transfer VM root domain before unconditional cleanup still/RC; invalid raw pointer is never classified by dereference";
 attribute :>> failureCustodian="Constructor retains input/private duty until canonical admission; accepted root service retains marker/control through uncertain reply; GC view owns scan tasks until closed; no raw counter replay, registry-miss fallback or premature root refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/mem.c:1778-1821;include/gambit.h.in:2875-2950;lib/_gambit#.scm:31-72;lib/sys.scm:1533-1573;lib/mem.c:1487-1500,1560-1709;lib/_kernel.scm:38-73;lib/mem.c:3625-3651,4210-4251;lib/mem.c:4020-4180;lib/mem.c:3969-3987,6780-6865,7003-7031;lib/_kernel.scm:1020-1072,1824-1849;lib/_thread.scm:3127-3151;lib/_kernel.scm:149-178;include/gambit.h.in:10043-10059;lib/setup.c:3276-3420;gsc/_ptree2.scm:2902-3030,3145-3187;lib/c_intf.c:6551-6564;lib/mem.c:1441-1484,1730-1739;lib/_system.scm:3570-3615,3750-3788;lib/_io.scm:10650-10725,12120-12140;gsc/_t-c-2.scm:3442,3841;lib/mem.c:4387-4451,4932-4935;include/gambit.h.in:13224-13230;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:702-825;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="C release/acquire or common lock covers input/root freeze, body/header/list/root commit and setup-before-mark; immutable fields still require lifetime-safe object borrow; registry lookup protects metadata before use; root slots cannot race relocation/clear; no atomics on a counter substitute for descriptor completeness or original-thread nonlocal jump legality";
 attribute :>> failureCustodian="Constructor retains input/private duty until canonical admission; accepted root service retains marker/control through uncertain reply; GC view owns scan tasks until closed; no raw counter replay, registry-miss fallback or premature root refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="marker-constructor";
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/mem.c:1778-1821";
 attribute :>> actualChain="make_sfun_stack_marker calls make_vector then copies proc/RC data; source TODO warns procedure can move first";
 attribute :>> hazard="Native C local is not an explicit root; data_rc is read only after allocation today";
 attribute :>> replacement="Register proc or frozen closure data/code lease in root domain before any safepoint; typed constructor replaces vector for managed cohort";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="typed-layout-authority";
 attribute :>> sourceAnchors="include/gambit.h.in:2875-2950;lib/_gambit#.scm:31-72;lib/sys.scm:1533-1573";
 attribute :>> actualChain="5 subtype bits; 16/17 absent locally, byte-vector predicate uses 16<x";
 attribute :>> hazard="Candidate 17 falls into byte-vector classification; candidate 16 default GC scan would treat raw bytes as roots";
 attribute :>> replacement="Select candidate16 conditionally; generated shared tables, exact body descriptor, feature admission and full subtype consumer audit required";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="still-allocation-commit";
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1560-1709;lib/_kernel.scm:38-73";
 attribute :>> actualChain="Generic allocator may GC, links still object, sets initial count1; caller fills body later; inline slow path decrements generic still result";
 attribute :>> hazard="Changing initial count to0 without joint root/list gate exposes uninitialized or unrooted object; generic inline allocation cannot construct new marker";
 attribute :>> replacement="Private allocation/accounting + valid header/body + pre-reserved root/list commit, zero raw count; no caller-filled generic new marker";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="zero-count-queue";
 attribute :>> sourceAnchors="lib/mem.c:3625-3651,4210-4251";
 attribute :>> actualChain="Setup marks zero-count still -1; explicit mark_array CAS can enqueue regardless refcount";
 attribute :>> hazard="Mark-before-late-setup is overwritten; duplicate/late setup can lose queued work";
 attribute :>> replacement="Retain per-list setup ownership then all-list barrier, root enumeration, CAS queue and completion debt";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="typed-scan-consumer";
 attribute :>> sourceAnchors="lib/mem.c:4020-4180";
 attribute :>> actualChain="FOREIGN skipped; ordinary default scans all body words; FRAME uses liveness map";
 attribute :>> hazard="FOREIGN wrapper loses proc edge; default scans arbitrary key bytes as SCMOBJ";
 attribute :>> replacement="Dedicated marker scan of body[0..1] only; reject wrong exact size/subtype and preserve relocation updates";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="processor-root-enumeration";
 attribute :>> sourceAnchors="lib/mem.c:3969-3987,6780-6865,7003-7031";
 attribute :>> actualChain="mark_rc runs only P0 branch; setup and mark separated by real BARRIER";
 attribute :>> hazard="Per-PSTATE root chain for processor1 cannot become VM-wide merely by reusing mark_rc name";
 attribute :>> replacement="VM root-domain registry covers all admitted contexts, pending constructors and quarantine; distinct independent-worker task/view protocol";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="return-route-and-live-check";
 attribute :>> sourceAnchors="lib/_kernel.scm:1020-1072,1824-1849;lib/_thread.scm:3127-3151";
 attribute :>> actualChain="Kernel raw vector slot1 routes processor before slot0 false check; hook may migrate Scheme thread";
 attribute :>> hazard="New representation cannot preserve raw offsets or equate processor id with native live owner";
 attribute :>> replacement="Checked classifier/route then exact key original-owner claim, preserving hook/error ordering and Scheme semantics";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="conversion-error-procedure";
 attribute :>> sourceAnchors="lib/_kernel.scm:149-178;include/gambit.h.in:10043-10059";
 attribute :>> actualChain="Kernel raw temp3 vector0 feeds conversion handler; SFUN reuses same marker through error loop";
 attribute :>> hazard="Missing raw read in migration loses error procedure or applies wrong one-return restriction";
 attribute :>> replacement="Checked rooted procedure accessor; per-delivery identity; close only original activation guard exit";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="matching-call-and-run";
 attribute :>> sourceAnchors="lib/setup.c:3276-3420;gsc/_ptree2.scm:2902-3030,3145-3187";
 attribute :>> actualChain="___call stores marker in two-slot return frame, catches matching object only; ___run and generated SFUN create/kill";
 attribute :>> hazard="Object equality currently matches native destination; serialized/copied key cannot create a live C frame";
 attribute :>> replacement="Preserve frame GC-map marker slot and exact object match plus key/owner claim; no native-stack reification from key";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="kill-counter-release";
 attribute :>> sourceAnchors="lib/c_intf.c:6551-6564;lib/mem.c:1441-1484,1730-1739";
 attribute :>> actualChain="kill false store then raw --; exports read/inc/dec fields without profile gate; release_scmobj decrements still";
 attribute :>> hazard="Zero-count cohort raw decrement wraps or makes a nonzero seed; invalid memory cannot be checked safely";
 attribute :>> replacement="Retire old kill/debit only for controlled cohort, profile-gate raw exports and generic release, require valid rooted handle";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="continuation-serialization";
 attribute :>> sourceAnchors="lib/_system.scm:3570-3615,3750-3788;lib/_io.scm:10650-10725,12120-12140;gsc/_t-c-2.scm:3442,3841";
 attribute :>> actualChain="Binary serializer visits live continuation/frame slots; writer explodes continuation; unsafe subtype/vector mutators generated directly";
 attribute :>> hazard="Copy/deserialize marker key is not authority; private raw subtype mutation can corrupt descriptor";
 attribute :>> replacement="Explicit unsupported-live-native-marker serialization; opaque printing; reject or revoke raw access capability, no managed cohort for unaudited unsafe module";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="sweep-and-teardown";
 attribute :>> sourceAnchors="lib/mem.c:4387-4451,4932-4935;include/gambit.h.in:13224-13230";
 attribute :>> actualChain="Sweep uses mark, teardown frees all still/RC; global-state ABI exposes marker create/kill";
 attribute :>> hazard="Record removal is not object death; teardown defeats extra root or native reader";
 attribute :>> replacement="Captured key persists after metadata; no direct free; root-domain drain/transfer before teardown, module feature admission required";
 }
 part caller12 : CallerRow {
 attribute :>> callerId="dynamic-closure-root";
 attribute :>> sourceAnchors="lib/os_dyn.c:744-790,1045-1058;lib/mem.c:702-825";
 attribute :>> actualChain="c_closure_self global with thread-local TODO; alloc/register/data RC API has distinct native list and data field";
 attribute :>> hazard="Reading mutable global after GC can select different callback and P0-only RC scan is insufficient";
 attribute :>> replacement="Freeze actual trampoline closure/code borrow and root proc before allocation; reject foreign-thread/unqualified alias path";
 }
 part caller13 : CallerRow {
 attribute :>> callerId="actual-host-callbacks";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> actualChain="Tcl command callback and dynamic function conversions instantiate real SFUN entry chains";
 attribute :>> hazard="Native-library lifetime, deletion and continuation escape are not fixed by marker type";
 attribute :>> replacement="Shared generated C service must carry root/activation/transport duties through each real callback; external ABI remains explicit admission gate";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Managed marker bytes";
 attribute :>> removedWork="Remove overloaded vector identity and raw pin debit";
 attribute :>> bound="Body=2W+24; still total=8W+24; 64-bit 40/88 bytes, 32-bit 32/56 bytes";
 attribute :>> addedCost="Compared with current SMP 2-word body: exactly +24 bytes per marker before allocator slack";
 attribute :>> condition="W=4 or8, STILL_BODY=6; no control/root/native record counted here; no RSS claim";
 }
 part cost1 : CostRow {
 attribute :>> capability="Allocator request";
 attribute :>> removedWork="Make padding/backpointer cost explicit";
 attribute :>> bound="64-bit request103 vs79; 32-bit request67 vs43 bytes";
 attribute :>> addedCost="Current aligned wrapper adds15 or11 bytes under pointerBytes=W and modulus0";
 attribute :>> condition="Source arithmetic only; malloc usable size, allocator bins and future allocator unresolved";
 }
 part cost2 : CostRow {
 attribute :>> capability="Precise body tracing";
 attribute :>> removedWork="Skip all raw identity words";
 attribute :>> bound="2 SCMOBJ cells examined per traced managed marker; 3 raw64 limbs never scanned";
 attribute :>> addedCost="SMP old vector already scanned2 cells; no reduction in these two cells";
 attribute :>> condition="Dedicated subtype+exact size+scan case mandatory; two cells scanned does not count transitive proc graph";
 }
 part cost3 : CostRow {
 attribute :>> capability="Root enumeration";
 attribute :>> removedWork="Replace managed initial refcount pin with one canonical root entry";
 attribute :>> bound="Raw initial count0; raw decrements0; one service root, released once after safe clear";
 attribute :>> addedCost="O(R) active root-slot visits plus still CAS/dedup; constructor procedure root through possible GC";
 attribute :>> condition="Every PSTATE/context included; no P0-only RC shortcut; publication and setup order proved";
 }
 part cost4 : CostRow {
 attribute :>> capability="Stable identity";
 attribute :>> removedWork="Avoid address reuse and managed-miss legacy fallback";
 attribute :>> bound="3 nonzero bounded64 components,24 bytes; key immutable through physical clear";
 attribute :>> addedCost="Protected registry lookup and root/object/control pin support";
 attribute :>> condition="No modular wrap; slot generation/VM incarnation exhaustion rejects admission; not Scheme continuation identity";
 }
 part cost5 : CostRow {
 attribute :>> capability="Return behavior";
 attribute :>> removedWork="Share checked accessor/claim rather than inline layout assumptions";
 attribute :>> bound="One owner commit per delivery; repeated fresh delivery while live remains legal";
 attribute :>> addedCost="Classifier,size,key decode and owner dispatch; 0 native jump authority from serialized key";
 attribute :>> condition="Wrong-processor hook order preserved; original-thread/live activation still necessary";
 }
 part cost6 : CostRow {
 attribute :>> capability="Construction and failure";
 attribute :>> removedWork="Eliminate unrooted allocation window for admitted markers";
 attribute :>> bound="Input roots precede first possible allocation; 1 list/root visibility commit";
 attribute :>> addedCost="Pre-reserved control/root capacity and bounded no-safepoint publication section";
 attribute :>> condition="Unknown commit keeps canonical custody; no refund, pointer probe or replay from absent ACK";
 }
 part cost7 : CostRow {
 attribute :>> capability="Raw access retirement";
 attribute :>> removedWork="Remove managed vector kill/debit and raw marker field reads";
 attribute :>> bound="Conditional replacement of constructor, kill,2 kernel consumer families and profile-gated APIs; 0 production paths retired now";
 attribute :>> addedCost="Generator/kernel/function-table/subtype/scan/serializer migration and binary admission";
 attribute :>> condition="Unaudited low-level C or Scheme mutators reject managed profile; unsafe C cannot be sandboxed by descriptor";
 }
 part cost8 : CostRow {
 attribute :>> capability="Closed continuation memory";
 attribute :>> removedWork="Permit metadata record retirement independent of heap marker reachability";
 attribute :>> bound="Captured closed marker keeps24-byte key; permitted proc clear can sever its procedure edge";
 attribute :>> addedCost="Marker and other captured-frame roots may remain; graph saving not bounded by marker count";
 attribute :>> condition="No whole graph reclamation follows from clearing one edge; no resurrection from registry miss";
 }
 part cost9 : CostRow {
 attribute :>> capability="Whole-round peak";
 attribute :>> removedWork="Avoid double-counting shared root/control backing";
 attribute :>> bound="Extra marker backing=24*M against SMP at same live-marker set; Peak=max_t(H+P+N+Q)";
 attribute :>> addedCost="Root/control pools, unknown construction and quarantine graph retention additionally increase peak";
 attribute :>> condition="M is actual concurrent physical markers, not activations ever; no whole-round peak reduction proved";
 }
 part cost10 : CostRow {
 attribute :>> capability="Modern C net value";
 attribute :>> removedWork="Generate one layout/scan/access contract consumable by modern C and future LLVM";
 attribute :>> bound="Zig-specific removed necessary support=0 demonstrated; runtime implementation remains0";
 attribute :>> addedCost="Same root,ABI,lifetime,ordering and identity proofs in C and Zig";
 attribute :>> condition="Positive value requires errors/retention/waits removed exceed admission/lookup/trace costs; no measured speedup";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="inputs"; attribute :>> labelText="Root proc / frozen closure data\\nbefore any safepoint"; }
 part node1 : DiagramNode { attribute :>> nodeId="private"; attribute :>> labelText="Reserve root / control capacity\\nprivate typed body, refcount0"; }
 part node2 : DiagramNode { attribute :>> nodeId="layout"; attribute :>> labelText="Subtype candidate16\\n2 SCMOBJ + 24 immutable raw bytes"; }
 part node3 : DiagramNode { attribute :>> nodeId="commit"; attribute :>> labelText="Bounded publication gate\\nvalid list + root entry together"; }
 part node4 : DiagramNode { attribute :>> nodeId="setup"; attribute :>> labelText="Freeze all domains\\nall still-list setup completes"; }
 part node5 : DiagramNode { attribute :>> nodeId="trace"; attribute :>> labelText="Root enumeration -> still CAS\\nscan exactly two root slots"; }
 part node6 : DiagramNode { attribute :>> nodeId="return"; attribute :>> labelText="Checked route + activation key\\noriginal-owner delivery claim"; }
 part node7 : DiagramNode { attribute :>> nodeId="close"; attribute :>> labelText="Logical close -> permitted proc clear\\nkey / route unchanged"; }
 part node8 : DiagramNode { attribute :>> nodeId="captured"; attribute :>> labelText="Captured frame retains marker\\nmetadata miss means Closed"; }
 part node9 : DiagramNode { attribute :>> nodeId="sweep"; attribute :>> labelText="Root/view/borrow drain\\nGC reachability alone frees marker"; }
 part node10 : DiagramNode { attribute :>> nodeId="reject"; attribute :>> labelText="Raw vector / counter / serialization\\nreplace or reject admission"; }
 part node11 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nsource and C-order gates open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="protect before allocate"; }
 part edge1 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node1; attribute :>> labelText="exact shape"; }
 part edge2 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node3; attribute :>> labelText="body initialized"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="jointly visible"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="all-list barrier first"; }
 part edge5 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node6; attribute :>> labelText="typed rooted object"; }
 part edge6 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="original exit guard"; }
 part edge7 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="immutable key survives"; }
 part edge8 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node8; attribute :>> labelText="frame roots traced"; }
 part edge9 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node9; attribute :>> labelText="release is not free"; }
 part edge10 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node9; attribute :>> labelText="actual heap reachability"; }
 part edge11 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node6; attribute :>> labelText="no legacy fallback"; }
 part edge12 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node2; attribute :>> labelText="no forged mutable type"; }
 part edge13 : DiagramEdge { ref :>> producer=node11; ref :>> consumer=node4; attribute :>> labelText="conditional refinement"; }
 part edge14 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node9; attribute :>> labelText="strong/weak completion"; }
}
