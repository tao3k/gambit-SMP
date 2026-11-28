/* Modern C design; no source or native admission asserted. */
package GambitRootScanArbitration {
 private import ScalarValues::*;
 part def CustodyState { attribute admitted : Boolean; attribute pending : Boolean; attribute owned : Boolean; attribute ready : Boolean; attribute quarantined : Boolean; attribute acknowledged : Boolean; attribute rootViewPinned : Boolean; }
 requirement def CustodyLaw { subject t : CustodyState; require constraint { not t.admitted or (t.pending or t.owned or t.ready or t.quarantined or t.acknowledged) } }
 part def ReturnState { attribute activePermit : Boolean; attribute rootAcknowledged : Boolean; attribute wholeRoundSeal : Boolean; attribute descendantDebt : Integer; attribute writerDebt : Integer; }
 requirement def ResumeLaw { subject r : ReturnState; require constraint { not r.activePermit or (r.rootAcknowledged and r.wholeRoundSeal and r.descendantDebt==0 and r.writerDebt==0) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/root_scan_arbitration.qnt";
 attribute :>> subjectScope="root_scan_arbitration:27-named-histories;safe;seed=17;100x100";
 attribute :>> premise="One admitted root task, two workers, one descendant, two bounded epochs; checkpoints and whole-round seal are abstract qualified premises; no actual C traversal, weak-memory or fairness proof";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/RootScanArbitration.lean";
 attribute :>> subjectScope="GambitSMP.RootScanArbitration:claimConserves;publishConserves;ackConserves;quarantineConserves;requeueConserves;stepConserves;traceConserves;emptyQueueNotComplete;unknownDebtBlocksClose;rootAckInsufficient;childDebtBlocksReturn;unknownWriterBlocksReturn;returnRequestPreservesDebt;stopWithoutCheckpointRejected;unknownTransferRetainsCustody;sourcePinRequired;staleGenerationRejected;cursorRestoreNoRepeatedPrefix;waitPathDecreases;rankedWaitsHaveNoCycle;workerCannotWaitForReturn;generationAdvanceRejectsOld";
 attribute :>> premise="22 conditional declarations: five custody states and Step/Trace conservation, root ack versus round seal, checkpoint custody, generation checks and ranked wait graph; not all QNT actions or C source simulation";
 }
 part enlist : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-ENLIST";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RootScanArbitration.lean";
 attribute :>> subjectScope="RA-ENLIST:actual-source-refinement";
 attribute :>> premise="Atomic enlistment fixes task/view epoch and root obligation before any queue notification; return ticket cannot revoke owed work; producer/worker lifecycle separated";
 }
 part claim : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-CLAIM";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RootScanArbitration.lean";
 attribute :>> subjectScope="RA-CLAIM:actual-source-refinement";
 attribute :>> premise="Pending-to-owned transfer binds task ID, epoch, attempt generation and worker before source queue ownership is released; reply loss queries canonical record; no second scan/replay inferred";
 }
 part workerExit : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-EXIT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RootScanArbitration.lean";
 attribute :>> subjectScope="RA-EXIT:actual-source-refinement";
 attribute :>> premise="Cooperative exit has stopped writer plus complete cursor/copy-frame/child-credit checkpoint and accepted replacement; unknown join or partial-copy outcome retains debt and blocks closure";
 }
 part finish : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-FINISH";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RootScanArbitration.lean";
 attribute :>> subjectScope="RA-FINISH:actual-source-refinement";
 attribute :>> premise="Strong termination includes pending/owned/private/ready/quarantined root and descendant obligations, separate weak generation and cleanup; empty queues or idle count alone not proof";
 }
 part returnGate : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-RETURN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RootScanArbitration.lean";
 attribute :>> subjectScope="RA-RETURN:actual-source-refinement";
 attribute :>> premise="RootAck never implies ResumeSeal; weak continuation movement, cleanup, capacity/fudge/context preparation and synchronized result delivery complete before active permit and reload";
 }
 part waitGraph : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-WAIT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RootScanArbitration.lean";
 attribute :>> subjectScope="RA-WAIT:actual-source-refinement";
 attribute :>> premise="Workers/coordinator never wait for the same return permit, metadata gate or owner-affine destructor needed by round completion; complete wait graph, finite producers, worker capacity and fairness remain source/progress duties";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/RootScanArbitration.lean";
 attribute :>> subjectScope="RA-ORDER:actual-C-memory-refinement";
 attribute :>> premise="Task publication, claim/attempt fencing, stable Ready result, stop/checkpoint transfer and whole-round seal use proved C happens-before and lifetime ordering; no volatile-only, timeout or machine-wrap qualification";
 }
 ref part nativeCoverage=GambitNativeRootReentry::coverage;
 ref part nativeFreeze=GambitNativeRootReentry::freeze;
 ref part nativeMember=GambitNativeRootReentry::member;
 ref part nativeScan=GambitNativeRootReentry::scan;
 ref part nativeReentry=GambitNativeRootReentry::reentry;
 ref part nativeFfi=GambitNativeRootReentry::foreign;
 ref part nativeOrder=GambitNativeRootReentry::order;
 ref part collector=GambitRuntimeAssurance::work.source;
 ref part release=GambitRuntimeAssurance::release.source;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=enlist; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=enlist; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=claim; ref part :>> prerequisite=history; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=claim; ref part :>> prerequisite=induction; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=workerExit; ref part :>> prerequisite=history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=workerExit; ref part :>> prerequisite=induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=finish; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=finish; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=returnGate; ref part :>> prerequisite=history; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=returnGate; ref part :>> prerequisite=induction; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=waitGraph; ref part :>> prerequisite=history; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=waitGraph; ref part :>> prerequisite=induction; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=collector; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=enlist; ref part :>> prerequisite=nativeMember; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=enlist; ref part :>> prerequisite=nativeCoverage; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=enlist; ref part :>> prerequisite=nativeFreeze; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=claim; ref part :>> prerequisite=enlist; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=claim; ref part :>> prerequisite=nativeScan; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=claim; ref part :>> prerequisite=order; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=workerExit; ref part :>> prerequisite=claim; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=workerExit; ref part :>> prerequisite=collector; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=workerExit; ref part :>> prerequisite=nativeOrder; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=finish; ref part :>> prerequisite=claim; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=finish; ref part :>> prerequisite=workerExit; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=finish; ref part :>> prerequisite=collector; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=returnGate; ref part :>> prerequisite=finish; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=returnGate; ref part :>> prerequisite=nativeReentry; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=returnGate; ref part :>> prerequisite=nativeFfi; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=waitGraph; ref part :>> prerequisite=enlist; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=waitGraph; ref part :>> prerequisite=workerExit; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=waitGraph; ref part :>> prerequisite=returnGate; }
 part dependency33 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=finish; ref part :>> prerequisite=order; }
 part dependency34 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=returnGate; ref part :>> prerequisite=order; }
 part dependency35 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=waitGraph; ref part :>> prerequisite=release; }
 part dependency36 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=finish; ref part :>> prerequisite=release; }
 part enlistRoute : GambitHostRootsRefinement::Route { ref part :>> need=enlist;
 attribute :>> sourceAnchors="setup.c:1012-1149,1190-1209;setup.h:53-67;mem.c:3410-3463,6775-6805;mem.c:6813-6869";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Atomic enlistment fixes task/view epoch and root obligation before any queue notification; return ticket cannot revoke owed work; producer/worker lifecycle separated";
 attribute :>> failureCustodian="Round/task service retains pending debt; claimed/quarantined worker state and pinned root view remain accountable; return ticket never discharges debt; unknown transfer keeps prior custodian";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part claimRoute : GambitHostRootsRefinement::Route { ref part :>> need=claim;
 attribute :>> sourceAnchors="mem.c:3251-3307;mem.c:4323-4386;mem.c:6690-6733";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Pending-to-owned transfer binds task ID, epoch, attempt generation and worker before source queue ownership is released; reply loss queries canonical record; no second scan/replay inferred";
 attribute :>> failureCustodian="Round/task service retains pending debt; claimed/quarantined worker state and pinned root view remain accountable; return ticket never discharges debt; unknown transfer keeps prior custodian";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part workerExitRoute : GambitHostRootsRefinement::Route { ref part :>> need=workerExit;
 attribute :>> sourceAnchors="mem.c:6690-6733;mem.c:3578-3622,4192-4208,4235-4250,4252-4276;gambit.h.in:11350-11416;setup.c:774-802,887-1003;os_thread.c:thread_join/exit";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Cooperative exit has stopped writer plus complete cursor/copy-frame/child-credit checkpoint and accepted replacement; unknown join or partial-copy outcome retains debt and blocks closure";
 attribute :>> failureCustodian="Round/task service retains pending debt; claimed/quarantined worker state and pinned root view remain accountable; return ticket never discharges debt; unknown transfer keeps prior custodian";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part finishRoute : GambitHostRootsRefinement::Route { ref part :>> need=finish;
 attribute :>> sourceAnchors="mem.c:6813-6869;mem.c:3251-3307;mem.c:3578-3622,4192-4208,4235-4250,4252-4276;gambit.h.in:11350-11416;mem.c:6677-6689,6736-6770;mem.c:6872-6935,6998-7085,4525-4568,4390-4449;c_intf.c:1683-1711";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Strong termination includes pending/owned/private/ready/quarantined root and descendant obligations, separate weak generation and cleanup; empty queues or idle count alone not proof";
 attribute :>> failureCustodian="Round/task service retains pending debt; claimed/quarantined worker state and pinned root view remain accountable; return ticket never discharges debt; unknown transfer keeps prior custodian";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part returnGateRoute : GambitHostRootsRefinement::Route { ref part :>> need=returnGate;
 attribute :>> sourceAnchors="mem.c:6872-6935,6998-7085,4525-4568,4390-4449;c_intf.c:1683-1711;setup.c:1012-1149,1190-1209;setup.h:53-67";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="RootAck never implies ResumeSeal; weak continuation movement, cleanup, capacity/fudge/context preparation and synchronized result delivery complete before active permit and reload";
 attribute :>> failureCustodian="Round/task service retains pending debt; claimed/quarantined worker state and pinned root view remain accountable; return ticket never discharges debt; unknown transfer keeps prior custodian";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part waitGraphRoute : GambitHostRootsRefinement::Route { ref part :>> need=waitGraph;
 attribute :>> sourceAnchors="mem.c:6677-6689,6736-6770;mem.c:6872-6935,6998-7085,4525-4568,4390-4449;c_intf.c:1683-1711;setup.c:774-802,887-1003;os_thread.c:thread_join/exit";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Workers/coordinator never wait for the same return permit, metadata gate or owner-affine destructor needed by round completion; complete wait graph, finite producers, worker capacity and fairness remain source/progress duties";
 attribute :>> failureCustodian="Round/task service retains pending debt; claimed/quarantined worker state and pinned root view remain accountable; return ticket never discharges debt; unknown transfer keeps prior custodian";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="setup.c:1012-1149,1190-1209;setup.h:53-67;mem.c:3410-3463,6775-6805;mem.c:6813-6869;mem.c:3251-3307;mem.c:4323-4386;mem.c:6690-6733;mem.c:3578-3622,4192-4208,4235-4250,4252-4276;gambit.h.in:11350-11416;mem.c:6677-6689,6736-6770;mem.c:6872-6935,6998-7085,4525-4568,4390-4449;c_intf.c:1683-1711;setup.c:774-802,887-1003;os_thread.c:thread_join/exit";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Task publication, claim/attempt fencing, stable Ready result, stop/checkpoint transfer and whole-round seal use proved C happens-before and lifetime ordering; no volatile-only, timeout or machine-wrap qualification";
 attribute :>> failureCustodian="Round/task service retains pending debt; claimed/quarantined worker state and pinned root view remain accountable; return ticket never discharges debt; unknown transfer keeps prior custodian";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="sync-request-dispatch";
 attribute :>> sourceAnchors="setup.c:1012-1149,1190-1209;setup.h:53-67";
 attribute :>> actualChain="on_all_processors raises sync interrupt; service/execute loop arbitrates, executes and returns combined result";
 attribute :>> hazard="Calling-thread and processor-count barrier coupling; an admitted root queue is a proposed replacement, not existing C code";
 attribute :>> replacement="Separate round/participant service; preserve combining/result obligations";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="round-setup";
 attribute :>> sourceAnchors="mem.c:3410-3463,6775-6805";
 attribute :>> actualChain="setup flips spaces, resets per-processor queues/cursors and seeds strong/weak worker counts from processor count";
 attribute :>> hazard="Pool worker identity cannot replace context count or erase pending root debt";
 attribute :>> replacement="Snapshot context/view duties separately from worker team";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="direct-root-scan";
 attribute :>> sourceAnchors="mem.c:6813-6869";
 attribute :>> actualChain="strong phase directly calls mark_continuation/registers/saved/type-cache plus processor0 RC/VM roots, then transitive scan";
 attribute :>> hazard="Roots are not dequeued tasks today; removing owner participation requires explicit task publication";
 attribute :>> replacement="Enlist canonical root task before released-context acknowledgement transfer";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="chunk-publisher";
 attribute :>> sourceAnchors="mem.c:3251-3307";
 attribute :>> actualChain="end_heap_chunk publishes marker/link then FIFO tail and signals";
 attribute :>> hazard="Two ordered visibility cuts; signal is not acceptance or completion";
 attribute :>> replacement="Publish child credit/payload before parent Ready; retain source ownership on unknown acceptance";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="local-chunk-claim";
 attribute :>> sourceAnchors="mem.c:4323-4386";
 attribute :>> actualChain="local FIFO head advances under spinlock; lock released before scan_complete_heap_chunk";
 attribute :>> hazard="Dequeued payload exists only in private cursor/work context while queue may appear empty";
 attribute :>> replacement="Canonical owned record survives head advance; preserve pending cursor step";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="remote-chunk-steal";
 attribute :>> sourceAnchors="mem.c:6690-6733";
 attribute :>> actualChain="stealer locks source FIFO, advances head, unlocks then scans on receiving PSTATE";
 attribute :>> hazard="Steal changes owner but no persistent attempt/result or death recovery record";
 attribute :>> replacement="Task generation/claim receipt plus CollectorWorkContext adapter";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="private-copy-and-still-pop";
 attribute :>> sourceAnchors="mem.c:3578-3622,4192-4208,4235-4250,4252-4276;gambit.h.in:11350-11416";
 attribute :>> actualChain="forwarding CAS precedes payload copy; PAIR advances after mark_array; still work popped before scan; complete chunk cursor local";
 attribute :>> hazard="PC or stopped thread alone loses partial-copy, Tail and descendant responsibility";
 attribute :>> replacement="Full qualified checkpoint, source pins and stopped-writer transfer; otherwise quarantine";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="idle-termination";
 attribute :>> sourceAnchors="mem.c:6677-6689,6736-6770";
 attribute :>> actualChain="drain local still/movable, steal, decrement worker count, condition wait or zero termination";
 attribute :>> hazard="Idle count assumes no unrepresented producer/private task; worker removal is not debt cancellation";
 attribute :>> replacement="Close strong on full frontier; reserve service capacity; keep weak round separate";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="phase-to-resume";
 attribute :>> sourceAnchors="mem.c:6872-6935,6998-7085,4525-4568,4390-4449;c_intf.c:1683-1711";
 attribute :>> actualChain="weak processes wills and moves continuation; cleanup invokes foreign destructor; resize/fudge then prepare_mem_pstate";
 attribute :>> hazard="RootAck precedes later frame movement and owner-affine destructor may cycle with return";
 attribute :>> replacement="ResumeSeal includes current round/capacity/context state; qualify destructor or deferred custody before freeing";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="processor-exit-resize";
 attribute :>> sourceAnchors="setup.c:774-802,887-1003;os_thread.c:thread_join/exit";
 attribute :>> actualChain="returned Scheme thunk keeps servicing sync operations; resize shrink cleans/exits processors and processor0 joins ignoring error";
 attribute :>> hazard="Normal processor exit is outside active scan; join call/error suppression does not prove independent worker stop";
 attribute :>> replacement="Explicit role revocation and drain separate from OS join and PSTATE/root facility cleanup";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Pending responsibility";
 attribute :>> removedWork="Released native context need not execute its own root scan";
 attribute :>> bound="For K admitted released contexts: K root tasks remain; active ack targets N-K";
 attribute :>> addedCost="O(K) descriptors/phase credits; enqueue/claim/ack state transitions";
 attribute :>> condition="No removed root scan; existing roots are direct calls, so task layer is new work";
 }
 part cost1 : CostRow {
 attribute :>> capability="Lost delivery";
 attribute :>> removedWork="Query a stable claim/Ready record instead of repeating effects";
 attribute :>> bound="Zero additional scan writes for a query or duplicate acknowledgement";
 attribute :>> addedCost="Task/epoch/attempt directory and terminal result retention";
 attribute :>> condition="Only ready/quiescent result loss; unknown write progress cannot be replayed";
 }
 part cost2 : CostRow {
 attribute :>> capability="Cooperative worker exit";
 attribute :>> removedWork="Continue from a qualified checkpoint without rescanning known prefix";
 attribute :>> bound="Restore cost O(Scheckpoint); no hard time bound for drain";
 attribute :>> addedCost="Checkpoint copy-frame/cursor/child credits plus source and target pins";
 attribute :>> condition="Stop alone or unknown join lacks complete state; arbitrary owner death remains blocked";
 }
 part cost3 : CostRow {
 attribute :>> capability="Strong termination";
 attribute :>> removedWork="Prevent empty-queue or idle-count false completion";
 attribute :>> bound="Frontier covers pending+claimed+ready+quarantine+private+derived work; scan remains O(R+H)";
 attribute :>> addedCost="Full-frontier accounting and separate strong/weak phase generations";
 attribute :>> condition="Zero unsafe early completions is a correctness target, not a speedup";
 }
 part cost4 : CostRow {
 attribute :>> capability="Reentry arbitration";
 attribute :>> removedWork="Preserve owed late claims and avoid worker waiting on requester";
 attribute :>> bound="RootAck is earlier than whole-round ResumeSeal; no shortening below actual phase dependencies";
 attribute :>> addedCost="Ticket/cut arbitration, phase wait and protected O(U) reload";
 attribute :>> condition="No bound without finite producers, available worker and fair scheduling";
 }
 part cost5 : CostRow {
 attribute :>> capability="Foreign cleanup boundary";
 attribute :>> removedWork="Break cleanup-to-owner-return cycle only through qualified deferred custody";
 attribute :>> bound="Retain Hforeign physical backing until actual destructor/release completion";
 attribute :>> addedCost="Owner-affine dispatch, root/native payload transfer and release receipts";
 attribute :>> condition="Cannot omit destructor or free still shell on enqueue alone; unqualified path refuses release profile";
 }
 part cost6 : CostRow {
 attribute :>> capability="Peak memory";
 attribute :>> removedWork="Reuse task records and existing root/frame backing only after last use";
 attribute :>> bound="Peak=max_t(existing backing+task/checkpoint/receipt pools+pins+deferred native backing)";
 attribute :>> addedCost="Retained views, root banks, suspended frames and quarantine may extend peak";
 attribute :>> condition="Count backing once; O(K) records is not O(K) total retained heap; no peak decrease proved";
 }
 part cost7 : CostRow {
 attribute :>> capability="Modern C and Zig";
 attribute :>> removedWork="Scheme owns coverage/FrameSpec; modern C owns typed roles, ledgers and collector adapters";
 attribute :>> bound="Zero additional Zig runtime-work reduction established";
 attribute :>> addedCost="Both need source closure, attempt fencing, resume seals and memory-order evidence";
 attribute :>> condition="Language replacement cannot supply missing recovery state or remove GC phases";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="enlist"; attribute :>> labelText="Phase snapshot\\nenlist root/view duty"; }
 part node1 : DiagramNode { attribute :>> nodeId="ticket"; attribute :>> labelText="Return ticket\\nretain already-owed work"; }
 part node2 : DiagramNode { attribute :>> nodeId="pending"; attribute :>> labelText="Service-owned pending task\\nepoch + attempt generation"; }
 part node3 : DiagramNode { attribute :>> nodeId="owned"; attribute :>> labelText="Worker claim + private scan\\ncursor / copy frame / child credits"; }
 part node4 : DiagramNode { attribute :>> nodeId="ready"; attribute :>> labelText="Quiescent Ready record\\nroot acknowledgement"; }
 part node5 : DiagramNode { attribute :>> nodeId="drain"; attribute :>> labelText="Drain descendants / weak phase\\ncleanup + capacity + context prepare"; }
 part node6 : DiagramNode { attribute :>> nodeId="seal"; attribute :>> labelText="Whole-round ResumeSeal\\nactive permit then reload"; }
 part node7 : DiagramNode { attribute :>> nodeId="exit"; attribute :>> labelText="Stopped + complete checkpoint\\naccepted handoff; new generation"; }
 part node8 : DiagramNode { attribute :>> nodeId="unknown"; attribute :>> labelText="Unknown writer / transfer\\nretain debt; refuse phase close"; }
 part node9 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT\\nQNT / Lean / source-order gaps"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node2; attribute :>> labelText="publish duty before notification"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="late owed claim remains legal"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="claim under phase/task gate"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="publish children before Ready"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="RootAck alone cannot resume"; }
 part edge5 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="complete admitted round"; }
 part edge6 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node7; attribute :>> labelText="cooperative cut + source pins"; }
 part edge7 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node2; attribute :>> labelText="requeue exact continuation"; }
 part edge8 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node8; attribute :>> labelText="ambiguous progress or stop"; }
 part edge9 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node5; attribute :>> labelText="closure denied"; }
 part edge10 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node6; attribute :>> labelText="wait outside metadata gate"; }
 part edge11 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node6; attribute :>> labelText="conditional refinement only"; }
}
