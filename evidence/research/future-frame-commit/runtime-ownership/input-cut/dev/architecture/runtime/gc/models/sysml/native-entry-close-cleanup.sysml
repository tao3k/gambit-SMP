/* Modern C entry-close/cleanup research; semantic authority for derived views. */
package GambitNativeEntryCloseCleanup {
 private import ScalarValues::*;
 part def ActivationCut { attribute valid : Boolean; attribute rootsHeld : Boolean; attribute markerSettled : Boolean; attribute catcherRestored : Boolean; attribute unknown : Boolean; }
 requirement def ReturnLaw { subject a : ActivationCut; require constraint { not a.valid or (not a.rootsHeld and a.markerSettled and a.catcherRestored and not a.unknown) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="EC-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/native_entry_close_cleanup.qnt";
 attribute :>> subjectScope="native_entry_close_cleanup:24-histories;safe;three-protocol-projections;seed17;3x100x100";
 attribute :>> premise="14 positive and 10 unsafe controls; one queued Tcl entry and pin, one parent epoch and one run cleanup. Opaque Tcl/run root contents, live owner/token and external drain/settlement are premises; not a shared-VM evaluator/ABI/weak-memory proof.";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="EC-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/NativeEntryCloseCleanup.lean";
 attribute :>> subjectScope="GambitSMP.NativeEntryCloseCleanup:14-conditional-declarations";
 attribute :>> premise="Conditional pin/delete lifetime, park/epoch, run return/cleanup/count and payload equations; selective operation laws, no complete QNT trace/source simulation.";
 }
 part token : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="EC-TOKEN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeEntryCloseCleanup.lean";
 attribute :>> subjectScope="EC-TOKEN:actual-owner-ClientData-entry-delete";
 attribute :>> premise="Live token anchor, owner-thread callback entry pin before data_rc, deleteProc close without self-wait, preserve trace/replacement behavior and separate Command versus ClientData lifetime.";
 }
 part parent : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="EC-PARENT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeEntryCloseCleanup.lean";
 attribute :>> subjectScope="EC-PARENT:actual-full-view-park-context-reload";
 attribute :>> premise="Every parent raw borrower stops, full map includes continuation/denv/native activation, context preparation and same-owner reload; no Tcl event pumping or duplicate call to avoid wait cycle.";
 }
 part marker : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="EC-RUN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeEntryCloseCleanup.lean";
 attribute :>> subjectScope="EC-RUN:both-run-callers-and-all-exits";
 attribute :>> premise="Transfer registered startup/worker thunk origin before worker publication/read/synchronization, then root before marker; cover ___call rethrow and known marker failure with post-END_TRY canonical cleanup; source data_scmobj alone is not root coverage.";
 }
 part conversion : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="EC-CLEANUP";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeEntryCloseCleanup.lean";
 attribute :>> subjectScope="EC-CLEANUP:marker-clear-count-root-terminal";
 attribute :>> premise="One custodian records marker initialized/cleared/count drop and root/status transfer; preserve setjmp-defined state, original error, frame/catcher and unknown-progress custody.";
 }
 part dispatch : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="EC-DRAIN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeEntryCloseCleanup.lean";
 attribute :>> subjectScope="EC-DRAIN:Tcl-captured-entry-creation-quiescence";
 attribute :>> premise="Actual Tcl version/installed match, trace reentry, queued/raw dispatch and reentrant CreateCommand installation/discard paths; no drain inferred from zero active entries.";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="EC-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/NativeEntryCloseCleanup.lean";
 attribute :>> subjectScope="EC-ORDER:C-pin-close-park-finalizer";
 attribute :>> premise="Concrete lock/lifetime/read-from, release/acquire park/reload, effect-qualified marker stores and scanner/root registry order; no native C refinement receipt.";
 }
 part terminal : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="EC-CUT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeEntryCloseCleanup.lean";
 attribute :>> subjectScope="EC-CUT:NativeActivationScope-first-slice";
 attribute :>> premise="First future source slice spans ___run plus activation-root/scanner/marker contracts; not kill-only repair or unconsumed API. Scheme SFUN generator and Tcl adapter have explicit later gates.";
 }
 ref part priorParent=GambitNativeIngressRootHandoff::parent;
 ref part priorExit=GambitNativeIngressRootHandoff::terminal;
 ref part priorOrder=GambitNativeIngressRootHandoff::order;
 ref part priorGcRoot=GambitRestAllocatorRootPublication::roots;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=token; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=token; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=parent; ref part :>> prerequisite=history; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=parent; ref part :>> prerequisite=induction; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=conversion; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=conversion; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=dispatch; ref part :>> prerequisite=history; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=dispatch; ref part :>> prerequisite=induction; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=terminal; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=terminal; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=token; ref part :>> prerequisite=conversion; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=token; ref part :>> prerequisite=dispatch; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=token; ref part :>> prerequisite=order; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=parent; ref part :>> prerequisite=conversion; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=parent; ref part :>> prerequisite=dispatch; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=parent; ref part :>> prerequisite=order; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=conversion; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=dispatch; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=order; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=terminal; ref part :>> prerequisite=conversion; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=terminal; ref part :>> prerequisite=dispatch; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=terminal; ref part :>> prerequisite=order; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=parent; ref part :>> prerequisite=priorParent; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=conversion; ref part :>> prerequisite=priorExit; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=priorGcRoot; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=terminal; ref part :>> prerequisite=marker; }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow { attribute :>> callerId="TCL-ENTRY"; attribute :>> sourceAnchors="vendor/gambit/examples/tcltk/tcltk.scm:135-177;Tcl tclBasic.c:2533-2565,4465-4519"; attribute :>> actualChain="TclInvokeStringCommand -> proc(clientData) -> scheme_call_cmd -> data_rc -> tcltk_call -> Scheme apply"; attribute :>> hazard="Acquire owner-scoped token/entry pin before data_rc, marker or conversion; no callback/GC/layout effect before accepted raw access."; attribute :>> replacement="Token storage lifetime must already cover first hook. Same-owner Tcl dispatch is selected; arbitrary cross-thread Tcl use and saved raw callbacks are excluded."; }
 part caller1 : CallerRow { attribute :>> callerId="TCL-DELETE"; attribute :>> sourceAnchors="vendor/gambit/examples/tcltk/tcltk.scm:180-195;Tcl tclBasic.c:3154-3325"; attribute :>> actualChain="delete traces and imported command deletion -> deleteProc -> hash/Command cleanup"; attribute :>> hazard="Close at replacement scheme_delete_cmd first non-reentrant action; return without waiting for pins held by the deleting callback itself. Release payload after pins/results retire."; attribute :>> replacement="Tcl Command reference counts do not defer extension deleteProc or preserve ClientData. Closing before Tcl traces would change allowed reentry; retain pre-deleteProc trace behavior."; }
 part caller2 : CallerRow { attribute :>> callerId="TCL-CREATE"; attribute :>> sourceAnchors="vendor/gambit/examples/tcltk/tcltk.scm:290-340;Tcl tclBasic.c:2094-2234"; attribute :>> actualChain="alloc_rc + still vector -> Tcl_CreateCommand; name conflict invokes old delete; recreated command may be discarded"; attribute :>> hazard="Construction transaction must distinguish never installed, installed, displaced and unknown token ownership. Retain tombstones until actual owner/dispatch quiescence."; attribute :>> replacement="CreateCommand return NULL, reentrant replacement and private/raw dispatch remain open routes; no universal drain receipt derived from pins==0."; }
 part caller3 : CallerRow { attribute :>> callerId="PARENT-PARK"; attribute :>> sourceAnchors="vendor/gambit/include/gambit.h.in:10325-10338;lib/setup.c:1117-1200;examples/tcltk/tcltk.scm:103-124,221-228"; attribute :>> actualChain="CFUN state materialization -> Tcl_Eval -> callback -> child registration attempt during GC close"; attribute :>> hazard="Freeze complete mapped parent locations, stop raw access and preserve native argv/catcher/activation; service only admitted VM wait work, then context seal, reload, same-call retry."; attribute :>> replacement="W_ALL and service_sync_op are source mechanisms, not complete freeze/map/binding receipts. Do not pump Tcl events under the gate or keep a raw borrow while waiting for reopen."; }
 part caller4 : CallerRow { attribute :>> callerId="RUN-STARTUP"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:6395-6440"; attribute :>> actualChain="thread binding -> program descriptor module thunk -> ___run -> cleanup on nonzero error"; attribute :>> hazard="First slice roots the already selected thunk before allocating marker and uses canonical NativeActivation cleanup after END_TRY for every outcome."; attribute :>> replacement="Input source root authority from program descriptor must be proved, not inferred from the C local thunk parameter."; }
 part caller5 : CallerRow { attribute :>> callerId="RUN-PROCESSOR"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:763-835,977-1003"; attribute :>> actualChain="thread data_scmobj -> resize synchronization -> ___run_and_throw_error_on_processor_0 -> ___run -> OP_PROCESSOR_0_THROW_ERROR -> sync service loop"; attribute :>> hazard="Keep worker source root from thread publication through the pre-___run synchronization loop, root reload, marker allocation and guard cleanup; deliver the original error only after activation retirement is settled."; attribute :>> replacement="start_processor_execution loads thunk before execute_sync_op_loop; a guard only inside ___run does not cover that interval. Thread data_scmobj alone is not a root-scanner proof. Zero/nonzero processors and source handoff remain separate admission obligations."; }
 part caller6 : CallerRow { attribute :>> callerId="RUN-ESCAPE"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:3350-3423;lib/c_intf.c:6511-6564;include/gambit.h.in:9979-9988"; attribute :>> actualChain="___call catches then rethrows to ___run outer catcher; inline kill after ___call is skipped"; attribute :>> hazard="Root/marker ownership state survives setjmp; after catcher restoration one cleanup claimant invalidates marker, drops owned count once, settles root/result backing, then returns original status."; attribute :>> replacement="Unknown marker decrement cannot be replayed or assumed done. Do not broadly restore arbitrary GVM state or replace language exception/continuation behavior."; }
 part def PathRow { attribute pathId : String; attribute sourceAnchors : String; attribute actualPath : String; attribute contract : String; attribute failure : String; attribute custodian : String; }
 part path0 : PathRow { attribute :>> pathId="PIN-DELETE"; attribute :>> sourceAnchors="Tcl owner profile; tcltk.scm:135-195"; attribute :>> actualPath="Pin/close before payload dereference"; attribute :>> contract="Pin and close share one control domain, token address is stable independently of payload. Pin winner may finish; close winner returns defined adapter rejection without reading payload."; attribute :>> failure="Delete hook never waits for its own active pin."; attribute :>> custodian="Last native return/result acceptor owns pin retirement; deferred payload release runs outside control lock."; }
 part path1 : PathRow { attribute :>> pathId="TOKEN-PAYLOAD"; attribute :>> sourceAnchors="Tcl tclBasic.c:3284,3313-3325; wrapper path2533-2565"; attribute :>> actualPath="Extension payload and Tcl Command storage retire at different points"; attribute :>> contract="Payload can retire at closed+zero accepted readers; closed token/tombstone survives already captured or unknown future entry."; attribute :>> failure="Zero active pins is not owner dispatch drain or interpreter physical destruction."; attribute :>> custodian="Registry/owner anchor retains token until the selected native producer inventory and quiescence receipt close."; }
 part path2 : PathRow { attribute :>> pathId="PARK-RELOAD"; attribute :>> sourceAnchors="gambit.h.in:10325-10338;setup.c:1117-1200"; attribute :>> actualPath="Stop raw writes/reads -> full view freeze -> collector update -> context ready -> reload"; attribute :>> contract="Freeze exact location map and continuation/denv, native activation and same invocation; no raw copies live across the moving epoch."; attribute :>> failure="Unknown borrower stop refuses freeze and source-ack retirement. A GC-done signal without context-ready/binding/reload is insufficient."; attribute :>> custodian="Parent retains source until child canonical acceptance; lost ACK queries same activation and keeps overlap."; }
 part path3 : PathRow { attribute :>> pathId="RUN-FINALIZER"; attribute :>> sourceAnchors="setup.c:3390-3423;gambit.h.in:9979-9988"; attribute :>> actualPath="One exit funnel after outer END_TRY"; attribute :>> contract="VM-owned activation state records root acceptance, marker creation, cleanup claim and error/return intent. No sole progress flag in a modified nonvolatile setjmp local."; attribute :>> failure="Known marker failure still retires source root. Unknown close/decrement retains root and must be settled from actual progress evidence."; attribute :>> custodian="Exactly one cleanup custodian; marker invalidation precedes owned count decrement and root release."; }
 part path4 : PathRow { attribute :>> pathId="FIRST-CUT"; attribute :>> sourceAnchors="setup.c ___run; c_intf.c marker pair; mem.c root scan; gambit.h.in internal declarations"; attribute :>> actualPath="NativeActivationScope for both actual ___run callers"; attribute :>> contract="Introduce the typed per-VM/context activation/root contract and all-context scan adapter; integrate every ___run exit, preserving external signature and error propagation."; attribute :>> failure="A post-call kill-only patch or unused new API is not this refactor. Source/C-order/native qualification gates remain required."; attribute :>> custodian="Next consumer is Scheme-generated SFUN; Tcl adapter follows with owner pin/delete/creation semantics. No runtime path retires in this study."; }
 part def OrderRow { attribute edgeId : String; attribute orderContract : String; attribute rejectedShortcut : String; }
 part orderRow0 : OrderRow { attribute :>> edgeId="OWNER-PIN"; attribute :>> orderContract="Run Tcl interpreter APIs only on their owner thread; use short bridge lock for pin/close versus GC metadata."; attribute :>> rejectedShortcut="GC worker never calls Tcl delete API. No bridge lock held across Tcl/Scheme callbacks or native waits."; }
 part orderRow1 : OrderRow { attribute :>> edgeId="DELETE-CUT"; attribute :>> orderContract="Preserve Tcl delete traces before deleteProc; close bridge admission at hook entry, publish close before returning."; attribute :>> rejectedShortcut="Changing the public deletion cut to before traces requires separate semantic change, not claimed compatibility."; }
 part orderRow2 : OrderRow { attribute :>> edgeId="TOMBSTONE"; attribute :>> orderContract="Pin storage and logical open/generation validation precede data_rc read; retirement acquires actual reader/owner-drain evidence."; attribute :>> rejectedShortcut="Command refCount, Tcl_Preserve(interp) and zero payload pins are three different lifetimes. None alone proves token storage safe."; }
 part orderRow3 : OrderRow { attribute :>> edgeId="PARK-HB"; attribute :>> orderContract="Stop raw accesses and complete mapped spills precede release PARKED; collector acquire precedes scan/update."; attribute :>> rejectedShortcut="A root registration or borrower counter decrement without complete view/stop proof does not admit independent scan."; }
 part orderRow4 : OrderRow { attribute :>> edgeId="RESUME-HB"; attribute :>> orderContract="Collector relocation and context/binding preparation precede release resume seal; owner acquire reloads mapped roots before same-call use."; attribute :>> rejectedShortcut="No re-evaluation of Scheme inputs, duplicate native invocation or reuse of old raw fp/hp/SCMOBJ copies."; }
 part orderRow5 : OrderRow { attribute :>> edgeId="RUN-CLEANUP"; attribute :>> orderContract="Outer catcher restored before canonical cleanup; claim, marker clear, count drop, root retirement and status delivery have explicit progress."; attribute :>> rejectedShortcut="The existing no-allocation kill body is source material for effect qualification, not proof of concurrent atomicity or idempotent decrement."; }
 part orderRow6 : OrderRow { attribute :>> edgeId="FAILURE"; attribute :>> orderContract="Known cleanup failure retains duty; unknown write/count outcome requires stop/result settlement before reclamation or replay."; attribute :>> rejectedShortcut="C longjmp state and object lifetime must refine actual C ordering; no timeout clears uncertainty."; }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow { attribute :>> capability="Tcl payload lifetime"; attribute :>> removedWork="Avoid retaining payload merely because Command structure remains referenced"; attribute :>> bound="Closed+zero accepted pins can release payload separately from token"; attribute :>> addedCost="Entry pin/close transitions and deferred last-pin release"; attribute :>> condition="Owner profile, result custody and no raw reader must close first. No measured speedup."; }
 part cost1 : CostRow { attribute :>> capability="Tcl token lifetime"; attribute :>> removedWork="Avoid UAF in late or captured entry"; attribute :>> bound="Tombstone metadata remains until dispatch/owner quiescence"; attribute :>> addedCost="Potential long-lived token metadata and registry lookup"; attribute :>> condition="Unbounded token/producer history means no bounded total memory theorem."; }
 part cost2 : CostRow { attribute :>> capability="Self-delete"; attribute :>> removedWork="Remove self-wait cycle in deleting callback"; attribute :>> bound="Delete hook waits for 0 callback pins: no waiting is permitted there"; attribute :>> addedCost="Deferred release and outer callback retirement bookkeeping"; attribute :>> condition="No callback, cleanup or Tcl event pump under bridge lock."; }
 part cost3 : CostRow { attribute :>> capability="Parent location reuse"; attribute :>> removedWork="Reuse mapped source locations instead of copying every root"; attribute :>> bound="0 duplicate value evaluations/native calls on qualified retry"; attribute :>> addedCost="Freeze/reload, map validation and activation pin"; attribute :>> condition="Cannot reuse an unmapped raw C local or unknown borrower."; }
 part cost4 : CostRow { attribute :>> capability="Run root payload"; attribute :>> removedWork="Explicit thunk/marker custody for selected zero-arg run"; attribute :>> bound="Illustrative two SCMOBJ slots: 16B at64; nested2:32B"; attribute :>> addedCost="Registry/map/control/native frame and marker allocation excluded"; attribute :>> condition="Existing program root or owned-still marker may alias/elide extra slots; not mandatory net allocation."; }
 part cost5 : CostRow { attribute :>> capability="Run error path"; attribute :>> removedWork="Retire normal-only inline marker ownership assumption"; attribute :>> bound="One cleanup claimant, marker clear and owned count drop each at most once"; attribute :>> addedCost="VM-canonical progress record and exit-funnel control work"; attribute :>> condition="Original error codes, catcher and continuation behavior must remain; native acceptance still required."; }
 part cost6 : CostRow { attribute :>> capability="Still ownership reuse"; attribute :>> removedWork="Reuse positive-refcount marker/vector/converter retention"; attribute :>> bound="No forced copying of every stable still payload"; attribute :>> addedCost="Typed ownership transfer and scan/write qualification"; attribute :>> condition="Stable address does not imply all root fields or arbitrary owner writes are safe."; }
 part cost7 : CostRow { attribute :>> capability="Peak accounting"; attribute :>> removedWork="Count separate token/root/native backing once"; attribute :>> bound="Peak=max_t(unique backing + separate roots/maps + token/native escrow)"; attribute :>> addedCost="Overlap on lost ACK, tombstones and unknown cleanup can increase peak"; attribute :>> condition="No net peak reduction or bounded GC latency proved."; }
 part cost8 : CostRow { attribute :>> capability="Retirement scope"; attribute :>> removedWork="Replace real ___run ownership logic before broad FFI migration"; attribute :>> bound="Two actual caller families; no external ___run signature change planned"; attribute :>> addedCost="Internal root scanner, marker ownership and producer migration obligations"; attribute :>> condition="SFUN/Tcl/raw ___call remain separate next routes; zero retired runtime paths now."; }
 part cost9 : CostRow { attribute :>> capability="Modern C leverage"; attribute :>> removedWork="Share one activation/root/exit contract across runtime and Scheme generators"; attribute :>> bound="One language-level runtime contract reused by multiple consumers"; attribute :>> addedCost="Typed metadata and generated effect/location plans"; attribute :>> condition="Not another advisory wrapper over unchanged unsafe producer assumptions."; }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref part producer : DiagramNode; ref part consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="token"; attribute :>> labelText="Stable Tcl token / owner anchor"; }
 part node1 : DiagramNode { attribute :>> nodeId="pin"; attribute :>> labelText="Pin before data_rc or close"; }
 part node2 : DiagramNode { attribute :>> nodeId="child"; attribute :>> labelText="Canonical NativeActivation roots"; }
 part node3 : DiagramNode { attribute :>> nodeId="park"; attribute :>> labelText="Stop raw borrow / freeze full view"; }
 part node4 : DiagramNode { attribute :>> nodeId="gc"; attribute :>> labelText="GC update / context-ready / reload"; }
 part node5 : DiagramNode { attribute :>> nodeId="run"; attribute :>> labelText="Run marker and Scheme call"; }
 part node6 : DiagramNode { attribute :>> nodeId="catch"; attribute :>> labelText="Outer catcher / one cleanup claim"; }
 part node7 : DiagramNode { attribute :>> nodeId="retire"; attribute :>> labelText="Clear marker / count / root / status"; }
 part node8 : DiagramNode { attribute :>> nodeId="delete"; attribute :>> labelText="Delete hook closes and returns"; }
 part node9 : DiagramNode { attribute :>> nodeId="drain"; attribute :>> labelText="Last pin / payload release / token drain"; }
 part edge0 : DiagramEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="owner entry hook"; }
 part edge1 : DiagramEdge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="pin wins"; }
 part edge2 : DiagramEdge { ref part :>> producer=node1; ref part :>> consumer=node8; attribute :>> labelText="delete wins"; }
 part edge3 : DiagramEdge { ref part :>> producer=node8; ref part :>> consumer=node9; attribute :>> labelText="no self wait"; }
 part edge4 : DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="GC closes"; }
 part edge5 : DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="mapped and stopped"; }
 part edge6 : DiagramEdge { ref part :>> producer=node4; ref part :>> consumer=node2; attribute :>> labelText="same call resumes"; }
 part edge7 : DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node5; attribute :>> labelText="root before allocation"; }
 part edge8 : DiagramEdge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="normal or rethrow"; }
 part edge9 : DiagramEdge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="canonical progress"; }
 part edge10 : DiagramEdge { ref part :>> producer=node7; ref part :>> consumer=node9; attribute :>> labelText="result and last pin"; }
 part edge11 : DiagramEdge { ref part :>> producer=node8; ref part :>> consumer=node0; attribute :>> labelText="keep tombstone"; }
 part edge12 : DiagramEdge { ref part :>> producer=node7; ref part :>> consumer=node2; attribute :>> labelText="unknown retains custody"; }
 part def SourceRoute { ref part need : GambitAssuranceRouting::ModelNeed; attribute sourceAnchors : String; attribute projection : String; attribute failureCustodian : String; attribute status : String; }
 part route0 : SourceRoute { ref part :>> need=token; attribute :>> sourceAnchors="tcltk.scm:135-195;Tcl tclBasic.c:2533-2565,3154-3325"; attribute :>> projection="Owner-scoped token pin/close before payload; preserve trace-before-hook cut"; attribute :>> failureCustodian="Owner/registry retain token; last accepted callback retires payload"; attribute :>> status="source-and-C-order-refinement-open"; }
 part route1 : SourceRoute { ref part :>> need=parent; attribute :>> sourceAnchors="gambit.h.in:10325-10338;setup.c:1117-1200"; attribute :>> projection="Full parent stop/freeze/context-ready/reload; W_ALL alone insufficient"; attribute :>> failureCustodian="Parent until child acceptance; unknown borrower keeps source"; attribute :>> status="source-and-C-order-refinement-open"; }
 part route2 : SourceRoute { ref part :>> need=marker; attribute :>> sourceAnchors="setup.c:763-835,3350-3423,6395-6440;c_intf.c:6511-6564"; attribute :>> projection="Both run source thunks including worker publication/pre-run synchronization and every outer-catcher exit"; attribute :>> failureCustodian="Canonical NativeActivation guard"; attribute :>> status="source-and-C-order-refinement-open"; }
 part route3 : SourceRoute { ref part :>> need=conversion; attribute :>> sourceAnchors="c_intf.c:6553-6564;gambit.h.in:9979-9988"; attribute :>> projection="Marker clear/count/root/status progress with defined setjmp state"; attribute :>> failureCustodian="Unique cleanup claimant; unknown count retains root"; attribute :>> status="source-and-C-order-refinement-open"; }
 part route4 : SourceRoute { ref part :>> need=dispatch; attribute :>> sourceAnchors="Tcl tclBasic.c:2094-2234,4465-4519;tcltk.scm:290-340"; attribute :>> projection="Real creation/captured dispatch and native quiescence"; attribute :>> failureCustodian="Owner acceptor/registry retains tombstone"; attribute :>> status="source-and-C-order-refinement-open"; }
 part route5 : SourceRoute { ref part :>> need=order; attribute :>> sourceAnchors="setup.c/c_intf.c/mem.c root/activation paths;gambit.h.in lock/catcher adapters"; attribute :>> projection="C happens-before and storage-lifetime refinement"; attribute :>> failureCustodian="VM control domain and participating owner"; attribute :>> status="source-and-C-order-refinement-open"; }
 part route6 : SourceRoute { ref part :>> need=terminal; attribute :>> sourceAnchors="setup.c:3390-3423;mem.c root scanning;gambit.h.in internal types"; attribute :>> projection="Future NativeActivationScope vertical slice, not unconsumed API"; attribute :>> failureCustodian="Modern C runtime/producer owner"; attribute :>> status="source-and-C-order-refinement-open"; }
 part node10 : DiagramNode { attribute :>> nodeId="startup"; attribute :>> labelText="Startup / thread source transfer"; }
 part edge13 : DiagramEdge { ref part :>> producer=node10; ref part :>> consumer=node2; attribute :>> labelText="before worker synchronization"; }
 part def RootPayload { attribute slots : Integer=2; attribute depth : Integer; attribute wordBytes : Integer=8; attribute payloadBytes : Integer=slots*depth*wordBytes; }
 part flat : RootPayload { attribute :>> depth=1; }
 part nested : RootPayload { attribute :>> depth=2; }
}
