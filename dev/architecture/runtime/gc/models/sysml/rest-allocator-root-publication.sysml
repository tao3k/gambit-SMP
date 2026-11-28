/* Modern C allocator/root publication research. SysML owns rows and obligations. */
package GambitRestAllocatorRootPublication {
 private import ScalarValues::*;
 part def ScanCut { attribute valid : Boolean; attribute gateClosed : Boolean; attribute rootsFrozen : Boolean; attribute activeWriters : Integer; attribute layoutOps : Integer; attribute unknown : Boolean; }
 requirement def ScanAdmission { subject c : ScanCut; require constraint { not c.valid or (c.gateClosed and c.rootsFrozen and c.activeWriters==0 and c.layoutOps==0 and not c.unknown) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ARP-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/rest_allocator_root_publication.qnt";
 attribute :>> subjectScope="rest_allocator_root_publication:19-histories;safe;routes0-2;linearizable-gate;one-GC;seed17;3x100x100";
 attribute :>> premise="Abstract admission/layout-operation, unknown custody, root-freeze/scan and resume histories. SC interleavings only; root mapping, C data races, allocator fit and liveness are not established.";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ARP-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/RestAllocatorRootPublication.lean";
 attribute :>> subjectScope="GambitSMP.RestAllocatorRootPublication:16-declarations;conditional-gate-and-HB";
 attribute :>> premise="Conditional gate preservation and explicit happens-before-chain composition. HB edges are premises, not derived from compiled C; Step covers close/publish/finish only.";
 }
 part allocator : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ARP-ALLOC";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestAllocatorRootPublication.lean";
 attribute :>> subjectScope="ARP-ALLOC:actual-mutator-layout-and-allocator";
 attribute :>> premise="Refine current-window, local reuse and global assignment to physical disjoint capacity without confusing thresholds/fudge/collector chunks; cover all layout writers and unknown native results.";
 }
 part apply : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ARP-APPLY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestAllocatorRootPublication.lean";
 attribute :>> subjectScope="ARP-APPLY:embedded-app-rooted-staging";
 attribute :>> premise="Refactor embedded app producer before POP_ARGS2; prove stable-input or single-read mutable staging, exact root coverage/read-error order and argument limit.";
 }
 part direct : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ARP-DIRECT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestAllocatorRootPublication.lean";
 attribute :>> subjectScope="ARP-DIRECT:front-evaluation-copy-and-jump-region";
 attribute :>> premise="Prepare logical call across _front evaluation/copy interleaving; certify location moves, all safepoints, inlining/local ABI and late-binding timing, not only targ-gen-jump.";
 }
 part native : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ARP-NATIVE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestAllocatorRootPublication.lean";
 attribute :>> subjectScope="ARP-NATIVE:pre-marker-and-pre-SFUN_ARG";
 attribute :>> premise="Prove RootHandle or inherited parent-borrow origin before any wait/root copy; raw movable SCMOBJ ingress without prior root authority is rejected. Protect proc and incoming SCMOBJ before marker allocation, root each converted prefix; reserve only after collecting conversions and before outgoing stores; prove catcher/cleanup ownership.";
 }
 part roots : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ARP-ROOT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestAllocatorRootPublication.lean";
 attribute :>> subjectScope="ARP-ROOT:all-context-updatable-root-and-freeze";
 attribute :>> premise="Collector-updateable RootView scanner for every context, nested view lifetime, native borrow exclusion, old-reader pin and relocation reload; processor0 RC scanning does not close arbitrary-owner roots.";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ARP-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/RestAllocatorRootPublication.lean";
 attribute :>> subjectScope="ARP-ORDER:actual-C-HB-lock-and-lifetime";
 attribute :>> premise="Concrete gate/allocator lock order, C object provenance, reads-from and release/acquire edges, complete writer coverage and descriptor reclamation; current target macros are not automatically qualified.";
 }
 part failure : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="ARP-FAIL";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestAllocatorRootPublication.lean";
 attribute :>> subjectScope="ARP-FAIL:denial-unknown-close-and-resume";
 attribute :>> premise="Prove logical root custody despite changed physical layout on denial, close/enter linearization, unknown debt reconciliation and same-call reentry without duplicate construction.";
 }
 ref part priorExclusion=GambitRestCapacityPreflight::exclusion;
 ref part priorRoot=GambitRestCapacityPreflight::rootView;
 ref part priorReceipt=GambitRestCapacityPreflight::receipt;
 ref part priorOrder=GambitRestCapacityPreflight::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=allocator; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=allocator; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=apply; ref part :>> prerequisite=history; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=apply; ref part :>> prerequisite=induction; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=direct; ref part :>> prerequisite=history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=direct; ref part :>> prerequisite=induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=native; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=native; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=history; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=induction; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=failure; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=failure; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=apply; ref part :>> prerequisite=roots; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=apply; ref part :>> prerequisite=allocator; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=apply; ref part :>> prerequisite=order; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=direct; ref part :>> prerequisite=roots; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=direct; ref part :>> prerequisite=allocator; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=direct; ref part :>> prerequisite=order; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=native; ref part :>> prerequisite=roots; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=native; ref part :>> prerequisite=allocator; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=native; ref part :>> prerequisite=order; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=failure; ref part :>> prerequisite=roots; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=failure; ref part :>> prerequisite=allocator; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=failure; ref part :>> prerequisite=order; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=allocator; ref part :>> prerequisite=priorExclusion; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=allocator; ref part :>> prerequisite=priorReceipt; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=priorRoot; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=failure; ref part :>> prerequisite=native; }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow { attribute :>> callerId="APPLY"; attribute :>> sourceAnchors="vendor/gambit/lib/_kernel.scm:2989-3060;lib/_kernel.c:19385-19445"; attribute :>> actualChain="wrapper rest splice -> app -> POP_ARGS2 -> PUSH/CAR/CDR -> POP_ARGS_IN_REGS -> JUMPEXTNOTSAFE"; attribute :>> hazard="Insert a framed root/staging helper before POP_ARGS2; preserve post-splice proc,args, continuation and initialized staging prefix. The embedded C body is a hand-written producer, not generated by targ-gen-jump."; attribute :>> replacement="Count/expand only immutable or qualified stable input; otherwise single-read staging with rooted progress, same read/error order and overflow handling."; }
 part caller1 : CallerRow { attribute :>> callerId="DIRECT"; attribute :>> sourceAnchors="vendor/gambit/gsc/_front.scm:3370-3705,3780-3918;gsc/_gvm.scm:466-473;gsc/_t-c-2.scm:631-640,718-774,1318-1405"; attribute :>> actualChain="slot arguments evaluated and saved -> register operands evaluated/spilled -> reload -> adjust-slots -> seal-bb -> make-jump -> C checks/adjust/jump"; attribute :>> hazard="Existing front-end interleaves evaluation and placement. Add a logical call preparation region and rooted value-location plan; a macro inserted only in targ-gen-jump is too late to reconstruct overwritten inputs."; attribute :>> replacement="Preserve chosen evaluation order and late global lookup timing; no poll or allocation after final grant. Front-end and backend must agree on every copy, R0 and frame map."; }
 part caller2 : CallerRow { attribute :>> callerId="NATIVE"; attribute :>> sourceAnchors="vendor/gambit/gsc/_ptree2.scm:2902-2930,3145-3187;include/gambit.h.in:10043-10071;lib/setup.c:3276-3360"; attribute :>> actualChain="BEGIN_SFUN marker -> prioritized SCMOBJ parameter conversion -> make-body SFUN_ARG loop -> SFUN_CALL -> ___call builds return frame"; attribute :>> hazard="Root proc and all incoming SCMOBJ values before marker allocation; publish a typed conversion view with safe initialized prefix before any collecting conversion; final reserve after conversions and before first SFUN_ARG."; attribute :>> replacement="Root ingress must inherit a still-live parent borrow/epoch pin or registered RootHandle origin before waiting for admission; bare movable SCMOBJ ingress cannot become safe retroactively by taking the gate. Original native activation/catcher remains live. Unannotated allocating/reentrant converters reject this profile."; }
 part caller3 : CallerRow { attribute :>> callerId="MARKER"; attribute :>> sourceAnchors="vendor/gambit/lib/c_intf.c:6509-6564;lib/mem.c:3969-3987,6845-6858"; attribute :>> actualChain="make_vector -> write marker proc/id -> publish pointer; kill clears element0 then decrements still refcount"; attribute :>> hazard="The explicit proc_or_false GC-protection TODO precedes conversion. Existing RC registration is PSTATE-local while mark_rc is called in the processor0 branch; do not assume an arbitrary processor RC is a complete view."; attribute :>> replacement="Generated RootView must have an explicit scan/update adapter for every admitted context; still refcount is lifetime, not complete relocation-root coverage."; }
 part def AllocatorRow { attribute pathId : String; attribute sourceAnchors : String; attribute actualPath : String; attribute contract : String; attribute failure : String; attribute custodian : String; }
 part allocatorRow0 : AllocatorRow { attribute :>> pathId="CURRENT-WINDOW"; attribute :>> sourceAnchors="vendor/gambit/lib/mem.c:4525-4567,7428-7505"; attribute :>> actualPath="prepare_mem_pstate publishes policy heap_limit/stack_limit; heap_limit may choose another section"; attribute :>> contract="Owner materializes fp/hp before helper; validate current backing object, semispace, guards, max simultaneous FrameSpec demand and no conflicting lease; use checked offsets within each backing object."; attribute :>> failure="Fast path may reserve current disjoint window with hp unchanged; policy threshold is not physical capacity."; attribute :>> custodian="Context owns roots and backing until canonical unused cancellation or completed writer close."; }
 part allocatorRow1 : AllocatorRow { attribute :>> pathId="LOCAL-REUSE"; attribute :>> sourceAnchors="vendor/gambit/lib/mem.c:7458-7475,3315-3356"; attribute :>> actualPath="PSTATE-local msection_free_list pop -> set_heap_msection; sharing repartitions both limits"; attribute :>> contract="A registered layout operation excludes GC/reset and same-context reentry; record list removal, prior/current section and layout generation before exposing grant."; attribute :>> failure="Known denial after a layout change preserves logical inputs, not necessarily old physical cursors/layout. No rollback over initialized objects."; attribute :>> custodian="Before assignment commit, context/VM arena escrow retains popped section; after commit, context owns it even if response lost."; }
 part allocatorRow2 : AllocatorRow { attribute :>> pathId="GLOBAL-ASSIGN"; attribute :>> sourceAnchors="vendor/gambit/lib/mem.c:3090-3129,3363-3385,7478-7498"; attribute :>> actualPath="ALLOC_MEM_LOCK -> approximate global free check -> next_heap_msection_without_locking -> sharing logic"; attribute :>> contract="Register layout debt under short VM gate, release gate, acquire existing alloc lock, assign, release alloc lock, commit known result under gate. No waiting or callback under either lock; no nested gate/alloc lock."; attribute :>> failure="GC close rejects new operations, waits outside locks for existing debt to resolve. Native backing growth, if needed, is a separate escrowed stage, not proved by global free count."; attribute :>> custodian="Unknown assignment retains layout debt and backing; timeout cannot declare denial or free the section."; }
 part allocatorRow3 : AllocatorRow { attribute :>> pathId="METADATA"; attribute :>> sourceAnchors="vendor/gambit/lib/mem.c:3238-3270,3389-3407,3540-3552,3740-3750"; attribute :>> actualPath="collector chunk start/end/first link setup versus mutator section switching"; attribute :>> contract="Build a MutatorLayoutAdapter for the exact current mode. Do not call prepare_heap_msection blindly on every mutator switch or impose collector chunk size as rest limit."; attribute :>> failure="Exclude actual metadata and guards in the selected layout; old whole-half arithmetic is only a candidate envelope."; attribute :>> custodian="Any unqualified chunk/header mode remains unresolved and cannot issue managed capacity."; }
 part allocatorRow4 : AllocatorRow { attribute :>> pathId="RESET-RESUME"; attribute :>> sourceAnchors="vendor/gambit/lib/mem.c:3413-3450,7003-7085;lib/_kernel.scm:1992-2048"; attribute :>> actualPath="GC flips/reset sections -> phase completion -> context preparation -> restored rest helper"; attribute :>> contract="Close gate -> cancel unused -> drain active/layout operations -> freeze roots -> scan/update -> prepare context -> release resume seal -> acquire/reload."; attribute :>> failure="Layout changes invalidate unused tickets even without a GC epoch change. Finished packets are not reconstructed."; attribute :>> custodian="GC owns frozen roots exclusively; native activation and result backing remain pinned until resume/exit acknowledgement."; }
 part def OrderRow { attribute edgeId : String; attribute orderContract : String; attribute rejectedShortcut : String; }
 part orderRow0 : OrderRow { attribute :>> edgeId="ROOT-REGISTER"; attribute :>> orderContract="Start from valid registered handles or an inherited parent root/epoch pin; initialize descriptor, exact SCMOBJ slots and map before registration unlock-release. Gate lock-acquire observes membership."; attribute :>> rejectedShortcut="Published membership permits closure accounting; it does not authorize scanning a still-running writer. Root storage cannot be allocated while unrooted or under the gate."; }
 part orderRow1 : OrderRow { attribute :>> edgeId="LAYOUT-DEBT"; attribute :>> orderContract="Gate-serialized open-check plus increment layoutOps; result commit/decrement under same gate after allocator lock release."; attribute :>> rejectedShortcut="No split open load then independent increment. close may precede completion; completion attaches backing/debt result but cannot issue a new grant after close."; }
 part orderRow2 : OrderRow { attribute :>> edgeId="GRANT-ENTER"; attribute :>> orderContract="Grant fields and unused state publish under gate unlock-release; consumer locks/acquires and rechecks owner, epoch, layout, serial, input, cursor and OPEN while changing UNUSED to ACTIVE."; attribute :>> rejectedShortcut="A separate acquire load of ticket plus relaxed active count is insufficient. Registry storage remains pinned during query/enter; stamp equality alone does not prevent use-after-free."; }
 part orderRow3 : OrderRow { attribute :>> edgeId="FRAME-PARK"; attribute :>> orderContract="Last initialized heap store, hp prefix, complete FrameSpec/R0 and no-native-borrow state precede gate unlock-release of PARKED. Collector lock-acquire checks all frozen members and zero active/layout debt."; attribute :>> rejectedShortcut="GC closes admission before it waits. No collector scan of ACTIVE/unknown state; constructor completes bounded work after close without reopening admission."; }
 part orderRow4 : OrderRow { attribute :>> edgeId="GC-RESUME"; attribute :>> orderContract="Collector relocation writes precede release publication of round/context-ready seal. Same native activation acquires seal and reloads every admitted root before unfreezing/regrant."; attribute :>> rejectedShortcut="Old C local copies, register caches, old tickets and old raw cursor values must not be reused. Original synchronous native result/exception ABI persists."; }
 part orderRow5 : OrderRow { attribute :>> edgeId="RECLAIM"; attribute :>> orderContract="Detach descriptor/ticket under gate only after owner exit/terminal acknowledgement, no query/consumer pins, no collector snapshot readers and no unknown layout/native debt."; attribute :>> rejectedShortcut="Release/acquire publication does not itself reclaim storage. Unknown owner stop or native write cannot be converted into a cancellation receipt."; }
 part orderRow6 : OrderRow { attribute :>> edgeId="PORTABILITY"; attribute :>> orderContract="Selected baseline: one short VM control mutex with acquire/release semantics; owner-private data remains ordinary C only under proved exclusive access."; attribute :>> rejectedShortcut="Existing W_ALL/R_ALL are register synchronization macros, not a new publication protocol. Existing __sync/volatile/ticketlock variants require target audit; no lock-free or all-target C11 claim."; }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow { attribute :>> capability="Check fusion"; attribute :>> removedWork="Remove j repeated rest heap checks/helper entries within a qualified lease"; attribute :>> bound="1 <= j <= k; four-rest example k=4"; attribute :>> addedCost="One preparation/validation and gate transitions; full-frame poll/pressure decision remains"; attribute :>> condition="Net CPU benefit requires saved checks/helpers > root, staging, gate and poll cost. No speedup measured."; }
 part cost1 : CostRow { attribute :>> capability="Fast-window reuse"; attribute :>> removedWork="Avoid section switching if current actual heap and stack ranges fit"; attribute :>> bound="0 additional section payload in that case"; attribute :>> addedCost="Root slots, descriptor and retained continuation lifetime"; attribute :>> condition="No gain if policy override violates pressure/safepoint guarantees; full-view mapping must close."; }
 part cost2 : CostRow { attribute :>> capability="Known layout denial"; attribute :>> removedWork="Keep evaluated values without rerunning user code"; attribute :>> bound="0 operand reevaluations; layout may change"; attribute :>> addedCost="Root reload and canonical layout-debt settlement"; attribute :>> condition="Failure does not imply cursor rollback; consumed pool backing remains counted."; }
 part cost3 : CostRow { attribute :>> capability="Mutable apply"; attribute :>> removedWork="Avoid rereading a mutating spine after GC"; attribute :>> bound="O(n) staged SCMOBJ slots; approximately n*wordBytes payload plus headers/maps"; attribute :>> addedCost="O(n) read/copy plus initialized-prefix root maintenance"; attribute :>> condition="Must preserve original observation/error order; stable-input fast path alone does not cover general apply."; }
 part cost4 : CostRow { attribute :>> capability="Direct call plan"; attribute :>> removedWork="Retire implicit call-move liveness reconstruction"; attribute :>> bound="Live input/root count determined by generated location plan"; attribute :>> addedCost="Additional spills or duplicate slots until move commit"; attribute :>> condition="No claim that every direct/local/inlined/late-global call shares one budget or safe cut."; }
 part cost5 : CostRow { attribute :>> capability="Native conversions"; attribute :>> removedWork="Retire unrooted proc/SCMOBJ and outgoing-stack assumptions for managed entry"; attribute :>> bound="SCMOBJ live input slots plus initialized converted prefix"; attribute :>> addedCost="Conversion cleanup map, marker/root registration and activation pin"; attribute :>> condition="Unknown converter effects or nonzero-processor scan gap rejects admission."; }
 part cost6 : CostRow { attribute :>> capability="Backing growth"; attribute :>> removedWork="Reuse existing pool rather than automatically grow it"; attribute :>> bound="Inherited full msection payload=131072*wordBytes; 1MiB at 64bit"; attribute :>> addedCost="Assignment may batch sections and retain old stack/copy backing"; attribute :>> condition="Small 112B/96B repair budget is not new-section/RSS/whole-round peak."; }
 part cost7 : CostRow { attribute :>> capability="Control coordination"; attribute :>> removedWork="Replace split grant/GC close races with one linearization domain"; attribute :>> bound="O(1) gate operations per grant/entry/close; O(p) member closure"; attribute :>> addedCost="Potential cross-core mutex contention, scan pins, layoutOps debt"; attribute :>> condition="Do not add per-CONS atomics; per-context sharding requires a separate membership-close proof."; }
 part cost8 : CostRow { attribute :>> capability="Unknown outcomes"; attribute :>> removedWork="Prevent double refund and premature arena reclamation"; attribute :>> bound="Unknown layout/native obligation stays >=1 until resolved"; attribute :>> addedCost="Potential unbounded retention and GC wait"; attribute :>> condition="No bounded peak/GC-latency theorem without bounded stop/result evidence."; }
 part cost9 : CostRow { attribute :>> capability="Peak accounting"; attribute :>> removedWork="Count unique physical backing and live root/staging storage once"; attribute :>> bound="Peak=max_t(backing+roots+staging+nativeEscrow); reserved slice within same backing is not another allocation"; attribute :>> addedCost="Extra staging or escrow can dominate saved checks"; attribute :>> condition="No positive net peak reduction proved; reusable lease reduces work only under qualifying geometry and effects."; }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref part producer : DiagramNode; ref part consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="caller"; attribute :>> labelText="Scheme call preparation"; }
 part node1 : DiagramNode { attribute :>> nodeId="root"; attribute :>> labelText="Typed RootView / conversion prefix"; }
 part node2 : DiagramNode { attribute :>> nodeId="gate"; attribute :>> labelText="VM gate: roots, layout debt, ticket state"; }
 part node3 : DiagramNode { attribute :>> nodeId="arena"; attribute :>> labelText="Mutator layout adapter / existing allocator"; }
 part node4 : DiagramNode { attribute :>> nodeId="active"; attribute :>> labelText="Bounded argument shuffle / rest construction"; }
 part node5 : DiagramNode { attribute :>> nodeId="park"; attribute :>> labelText="Complete FrameSpec / parked roots"; }
 part node6 : DiagramNode { attribute :>> nodeId="gc"; attribute :>> labelText="GC exclusive scan / relocation"; }
 part node7 : DiagramNode { attribute :>> nodeId="resume"; attribute :>> labelText="Context seal / acquire reload"; }
 part node8 : DiagramNode { attribute :>> nodeId="models"; attribute :>> labelText="ASCENT needs -> QNT / Lean"; }
 part node9 : DiagramNode { attribute :>> nodeId="unknown"; attribute :>> labelText="Canonical arena/native escrow"; }
 part edge0 : DiagramEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="preserve evaluated inputs"; }
 part edge1 : DiagramEdge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="register and publish"; }
 part edge2 : DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="layout operation pin"; }
 part edge3 : DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node2; attribute :>> labelText="known commit or deny"; }
 part edge4 : DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node9; attribute :>> labelText="unknown result retains duty"; }
 part edge5 : DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node4; attribute :>> labelText="atomic enter before close"; }
 part edge6 : DiagramEdge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="finish despite close"; }
 part edge7 : DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node5; attribute :>> labelText="cancel unused then freeze"; }
 part edge8 : DiagramEdge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="zero debt and writers"; }
 part edge9 : DiagramEdge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="publish relocation and context seal"; }
 part edge10 : DiagramEdge { ref part :>> producer=node7; ref part :>> consumer=node1; attribute :>> labelText="reload same logical call"; }
 part edge11 : DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node8; attribute :>> labelText="component model obligations"; }
 part edge12 : DiagramEdge { ref part :>> producer=node9; ref part :>> consumer=node5; attribute :>> labelText="reconcile before freeze"; }
 ref part inheritedBudget=GambitRestCapacityPreflight::preflightW8R0B1;
 ref part inheritedFixed=GambitRestCapacityPreflight::preflightW8R1B1;
 ref part inheritedGeometry=GambitRestCapacityPreflight::fresh64;
}
