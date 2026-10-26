/* Modern C release admission research; no runtime implementation. */
package GambitReleaseProducerAdmission {
 private import ScalarValues::*;
 part def ResourceBudget { attribute taskSlots : Integer; attribute rootCells : Integer; attribute waitBytes : Integer; attribute codePins : Integer; attribute nativeBytes : Integer; attribute handles : Integer; attribute descendantSlots : Integer; }
 part def ReleaseProfile { attribute codeIdentity : String; attribute configurationIdentity : String; attribute allowedOrigins : String; attribute affinity : String; attribute callbackEffects : String; attribute lockOrder : String; attribute allocationEffects : String; attribute disposalEffects : String; attribute dependencyShape : String; attribute delayPermission : String; ref reservationBound : ResourceBudget; }
 part def ReleaseRight { ref profile : ReleaseProfile; ref reserved : ResourceBudget; attribute rightIdentity : String; attribute generation : Integer; attribute producer : String; attribute custody : String; attribute nativeOutcome : String; attribute rootRegistrationReceipt : String; attribute currentTraceReceipt : String; attribute readerAndChildDebt : Integer; }
 part def ClosureState { attribute issued : Boolean; attribute constructorDebt : Integer; attribute rootDebt : Integer; }
 requirement def ConstructionClosureLaw { subject s : ClosureState; require constraint { not s.issued or (s.constructorDebt == 0 and s.rootDebt == 0) } }
 part def AdmissionState { attribute deferred : Boolean; attribute profileKnown : Boolean; attribute budgetReserved : Boolean; attribute rootsRegistered : Boolean; attribute rootsTraced : Boolean; attribute originAllowed : Boolean; }
 requirement def ReleaseAdmissionLaw { subject s : AdmissionState; require constraint { not s.deferred or (s.profileKnown and s.budgetReserved and s.rootsRegistered and s.rootsTraced and s.originAllowed) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RP-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/release_producer_admission.qnt";
 attribute :>> subjectScope="release_producer_admission:26-named-histories;safe;seed=17;100x100";
 attribute :>> premise="Two release rights with common function/pointer identity; bounded slots and native-byte credits; roots and known outcome are abstract predicates; no real allocation, effect interpreter or whole-GC liveness";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RP-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/ReleaseProducerAdmission.lean";
 attribute :>> subjectScope="GambitSMP.ReleaseProducerAdmission:wrapConserves;acceptConserves;startConserves;finishConserves;retireConserves;stepConserves;traceConserves;reservationBound;equalFunctionDoesNotMergeRights;unknownKeepsCapacity;unknownEffectRejects;unknownAffinityRejects;untracedRootRejects;unreservedRejects;synchronousOriginRejects;readersRejectRetirement;unknownDispositionRejectsRetirement;rootCoverageTransitive;constructorDebtRejectsClosure;rootDebtRejectsClosure";
 attribute :>> premise="20 conditional declarations: disjoint credit Step/Trace conservation, admission rejection and retirement gates; no complete QNT-to-C simulation";
 }
 part census : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RP-CENSUS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ReleaseProducerAdmission.lean";
 attribute :>> subjectScope="RP-CENSUS:actual-source-refinement";
 attribute :>> premise="Lexical closed-repository runtime registrations, generated converter templates, explicit/rollback/teardown origins and custom example declarations must be enumerated; arbitrary C converters, c-declare, dynamic modules and exported APIs remain open-world until registered; installed configuration not inferred";
 }
 part effects : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RP-EFFECTS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ReleaseProducerAdmission.lean";
 attribute :>> subjectScope="RP-EFFECTS:actual-source-refinement";
 attribute :>> premise="Bind exact release code/library/config generation, transitive callbacks/locks/allocator/free effects, owner/VM/processor/thread affinity and typed disposal to each producing right; unknown effects/affinity or invalid rollback target refuses deferred admission";
 }
 part budget : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RP-BUDGET";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ReleaseProducerAdmission.lean";
 attribute :>> subjectScope="RP-BUDGET:actual-source-refinement";
 attribute :>> premise="Atomically reserve slot/root/code/wait/handle/native-byte capacity before native production; every wrapped, in-flight, queued and terminal-retained right occupies one disjoint ticket; finite descendant bounds or same-ticket resumable continuation required; no refund from ACK/unknown result";
 }
 part roots : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RP-ROOTS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ReleaseProducerAdmission.lean";
 attribute :>> subjectScope="RP-ROOTS:actual-source-refinement";
 attribute :>> premise="Declare dependency shape at profile registration; root and pin concrete dependencies before first GC/native escape; trace/relocate current-round roots before cleanup settlement, or counted pre-seal rescan under admitted credit; FOREIGN opacity, RC teardown and profile/code readers require real closure";
 }
 part origins : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RP-ORIGINS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ReleaseProducerAdmission.lean";
 attribute :>> subjectScope="RP-ORIGINS:actual-source-refinement";
 attribute :>> premise="Explicit foreign-release!, value-conversion rollback and library/device constructor rollback retain synchronous outcome/visibility unless separately proven equivalent; GC deferral needs legal delay, teardown needs service drain; no-op/permanent wrappers create zero release jobs";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RP-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/ReleaseProducerAdmission.lean";
 attribute :>> subjectScope="RP-ORDER:actual-C-memory-refinement";
 attribute :>> premise="C release/acquire publish immutable profile and accepted ticket before source detach; close producer gate then acquire all reservations; generation-safe root/slot/code retirement after readers/children; stop/unknown foreign effects remain platform obligations";
 }
 ref part priorSeal=GambitResumeSealCleanup::sealLaw;
 ref part priorHandoff=GambitResumeSealCleanup::handoff;
 ref part priorRoots=GambitResumeSealCleanup::rootCustody;
 ref part priorDispatch=GambitResumeSealCleanup::dispatch;
 ref part priorOrigins=GambitResumeSealCleanup::origins;
 ref part priorRecovery=GambitResumeSealCleanup::recovery;
 ref part priorOrder=GambitResumeSealCleanup::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=census; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=census; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=census; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=effects; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=effects; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=effects; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=budget; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=budget; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=budget; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origins; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origins; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origins; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=effects; ref part :>> prerequisite=census; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origins; ref part :>> prerequisite=census; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=budget; ref part :>> prerequisite=effects; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=budget; ref part :>> prerequisite=origins; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=budget; ref part :>> prerequisite=priorHandoff; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=effects; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=priorRoots; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=effects; ref part :>> prerequisite=priorDispatch; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origins; ref part :>> prerequisite=priorOrigins; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=priorSeal; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=budget; ref part :>> prerequisite=priorRecovery; }
 part censusRoute : GambitHostRootsRefinement::Route { ref part :>> need=census;
 attribute :>> sourceAnchors="lib/os_io.c:4550;lib/os_io.c:7135;lib/os_io.c:10162;lib/os_io.c:10458;lib/os_io.c:10526;lib/os_io.c:10615;lib/os_io.c:10758;lib/os_io.c:10910;lib/os_io.c:10952;lib/os_io.c:11046;lib/os_io.c:11375;lib/os_io.c:11453;lib/setup.c:1942-1955;lib/c_intf.c:5156-5223;gsc/_ptree2.scm:2586-2678;lib/c_intf.c:1716-1727;gsc/_ptree2.scm:2623-2661;include/gambit.h.in:9838-9961,10008-10031;gsc/_ptree2.scm:2380-2431,2586-2678;gsc/_ptree2.scm:2210-2245,2260;include/gambit.h.in:13001-13033;lib/_kernel.scm:3884-3894;lib/c_intf.c:1683-1711;lib/c_intf.c:5283-5382;lib/mem.c:4390-4451,4932-4935;lib/setup.c:4572-4590;examples/Xlib-simple/Xlib.scm:61-70,123;examples/Xlib-simple/Xlib.scm:73-82,126;examples/Xlib-simple/Xlib.scm:85-94,129;examples/Xlib-simple/Xlib.scm:97-106,132";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Lexical closed-repository runtime registrations, generated converter templates, explicit/rollback/teardown origins and custom example declarations must be enumerated; arbitrary C converters, c-declare, dynamic modules and exported APIs remain open-world until registered; installed configuration not inferred";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part effectsRoute : GambitHostRootsRefinement::Route { ref part :>> need=effects;
 attribute :>> sourceAnchors="lib/os_io.c:4550;lib/os_io.c:7135;lib/os_io.c:10162;lib/os_io.c:10952;lib/setup.c:1942-1955;gsc/_ptree2.scm:2380-2431,2586-2678;examples/Xlib-simple/Xlib.scm:73-82,126;examples/Xlib-simple/Xlib.scm:85-94,129;examples/Xlib-simple/Xlib.scm:97-106,132";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Bind exact release code/library/config generation, transitive callbacks/locks/allocator/free effects, owner/VM/processor/thread affinity and typed disposal to each producing right; unknown effects/affinity or invalid rollback target refuses deferred admission";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part budgetRoute : GambitHostRootsRefinement::Route { ref part :>> need=budget;
 attribute :>> sourceAnchors="lib/os_io.c:4550;lib/os_io.c:7135;lib/os_io.c:10615;lib/os_io.c:10952;lib/c_intf.c:5156-5223;gsc/_ptree2.scm:2586-2678;lib/c_intf.c:1716-1727;gsc/_ptree2.scm:2380-2431,2586-2678;lib/mem.c:4390-4451,4932-4935;lib/setup.c:4572-4590";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Atomically reserve slot/root/code/wait/handle/native-byte capacity before native production; every wrapped, in-flight, queued and terminal-retained right occupies one disjoint ticket; finite descendant bounds or same-ticket resumable continuation required; no refund from ACK/unknown result";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part rootsRoute : GambitHostRootsRefinement::Route { ref part :>> need=roots;
 attribute :>> sourceAnchors="lib/os_io.c:4550;lib/setup.c:1942-1955;lib/c_intf.c:5156-5223;gsc/_ptree2.scm:2210-2245,2260;include/gambit.h.in:13001-13033;lib/mem.c:4390-4451,4932-4935;lib/setup.c:4572-4590;examples/Xlib-simple/Xlib.scm:61-70,123";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Declare dependency shape at profile registration; root and pin concrete dependencies before first GC/native escape; trace/relocate current-round roots before cleanup settlement, or counted pre-seal rescan under admitted credit; FOREIGN opacity, RC teardown and profile/code readers require real closure";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part originsRoute : GambitHostRootsRefinement::Route { ref part :>> need=origins;
 attribute :>> sourceAnchors="lib/os_io.c:4550;lib/os_io.c:7135;lib/os_io.c:10615;lib/os_io.c:10952;lib/c_intf.c:5283-5382;lib/mem.c:4390-4451,4932-4935;lib/setup.c:4572-4590;examples/Xlib-simple/Xlib.scm:61-70,123";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Explicit foreign-release!, value-conversion rollback and library/device constructor rollback retain synchronous outcome/visibility unless separately proven equivalent; GC deferral needs legal delay, teardown needs service drain; no-op/permanent wrappers create zero release jobs";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="lib/os_io.c:4550;lib/os_io.c:7135;lib/os_io.c:10162;lib/os_io.c:10458;lib/os_io.c:10526;lib/os_io.c:10615;lib/os_io.c:10758;lib/os_io.c:10910;lib/os_io.c:10952;lib/os_io.c:11046;lib/os_io.c:11375;lib/os_io.c:11453;lib/setup.c:1942-1955;lib/c_intf.c:5156-5223;gsc/_ptree2.scm:2586-2678;lib/c_intf.c:1716-1727;gsc/_ptree2.scm:2623-2661;include/gambit.h.in:9838-9961,10008-10031;gsc/_ptree2.scm:2380-2431,2586-2678;gsc/_ptree2.scm:2210-2245,2260;include/gambit.h.in:13001-13033;lib/_kernel.scm:3884-3894;lib/c_intf.c:1683-1711;lib/c_intf.c:5283-5382;lib/mem.c:4390-4451,4932-4935;lib/setup.c:4572-4590;examples/Xlib-simple/Xlib.scm:61-70,123;examples/Xlib-simple/Xlib.scm:73-82,126;examples/Xlib-simple/Xlib.scm:85-94,129;examples/Xlib-simple/Xlib.scm:97-106,132";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="C release/acquire publish immutable profile and accepted ticket before source detach; close producer gate then acquire all reservations; generation-safe root/slot/code retirement after readers/children; stop/unknown foreign effects remain platform obligations";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="___os_make_tls_context";
 attribute :>> sourceAnchors="lib/os_io.c:4550";
 attribute :>> actualChain="c -> ___release_rc_tls_context; same TLS context released synchronously";
 attribute :>> hazard="Release strings/SSL_CTX/RC; callback/config/RC owner and code lifetime not worker-qualified";
 attribute :>> replacement="Conditional candidate only; exact effects, roots, legal delay and budget unqualified";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="___device_event_queue_read";
 attribute :>> sourceAnchors="lib/os_io.c:7135";
 attribute :>> actualChain="ev -> ___release_event; direct return after PeekMessage(PM_REMOVE); no local conversion-failure release branch";
 attribute :>> hazard="Release RC MSG storage; producer consumes thread message; Win32-only branch";
 attribute :>> replacement="Source correction/ownership evidence required before deferral; no native reproduction";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="___os_device_raw_open_from_fd";
 attribute :>> sourceAnchors="lib/os_io.c:10162";
 attribute :>> actualChain="dev -> ___device_cleanup_from_ptr; same dev cleaned synchronously; scalar cleanup error ignored";
 attribute :>> hazard="Device group unlink + directional close/select wait + virtual release/free; per-vtable affinity and aliases required";
 attribute :>> replacement="Conditional candidate only; exact effects, roots, legal delay and budget unqualified";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="___os_device_stream_open_predefined";
 attribute :>> sourceAnchors="lib/os_io.c:10458";
 attribute :>> actualChain="dev -> ___device_cleanup_from_ptr; same dev cleaned synchronously; scalar cleanup error ignored";
 attribute :>> hazard="Device group unlink + directional close/select wait + virtual release/free; per-vtable affinity and aliases required";
 attribute :>> replacement="Conditional candidate only; exact effects, roots, legal delay and budget unqualified";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="___os_device_stream_open_path";
 attribute :>> sourceAnchors="lib/os_io.c:10526";
 attribute :>> actualChain="dev -> ___device_cleanup_from_ptr; same dev cleaned synchronously; scalar cleanup error ignored";
 attribute :>> hazard="Device group unlink + directional close/select wait + virtual release/free; per-vtable affinity and aliases required";
 attribute :>> replacement="Conditional candidate only; exact effects, roots, legal delay and budget unqualified";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="___os_device_stream_open_process";
 attribute :>> sourceAnchors="lib/os_io.c:10615";
 attribute :>> actualChain="dev -> ___device_cleanup_from_ptr; conversion success drops Scheme hold; failure has no local device cleanup; string temporaries released";
 attribute :>> hazard="Device group unlink + directional close/select wait + virtual release/free; per-vtable affinity and aliases required";
 attribute :>> replacement="Source correction/ownership evidence required before deferral; no native reproduction";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="___os_device_tcp_client_open";
 attribute :>> sourceAnchors="lib/os_io.c:10758";
 attribute :>> actualChain="dev -> ___device_cleanup_from_ptr; same dev cleaned synchronously; scalar cleanup error ignored";
 attribute :>> hazard="Device group unlink + directional close/select wait + virtual release/free; per-vtable affinity and aliases required";
 attribute :>> replacement="Conditional candidate only; exact effects, roots, legal delay and budget unqualified";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="___os_device_tcp_server_open";
 attribute :>> sourceAnchors="lib/os_io.c:10910";
 attribute :>> actualChain="dev -> ___device_cleanup_from_ptr; same dev cleaned synchronously; scalar cleanup error ignored";
 attribute :>> hazard="Device group unlink + directional close/select wait + virtual release/free; per-vtable affinity and aliases required";
 attribute :>> replacement="Conditional candidate only; exact effects, roots, legal delay and budget unqualified";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="___os_device_tcp_server_read";
 attribute :>> sourceAnchors="lib/os_io.c:10952";
 attribute :>> actualChain="client -> ___device_cleanup_from_ptr; conversion failure cleans d (server), although wrapped payload is client";
 attribute :>> hazard="Device group unlink + directional close/select wait + virtual release/free; per-vtable affinity and aliases required";
 attribute :>> replacement="Source correction/ownership evidence required before deferral; no native reproduction";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="___os_device_udp_open";
 attribute :>> sourceAnchors="lib/os_io.c:11046";
 attribute :>> actualChain="dev -> ___device_cleanup_from_ptr; same dev cleaned synchronously; scalar cleanup error ignored";
 attribute :>> hazard="Device group unlink + directional close/select wait + virtual release/free; per-vtable affinity and aliases required";
 attribute :>> replacement="Conditional candidate only; exact effects, roots, legal delay and budget unqualified";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="___os_device_directory_open_path";
 attribute :>> sourceAnchors="lib/os_io.c:11375";
 attribute :>> actualChain="dev -> ___device_cleanup_from_ptr; same dev cleaned synchronously; scalar cleanup error ignored";
 attribute :>> hazard="Device group unlink + directional close/select wait + virtual release/free; per-vtable affinity and aliases required";
 attribute :>> replacement="Conditional candidate only; exact effects, roots, legal delay and budget unqualified";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="___os_device_event_queue_open";
 attribute :>> sourceAnchors="lib/os_io.c:11453";
 attribute :>> actualChain="dev -> ___device_cleanup_from_ptr; same dev cleaned synchronously; scalar cleanup error ignored";
 attribute :>> hazard="Device group unlink + directional close/select wait + virtual release/free; per-vtable affinity and aliases required";
 attribute :>> replacement="Conditional candidate only; exact effects, roots, legal delay and budget unqualified";
 }
 part caller12 : CallerRow {
 attribute :>> callerId="permanent-module";
 attribute :>> sourceAnchors="lib/setup.c:1942-1955";
 attribute :>> actualChain="Permanent module wrapper; NULL release pointer";
 attribute :>> hazard="No release job; module/code storage still pinned by actual users";
 attribute :>> replacement="No deferred ticket; module unload/drain remains independent";
 }
 part caller13 : CallerRow {
 attribute :>> callerId="pointer-installer";
 attribute :>> sourceAnchors="lib/c_intf.c:5156-5223";
 attribute :>> actualChain="One field installer; nonnull converter forwards to it; allocation can GC/fail";
 attribute :>> hazard="Native producer already happened before converter entry";
 attribute :>> replacement="New producer preflight before native call; pointer converter consumes reserved ownership";
 }
 part caller14 : CallerRow {
 attribute :>> callerId="generated-default-pointer";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2586-2678;lib/c_intf.c:1716-1727";
 attribute :>> actualChain="Pointer/nonnull default ___RELEASE_POINTER is no-op";
 attribute :>> hazard="C-world resource not reclaimed by this callback";
 attribute :>> replacement="No deferred release job; preserve borrow/explicit native ownership";
 }
 part caller15 : CallerRow {
 attribute :>> callerId="generated-value-releases";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2623-2661;include/gambit.h.in:9838-9961,10008-10031";
 attribute :>> actualChain="Three STRUCT/UNION/TYPE release templates; per-module kind/name code dedup";
 attribute :>> hazard="C path uses RC release under configured RC allocation, otherwise FREE_MEM; code dedup is not resource-right dedup";
 attribute :>> replacement="Typed allocator/RC-owner profiles and one per-instance ticket; exclude C++ architecture";
 }
 part caller16 : CallerRow {
 attribute :>> callerId="custom-release-generator";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2380-2431,2586-2678";
 attribute :>> actualChain="Custom function identifier passed directly to generated to-Scheme conversion";
 attribute :>> hazard="Identifier validity proves neither effects nor thread safety";
 attribute :>> replacement="Explicit manifest/profile or reject independent delayed GC service";
 }
 part caller17 : CallerRow {
 attribute :>> callerId="custom-converter-escape";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2210-2245,2260;include/gambit.h.in:13001-13033";
 attribute :>> actualChain="Named custom converters, c-declare and public runtime API may construct foreign objects";
 attribute :>> hazard="Unbounded external producer/effect set; exported representation permits aliases";
 attribute :>> replacement="Managed-domain registration and audited write capability; unregistered extensions remain unsupported";
 }
 part caller18 : CallerRow {
 attribute :>> callerId="explicit-release";
 attribute :>> sourceAnchors="lib/_kernel.scm:3884-3894;lib/c_intf.c:1683-1711";
 attribute :>> actualChain="foreign-release! calls release, clears fields then invokes; raises from nonzero result";
 attribute :>> hazard="Return time/error/effect observable; clearing fields is not accepted service custody";
 attribute :>> replacement="Keep synchronous invocation boundary; factor typed common dispatcher without blanket delay";
 }
 part caller19 : CallerRow {
 attribute :>> callerId="value-conversion-rollback";
 attribute :>> sourceAnchors="lib/c_intf.c:5283-5382";
 attribute :>> actualChain="STRUCT/UNION/TYPE conversion failure directly calls release_fn(x)";
 attribute :>> hazard="Cleanup starts before wrapper exists; same credit must cover failure, not allocate a fresh job";
 attribute :>> replacement="Reserved result slot + synchronous rollback or separately qualified source custody";
 }
 part caller20 : CallerRow {
 attribute :>> callerId="gc-and-teardown";
 attribute :>> sourceAnchors="lib/mem.c:4390-4451,4932-4935;lib/setup.c:4572-4590";
 attribute :>> actualChain="Sweep/free_still_objs call release; cleanup_rc follows still retirement before OS cleanup";
 attribute :>> hazard="Unconditional RC chain cleanup bypasses addref; source and service dependencies differ";
 attribute :>> replacement="Drain/physical RC transfer before teardown; no reference-count-only lifetime proof";
 }
 part caller21 : CallerRow {
 attribute :>> callerId="Xlib-release-rc-values";
 attribute :>> sourceAnchors="examples/Xlib-simple/Xlib.scm:61-70,123";
 attribute :>> actualChain="XGCValues pointer registers release_rc_XGCValues";
 attribute :>> hazard="RC chain owner; optional debug I/O; alias/drain requirements";
 attribute :>> replacement="Example profile only; no cross-thread or installed-target admission";
 }
 part caller22 : CallerRow {
 attribute :>> callerId="Xlib-font-info";
 attribute :>> sourceAnchors="examples/Xlib-simple/Xlib.scm:73-82,126";
 attribute :>> actualChain="XFontStruct registers XFreeFontInfo_XFontStruct";
 attribute :>> hazard="Xlib free and optional I/O; library/thread/display policy unproved";
 attribute :>> replacement="Reject worker deferral pending exact library/owner profile";
 }
 part caller23 : CallerRow {
 attribute :>> callerId="Xlib-release-rc-color";
 attribute :>> sourceAnchors="examples/Xlib-simple/Xlib.scm:85-94,129";
 attribute :>> actualChain="XColor registers release_rc_XColor";
 attribute :>> hazard="RC chain lifetime; optional debug I/O";
 attribute :>> replacement="Example profile only; no generic free shortcut";
 }
 part caller24 : CallerRow {
 attribute :>> callerId="Xlib-release-rc-event";
 attribute :>> sourceAnchors="examples/Xlib-simple/Xlib.scm:97-106,132";
 attribute :>> actualChain="XEvent registers release_rc_XEvent";
 attribute :>> hazard="RC chain lifetime; optional debug I/O";
 attribute :>> replacement="Example profile only; no pointer identity dedup";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="GC critical release work";
 attribute :>> removedWork="Move only admitted legal-delay bodies Fi out of collective cleanup";
 attribute :>> bound="Delta critical work = sum eligible(Fi-Hi)-profile/root/ledger cost; serial comparison only";
 attribute :>> addedCost="One handoff per right plus roots/rescan; scheduler contention";
 attribute :>> condition="Positive only if saved body work exceeds these costs; zero measured speedup";
 }
 part cost1 : CostRow {
 attribute :>> capability="Budget unit";
 attribute :>> removedWork="Share one persistent ticket across producer/wrapper/queue/terminal states";
 attribute :>> bound="M=sum disjoint Constructing+Wrapped+Queued+Running+Retained; not distinct function count";
 attribute :>> addedCost="O(M) ticket/receipt slots and generation metadata";
 attribute :>> condition="Two equal release functions or RC payload addresses can still require two release rights";
 }
 part cost2 : CostRow {
 attribute :>> capability="Preflight capacity";
 attribute :>> removedWork="Avoid collector allocation/waiting for owner to free queue capacity";
 attribute :>> bound="For each resource dimension k: sum live q_i[k]+inflight descendant reserve <= pool[k]";
 attribute :>> addedCost="Atomic quota ledger; root/code/wait/handle/native-byte bounds";
 attribute :>> condition="Reserve before first native effect; unknown size/fanout refuses bounded profile";
 }
 part cost3 : CostRow {
 attribute :>> capability="Peak control memory";
 attribute :>> removedWork="Reuse same slot when transferring one duty; no second queue payload copy required";
 attribute :>> bound="Pool = M*slotBytes + rootCells*rootCellBytes + waitBytes + receipts + allocator overhead";
 attribute :>> addedCost="Resident pre-reserved storage can increase low-load peak";
 attribute :>> condition="Logical credit cap requires actual physical backing proof; no numeric byte estimate without layouts";
 }
 part cost4 : CostRow {
 attribute :>> capability="Retained native memory";
 attribute :>> removedWork="Account resources ignored by Scheme wrapper size";
 attribute :>> bound="Peak=max_t(baseHeap(t)+physicalPools(t)+retainedNative(t)+rootBacking(t)+quarantine(t))";
 attribute :>> addedCost="Delay can retain payload longer; unknown outcomes can retain indefinitely";
 attribute :>> condition="Do not sum independent maxima, double-count already physical reserved bytes or refund on queue ACK";
 }
 part cost5 : CostRow {
 attribute :>> capability="Root closure";
 attribute :>> removedWork="Reuse registered dependency handles; avoid re-discovery during destructor";
 attribute :>> bound="R dependency cells scanned/relocated; late managed edges require counted pre-seal rescan";
 attribute :>> addedCost="Instance registration before possible GC; weak/strong ordering";
 attribute :>> condition="Descriptor alone not root instance or current trace receipt; opaque FOREIGN not a managed root";
 }
 part cost6 : CostRow {
 attribute :>> capability="Code/library profile";
 attribute :>> removedWork="Share immutable effect/affinity descriptor per code/config generation";
 attribute :>> bound="O(P) descriptors plus O(M) generation references";
 attribute :>> addedCost="Configuration-change revocation, external alias audit, library pins";
 attribute :>> condition="Code descriptor dedup permitted; per-instance release rights cannot be deduplicated";
 }
 part cost7 : CostRow {
 attribute :>> capability="Explicit and rollback paths";
 attribute :>> removedWork="Reuse typed disposition/custody support while preserving caller boundary";
 attribute :>> bound="No work reduction claimed for synchronous origins; three value rollback protocols";
 attribute :>> addedCost="Preflight adaptation in CFUN/SFUN plus each direct constructor";
 attribute :>> condition="No legal timing/error equivalence means no delayed job admission";
 }
 part cost8 : CostRow {
 attribute :>> capability="Source coverage";
 attribute :>> removedWork="One generator protocol can cover arbitrarily many generated value releases";
 attribute :>> bound="12 os_io registrations + 1 permanent-null setup expression; 3 value templates; 4 example custom types";
 attribute :>> addedCost="Open custom converters/C API require registration; platform predicates remain";
 attribute :>> condition="Counts are source inventory, never active Darwin leaf coverage or speedup";
 }
 part cost9 : CostRow {
 attribute :>> capability="Source correction cuts";
 attribute :>> removedWork="Replace ambiguous failure ownership with exact return-slot custody";
 attribute :>> bound="Three lexical blockers: Win32 event return, process conversion failure, accepted-client/server mismatch";
 attribute :>> addedCost="Source corrections and independent failure-path evidence";
 attribute :>> condition="No implementation done; do not assign resource leak frequency or observable impact without native evidence";
 }
 part cost10 : CostRow {
 attribute :>> capability="Teardown";
 attribute :>> removedWork="Use shared drain/transfer barrier instead of implicit PSTATE lifetime";
 attribute :>> bound="No live ticket/code/root reader when withdrawing scanning/RC/native service";
 attribute :>> addedCost="Ordered shutdown DAG; owner dispatch must not wait round seal cyclically";
 attribute :>> condition="Unknown task disposition/root transfer refuses teardown, not automatic refund";
 }
 part cost11 : CostRow {
 attribute :>> capability="Modern C versus Zig";
 attribute :>> removedWork="Scheme emits one typed ReleaseSpec and modern C adapters";
 attribute :>> bound="Zero extra runtime-work saving established for Zig";
 attribute :>> addedCost="Both need same profile, credit, root, ABI and memory-order proofs";
 attribute :>> condition="Modern C mandatory; Zig optional only with independently demonstrated incremental benefit";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="producer"; attribute :>> labelText="Scheme generator / native constructor\\nprofile + origin + result slot"; }
 part node1 : DiagramNode { attribute :>> nodeId="reserve"; attribute :>> labelText="Atomic vector budget reservation\\nbefore native resource creation"; }
 part node2 : DiagramNode { attribute :>> nodeId="roots"; attribute :>> labelText="Instance dependency registration\\nbefore first possible GC / escape"; }
 part node3 : DiagramNode { attribute :>> nodeId="native"; attribute :>> labelText="Native effect + conversion\\nsame ticket; synchronous rollback"; }
 part node4 : DiagramNode { attribute :>> nodeId="cut"; attribute :>> labelText="Producer close + acquired ledger\\nin-flight reservations remain charged"; }
 part node5 : DiagramNode { attribute :>> nodeId="trace"; attribute :>> labelText="Current-round dependency trace\\nor counted pre-seal rescan"; }
 part node6 : DiagramNode { attribute :>> nodeId="handoff"; attribute :>> labelText="Accepted task custody\\nthen wrapper retirement"; }
 part node7 : DiagramNode { attribute :>> nodeId="run"; attribute :>> labelText="Qualified executor / owner dispatch\\nexplicit WaitContext + code pin"; }
 part node8 : DiagramNode { attribute :>> nodeId="retire"; attribute :>> labelText="Known disposition + readers/children drain\\nphysical free then budget refund"; }
 part node9 : DiagramNode { attribute :>> nodeId="reject"; attribute :>> labelText="Unknown profile / rollback owner / roots\\nreject deferral; retain known source custody"; }
 part node10 : DiagramNode { attribute :>> nodeId="models"; attribute :>> labelText="SysML -> ASCENT\\nQNT + Lean conditional evidence"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="shape and effect admission"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="capacity secured"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="rooted native arguments/results"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="wrapped and in-flight duties"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="no unregistered producer"; }
 part edge5 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="roots traced before cleanup seal"; }
 part edge6 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="owner callback waits active permit"; }
 part edge7 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="ACK alone insufficient"; }
 part edge8 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node9; attribute :>> labelText="failed or unknown custody"; }
 part edge9 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node9; attribute :>> labelText="unknown external effects"; }
 part edge10 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node6; attribute :>> labelText="source and C-order gaps remain"; }
}
