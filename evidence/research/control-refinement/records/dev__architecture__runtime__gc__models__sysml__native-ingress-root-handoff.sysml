/* Modern C allocator/root publication research. SysML owns rows and obligations. */
package GambitNativeIngressRootHandoff {
 private import ScalarValues::*;
 part def IngressState { attribute valid : Boolean; attribute sourceCovered : Boolean; attribute childCovered : Boolean; attribute sourceReleased : Boolean; attribute rawReadable : Boolean; attribute sameEpoch : Boolean; attribute pinned : Boolean; }
 requirement def RootTransferLaw { subject c : IngressState; require constraint { not c.valid or ((c.sourceCovered or c.childCovered) and (not c.sourceReleased or c.childCovered) and (not c.rawReadable or (c.sameEpoch and c.pinned))) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="NI-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/native_ingress_root_handoff.qnt";
 attribute :>> subjectScope="native_ingress_root_handoff:19-histories;safe;handle-parent-raw;one-GC;one-nested;seed17;3x100x100";
 attribute :>> premise="Linearizable custody transitions with complete scan-ready root maps and live dispatch-origin premises; unknown remains retained; externally confirmed stop/drain actions are assumptions, not observed platform events.";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="NI-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/NativeIngressRootHandoff.lean";
 attribute :>> subjectScope="GambitSMP.NativeIngressRootHandoff:15-declarations;conditional-custody";
 attribute :>> premise="Conditional publish/ack/collect Step preservation, overlap-before-ack, raw epoch exclusion, identity and reclamation premises; no full QNT/source/C simulation.";
 }
 part origin : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="NI-ORIGIN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeIngressRootHandoff.lean";
 attribute :>> subjectScope="NI-ORIGIN:live-namespace-before-payload";
 attribute :>> premise="RootHandle namespace/generation lookup from live VM anchor, pin-retire ordering and opaque-only waiting; bare movable SCMOBJ must not be upgraded retroactively; classify immortal/owned-still separately.";
 }
 part parent : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="NI-PARENT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeIngressRootHandoff.lean";
 attribute :>> subjectScope="NI-PARENT:parent-source-borrow-close";
 attribute :>> premise="Mapped parent source lease exists before foreign export; child acceptance covers roots before source release; park complete parent on close without keeping raw borrower active or violating synchronous C ABI.";
 }
 part marker : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="NI-MARKER";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeIngressRootHandoff.lean";
 attribute :>> subjectScope="NI-MARKER:all-marker-producers";
 attribute :>> premise="Generated SFUN plus ___run marker entry; captured target origin before marker allocation and stable activation identity across nested selector effects; preserve marker and code lifetime.";
 }
 part conversion : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="NI-CONVERT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeIngressRootHandoff.lean";
 attribute :>> subjectScope="NI-CONVERT:owned-still-and-prefix";
 attribute :>> premise="Classify actual converter outputs and cleanup; reuse still/permanent retention where valid, cover initialization and inter-conversion GC, and all-context scanner/FFI writes without assuming every result moves.";
 }
 part dispatch : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="NI-DISPATCH";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeIngressRootHandoff.lean";
 attribute :>> subjectScope="NI-DISPATCH:entry-and-native-drain";
 attribute :>> premise="Actual Tcl ClientData and function-pointer producers must establish pre-entry lifetime, stable activation selector and delete/queued-call/in-flight drain; inactive os_dyn thunk code is not Darwin arm64 capability.";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="NI-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/NativeIngressRootHandoff.lean";
 attribute :>> subjectScope="NI-ORDER:C-HB-origin-and-custody";
 attribute :>> premise="Actual C pin/retire, source-to-child acceptance, close/park, scan/update/reload and reclaim edges; ordinary C object lifetime, setjmp automatic-local rules and lock adapters still require refinement.";
 }
 part terminal : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
 attribute :>> obligationId="NI-EXIT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeIngressRootHandoff.lean";
 attribute :>> subjectScope="NI-EXIT:catcher-and-terminal-custody";
 attribute :>> premise="Normal/conversion error and ___call/___run rethrow paths need canonical cleanup progress, nested duty, accepted result/error and data-write closure before freeing roots/marker/code.";
 }
 ref part priorNative=GambitRestAllocatorRootPublication::native;
 ref part priorRoots=GambitRestAllocatorRootPublication::roots;
 ref part priorOrder=GambitRestAllocatorRootPublication::order;
 ref part priorFailure=GambitRestAllocatorRootPublication::failure;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origin; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origin; ref part :>> prerequisite=induction; }
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
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=parent; ref part :>> prerequisite=origin; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=parent; ref part :>> prerequisite=order; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=parent; ref part :>> prerequisite=dispatch; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=origin; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=order; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=dispatch; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=conversion; ref part :>> prerequisite=origin; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=conversion; ref part :>> prerequisite=order; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=conversion; ref part :>> prerequisite=dispatch; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=terminal; ref part :>> prerequisite=origin; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=terminal; ref part :>> prerequisite=order; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=terminal; ref part :>> prerequisite=dispatch; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origin; ref part :>> prerequisite=priorRoots; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=marker; ref part :>> prerequisite=priorNative; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=conversion; ref part :>> prerequisite=priorRoots; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=terminal; ref part :>> prerequisite=priorFailure; }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow { attribute :>> callerId="TCL-CONTEXT"; attribute :>> sourceAnchors="vendor/gambit/examples/tcltk/tcltk.scm:135-195,221-228,290-340"; attribute :>> actualChain="command create alloc_rc + make_vector + set_data_rc -> scheme_call_cmd data_rc -> tcltk_call SFUN -> apply; delete releases vector and RC"; attribute :>> hazard="ClientData must carry a stable acceptor/handle origin before data_rc. Pin callback dispatch before raw payload read; nested deletion must close new entry and defer reclaim until in-flight and queued-entry evidence drains."; attribute :>> replacement="Vector is explicitly STILL with initial strong retention; do not classify it as an unrooted movable argument. Moving fields, delete lifetime and nonzero RC scan remain separate."; }
 part caller1 : CallerRow { attribute :>> callerId="STATIC-CALLBACK"; attribute :>> sourceAnchors="vendor/gambit/tests/mem.scm:245-297;lib/c_intf.c:2887-2940;gsc/_ptree2.scm:3186-3226"; attribute :>> actualChain="foo function argument hop -> SCMOBJ_to_FUNCTION c-define static host -> foo calls f -> hop converter"; attribute :>> hazard="Static c-define code identity does not need c_closure_self. Root native SCMOBJ arguments according to their origins; nested C string conversion has its own retained-object ownership."; attribute :>> replacement="This retained source is not a new native execution witness; static entry must still validate VM owner/activation and closure/GC admission."; }
 part caller2 : CallerRow { attribute :>> callerId="DYNAMIC-CLOSURE"; attribute :>> sourceAnchors="vendor/gambit/lib/c_intf.c:2887-2940,6511-6545;lib/os_dyn.c:633-675,744-791,1048-1059"; attribute :>> actualChain="non-c-define procedure -> make_c_closure alloc_rc/data -> thunk writes c_closure_self -> converter -> marker reads closure payload"; attribute :>> hazard="Capture stable export/activation identity before allocating marker, preserve it across nested entry, and drain dispatch before reclaiming executable backing. TLS alone does not supply nested identity or lifetime."; attribute :>> replacement="C_CLOSURE_CODE_SIZE in this source covers selected x86-32/ppc32/sparc branches, not a demonstrated Darwin arm64 dynamic thunk. Unsupported targets reject; explicit userdata adapters can avoid this route."; }
 part caller3 : CallerRow { attribute :>> callerId="GENERATOR"; attribute :>> sourceAnchors="vendor/gambit/gsc/_ptree2.scm:2773-2843,2902-3008,3145-3226;include/gambit.h.in:10043-10066"; attribute :>> actualChain="BEGIN_SFUN marker before conversion; SCMOBJ-prioritized conversions; SFUN_ARG then call; generated END conversion releases"; attribute :>> hazard="Emit an ingress descriptor before marker; classify incoming RootHandle/parent borrow/owned-still/immortal/scalar. Publish child view and conversion prefix before dropping source roots."; attribute :>> replacement="A raw SCMOBJ is a representation, not origin evidence. Existing owned-still results may reuse retention rather than adding duplicate root slots."; }
 part caller4 : CallerRow { attribute :>> callerId="RUN-BOOTSTRAP"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:3390-3423;lib/c_intf.c:6511-6564"; attribute :>> actualChain="___run sets R0 -> BEGIN_TRY -> make marker(thunk) -> call -> kill marker -> END_TRY"; attribute :>> hazard="___run is another real marker producer outside SFUN. Require a rooted thunk origin and canonical activation cleanup so nonlocal error cannot silently skip kill/custody close."; attribute :>> replacement="No claim that adding guards only to generated SFUN covers bootstrap, processor run, or raw direct ___call users."; }
 part def AllocatorRow { attribute pathId : String; attribute sourceAnchors : String; attribute actualPath : String; attribute contract : String; attribute failure : String; attribute custodian : String; }
 part allocatorRow0 : AllocatorRow { attribute :>> pathId="HANDLE-PIN"; attribute :>> sourceAnchors="VM RootRegistry is proposed; current rc primitives at lib/mem.c:705-831"; attribute :>> actualPath="registered opaque identity -> namespace/generation lookup -> storage pin -> gate admission -> payload read"; attribute :>> contract="Lookup from a live VM anchor; pin/retire serialize. Handle pin protects storage while registered root cell remains scan/update-owned. It does not prohibit GC."; attribute :>> failure="If closed, wait using identity only and reload after round seal; never preserve a raw movable copy across collection."; attribute :>> custodian="Registry retains handle cell until pin/readers/terminal drain. Generation wrap must reject reuse or prove a stronger bound."; }
 part allocatorRow1 : AllocatorRow { attribute :>> pathId="PARENT-BORROW"; attribute :>> sourceAnchors="include/gambit.h.in:10325-10338;lib/setup.c:3276-3390"; attribute :>> actualPath="parent frame/root view -> source lease -> child view publish -> acknowledgement"; attribute :>> contract="Child publication accepts roots before raw borrow ends; acknowledgement releases parent source duty. Lost ACK queries the same activation/request, never registers twice."; attribute :>> failure="If GC closes before publication, park the complete parent view and stop raw accesses; retaining an active borrow while waiting for OPEN creates a wait cycle."; attribute :>> custodian="Parent retains custody until child acceptance; canonical child retains it after acceptance even if response is lost."; }
 part allocatorRow2 : AllocatorRow { attribute :>> pathId="OWNED-STILL"; attribute :>> sourceAnchors="lib/c_intf.c:4333-4348,5732-5800;lib/mem.c:1485-1500,1675-1739,4210-4248,6800"; attribute :>> actualPath="C conversion creates still refcount1 or permanent object; still setup scans positive refcount; release_scmobj drops still count"; attribute :>> contract="Reuse known still/permanent ownership with typed cleanup. Initialization must finish before another allocation; stable address does not mean fields can be mutated during scan."; attribute :>> failure="Conversion failure retains or releases the exact initialized prefix once; transfer between existing refcount and managed view needs an explicit receipt."; attribute :>> custodian="Original converter owns until child/foreign result acceptor acknowledges; no blanket replacement of every still root by another handle."; }
 part allocatorRow3 : AllocatorRow { attribute :>> pathId="NESTED-VIEW"; attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:135-195,221-228;lib/os_dyn.c:744-791;include/gambit.h.in:9979-9988"; attribute :>> actualPath="callback -> child SFUN -> Scheme -> native/event reentry -> another callback"; attribute :>> contract="Stable parent/child activation keys and activation-local selector; freeze/reload all participating views, marker and conversion prefixes. Do not key solely by OS thread or processor number."; attribute :>> failure="Child return restores exact parent binding/control state; parent cannot detach while nested responsibility remains, including unknown exit."; attribute :>> custodian="Each view owns its marker, initialized conversions and result/error until the designated acceptor takes custody."; }
 part allocatorRow4 : AllocatorRow { attribute :>> pathId="EXIT-RECLAIM"; attribute :>> sourceAnchors="include/gambit.h.in:9959-9988,10043-10059,10288-10324;lib/setup.c:841-866,3350-3423"; attribute :>> actualPath="normal END cleanup versus ___call rethrow/nonlocal longjmp and propagate_error"; attribute :>> contract="Use VM-canonical cleanup progress and terminal receipt; interception must precede escaping to an older catcher. Do not rely only on lexical epilogue or changed nonvolatile automatic locals after longjmp."; attribute :>> failure="Unknown exit keeps roots and native backing; confirmed stop closes writes but does not by itself settle nested tasks/result delivery or library queues."; attribute :>> custodian="Reclaim after accepted result/error, no nested roots/readers/pins, no unknown write, and actual dispatch drain."; }
 part def OrderRow { attribute edgeId : String; attribute orderContract : String; attribute rejectedShortcut : String; }
 part orderRow0 : OrderRow { attribute :>> edgeId="PIN-RETIRE"; attribute :>> orderContract="VM lookup and handle pin/retire share a coherent gate; only read opaque token until accepted."; attribute :>> rejectedShortcut="A pointer to already-freed handle/code/clientData cannot be made safe by addref after entry. External unregister/queued-call drain evidence is required."; }
 part orderRow1 : OrderRow { attribute :>> edgeId="BORROW-PUBLISH"; attribute :>> orderContract="Parent source lease covers every read before child root registration. Child acceptance and raw-borrow relinquish are one custody transition; acknowledgement can be later."; attribute :>> rejectedShortcut="Do not decrement parent coverage then link child roots. Lost ACK retains overlapping custody and uses canonical query."; }
 part orderRow2 : OrderRow { attribute :>> edgeId="CLOSE-PARK"; attribute :>> orderContract="Close stops new raw-entry claims before waiting. Already pinned handle storage may persist while its payload cell is scanned; parent raw borrow must park/transfer or abort from a full view."; attribute :>> rejectedShortcut="Do not wait for gate reopening while the same active borrow prevents collector entry. Opaque pins and raw execution authority are distinct."; }
 part orderRow3 : OrderRow { attribute :>> edgeId="MARKER-CONVERT"; attribute :>> orderContract="Child root acceptance precedes marker allocation; each conversion publishes a safe initialized prefix before the next collecting allocation."; attribute :>> rejectedShortcut="Existing still-owned results are already retained in their qualified profile; stable-address ownership does not prove arbitrary field writes or nonzero RC coverage."; }
 part orderRow4 : OrderRow { attribute :>> edgeId="NESTED-IDENTITY"; attribute :>> orderContract="Activation-local selector is captured before allocating/reentering and restored from the parent activation, not reread from mutable global state."; attribute :>> rejectedShortcut="TLS removes cross-thread sharing only; nested overwrite/cleanup still needs stack discipline and executable-entry lifetime. No arm64 support is inferred from inactive thunk code."; }
 part orderRow5 : OrderRow { attribute :>> edgeId="EXIT-RESULT"; attribute :>> orderContract="Canonical root/marker/resource cleanup receipt precedes terminal propagation; accepted result/error backing remains pinned until receiver acknowledgement."; attribute :>> rejectedShortcut="A kill call textually after ___call is not guaranteed to run when ___call rethrows. C setjmp cleanup state needs defined lifetime and value rules."; }
 part orderRow6 : OrderRow { attribute :>> edgeId="RELOAD-RECLAIM"; attribute :>> orderContract="Collector-exclusive slot updates happen-before acquired resume/reload; reclamation additionally drains all descriptor/code/clientData readers and native dispatch."; attribute :>> rejectedShortcut="Release/acquire visibility is not storage lifetime. Unknown results cannot count as cancelled, reclaimed, or harmless solely by timeout."; }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow { attribute :>> capability="Handle ingress"; attribute :>> removedWork="Avoid stale raw payload copies across closed epochs"; attribute :>> bound="Opaque identity only while waiting; payload load after admission"; attribute :>> addedCost="Registry lookup/pin/retire and root-cell metadata"; attribute :>> condition="Benefit is correct decoupled admission; CPU improvement is not established."; }
 part cost1 : CostRow { attribute :>> capability="Parent root reuse"; attribute :>> removedWork="Avoid copying every live parent value into a new handle"; attribute :>> bound="Reuse mapped locations when compiler certificate covers them"; attribute :>> addedCost="Borrow/accept/ack bookkeeping; possible duplicate root coverage until ACK"; attribute :>> condition="Positive work reduction requires fewer copies than registration/coordination work."; }
 part cost2 : CostRow { attribute :>> capability="Existing still ownership"; attribute :>> removedWork="Reuse retained still/permanent converter results"; attribute :>> bound="Known still refcount1; no forced duplicate per-result handle"; attribute :>> addedCost="Typed ownership classification and once-only cleanup receipt"; attribute :>> condition="A smaller measured profile may need no extra root payload for these results; source/scan closure remains required."; }
 part cost3 : CostRow { attribute :>> capability="Root slot payload"; attribute :>> removedWork="Explicit root words for input and converted prefix"; attribute :>> bound="Illustrative 4 inputs + 2 converted at 8 bytes: 48B; depth2: 96B"; attribute :>> addedCost="Descriptor/map/registry/marker/native backing not included"; attribute :>> condition="These are native-evaluated model payload examples, not measured allocation or mandatory net added memory."; }
 part cost4 : CostRow { attribute :>> capability="Conversion cleanup"; attribute :>> removedWork="Retire implicit nested generated release assumptions for admitted path"; attribute :>> bound="O(initialized-prefix) cleanup, exactly one accepted custodian"; attribute :>> addedCost="Progress tracking, result/error receipt, longjmp-safe state"; attribute :>> condition="No global GC blocker may be hidden in unknown cleanup effects."; }
 part cost5 : CostRow { attribute :>> capability="Nested callbacks"; attribute :>> removedWork="Retain precise continuation/native activation ownership"; attribute :>> bound="O(depth * live root slots) plus native activation backing"; attribute :>> addedCost="Activation stack, marker/result retention and root reload"; attribute :>> condition="Depth/borrow duration bounds are needed for bounded peak; no such general bound is proved."; }
 part cost6 : CostRow { attribute :>> capability="Tcl userdata adapter"; attribute :>> removedWork="Avoid needing a machine-code closure when API supplies context"; attribute :>> bound="Use ClientData as a managed acceptor identity"; attribute :>> addedCost="Adapter changes and delete/in-flight/queued-call drain contract"; attribute :>> condition="Does not establish generic C ABI callback closure support or raw ClientData safety after deletion."; }
 part cost7 : CostRow { attribute :>> capability="Dynamic thunk"; attribute :>> removedWork="Retire global selector dependency only after certified replacement"; attribute :>> bound="0 dynamic-thunk support newly established on Darwin arm64"; attribute :>> addedCost="Target ABI/backend or mature closure library, executable lifetime, nested selector protocol"; attribute :>> condition="Modern C alone cannot synthesize arbitrary context-free callback closures portably."; }
 part cost8 : CostRow { attribute :>> capability="Peak and unknown exit"; attribute :>> removedWork="Avoid premature reclamation and lost roots"; attribute :>> bound="Peak=max_t(unique backing + separate roots/maps + native/dispatch escrow)"; attribute :>> addedCost="Overlapping parent/child roots and unknown native resources may remain retained"; attribute :>> condition="No bounded peak reduction or GC latency claim without stop/drain and origin evidence."; }
 part cost9 : CostRow { attribute :>> capability="Modern C branch"; attribute :>> removedWork="Isolate forthcoming C-layer refactor decisions from language expansion"; attribute :>> bound="vendor branch modern-c at recorded unchanged source commit"; attribute :>> addedCost="Future implementation and native qualification are separate tasks"; attribute :>> condition="This turn creates the branch only; existing vector edit preserved; no production path retired."; }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref part producer : DiagramNode; ref part consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="source"; attribute :>> labelText="Registered handle / complete parent view"; }
 part node1 : DiagramNode { attribute :>> nodeId="pin"; attribute :>> labelText="Opaque ingress pin / source borrow"; }
 part node2 : DiagramNode { attribute :>> nodeId="gate"; attribute :>> labelText="GC close and native admission"; }
 part node3 : DiagramNode { attribute :>> nodeId="child"; attribute :>> labelText="Canonical child RootView acceptance"; }
 part node4 : DiagramNode { attribute :>> nodeId="marker"; attribute :>> labelText="Marker and conversion prefix"; }
 part node5 : DiagramNode { attribute :>> nodeId="nested"; attribute :>> labelText="Nested activation / Scheme execution"; }
 part node6 : DiagramNode { attribute :>> nodeId="park"; attribute :>> labelText="Stop raw access / freeze parent and child"; }
 part node7 : DiagramNode { attribute :>> nodeId="gc"; attribute :>> labelText="GC update / context seal / reload"; }
 part node8 : DiagramNode { attribute :>> nodeId="exit"; attribute :>> labelText="Result or error custody / cleanup"; }
 part node9 : DiagramNode { attribute :>> nodeId="reclaim"; attribute :>> labelText="Dispatch drain + pin/reader retirement"; }
 part edge0 : DiagramEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="source covers entry window"; }
 part edge1 : DiagramEdge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="claim or park"; }
 part edge2 : DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="open validates identity"; }
 part edge3 : DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node6; attribute :>> labelText="close wins"; }
 part edge4 : DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="accept before allocate"; }
 part edge5 : DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node0; attribute :>> labelText="ack releases source duty"; }
 part edge6 : DiagramEdge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="typed arguments and roots"; }
 part edge7 : DiagramEdge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="cooperative nested park"; }
 part edge8 : DiagramEdge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="no raw borrow"; }
 part edge9 : DiagramEdge { ref part :>> producer=node7; ref part :>> consumer=node2; attribute :>> labelText="same activation reload"; }
 part edge10 : DiagramEdge { ref part :>> producer=node5; ref part :>> consumer=node8; attribute :>> labelText="normal or known failure"; }
 part edge11 : DiagramEdge { ref part :>> producer=node8; ref part :>> consumer=node9; attribute :>> labelText="receiver accepts and dispatch drains"; }
 part edge12 : DiagramEdge { ref part :>> producer=node8; ref part :>> consumer=node3; attribute :>> labelText="unknown keeps root custody"; }
 part def RootPayload { attribute inputs : Integer=4; attribute converted : Integer=2; attribute depth : Integer; attribute wordBytes : Integer=8; attribute payloadBytes : Integer=depth*(inputs+converted)*wordBytes; }
 part flat : RootPayload { attribute :>> depth=1; }
 part nested : RootPayload { attribute :>> depth=2; }
}
