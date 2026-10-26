/* Modern C design authority; no runtime implementation. */
package GambitWriterStopHandoff { private import ScalarValues::*;
part history:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="WS-H";
attribute :>> kind="interleaving";
attribute :>> subjectPath="models/gambit/writer_stop_handoff.qnt";
attribute :>> subjectScope="writer_stop_handoff:owner-two-successive-helpers-split-writes-and-cleanup;seed17";
attribute :>> premise="Three authority generations, split physical store/log, losing acquisition response, repeated helper exit and GC scan. Real cooperative/platform stop and root completeness are external witnesses; bounded histories are not native proof.";
}
part induction:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="WS-I";
attribute :>> kind="induction";
attribute :>> subjectPath="models/gambit/lean/WriterStopHandoff.lean";
attribute :>> subjectScope="GambitSMP.WriterStopHandoff:conditional-stop-generation-and-custody-laws";
attribute :>> premise="Selective conditional laws for per-generation closure, successor admission, root retention and unknown-result custody. Not complete transition induction/source simulation.";
}
part sfun:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="WS-SFUN";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/WriterStopHandoff.lean";
attribute :>> subjectScope="WS-SFUN:generated-conversion-and-marker-exit-funnel";
attribute :>> premise="Generate stable VM scope before marker allocation, root procedure first, and funnel SFUN conversions, result and propagation through exact activation cleanup; no untracked raw escape admitted.";
}
part cfun:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="WS-CFUN";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/WriterStopHandoff.lean";
attribute :>> subjectScope="WS-CFUN:cleanup-independent-generated-write-effects";
attribute :>> premise="Generate effect/borrow scope independently of conversion cleanup selection; close future entry and drain operations at safe exit, including inline and out-of-line conversion/error edges.";
}
part runDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="WS-RUN";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/WriterStopHandoff.lean";
attribute :>> subjectScope="WS-RUN:post-catcher-resident-journal-and-nested-unwind";
attribute :>> premise="call rethrow must carry stable journal to enclosing run/generated catch; restored catcher precedes no-throw close funnel; marker kill and result/root ownership settle separately; nested closure is per activation.";
}
part threadDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="WS-THREAD";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/WriterStopHandoff.lean";
attribute :>> subjectScope="WS-THREAD:actual-termination-and-complete-producer-census";
attribute :>> premise="PSTATE cleanup or thread_exit call is not termination; actual successful unique join plus runtime/helper/foreign-borrower census and callback debt settlement is required. Errors/unknown keep VM custody.";
}
part helperDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="WS-HELP";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/WriterStopHandoff.lean";
attribute :>> subjectScope="WS-HELP:repeated-helper-stop-and-bounded-lease-reuse";
attribute :>> premise="Successor requires previous helper generation control/data closure, no delayed operations or writers, exact lease and drained metadata readers; never reuse original owner receipt or replay root/native effects.";
}
part orderDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="WS-ORDER";
attribute :>> kind="native-memory-order";
attribute :>> subjectPath="models/gambit/lean/WriterStopHandoff.lean";
attribute :>> subjectScope="WS-ORDER:close-entry-drain-publish-and-acquire";
attribute :>> premise="Entry gate and in-flight acquisition must be one race-safe protocol; release close receipt follows actual stores, acquire exact generation precedes handoff. Plain field exclusivity and platform stop remain open.";
}
ref part priorStop=GambitOriginBindCommit::stopDuty;
ref part priorRoot=GambitOriginBindCommit::rootDuty;
ref part priorOrder=GambitOriginBindCommit::orderDuty;
part dependency0:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sfun; ref part :>> prerequisite=history; }
part dependency1:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sfun; ref part :>> prerequisite=induction; }
part dependency2:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cfun; ref part :>> prerequisite=history; }
part dependency3:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cfun; ref part :>> prerequisite=induction; }
part dependency4:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=runDuty; ref part :>> prerequisite=history; }
part dependency5:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=runDuty; ref part :>> prerequisite=induction; }
part dependency6:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=threadDuty; ref part :>> prerequisite=history; }
part dependency7:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=threadDuty; ref part :>> prerequisite=induction; }
part dependency8:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=helperDuty; ref part :>> prerequisite=history; }
part dependency9:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=helperDuty; ref part :>> prerequisite=induction; }
part dependency10:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=orderDuty; ref part :>> prerequisite=history; }
part dependency11:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=orderDuty; ref part :>> prerequisite=induction; }
part dependency12:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sfun; ref part :>> prerequisite=priorRoot; }
part dependency13:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=runDuty; ref part :>> prerequisite=sfun; }
part dependency14:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=runDuty; ref part :>> prerequisite=cfun; }
part dependency15:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=threadDuty; ref part :>> prerequisite=runDuty; }
part dependency16:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=helperDuty; ref part :>> prerequisite=priorStop; }
part dependency17:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=helperDuty; ref part :>> prerequisite=priorRoot; }
part dependency18:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=helperDuty; ref part :>> prerequisite=orderDuty; }
part dependency19:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=orderDuty; ref part :>> prerequisite=priorOrder; }
part def CallerRow {  attribute callerId:String; attribute sourceAnchors:String; attribute actualChain:String; attribute hazard:String; attribute replacement:String; }
part caller0:CallerRow { attribute :>> callerId="GENERATOR"; attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-2925,2940-3017,3238-3251"; attribute :>> actualChain="cleanup? depends on conversion types, not native write/escape effects"; attribute :>> hazard="Emit NativeActivationScope/ExitSpec for selected managed CFUN/SFUN regardless of cleanup?"; attribute :>> replacement="Unknown user C return/goto/longjmp stays unqualified"; }
part caller1:CallerRow { attribute :>> callerId="SFUN"; attribute :>> sourceAnchors="include/gambit.h.in:10043-10065;lib/c_intf.c:6511-6564"; attribute :>> actualChain="Marker allocation precedes arguments; kill and propagate on normal macro fallthrough"; attribute :>> hazard="Register/freeze procedure root before allocation; stable marker ownership and common close funnel"; attribute :>> replacement="Rethrow can bypass macro fallthrough; raw marker read/write must be inventoried"; }
part caller2:CallerRow { attribute :>> callerId="CALL-RUN"; attribute :>> sourceAnchors="lib/setup.c:3276-3423;include/gambit.h.in:9979-9988"; attribute :>> actualChain="call catches trampoline then may rethrow; run kill lies inside TRY"; attribute :>> hazard="Resident journal accessible after catcher restore; local call scope transfers on rethrow"; attribute :>> replacement="Do not infer completion from observing catcher or changed nonvolatile automatic locals"; }
part caller3:CallerRow { attribute :>> callerId="WORKER"; attribute :>> sourceAnchors="lib/setup.c:763-835,930-1001;lib/os_thread.c:546-590"; attribute :>> actualChain="Shrinking member cleans PSTATE then exits; processor0 ignores join error"; attribute :>> hazard="VM owns scopes before cleanup; supervisor verifies unique join and all producers"; attribute :>> replacement="Failed/unknown join or foreign destructor/helper retains custody"; }
part caller4:CallerRow { attribute :>> callerId="TWO-RUN-CALLERS"; attribute :>> sourceAnchors="lib/setup.c:763-810,6395-6440"; attribute :>> actualChain="Worker run followed by error delivery/sync loop; main run followed by process cleanup"; attribute :>> hazard="Wrap both root entry and post-run sync lifetime; reload rooted thunk after GC"; attribute :>> replacement="run return alone closes neither worker lifetime nor nested external callbacks"; }
part caller5:CallerRow { attribute :>> callerId="ROOT-CONSUMER"; attribute :>> sourceAnchors="lib/mem.c:3969-3988,4928-4964,6845-6858"; attribute :>> actualChain="RC scanner call only on processor0; cleanup releases per-PSTATE state"; attribute :>> hazard="Canonical VM root adapter and scan pin outlive failed owner/helper"; attribute :>> replacement="No managed nonzero processor admission until root-scan path is covered"; }
part def PathRow {  attribute pathId:String; attribute actualPath:String; attribute contract:String; attribute failure:String; attribute custodian:String; }
part path0:PathRow { attribute :>> pathId="COOPERATIVE"; attribute :>> actualPath="Generated SFUN/CFUN exit after all nested calls return"; attribute :>> contract="Close admissions, return/drain exact borrows, settle callback-created debt, restore catcher, publish data/control seals"; attribute :>> failure="Any unenumerated native escape or borrowed pointer prevents seal"; attribute :>> custodian="VM source/journal remains until canonical root/result ACK"; }
part path1:PathRow { attribute :>> pathId="CATCHER"; attribute :>> actualPath="call rethrow to run or generated outer catch"; attribute :>> contract="Post-catch noescape funnel uses resident scope, preserves original error and transfers unfinished cleanup"; attribute :>> failure="If cleanup can itself throw, make debt before calling it; no seal on nonreturn"; attribute :>> custodian="VM journal with original error/result and marker reference"; }
part path2:PathRow { attribute :>> pathId="THREAD"; attribute :>> actualPath="cleanup_pstate then pthread_exit; unique supervisor join"; attribute :>> contract="Detach all PSTATE borrowing before cleanup; actual termination plus producer census closes data/control authority"; attribute :>> failure="Join error/unknown or foreign helper/destructor unknown cannot be repaired by dead flag"; attribute :>> custodian="Resident VM scope and pinned source/slot; may block reclaim or GC if root not frozen"; }
part path3:PathRow { attribute :>> pathId="HELPER"; attribute :>> actualPath="Stopped owner then helper acquires exact generation"; attribute :>> contract="New helper is a new writer, including late acquisition response; repeat close/drain before successor"; attribute :>> failure="Original owner seal cannot close helper; failed helper has its own pending-store debt"; attribute :>> custodian="Single canonical lease/progress record, checked generation, no retry map"; }
part path4:PathRow { attribute :>> pathId="GC"; attribute :>> actualPath="Already registered frozen source across unknown metadata state"; attribute :>> contract="Collector scans old source independently of owner callback, then reload accepted current root"; attribute :>> failure="Unregistered/raw source or unknown data writer refuses independent scan"; attribute :>> custodian="Root domain holds scan pin; helper never rewrites relocated payload"; }
part def OrderRow {  attribute edgeId:String; attribute orderContract:String; attribute rejectedShortcut:String; }
part orderRow0:OrderRow { attribute :>> edgeId="ENTRY-CLOSE"; attribute :>> orderContract="Acquire writer gate/borrow atomically with close exclusion; close prevents future acquisitions and waits for existing permits"; attribute :>> rejectedShortcut="Separate open check then increment permits a writer after zero was observed"; }
part orderRow1:OrderRow { attribute :>> edgeId="STORE-LOG"; attribute :>> orderContract="Finish physical write before release-publishing its progress; interruption between them permits only exclusive idempotent private repair"; attribute :>> rejectedShortcut="A missing progress bit is not proof that a write did not occur"; }
part orderRow2:OrderRow { attribute :>> edgeId="SEAL"; attribute :>> orderContract="Publish generation-bound data/control seal only after no future authority and no in-flight stores/CAS/borrowers/debt"; attribute :>> rejectedShortcut="Catcher restoration, exit flag, counter increment or release fence alone is not a seal"; }
part orderRow3:OrderRow { attribute :>> edgeId="HELPER"; attribute :>> orderContract="Acquire prior exact-generation seals and no old metadata readers before checked generation transition"; attribute :>> rejectedShortcut="Old helper cannot write after successor publication; wrap/exhaustion refuses new authority"; }
part orderRow4:OrderRow { attribute :>> edgeId="ROOT"; attribute :>> orderContract="Separate GC root publication/update protocol from control repair; preserve source and scan pins through unresolved handoff"; attribute :>> rejectedShortcut="No reinitialization of GC-updated root from immutable but stale SCMOBJ intent"; }
part def CostRow {  attribute capability:String; attribute removedWork:String; attribute bound:String; attribute addedCost:String; attribute condition:String; }
part cost0:CostRow { attribute :>> capability="Generated effect/exit scope"; attribute :>> removedWork="Replace type-cleanup heuristic as safety criterion"; attribute :>> bound="One finite ExitSpec per admitted entry; zero runtime paths retired today"; attribute :>> addedCost="Entry/exit gate, stable journal, explicit borrow census"; attribute :>> condition="Benefit is complete nonlocal-exit coverage only if all admitted exits generated or refused"; }
part cost1:CostRow { attribute :>> capability="Repeated helper recovery"; attribute :>> removedWork="Avoid one permanent log per retry/helper"; attribute :>> bound="One live canonical lease per activation; g checked generation changes; O(1) resident history per activation"; attribute :>> addedCost="Each succession needs two exact seals plus reader drain; O(g) total handshake work"; attribute :>> condition="No progress guarantee when stop is unknown or generation space exhausted"; }
part cost2:CostRow { attribute :>> capability="GC decoupling"; attribute :>> removedWork="Zero owner callbacks needed for already frozen root view by contract"; attribute :>> bound="Root bytes shared with prior source lease, not counted twice"; attribute :>> addedCost="O(C) simple root-port/tag scan; overlap source/canonical root until ACK"; attribute :>> condition="Unknown raw writer can still block GC; no whole-heap speedup proven"; }
part cost3:CostRow { attribute :>> capability="Peak support"; attribute :>> removedWork="Avoid retry-count-scaled metadata retention"; attribute :>> bound="DeltaH = A*newScopeBytes + L*newLeaseBytes + R*newReceiptBytes + pinnedBacking; embedded prior fields subtracted"; attribute :>> addedCost="Pinned frames, marker/still backing, raw resources can dominate and remain unbounded by this protocol"; attribute :>> condition="Peak falls only when eliminated history/backing exceeds added support plus overlap; no measured byte figure"; }
part cost4:CostRow { attribute :>> capability="Marker settlement"; attribute :>> removedWork="At most one physical clear/refcount decrement per exact activation"; attribute :>> bound="One tracked marker disposition; clear and decrement are separate effect obligations"; attribute :>> addedCost="Partial clear/decrement outcome cannot be replayed speculatively"; attribute :>> condition="Needs separate idempotent/receipt adapter; helper must not rerun native destructor or Scheme code"; }
part cost5:CostRow { attribute :>> capability="Language choice"; attribute :>> removedWork="One modern C contract shared by generator/runtime/formal projection"; attribute :>> bound="No second Zig runtime required for this cut"; attribute :>> addedCost="C atomics/layout/source and platform stop evidence remain necessary"; attribute :>> condition="Zig optional only after incremental benefits beat toolchain/ABI/duplicate support cost; no such net gain proved"; }
part def ImplementationStep {  attribute stepId:String; attribute status:String; attribute files:String; attribute change:String; attribute dependencies:String; attribute acceptance:String; attribute rollback:String; }
part impl0:ImplementationStep { attribute :>> stepId="MC-SCOPE"; attribute :>> status="PLANNED"; attribute :>> files="include/gambit.h.in;lib/setup.c"; attribute :>> change="VM-resident bounded NativeActivationScope/WriterLease/ExitSpec, explicit gate, exact generation and terminal outcome; no Scheme evaluation during repair"; attribute :>> dependencies="RootRegistry and prior OB-FIRST/OB-ROOT remain prerequisites; no raw-marker switch yet"; attribute :>> acceptance="Schema/layout bounds and failure custody reviewed; all new scope slots safe empty before exposure"; attribute :>> rollback="No active managed callers; remove unused fields only after no live readers"; }
part impl1:ImplementationStep { attribute :>> stepId="MC-GENERATE"; attribute :>> status="PLANNED"; attribute :>> files="gsc/_ptree2.scm;c-lambda/c-define generation"; attribute :>> change="Emit effect and exit scopes independent of cleanup?; enumerate conversions, early returns and nonlocal error edges"; attribute :>> dependencies="MC-SCOPE; WS-CFUN; WS-SFUN"; attribute :>> acceptance="Generator fixtures show every admitted exit; raw unknown C escape explicitly rejected"; attribute :>> rollback="Keep whole selected entry on old path until connected adapter qualifies"; }
part impl2:ImplementationStep { attribute :>> stepId="MC-ROOT"; attribute :>> status="BLOCKED-SOURCE"; attribute :>> files="lib/c_intf.c;lib/mem.c;include/gambit.h.in"; attribute :>> change="RootHandle before make_sfun_stack_marker allocation; canonical VM scan adapter on every processor; exact marker disposition"; attribute :>> dependencies="MC-GENERATE; OB-ROOT; nonzero processor RC scan closure"; attribute :>> acceptance="Root remains updateable across allocation/GC; no unrooted proc_or_false window"; attribute :>> rollback="Do not admit managed entry without complete source; preserve old caller root"; }
part impl3:ImplementationStep { attribute :>> stepId="MC-CATCH"; attribute :>> status="PLANNED"; attribute :>> files="lib/setup.c:___call/___run/___propagate_error;include/gambit.h.in"; attribute :>> change="Common post-catcher noescape close/transfer funnel; preserve original exception/result; both run callers scoped"; attribute :>> dependencies="MC-ROOT; WS-RUN; generated SFUN/CFUN exits"; attribute :>> acceptance="Nested escapes, marker-allocation failure, skipped normal kill and cleanup nonreturn retain exactly one custodian"; attribute :>> rollback="Disable selected connected entry before ABI removal; never free live scope"; }
part impl4:ImplementationStep { attribute :>> stepId="MC-HELP"; attribute :>> status="BLOCKED-C-MEMORY"; attribute :>> files="lib/setup.c;future internal scope service"; attribute :>> change="Close admission/drain permit protocol; per-helper exact generation seals; bounded canonical lease and query after lost return"; attribute :>> dependencies="MC-CATCH; WS-HELP; WS-ORDER"; attribute :>> acceptance="No delayed old store/CAS reaches successor; exhaustion refuses; result unknown query never re-evaluates Scheme"; attribute :>> rollback="Retain VM journal/source for unknown stop; no blind force-unlock"; }
part impl5:ImplementationStep { attribute :>> stepId="MC-THREAD"; attribute :>> status="BLOCKED-SOURCE"; attribute :>> files="lib/setup.c:resize/start_processor_execution;lib/os_thread.c"; attribute :>> change="VM custody before PSTATE cleanup; rooted startup descriptors; typed join/create outcomes and complete producer census"; attribute :>> dependencies="MC-HELP; WS-THREAD; GC membership/root admission gates"; attribute :>> acceptance="Partial create failure and failed/unknown join preserve resources; no member freed on unverified exit"; attribute :>> rollback="Shrink cannot destroy live source or scan facilities; quarantine unresolved member"; }
part impl6:ImplementationStep { attribute :>> stepId="MC-SELECT"; attribute :>> status="PLANNED"; attribute :>> files="lib/_kernel.scm:current-vm-resize;generated lib/_kernel.c;two run callers"; attribute :>> change="Switch one connected resize/start/entry/exit service using generated typed source references and stable identity"; attribute :>> dependencies="MC-THREAD and all source/C/native gates for selected slice"; attribute :>> acceptance="Future authorized bootstrap, GCC/Darwin compiler, nested FFI, GC and SMP acceptance pass; tracked generated C refreshed from exact source"; attribute :>> rollback="One slice switches as a unit; no indefinitely co-maintained competing ownership system"; }
part impl7:ImplementationStep { attribute :>> stepId="MC-RETIRE"; attribute :>> status="BLOCKED-ACCEPTANCE"; attribute :>> files="gsc/_ptree2.scm;include/gambit.h.in;lib/c_intf.c;lib/setup.c"; attribute :>> change="Retire selected raw thunk handoff, marker-only lifetime, cleanup?-only scope selection, ignored join and PSTATE-only journal"; attribute :>> dependencies="MC-SELECT with full caller inventory and native acceptance"; attribute :>> acceptance="No selected consumer uses removed macros/implicit ownership; old paths for unaudited FFI stay explicitly outside managed profile"; attribute :>> rollback="No retirement claimed by design/QNT/Lean alone"; }
part def Transition { ref part need:GambitAssuranceRouting::ModelNeed; attribute fromPhase:String; attribute toPhase:String; attribute qntStep:String; attribute guardContract:String; attribute leanLaw:String; attribute sourceAnchors:String; }
part transition0:Transition { ref part :>> need=cfun; attribute :>> fromPhase="Open"; attribute :>> toPhase="Closing"; attribute :>> qntStep="closeEntry"; attribute :>> guardContract="No new borrow after close wins; existing permit retains responsibility"; attribute :>> leanLaw="openGateNeeded"; attribute :>> sourceAnchors="_ptree2.scm:2902-2925"; }
part transition1:Transition { ref part :>> need=runDuty; attribute :>> fromPhase="Closing"; attribute :>> toPhase="FunnelDrained"; attribute :>> qntStep="finishFunnel / settleCleanup"; attribute :>> guardContract="Catcher restored, exact frame unwound, callback debt accounted before seal"; attribute :>> leanLaw="cleanupDebtBlocksSeal"; attribute :>> sourceAnchors="setup.c:3276-3423"; }
part transition2:Transition { ref part :>> need=threadDuty; attribute :>> fromPhase="Closing"; attribute :>> toPhase="ThreadStopped"; attribute :>> qntStep="joinSuccess / closeCensus"; attribute :>> guardContract="Successful unique join and complete producer/helper census; external stop witness"; attribute :>> leanLaw="exitObservationInsufficient"; attribute :>> sourceAnchors="os_thread.c:546-590;setup.c:930-971"; }
part transition3:Transition { ref part :>> need=helperDuty; attribute :>> fromPhase="StoppedGeneration"; attribute :>> toPhase="SuccessorOwns"; attribute :>> qntStep="handoff"; attribute :>> guardContract="Both seals bind exact generation, no in-flight writes/readers; finite generation not exhausted"; attribute :>> leanLaw="oldSealCannotAuthorizeNewHelper"; attribute :>> sourceAnchors="proposed scope service"; }
part transition4:Transition { ref part :>> need=helperDuty; attribute :>> fromPhase="HelperInterrupted"; attribute :>> toPhase="ClosingAgain"; attribute :>> qntStep="observeExit / closeEntry"; attribute :>> guardContract="Helper is a full new producer; preserve progress and same canonical source"; attribute :>> leanLaw="unknownStopRetainsCustody"; attribute :>> sourceAnchors="proposed scope service"; }
part transition5:Transition { ref part :>> need=helperDuty; attribute :>> fromPhase="PrivateStorePending"; attribute :>> toPhase="ProgressSettled"; attribute :>> qntStep="store / logStore / drainWrite"; attribute :>> guardContract="Unlogged physical write repaired only exclusively and idempotently"; attribute :>> leanLaw="repairPreservesRoot"; attribute :>> sourceAnchors="gambit.h.in:10325-10404"; }
part transition6:Transition { ref part :>> need=runDuty; attribute :>> fromPhase="CommittedOrAborted"; attribute :>> toPhase="Reclaimable"; attribute :>> qntStep="ack / release"; attribute :>> guardContract="Exact result settlement, both seals, scanner/readers drained, source no longer needed"; attribute :>> leanLaw="unknownResultBlocksRelease"; attribute :>> sourceAnchors="c_intf.c:6550-6564;mem.c:4928-4964"; }
part def SourceRoute { ref part need:GambitAssuranceRouting::ModelNeed; attribute sourceAnchors:String; attribute projection:String; attribute failureCustodian:String; attribute status:String; }
part route0:SourceRoute { ref part :>> need=sfun; attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-2925,2940-3017,3238-3251; include/gambit.h.in:10043-10065;lib/c_intf.c:6511-6564; lib/setup.c:3276-3423;include/gambit.h.in:9979-9988; lib/setup.c:763-835,930-1001;lib/os_thread.c:546-590; lib/setup.c:763-810,6395-6440; lib/mem.c:3969-3988,4928-4964,6845-6858"; attribute :>> projection="Generate stable VM scope before marker allocation, root procedure first, and funnel SFUN conversions, result and propagation through exact activation cleanup; no untracked raw escape admitted."; attribute :>> failureCustodian="Resident VM journal/source/exact slot lease; unknown stop refuses reclaim"; attribute :>> status="OPEN: source/C refinement"; }
part route1:SourceRoute { ref part :>> need=cfun; attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-2925,2940-3017,3238-3251; include/gambit.h.in:10043-10065;lib/c_intf.c:6511-6564; lib/setup.c:3276-3423;include/gambit.h.in:9979-9988; lib/setup.c:763-835,930-1001;lib/os_thread.c:546-590; lib/setup.c:763-810,6395-6440; lib/mem.c:3969-3988,4928-4964,6845-6858"; attribute :>> projection="Generate effect/borrow scope independently of conversion cleanup selection; close future entry and drain operations at safe exit, including inline and out-of-line conversion/error edges."; attribute :>> failureCustodian="Resident VM journal/source/exact slot lease; unknown stop refuses reclaim"; attribute :>> status="OPEN: source/C refinement"; }
part route2:SourceRoute { ref part :>> need=runDuty; attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-2925,2940-3017,3238-3251; include/gambit.h.in:10043-10065;lib/c_intf.c:6511-6564; lib/setup.c:3276-3423;include/gambit.h.in:9979-9988; lib/setup.c:763-835,930-1001;lib/os_thread.c:546-590; lib/setup.c:763-810,6395-6440; lib/mem.c:3969-3988,4928-4964,6845-6858"; attribute :>> projection="call rethrow must carry stable journal to enclosing run/generated catch; restored catcher precedes no-throw close funnel; marker kill and result/root ownership settle separately; nested closure is per activation."; attribute :>> failureCustodian="Resident VM journal/source/exact slot lease; unknown stop refuses reclaim"; attribute :>> status="OPEN: source/C refinement"; }
part route3:SourceRoute { ref part :>> need=threadDuty; attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-2925,2940-3017,3238-3251; include/gambit.h.in:10043-10065;lib/c_intf.c:6511-6564; lib/setup.c:3276-3423;include/gambit.h.in:9979-9988; lib/setup.c:763-835,930-1001;lib/os_thread.c:546-590; lib/setup.c:763-810,6395-6440; lib/mem.c:3969-3988,4928-4964,6845-6858"; attribute :>> projection="PSTATE cleanup or thread_exit call is not termination; actual successful unique join plus runtime/helper/foreign-borrower census and callback debt settlement is required. Errors/unknown keep VM custody."; attribute :>> failureCustodian="Resident VM journal/source/exact slot lease; unknown stop refuses reclaim"; attribute :>> status="OPEN: source/C refinement"; }
part route4:SourceRoute { ref part :>> need=helperDuty; attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-2925,2940-3017,3238-3251; include/gambit.h.in:10043-10065;lib/c_intf.c:6511-6564; lib/setup.c:3276-3423;include/gambit.h.in:9979-9988; lib/setup.c:763-835,930-1001;lib/os_thread.c:546-590; lib/setup.c:763-810,6395-6440; lib/mem.c:3969-3988,4928-4964,6845-6858"; attribute :>> projection="Successor requires previous helper generation control/data closure, no delayed operations or writers, exact lease and drained metadata readers; never reuse original owner receipt or replay root/native effects."; attribute :>> failureCustodian="Resident VM journal/source/exact slot lease; unknown stop refuses reclaim"; attribute :>> status="OPEN: source/C refinement"; }
part route5:SourceRoute { ref part :>> need=orderDuty; attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-2925,2940-3017,3238-3251; include/gambit.h.in:10043-10065;lib/c_intf.c:6511-6564; lib/setup.c:3276-3423;include/gambit.h.in:9979-9988; lib/setup.c:763-835,930-1001;lib/os_thread.c:546-590; lib/setup.c:763-810,6395-6440; lib/mem.c:3969-3988,4928-4964,6845-6858"; attribute :>> projection="Entry gate and in-flight acquisition must be one race-safe protocol; release close receipt follows actual stores, acquire exact generation precedes handoff. Plain field exclusivity and platform stop remain open."; attribute :>> failureCustodian="Resident VM journal/source/exact slot lease; unknown stop refuses reclaim"; attribute :>> status="OPEN: source/C refinement"; }
part def DiagramNode {  attribute nodeId:String; attribute labelText:String; }
part node0:DiagramNode { attribute :>> nodeId="source"; attribute :>> labelText="Registered frozen source and VM journal"; }
part node1:DiagramNode { attribute :>> nodeId="entry"; attribute :>> labelText="Race-safe writer admission"; }
part node2:DiagramNode { attribute :>> nodeId="store"; attribute :>> labelText="Physical write may precede progress"; }
part node3:DiagramNode { attribute :>> nodeId="close"; attribute :>> labelText="Close future data and control authority"; }
part node4:DiagramNode { attribute :>> nodeId="funnel"; attribute :>> labelText="Generated post-catcher exit and debt drain"; }
part node5:DiagramNode { attribute :>> nodeId="stop"; attribute :>> labelText="Exact generation data/control seals"; }
part node6:DiagramNode { attribute :>> nodeId="helper"; attribute :>> labelText="New helper generation; same canonical journal"; }
part node7:DiagramNode { attribute :>> nodeId="unknown"; attribute :>> labelText="Unknown stop: retain VM custody"; }
part node8:DiagramNode { attribute :>> nodeId="gc"; attribute :>> labelText="Independent scan of frozen source"; }
part node9:DiagramNode { attribute :>> nodeId="reclaim"; attribute :>> labelText="Result ACK and all readers drained"; }
part node10:DiagramNode { attribute :>> nodeId="plan"; attribute :>> labelText="modern-c source implementation action board"; }
part def DiagramEdge { ref part producer:DiagramNode; ref part consumer:DiagramNode; attribute labelText:String; }
part edge0:DiagramEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="roots precede native effect"; }
part edge1:DiagramEdge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="permit owns in-flight store"; }
part edge2:DiagramEdge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="exit may interrupt again"; }
part edge3:DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="cooperative qualified route"; }
part edge4:DiagramEdge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="actual no-future and no-inflight"; }
part edge5:DiagramEdge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="acquire exact seals before successor"; }
part edge6:DiagramEdge { ref part :>> producer=node6; ref part :>> consumer=node2; attribute :>> labelText="helper can itself be interrupted"; }
part edge7:DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node7; attribute :>> labelText="unverified stop or raw borrower"; }
part edge8:DiagramEdge { ref part :>> producer=node7; ref part :>> consumer=node0; attribute :>> labelText="preserve root slot and journal"; }
part edge9:DiagramEdge { ref part :>> producer=node0; ref part :>> consumer=node8; attribute :>> labelText="no callback needed if frozen"; }
part edge10:DiagramEdge { ref part :>> producer=node5; ref part :>> consumer=node9; attribute :>> labelText="separate result and scan settlement"; }
part edge11:DiagramEdge { ref part :>> producer=node8; ref part :>> consumer=node9; attribute :>> labelText="scan pin must drain"; }
part edge12:DiagramEdge { ref part :>> producer=node10; ref part :>> consumer=node4; attribute :>> labelText="generator catcher thread patch chain"; }
part def ResearchGate { attribute gateId:String; }
part def GateNeed { ref part gate:ResearchGate; ref part need:GambitAssuranceRouting::ModelNeed; }
part gateRow0:ResearchGate { attribute :>> gateId="generated-exit"; }
part gateNeed0:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=sfun; }
part gateNeed1:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=cfun; }
part gateNeed2:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=runDuty; }
part gateNeed3:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=priorRoot; }
part gateRow1:ResearchGate { attribute :>> gateId="repeat-helper"; }
part gateNeed4:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=helperDuty; }
part gateNeed5:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=orderDuty; }
part gateNeed6:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=priorStop; }
part gateNeed7:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=priorOrder; }
part gateRow2:ResearchGate { attribute :>> gateId="first-source-cut"; }
part gateNeed8:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=sfun; }
part gateNeed9:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=cfun; }
part gateNeed10:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=runDuty; }
part gateNeed11:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=threadDuty; }
part gateNeed12:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=helperDuty; }
part gateNeed13:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=orderDuty; }
part gateNeed14:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=priorStop; }
part gateNeed15:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=priorRoot; }
part gateNeed16:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=priorOrder; }
part def ClosureCut { attribute generation:Integer; attribute receiptGeneration:Integer; attribute dataClosed:Boolean; attribute controlClosed:Boolean; attribute dataInFlight:Boolean; attribute controlInFlight:Boolean; attribute producerCensus:Boolean; attribute readerPins:Integer; attribute rootFrozen:Boolean; attribute canHelp:Boolean=generation==receiptGeneration and dataClosed and controlClosed and not dataInFlight and not controlInFlight and producerCensus and readerPins==0; attribute canScanFrozen:Boolean=rootFrozen; }
part ownerExit:ClosureCut { attribute :>> generation=0; attribute :>> receiptGeneration=-1; attribute :>> dataClosed=false; attribute :>> controlClosed=false; attribute :>> dataInFlight=false; attribute :>> controlInFlight=false; attribute :>> producerCensus=false; attribute :>> readerPins=0; attribute :>> rootFrozen=true; }
part dataOnly:ClosureCut { attribute :>> generation=0; attribute :>> receiptGeneration=0; attribute :>> dataClosed=true; attribute :>> controlClosed=false; attribute :>> dataInFlight=false; attribute :>> controlInFlight=true; attribute :>> producerCensus=true; attribute :>> readerPins=0; attribute :>> rootFrozen=true; }
part bothStopped:ClosureCut { attribute :>> generation=0; attribute :>> receiptGeneration=0; attribute :>> dataClosed=true; attribute :>> controlClosed=true; attribute :>> dataInFlight=false; attribute :>> controlInFlight=false; attribute :>> producerCensus=true; attribute :>> readerPins=0; attribute :>> rootFrozen=true; }
part staleOwnerSeal:ClosureCut { attribute :>> generation=1; attribute :>> receiptGeneration=0; attribute :>> dataClosed=true; attribute :>> controlClosed=true; attribute :>> dataInFlight=false; attribute :>> controlInFlight=false; attribute :>> producerCensus=true; attribute :>> readerPins=0; attribute :>> rootFrozen=true; }
part helperStorePending:ClosureCut { attribute :>> generation=1; attribute :>> receiptGeneration=1; attribute :>> dataClosed=true; attribute :>> controlClosed=true; attribute :>> dataInFlight=true; attribute :>> controlInFlight=false; attribute :>> producerCensus=true; attribute :>> readerPins=0; attribute :>> rootFrozen=true; }
part helperStopped:ClosureCut { attribute :>> generation=1; attribute :>> receiptGeneration=1; attribute :>> dataClosed=true; attribute :>> controlClosed=true; attribute :>> dataInFlight=false; attribute :>> controlInFlight=false; attribute :>> producerCensus=true; attribute :>> readerPins=0; attribute :>> rootFrozen=true; }
part unknownRoot:ClosureCut { attribute :>> generation=1; attribute :>> receiptGeneration=-1; attribute :>> dataClosed=false; attribute :>> controlClosed=false; attribute :>> dataInFlight=false; attribute :>> controlInFlight=false; attribute :>> producerCensus=false; attribute :>> readerPins=1; attribute :>> rootFrozen=false; }
part def ImplementationNeed { ref part step:ImplementationStep; ref part need:GambitAssuranceRouting::ModelNeed; }
part implementationNeed0:ImplementationNeed { ref part :>> step=impl0; ref part :>> need=history; }
part implementationNeed1:ImplementationNeed { ref part :>> step=impl0; ref part :>> need=induction; }
part implementationNeed2:ImplementationNeed { ref part :>> step=impl0; ref part :>> need=priorRoot; }
part implementationNeed3:ImplementationNeed { ref part :>> step=impl1; ref part :>> need=cfun; }
part implementationNeed4:ImplementationNeed { ref part :>> step=impl1; ref part :>> need=sfun; }
part implementationNeed5:ImplementationNeed { ref part :>> step=impl2; ref part :>> need=sfun; }
part implementationNeed6:ImplementationNeed { ref part :>> step=impl2; ref part :>> need=priorRoot; }
part implementationNeed7:ImplementationNeed { ref part :>> step=impl3; ref part :>> need=runDuty; }
part implementationNeed8:ImplementationNeed { ref part :>> step=impl3; ref part :>> need=sfun; }
part implementationNeed9:ImplementationNeed { ref part :>> step=impl3; ref part :>> need=cfun; }
part implementationNeed10:ImplementationNeed { ref part :>> step=impl4; ref part :>> need=helperDuty; }
part implementationNeed11:ImplementationNeed { ref part :>> step=impl4; ref part :>> need=orderDuty; }
part implementationNeed12:ImplementationNeed { ref part :>> step=impl4; ref part :>> need=priorStop; }
part implementationNeed13:ImplementationNeed { ref part :>> step=impl5; ref part :>> need=threadDuty; }
part implementationNeed14:ImplementationNeed { ref part :>> step=impl5; ref part :>> need=priorRoot; }
part implementationNeed15:ImplementationNeed { ref part :>> step=impl6; ref part :>> need=runDuty; }
part implementationNeed16:ImplementationNeed { ref part :>> step=impl6; ref part :>> need=threadDuty; }
part implementationNeed17:ImplementationNeed { ref part :>> step=impl6; ref part :>> need=helperDuty; }
part implementationNeed18:ImplementationNeed { ref part :>> step=impl6; ref part :>> need=orderDuty; }
part implementationNeed19:ImplementationNeed { ref part :>> step=impl6; ref part :>> need=priorRoot; }
part implementationNeed20:ImplementationNeed { ref part :>> step=impl7; ref part :>> need=sfun; }
part implementationNeed21:ImplementationNeed { ref part :>> step=impl7; ref part :>> need=cfun; }
part implementationNeed22:ImplementationNeed { ref part :>> step=impl7; ref part :>> need=runDuty; }
part implementationNeed23:ImplementationNeed { ref part :>> step=impl7; ref part :>> need=threadDuty; }
part implementationNeed24:ImplementationNeed { ref part :>> step=impl7; ref part :>> need=helperDuty; }
part implementationNeed25:ImplementationNeed { ref part :>> step=impl7; ref part :>> need=orderDuty; }
}
