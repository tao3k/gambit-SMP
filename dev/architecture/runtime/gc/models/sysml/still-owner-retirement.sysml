/* Modern C target; no satisfied runtime instance, forced thread kill or crash guarantee. */
package GambitStillOwnerRetirement {
 private import ScalarValues::*;
 part def StopRecord { attribute stopAuthenticated : Boolean; attribute allWritersClosed : Boolean;
  attribute privateUnpublished : Boolean; attribute effectFree : Boolean; attribute inputStable : Boolean;
  attribute rootsRetained : Boolean; attribute takeoverAllowed : Boolean;
 }
 requirement def TakeoverLaw { subject t : StopRecord;
  require constraint { not t.takeoverAllowed or (t.stopAuthenticated and t.allWritersClosed and
   t.privateUnpublished and t.effectFree and t.inputStable and t.rootsRetained) }
 }
 part def NativeIsolation { attribute publishedBeforeStart : Boolean; attribute nativeOnly : Boolean;
  attribute rootsRegistered : Boolean; attribute registryIndependent : Boolean; attribute rawHeapAlias : Boolean;
  attribute resourcesIndependent : Boolean; attribute gcMayIgnoreHelperWait : Boolean;
 }
 requirement def IsolationLaw { subject i : NativeIsolation;
  require constraint { not i.gcMayIgnoreHelperWait or (i.publishedBeforeStart and i.nativeOnly and
   i.rootsRegistered and i.registryIndependent and i.resourcesIndependent and not i.rawHeapAlias) }
 }
 part def ReceiptRetirement { attribute ingressClosed : Boolean; attribute clientAcknowledged : Boolean;
  attribute queryUsers : Integer; attribute callbackUsers : Integer; attribute derivedUsers : Integer;
  attribute prefixSettled : Boolean; attribute rejectFenceRetained : Boolean; attribute fullRecordRemoved : Boolean;
 }
 requirement def RetirementLaw { subject r : ReceiptRetirement;
  require constraint { r.queryUsers>=0 and r.callbackUsers>=0 and r.derivedUsers>=0 and
   (not r.fullRecordRemoved or (r.ingressClosed and r.clientAcknowledged and r.queryUsers==0 and
    r.callbackUsers==0 and r.derivedUsers==0 and r.prefixSettled and r.rejectFenceRetained)) }
 }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="OR-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/still_owner_retirement.qnt";
 attribute :>> subjectScope="still_owner_retirement:33-named-histories;safe;seed=17;100x100";
 attribute :>> premise="One helper/three fields/two generations, one receipt plus abstract earlier gap; private replay, isolated GC, child pins and retired retry controls; no native liveness";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="OR-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/StillOwnerRetirement.lean";
 attribute :>> subjectScope="GambitSMP.StillOwnerRetirement:unknownOwnerDoesNotChangeGate;pendingNativeWritesDoNotChangeGate;isolationRequiresRoots;isolationRequiresIndependentResources;isolationRejectsRawAlias;stopAloneInsufficient;sideEffectsForbidReplay;noPublishedReplay;oldGenerationRevoked;prefixPreserved;drainStepDoesNotIncreaseDebt;drainTraceDoesNotIncreaseDebt;closedNeverReopens;childHandoffConservesDebt;outstandingDebtBlocksRetire;childHandoffStillBlocks;unacknowledgedRetains;earlierGapBlocksFloor;retiredRetryRejected;floorNeverForgets;stagingPeakIncludesBoth;sentinelAddsWrites";
 attribute :>> premise="22 conditional isolation/takeover/debt/retirement statements; finite drain Step/Trace kernel only, not whole QNT or C refinement";
 }
 part stop : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="OR-STOP";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillOwnerRetirement.lean";
 attribute :>> subjectScope="OR-STOP:actual-source-refinement";
 attribute :>> premise="Exact native join success, unique join owner, generation identity and delegated writer closure; errors/timeouts/cleanup flags do not confirm stopped writes";
 }
 part isolation : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="OR-ISOLATE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillOwnerRetirement.lean";
 attribute :>> subjectScope="OR-ISOLATE:actual-source-refinement";
 attribute :>> premise="Before helper start publish an independent root domain; helper uses preallocated native bytes/opaque IDs only and holds no collector root/allocator resource; no post-failure relabeling of raw heap writers";
 }
 part takeover : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="OR-TAKEOVER";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillOwnerRetirement.lean";
 attribute :>> subjectScope="OR-TAKEOVER:actual-source-refinement";
 attribute :>> premise="After confirmed stop and writer drain, replay only private unpublished effect-free batch from stable input; preserve prefix, revoke old generation; heap-visible materialization remains a separate safe-point gate";
 }
 part retirement : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="OR-RETIRE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillOwnerRetirement.lean";
 attribute :>> subjectScope="OR-RETIRE:actual-source-refinement";
 attribute :>> premise="Recipient acknowledgement, closed ingress, query/callback/derived drain, contiguous retired floor and retained generation fence before receipt deletion; reject late retry without execution";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=GambitRetainedRcScan::joinResult; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=GambitRetainedRcScan::lifetime; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=GambitPromotionIntervalHandoff::memory; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=isolation; ref part :>> prerequisite=history; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=isolation; ref part :>> prerequisite=induction; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=isolation; ref part :>> prerequisite=GambitHostRootsRefinement::rc; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=isolation; ref part :>> prerequisite=GambitHostRootsRefinement::bindingState; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=isolation; ref part :>> prerequisite=GambitRuntimeAssurance::work.source; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=takeover; ref part :>> prerequisite=history; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=takeover; ref part :>> prerequisite=induction; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=takeover; ref part :>> prerequisite=stop; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=takeover; ref part :>> prerequisite=isolation; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=takeover; ref part :>> prerequisite=GambitStillInitRecovery::progress; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=takeover; ref part :>> prerequisite=GambitStillInitRecovery::roots; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=history; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=induction; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=GambitStillInitRecovery::delivery; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=GambitRetainedRcScan::lifetime; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=GambitRuntimeAssurance::release.source; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=GambitHostRootsRefinement::exitState; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStructurePollStillEnvelope::still; ref part :>> prerequisite=takeover; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStructurePollStillEnvelope::still; ref part :>> prerequisite=isolation; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStructurePollStillEnvelope::peak; ref part :>> prerequisite=retirement; }
 part stopRoute : GambitHostRootsRefinement::Route { ref part :>> need=stop;
 attribute :>> sourceAnchors="lib/os_thread.c:546-591;lib/_thread.scm:1511-1596;lib/setup.c:903-978,1012-1043,4665-4770;lib/mem.c:684-703,723-829,4928-4935;lib/_kernel.scm:43-112;lib/c_intf.c:5413-5500,6550-6562;lib/os_io.c:6816-6872,11412-11428;examples/tcltk/tcltk.scm:100-194,221-227";
 attribute :>> patchAnchors="Cumulative fixture join/root/marker recipes remain distinct from base vendor and native qualification; no new runtime patch";
 attribute :>> projection="Exact native join success, unique join owner, generation identity and delegated writer closure; errors/timeouts/cleanup flags do not confirm stopped writes";
 attribute :>> failureCustodian="Operation/root-domain owner retains uncertain helper and native backing; takeover requires stopped writer closure; lifecycle arbiter owns terminal receipt plus late-retry rejection fence";
 attribute :>> status="selected-callers-and-target-protocol-known-source-and-platform-refinement-open";
 }
 part isolationRoute : GambitHostRootsRefinement::Route { ref part :>> need=isolation;
 attribute :>> sourceAnchors="lib/os_thread.c:546-591;lib/_thread.scm:1511-1596;lib/setup.c:903-978,1012-1043,4665-4770;lib/mem.c:684-703,723-829,4928-4935;lib/_kernel.scm:43-112;lib/c_intf.c:5413-5500,6550-6562;lib/os_io.c:6816-6872,11412-11428;examples/tcltk/tcltk.scm:100-194,221-227";
 attribute :>> patchAnchors="Cumulative fixture join/root/marker recipes remain distinct from base vendor and native qualification; no new runtime patch";
 attribute :>> projection="Before helper start publish an independent root domain; helper touches native bytes/opaque IDs only and holds no collector root lock; no post-failure relabeling of raw heap writers";
 attribute :>> failureCustodian="Operation/root-domain owner retains uncertain helper and native backing; takeover requires stopped writer closure; lifecycle arbiter owns terminal receipt plus late-retry rejection fence";
 attribute :>> status="selected-callers-and-target-protocol-known-source-and-platform-refinement-open";
 }
 part takeoverRoute : GambitHostRootsRefinement::Route { ref part :>> need=takeover;
 attribute :>> sourceAnchors="lib/os_thread.c:546-591;lib/_thread.scm:1511-1596;lib/setup.c:903-978,1012-1043,4665-4770;lib/mem.c:684-703,723-829,4928-4935;lib/_kernel.scm:43-112;lib/c_intf.c:5413-5500,6550-6562;lib/os_io.c:6816-6872,11412-11428;examples/tcltk/tcltk.scm:100-194,221-227";
 attribute :>> patchAnchors="Cumulative fixture join/root/marker recipes remain distinct from base vendor and native qualification; no new runtime patch";
 attribute :>> projection="After confirmed stop and writer drain, replay only private unpublished effect-free batch from stable input; preserve prefix, revoke old generation; heap-visible materialization remains a separate safe-point gate";
 attribute :>> failureCustodian="Operation/root-domain owner retains uncertain helper and native backing; takeover requires stopped writer closure; lifecycle arbiter owns terminal receipt plus late-retry rejection fence";
 attribute :>> status="selected-callers-and-target-protocol-known-source-and-platform-refinement-open";
 }
 part retirementRoute : GambitHostRootsRefinement::Route { ref part :>> need=retirement;
 attribute :>> sourceAnchors="lib/os_thread.c:546-591;lib/_thread.scm:1511-1596;lib/setup.c:903-978,1012-1043,4665-4770;lib/mem.c:684-703,723-829,4928-4935;lib/_kernel.scm:43-112;lib/c_intf.c:5413-5500,6550-6562;lib/os_io.c:6816-6872,11412-11428;examples/tcltk/tcltk.scm:100-194,221-227";
 attribute :>> patchAnchors="Cumulative fixture join/root/marker recipes remain distinct from base vendor and native qualification; no new runtime patch";
 attribute :>> projection="Recipient acknowledgement, closed ingress, query/callback/derived drain, contiguous retired floor and retained generation fence before receipt deletion; reject late retry without execution";
 attribute :>> failureCustodian="Operation/root-domain owner retains uncertain helper and native backing; takeover requires stopped writer closure; lifecycle arbiter owns terminal receipt plus late-retry rejection fence";
 attribute :>> status="selected-callers-and-target-protocol-known-source-and-platform-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="join";
 attribute :>> sourceAnchors="os_thread.c:546-591;_thread.scm:1511-1596;setup.c:978";
 attribute :>> actualChain="Scheme termination schedules/interrupts; native pthread_join -> status; resize ignores error";
 attribute :>> hazard="Scheme termination is not OS stop; native success stops target only; preserve raw join identity";
 attribute :>> replacement="StopReceipt plus delegated writer closure; no timeout/second join inference";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="resize";
 attribute :>> sourceAnchors="setup.c:903-978,1012-1043";
 attribute :>> actualChain="Direct GC pstate -> collective resize -> pstate cleanup/exit -> join";
 attribute :>> hazard="A blocking join can remain on collective control path; executor count is not root-domain census";
 attribute :>> replacement="Park participant before waiting; independent root domain enrolled before removal";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="cleanup";
 attribute :>> sourceAnchors="mem.c:684-703,4928-4935;setup.c:4665-4770";
 attribute :>> actualChain="cleanup_mem_pstate -> free_still_objs and cleanup_rc";
 attribute :>> hazard="Thread exit/cleanup may destroy roots while operations/native borrowers remain";
 attribute :>> replacement="Durable domain transfer and last-user receipt before old cleanup retires";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="constructor";
 attribute :>> sourceAnchors="_kernel.scm:43-112;_kernel.c:23864-23904";
 attribute :>> actualChain="Linked still body -> fill -> GVM result";
 attribute :>> hazard="Current raw pointer body is not private replayable staging; no native async stop contract";
 attribute :>> replacement="Keep synchronous fast path; admit service work only via isolated bytes/handle recipe";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="utf8-input";
 attribute :>> sourceAnchors="c_intf.c:5413-5500;os_base.c:1735-1747";
 attribute :>> actualChain="Two-pass decoder over native/stack buffer -> atomic result";
 attribute :>> hazard="An expired/mutated input cannot reconstruct a pending private batch";
 attribute :>> replacement="Stable input image plus output index/byte offset/decoder state; no effect replay";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="directory";
 attribute :>> sourceAnchors="os_io.c:6816-6872,11412-11428";
 attribute :>> actualChain="readdir/de->d_name -> string conversion -> release/return";
 attribute :>> hazard="Directory advancement cannot be repeated during initializer recovery";
 attribute :>> replacement="Record effect outcome before staging; copy/lease name; raw effect ambiguity remains unknown";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="native-callback";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:100-194,221-227;c_intf.c:6550-6562";
 attribute :>> actualChain="Tcl command callback/deletion -> release roots/RC; marker invalidation";
 attribute :>> hazard="Delete/marker false is not proof of drained native aliases or future continuation uses";
 attribute :>> replacement="Close new entries, retain in-flight and child pins, then retire exact generation";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="receipt-consumer";
 attribute :>> sourceAnchors="gambit.h.in:10033-10066,10269-10272;setup.c:3275-3413";
 attribute :>> actualChain="Generated native conversion, Scheme call and exceptional return";
 attribute :>> hazard="Existing output/status ABI has no general retired-retry rejection protocol";
 attribute :>> replacement="Managed session opt-in; raw ABI retains synchronous semantics without resumable authority";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="isolated native helper";
 attribute :>> removedWork="Remove its unresolved completion/join from GC membership wait";
 attribute :>> bound="Conditional GC gate independent of unknown owner and pending native writes";
 attribute :>> addedCost="Independent root-domain scan, handle IDs and stable input; no collector lock held by helper";
 attribute :>> condition="Raw heap access, raw movable pointers or a helper-owned scan lock falsifies isolation";
 }
 part cost1 : CostRow {
 attribute :>> capability="private batch takeover";
 attribute :>> removedWork="Replay only unpublished native range after exact stop and all-writer drain";
 attribute :>> bound="With batch q, ambiguous recomputation at most q output items if recipe/input bound holds";
 attribute :>> addedCost="Stop generation, input lease, cursor and replacement executor metadata";
 attribute :>> condition="No replay of heap-visible fields, directory I/O, callbacks or unknown-live writer";
 }
 part cost2 : CostRow {
 attribute :>> capability="staging and materialization";
 attribute :>> removedWork="Allow collector to ignore unscannable native buffer";
 attribute :>> bound="Mandatory final Scheme fill/allocation still remains; staged bytes S may coexist with heap B";
 attribute :>> addedCost="At least overlapping S+B plus input E/roots/ledger before stage release";
 attribute :>> condition="No automatic peak reduction; direct synchronous constructors need not pay staging";
 }
 part cost3 : CostRow {
 attribute :>> capability="valid-shell alternative";
 attribute :>> removedWork="Potentially scan a partial pointer body only under a different proven layout";
 attribute :>> bound="Sentinel then final fill costs 2a writes versus a; pre-dirty coverage and atomic store premises extra";
 attribute :>> addedCost="Extra a writes, publication/barrier support and root lifetimes";
 attribute :>> condition="Does not alone allow GC concurrent with an unknown raw mutator; not the default or implemented";
 }
 part cost4 : CostRow {
 attribute :>> capability="receipt compaction";
 attribute :>> removedWork="Drop full completed reply after receiver acknowledgement and closed/drained ingress";
 attribute :>> bound="Full result/dedup record -> smaller retained floor/session fence; O(sessions+gaps+live users)";
 attribute :>> addedCost="Retired floor and generation namespace remain; unacknowledged records retained";
 attribute :>> condition="Managed protocol may return Retired; unlimited exact-original-reply ABI cannot use this compaction";
 }
 part cost5 : CostRow {
 attribute :>> capability="callback-derived drain";
 attribute :>> removedWork="Avoid deleting receipt while a parent hands responsibility to a child";
 attribute :>> bound="Parent pin decrement and child pin increment conserve unfinished debt";
 attribute :>> addedCost="Per-query/callback/derived refs and terminal arbitration";
 attribute :>> condition="Close ingress is insufficient if admitted callbacks can still derive children";
 }
 part cost6 : CostRow {
 attribute :>> capability="unknown memory";
 attribute :>> removedWork="Permit GC progress without pretending uncertain backing was freed";
 attribute :>> bound="Retain full native buffer S and source/root/operation liabilities until authoritative outcome";
 attribute :>> addedCost="Potential indefinite retained memory and bounded-admission pressure";
 attribute :>> condition="GC noninterference is not eventual completion, bounded RSS, resource free or process-crash recovery";
 }
 part cost7 : CostRow {
 attribute :>> capability="whole peak";
 attribute :>> removedWork="Credit only actual acquisition/record lifetime eliminated across phases";
 attribute :>> bound="Peak candidate max_t(P_t-Q_t+A_t); stage S+heap B overlap may dominate";
 attribute :>> addedCost="Staging, snapshots, root domains, stop records, query pins and rejection floors";
 attribute :>> condition="No measured saving, no obligatory payload allocation retired; later compaction cannot erase earlier peak";
 }
 part def ViewNode { attribute nodeId : String; attribute labelText : String; }
 part node0 : ViewNode { attribute :>> nodeId="isolate"; attribute :>> labelText="Before start: independent roots + native-only recipe"; }
 part node1 : ViewNode { attribute :>> nodeId="stage"; attribute :>> labelText="Helper writes private bytes / opaque IDs"; }
 part node2 : ViewNode { attribute :>> nodeId="unknown"; attribute :>> labelText="Unknown owner: retain buffer; GC may scan roots"; }
 part node3 : ViewNode { attribute :>> nodeId="stop"; attribute :>> labelText="Exact stop + all writers/borrowers closed"; }
 part node4 : ViewNode { attribute :>> nodeId="takeover"; attribute :>> labelText="New generation; replay private pending batch only"; }
 part node5 : ViewNode { attribute :>> nodeId="heap"; attribute :>> labelText="Materialize under managed GC/root gate"; }
 part node6 : ViewNode { attribute :>> nodeId="receipt"; attribute :>> labelText="Recipient root + acceptance receipt"; }
 part node7 : ViewNode { attribute :>> nodeId="drain"; attribute :>> labelText="Close ingress; ACK; drain queries/callback children"; }
 part node8 : ViewNode { attribute :>> nodeId="floor"; attribute :>> labelText="Publish retired floor; remove full reply; reject late retry"; }
 part node9 : ViewNode { attribute :>> nodeId="peak"; attribute :>> labelText="Stage + heap + input + root/receipt/fence peak"; }
 part node10 : ViewNode { attribute :>> nodeId="collector"; attribute :>> labelText="GC scans registered roots; never native staging"; }
 part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
 part edge0 : ViewEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="admit before any native write"; }
 part edge1 : ViewEdge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="lost outcome; no heap aliases"; }
 part edge2 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="successful identity-bound stop; not timeout"; }
 part edge3 : ViewEdge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="stable effect-free unpublished range"; }
 part edge4 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node1; attribute :>> labelText="preserve prefix; revoke old writer"; }
 part edge5 : ViewEdge { ref part :>> producer=node1; ref part :>> consumer=node5; attribute :>> labelText="stage done; no outstanding writer"; }
 part edge6 : ViewEdge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="publish result root before delivery"; }
 part edge7 : ViewEdge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="no rollback after acceptance"; }
 part edge8 : ViewEdge { ref part :>> producer=node7; ref part :>> consumer=node8; attribute :>> labelText="no gap and zero admitted-user debt"; }
 part edge9 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node9; attribute :>> labelText="retained native backing"; }
 part edge10 : ViewEdge { ref part :>> producer=node1; ref part :>> consumer=node9; attribute :>> labelText="stage/input overlap"; }
 part edge11 : ViewEdge { ref part :>> producer=node5; ref part :>> consumer=node9; attribute :>> labelText="heap materialization overlap"; }
 part edge12 : ViewEdge { ref part :>> producer=node8; ref part :>> consumer=node9; attribute :>> labelText="compact metadata; fence remains"; }
 part edge13 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node10; attribute :>> labelText="GC does not await helper completion"; }
 part edge14 : ViewEdge { ref part :>> producer=node0; ref part :>> consumer=node10; attribute :>> labelText="root domain enrolled before helper start"; }
}
