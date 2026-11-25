/* Model-owned source-sites/roots declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpRootSources {
 private import GambitSharedHeapSmp::*;

 part packetRcFrozenChainLease:SourceSite {
  attribute :>> id="packetRcFrozenChainLease";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-roots.inc";
  attribute :>> anchor="___HIDDEN ___BOOL mark_rc";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="mark_rc holds the RC source gate from CLAIMED validation through the complete header-list traversal and both mark_array calls per node, then publishes SCANNED. This currently protects the next pointers and node storage, not just task metadata.";
  attribute :>> required="Before shortening the metadata critical section, establish a whole-round frozen topology/node lease: registration and payload rebinding remain closed, release can drop logical counts but cannot unlink/free a traversable node, and scan/observer/round pins cover all last users. Scan outside the gate only under that lease; deferred byte unlink/free drains after known restored/refused closure and reader drain.";
  attribute :>> gap="The existing task scan lease and FROZEN flag do not by themselves change release_rc's unlink policy. Removing the scan lock without updating every unlink/free and list-reader path creates a dangling iterator; no native safety claim is made.";
  ref part :>> question=cutSource;
 }
 part packetRcUnlinkGuard:SourceSite {
  attribute :>> id="packetRcUnlinkGuard";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="___HIDDEN ___BOOL rc_unlink_if_dead";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="rc_unlink_if_dead currently tests refcount and root_borrows only. release_rc/return_rc_root may unlink under the source gate and free outside it; cleanup_rc may free the round and idle activation after rc_can_close.";
  attribute :>> required="Add frozen-view and short-reader/retained-install last-use guards to physical unlink, domain destruction and cleanup. Zero reference count is logical release, not node retirement while a frozen iterator or source observer still exists. Failed/unknown stop retains node/domain/gate; known pre-copy refusal and successful restored closure have explicit deferred-drain endpoints.";
  attribute :>> gap="No implemented frozen-topology or query-pin guard exists. All release/addref/borrow-return, owner detach and cleanup callers must be audited together; an atomic refcount alone cannot supply that lifetime proof.";
  ref part :>> question=cutSource;
 }
 part packetGlobalTaskGuard:SourceSite {
  attribute :>> id="packetGlobalTaskGuard";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___BOOL ___root_task_finish_globals";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="Global finish currently changes task DONE/scan_leases and snapshot shard under the global gate. Global claim/completed and several confined task validators use plain fields. root_round_finish_scan checks RC under member gates but reads other task states after the collective; round refusal also rewrites tasks and shards.";
  attribute :>> required="Use global-before-source order where global finish needs both; source observers never request global while holding source metadata. Treat shard completion and task completion as related but separately guarded facts; global end still requires every shard. Cover init/publish/claim/scan/finish/completed, round join/end/refusal and restore validation, not only the common state helper.";
  attribute :>> gap="Current collective confinement is not arbitrary observer safety; no existing whole read/write gate inventory or cross-record atomic snapshot is established. Source locking added only to query would still race ordinary writers.";
  ref part :>> question=cutSource;
 }

 part packetTaskMetadataGuard:SourceSite {
  attribute :>> id="packetTaskMetadataGuard";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___HIDDEN ___BOOL root_task_claim_state";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="Common task-state helpers update ordinary state/lease fields. RC operations wrap them in the source gate, while several confined VM/bank/stack/global operations use stopped-collective or registry exclusion. There is no universal observer gate implied by an RC lock.";
  attribute :>> required="Bind every observed task to its source metadata owner and route all matching readers/writers through the same guard. RC/member tasks reuse the source RC gate; VM/symkey/round facts use coordinator ownership. Keep global-before-source lock order when both are required; release before root traversal, callback, allocation and phase barriers.";
  attribute :>> gap="The selected source-role query needs an actual writer-side synchronization retrofit and source pin/reuse lifetime, not just a read helper. Standalone confined p1 tasks without published metadata ownership remain worker-local, outside source observation.";
  ref part :>> question=cutSource;
 }

 part rootEpoch:SourceSite {
  attribute :>> id="rootEpoch";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___BOOL ___root_round_freeze(";
  attribute :>> role="freeze";
  attribute :>> observed="RC gate checks owner/context/round identity, closes binding access and publishes a single scan lease";
  attribute :>> required="Final mutator store happens-before frozen publication; complete writer coverage and stopped root views precede collector writes";
  attribute :>> gap="Cooperative closure and joined-round identity are source premises, not proof every raw/native writer participates";
  ref part :>> question=cutSource;
 }
 part rcBorrow:SourceSite {
  attribute :>> id="rcBorrow";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="const ___SCMOBJ *___borrow_rc_root(";
  attribute :>> role="borrow";
  attribute :>> observed="Returns address of managed payload and counts borrows under RC mutex; setter rejects changed borrowed payload";
  attribute :>> required="Reload slot after every allocating/reentrant boundary; park or close data access while collector may update slot; drain pins before reclamation";
  attribute :>> gap="Borrow counter protects lifetime, not an unsynchronized raw read during GC; freeze does not itself prove borrower quiescence";
  ref part :>> question=cutSource;
 }
 part rootEnd:SourceSite {
  attribute :>> id="rootEnd";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___BOOL ___root_round_end(";
  attribute :>> role="retirement";
  attribute :>> observed="Scan finish enters DRAINING; end checks restored source identities then clears joined_round and re-admits bindings";
  attribute :>> required="Copy/scan closure, weak/sweep/capacity and context restore precede new writer permits; owner-affine effects remain separately retained";
  attribute :>> gap="Root task DONE is not whole-round or native-resource retirement; same-heap unknown writer cannot be waived";
  ref part :>> question=cutSource;
 }
 part minorBorrow:SourceSite {
  attribute :>> id="minorBorrow";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="const ___SCMOBJ *___borrow_rc_root";
  attribute :>> role="minor-admission";
  attribute :>> observed="Registered RC root borrowing supplies fixture reachability and distinct native access lifetime.";
  attribute :>> required="Close raw movable borrow and reload relocated canonical handles; retain UNKNOWN custody until last access is disproved. Unknown reachable writer blocks any moving collection.";
  attribute :>> gap="Exercise wrong VM, nested exception, late write and ACK loss with exact source and target coverage.";
  ref part :>> question=boundarySource;
 }
 part minorWorkerStride:SourceSite {
  attribute :>> id="minorWorkerStride";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="id+=round->collection.worker_count";
  attribute :>> role="minor-admission";
  attribute :>> observed="Active workers stride the sealed R sources by W; local DONE does not retire the source.";
  attribute :>> required="Join every source before weak work, then publish repaired slots and residual bank before thaw.";
  attribute :>> gap="At R=3,W=2 place the sole edge in source 2, delay closure and verify it survives another epoch without a store; keep major control.";
  ref part :>> question=nativeAcceptance;
 }
 part minorWeakSettlement:SourceSite {
  attribute :>> id="minorWeakSettlement";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="if (!___root_globals_end(&round->globals,ps)) return 0;";
  attribute :>> role="minor-admission";
  attribute :>> observed="Processor 0 joins DONE and zero leases, retires the globals snapshot and publishes DRAINING; weak entry has no separate acquire.";
  attribute :>> required="Separate strong work completion from root settlement, weak completion and later resume permission.";
  attribute :>> gap="Check source 2 at R=3,W=2; preserve a distinct full route and verify no early source reuse.";
  ref part :>> question=nativeAcceptance;
 }
 part minorNextBank:SourceSite {
  attribute :>> id="minorNextBank";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="round->state==___ROOT_ROUND_DRAINING && round->epoch==epoch";
  attribute :>> role="minor-admission";
  attribute :>> observed="RC reopen consumes DRAINING and context restoration; hash cleanup follows internal restoration in the caller.";
  attribute :>> required="Publish typed residual records after final repair and cleanup, before owner reopen. Acquire completion and publish one next-bank revision; retain on UNKNOWN.";
  attribute :>> gap="Replay real generated writes and FFI park/reload with no new target store across two rounds, omitted rearm, overflow and delayed commit.";
  ref part :>> question=nativeAcceptance;
 }
 part minorTableBankReader:SourceSite {
  attribute :>> id="minorTableBankReader";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="id+=round->collection.worker_count";
  attribute :>> role="minor-admission";
  attribute :>> observed="The existing strided root scan distinguishes non-worker sources from executors; no revisioned bank reader custody exists here.";
  attribute :>> required="Acquire successor bank and layout lease; mismatch routes to current typed coverage. Query lost reader ACK before reuse.";
  attribute :>> gap="R=3 W=2 with lost ACK, layout reorder, no subsequent target store and next-round strong survival and weak deletion.";
  ref part :>> question=nativeAcceptance;
 }

 part minorSuccessorClaim:SourceSite {
  attribute :>> id="minorSuccessorClaim";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___HIDDEN ___BOOL root_task_claim_state";
  attribute :>> role="minor-admission";
  attribute :>> observed="Native RootTask claim binds kind/executor/epoch and one READY lease. DEV advances from a settled RC node to an actual primary slot write in each of two R=3/W=2 rounds; the successor reconciles forwarding before the same-node suffix. The DEV successor reconstructs the missing write result without a saved post-value, and a two-credit ledger blocks old-bank retirement until reader ACK. The same full DEV ledger now causes real post-census pre-copy refusal. Wrong epoch, unknown reader and duplicate ACK preserve credits; the final of two valid reader ACKs permits old-bank retirement and full-GC retry. Two real DEV pthread readers now hold malloc-backed bank storage across refusal. After join, a withheld ACK is recovered by exact reader journal query; only the last valid ACK frees old bytes and permits full GC. Two forked DEV readers now hold the same mapped bank. A synced ACK is queried after normal exit and a killed reader leaves an absent record settled only after waitpid. The original pre-copy refusal and full-GC retry are observed; A separate native exec harness kills the owner at four ACK/retirement cuts, then replays from synced identity and journal state; The same journal now drives the actual post-census pre-copy refusal and subsequent full-GC admission for all four cuts. DEV torn tail fails closed. Two additional native cuts keep the independent exec reader mapped across owner SIGKILL. Fresh replay refuses with the shared bank lease held, both before and after durable ACK. The actual collector refuses after census; exclusive lease acquisition and ACK replay allow one unlink and full-GC retry. The multi-reader DEV replay closes the admission gate, rejects a late exec and a competing recovery writer, and keeps the bank pinned after the first reader drains. Both ACKs and the last lease drain precede one unlink. Production durability and admission refinement remain open.";
  attribute :>> required="Publish deduplicated typed task by backing identity and sealed layout before claim; unknown claims retain the task and leases.";
  attribute :>> gap="Inject R=3,W=2 busy, known pre-claim failure and lost return; require no duplicate partial write.";
  ref part :>> question=nativeAcceptance;
 }
 part minorSuccessorFinish:SourceSite {
  attribute :>> id="minorSuccessorFinish";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___HIDDEN ___BOOL root_task_finish_state";
  attribute :>> role="minor-admission";
  attribute :>> observed="Matching SCANNED becomes DONE and drops one lease; repeating matching DONE succeeds.";
  attribute :>> required="Separate strong completion from final receipt after weak cleanup and residual publication.";
  attribute :>> gap="Lose finish reply and delay cleanup; verify one completion and no early bank retirement.";
  ref part :>> question=nativeAcceptance;
 }
 part minorSuccessorRetire:SourceSite {
  attribute :>> id="minorSuccessorRetire";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___BOOL ___root_round_end";
  attribute :>> role="minor-admission";
  attribute :>> observed="Current round end releases enclosing source/exit leases only after restoration.";
  attribute :>> required="Retire remembered bank after successor coverage and all old users drain; metadata UNKNOWN retains storage within budget.";
  attribute :>> gap="Exercise no-new-store survival, weak deletion, lost ACK and exhausted retention with original census and heap.";
  ref part :>> question=nativeAcceptance;
 }
 part cleanupRootDomain:SourceSite {
  attribute :>> id="cleanupRootDomain";
  attribute :>> artifact="vendor/gambit/lib/_mem/memory-lifecycle.inc";
  attribute :>> anchor="cleanup_rc (___ps);";
  attribute :>> role="exit";
  attribute :>> observed="Memory cleanup calls rc_prepare_cleanup before detaching the domain";
  attribute :>> required="Transfer retained byte owners without PS/VM dereferences; stop scanning and reader borrows before destroying gates";
  attribute :>> gap="Partial setup/rollback and every cleanup caller must preserve initialization stage and outstanding root debt";
  ref part :>> question=cutSource;
 }
 part rcSourceMutex:SourceSite {
  attribute :>> id="rcSourceMutex";
  attribute :>> artifact="vendor/gambit/lib/rc.h";
  attribute :>> anchor="#define ___RC_LOCK(d)";
  attribute :>> role="synchronization";
  attribute :>> observed="RC source gate is a platform mutex in threaded builds and erased in no-thread builds";
  attribute :>> required="Pin source gate lifetime through all publication/claim/rewrite/return operations; prove configured mutex orders";
  attribute :>> gap="No-thread macros cannot qualify SMP; gate removal requires known last reader and final physical stop";
  ref part :>> question=cutSource;
 }

 part stillRootRefcounts:SourceSite {
  attribute :>> id="stillRootRefcounts";
  attribute :>> artifact="vendor/gambit/lib/_mem/still-refcount.inc";
  attribute :>> anchor="___EXP_FUNC(void,___still_obj_refcount_inc)";
  attribute :>> role="supplemental-root-producer";
  attribute :>> observed="Still object external refcounts use direct header-body increment/decrement; native conversion/release paths call these services";
  attribute :>> required="Treat changes in strong-root status as GC-relevant producer/writer work; close actual foreign access and count mutations before still-root setup/sweep";
  attribute :>> gap="RC node lifetime and still Scheme-object refcount are distinct; no complete all-caller freeze proof follows from six RootTask kinds";
  ref part :>> question=cutSource;
 }

 part firstRootRegistration:SourceSite {
  attribute :>> id="firstRootRegistration";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="___EXP_FUNC(void*,___register_rc)";
  attribute :>> role="source-refinement-endpoint";
  attribute :>> observed="Private RC node starts with FAL payload and gets linked under domain mutex before payload setter runs";
  attribute :>> required="Parent/source loan persists until durable initialized-root commit; mere membership or FAL payload cannot acknowledge transfer";
  attribute :>> gap="No general pre-registration source-loan/initialized-root acknowledgment protocol is demonstrated by this function";
  ref part :>> question=cutSource;
 }
 part borrowReentry:SourceSite {
  attribute :>> id="borrowReentry";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="___HIDDEN void reopen_rc_roots";
  attribute :>> role="source-refinement-endpoint";
  attribute :>> observed="Reopen validates source owner, round/assignment and accepted restored resume span before changing RC phase";
  attribute :>> required="Observe complete restore and round end before canonical slot reload; source lifetime and active data permission are distinct";
  attribute :>> gap="The helper does not implement arbitrary native borrower park/reload or a source-independent recovery query";
  ref part :>> question=cutSource;
 }
 part workerSourceAssignment:SourceSite {
  attribute :>> id="workerSourceAssignment";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___BOOL ___root_round_publish";
  attribute :>> role="source-refinement-endpoint";
  attribute :>> observed="RC scan executor is changed to member i modulo worker count under source gate";
  attribute :>> required="Source origin/epoch identity and query pin remain stable across worker assignment changes";
  attribute :>> gap="Current executor field is not a stable publisher/recovery identity";
  ref part :>> question=cutSource;
 }
 part workerCompletionQuery:SourceSite {
  attribute :>> id="workerCompletionQuery";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___BOOL ___root_task_completed(";
  attribute :>> role="source-refinement-endpoint";
  attribute :>> observed="Completion query requires executor equals current PSTATE and stored task executor, epoch, DONE and zero lease";
  attribute :>> required="A source-origin query must independently observe enrollment, scan and round-resume outcomes under live record pins";
  attribute :>> gap="For an original nonworker owner in W<R no existing executor argument satisfies both checks; this is a missing general query role, not a bug in worker-private completion";
  ref part :>> question=cutSource;
 }
 part activationRootSpan:SourceSite {
  attribute :>> id="activationRootSpan";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="___EXP_FUNC(___SCMOBJ,___sfun_arg)";
  attribute :>> role="activation-span-writer-and-reloader";
  attribute :>> observed="Concurrent source delta colocates sfun_arg with store_rc_root in rc-allocation.inc. Positive indices require the live record owner/roots/kind and exactly one root borrow; shared helper also checks source-open/refcount/range under the RC gate. begin_sfun/call_sfun/end_sfun remain in sfun-entry.inc; this navigation update grants no native or whole-writer closure.";
  attribute :>> required="Slot universe includes procedure h->data and every root_count cell; count immutable while published, active raw access parked during scan, all initialized prefixes and physical C extent exits retain one owner";
  attribute :>> gap="This is a concurrent implementation delta, not a native pass: generated variants, call-frame reserve, nested callbacks, raw pre-entry protection, exception/unknown exits and cross-epoch reuse need complete source and execution qualification";
  ref part :>> question=cutSource;
 }
 part strongRootFinish:SourceSite {
  attribute :>> id="strongRootFinish";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___BOOL ___root_round_finish_scan";
  attribute :>> role="strong-root-phase-completion";
  attribute :>> observed="Joins direct root tasks and ends global snapshot before setting round DRAINING; collection-round invokes weak scanning and physical restore afterward";
  attribute :>> required="Do not identify DRAINING with whole QNT finish; use remaining work, all-source restoration and concrete control location";
  attribute :>> gap="No one-field phase mapping proves weak/cleanup/private/Tail closure, memory order or eventual resume";
  ref part :>> question=cutSource;
 }
 part bulkPrivateReleaseBranch:SourceSite {
  attribute :>> id="bulkPrivateReleaseBranch";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="if (d == 0) { if (--h->refcount == 0)";
  attribute :>> role="actual-domain-zero-release-decision";
  attribute :>> observed="Release directly frees a zero-domain allocation; linked-list domain/count publication is a distinct multi-store sequence";
  attribute :>> required="Only a proved private/unlinked allocation may take this branch during new preparation/exit settlement";
  attribute :>> gap="Domain zero alone cannot prove an interrupted registration never linked the node";
  ref part :>> question=cutSource;
 }
 part bulkRegisterCommitStores:SourceSite {
  attribute :>> id="bulkRegisterCommitStores";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="h->domain=d; ++d->nodes;";
  attribute :>> role="multi-store-registration-boundary";
  attribute :>> observed="alloc_rc and alloc_rc_roots call register_rc. Links/domain/count precede RC gate unlock; mark_rc acquires the same gate and additionally requires frozen source and claimed scan lease";
  attribute :>> required="Verify selected gate provider completion before publishing exact fresh registration under held intent guard. Keep private allocation, registration, adopted loan and full target commit distinct";
  attribute :>> gap="RC registration is not an arbitrary-death atomic/crash-recoverable transaction; partial linked-list/mutex state remains unqualified";
  ref part :>> question=cutSource;
 }
 part bulkCleanupProducer:SourceSite {
  attribute :>> id="bulkCleanupProducer";
  attribute :>> artifact="vendor/gambit/lib/_mem/still-sweep.inc";
  attribute :>> anchor="void ___lifecycle_defer";
  attribute :>> role="actual-deferred-effect-producer";
  attribute :>> observed="Sweep/free detaches FOREIGN nodes to owner pending queue and accounts internal words; drain moves one to inflight before callback";
  attribute :>> required="Retain pending/inflight/uncertain ownership, affinity, root-bearing payload contract and unique byte accounting across deferral";
  attribute :>> gap="Internal words do not describe opaque external payload state or prove all embedded Scheme references rooted";
  ref part :>> question=cutSource;
 }
 part bulkTargetScanChain:SourceSite {
  attribute :>> id="bulkTargetScanChain";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___BOOL ___root_round_scan";
  attribute :>> role="future-target-root-consumer";
  attribute :>> observed="Frozen round assigns each active member RC task to a worker and calls claim/scan/finish in a worker-strided loop";
  attribute :>> required="Installed target must remain in active roster through source freeze and scan; mark_rc rewrites every registered root_count slot";
  attribute :>> gap="No special orphan/native-list scan or target transfer ACK exists; W<R does not waive target inclusion";
  ref part :>> question=cutSource;
 }
 part bulkOwnerEffectDispatch:SourceSite {
  attribute :>> id="bulkOwnerEffectDispatch";
  attribute :>> artifact="vendor/gambit/lib/_mem/still-sweep.inc";
  attribute :>> anchor="___BOOL ___lifecycle_drain";
  attribute :>> role="owner-affine-effect-caller";
  attribute :>> observed="Pending owner FOREIGN entries call release_foreign under TRY; error sets uncertain and nested drain preserves in-flight debt";
  attribute :>> required="Root and retain deferred effects without running them inside bulk physical span or dropping owner affinity";
  attribute :>> gap="Deferring drain requires explicit ownership, scheduling and error state; q uncertain is not recovered from GC success";
  ref part :>> question=cutSource;
 }
 part bulkStillOnlyHandoff:SourceSite {
  attribute :>> id="bulkStillOnlyHandoff";
  attribute :>> artifact="vendor/gambit/lib/_mem/still-sweep.inc";
  attribute :>> anchor="void ___lifecycle_handoff";
  attribute :>> role="existing-owner-transfer-boundary";
  attribute :>> observed="Transfers still chain and still/byte accounting between PSTATEs after eligibility checks";
  attribute :>> required="Do not confuse this with RC staging transfer; actual rooted target source and purpose-aware last-use dispatch are required";
  attribute :>> gap="No RC root header reparenting or orphan-root roster is implemented here";
  ref part :>> question=cutSource;
 }
 part bulkRootTransferGuard:SourceSite {
  attribute :>> id="bulkRootTransferGuard";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="/* First registration requires exclusive ownership of a private block.";
  attribute :>> role="actual-cross-source-registration-rejection";
  attribute :>> observed="register_rc rejects a registered block whose domain differs from target source";
  attribute :>> required="Use separate fully initialized target typed span and canonical copy under qualified source/target access, not re-registering old header";
  attribute :>> gap="Cross-source copy, target owner admission, stable query and ACK remain missing";
  ref part :>> question=cutSource;
 }
 part bulkStageWriterGate:SourceSite {
  attribute :>> id="bulkStageWriterGate";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="___HIDDEN ___BOOL root_writer_open";
  attribute :>> role="actual-root-write-admission";
  attribute :>> observed="Requires current owner PSTATE, RC_OPEN and no joined round; stores hold source mutex and cannot collect/reenter";
  attribute :>> required="Bulk purpose uses real source/lifetime proof and bounded noncollecting writes, without a forged SFUN record";
  attribute :>> gap="A matching borrow count or mutex pointer is not a bulk purpose; off-gate destination writes need distinct closure";
  ref part :>> question=cutSource;
 }
 part bulkStageFreeze:SourceSite {
  attribute :>> id="bulkStageFreeze";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___BOOL ___root_task_publish";
  attribute :>> role="stage-freeze-publication";
  attribute :>> observed="Publishes source/epoch/executor and one scan lease under RC gate before marking source FROZEN";
  attribute :>> required="Freeze observes complete stage writes and drains all admitted physical bulk spans before READY";
  attribute :>> gap="Current code does not enroll or drain bulk destination spans";
  ref part :>> question=cutSource;
 }
 part bulkStageCloseGuard:SourceSite {
  attribute :>> id="bulkStageCloseGuard";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="___HIDDEN ___BOOL rc_can_close";
  attribute :>> role="stage-final-cleanup-admission";
  attribute :>> observed="Rejects joined rounds, pending work/borrows/scan leases/FROZEN and any non-FAL root cells";
  attribute :>> required="Settle effects, clear roots under exclusive authorized maintenance, close all users then permit teardown";
  attribute :>> gap="Generic cleanup cannot infer bulk completion or clear live staging just to make close succeed";
  ref part :>> question=cutSource;
 }
 part bulkStageUnlink:SourceSite {
  attribute :>> id="bulkStageUnlink";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="___HIDDEN ___BOOL rc_unlink_if_dead";
  attribute :>> role="last-root-owner-release";
  attribute :>> observed="Unlinks only when refcount and root_borrows are zero under source gate";
  attribute :>> required="Retain an actual owner until every write/result/query/helper and scan use is settled";
  attribute :>> gap="A scan lease or registered root_count alone is not a native allocation lifetime reference";
  ref part :>> question=cutSource;
 }
 part typedStagingSource:SourceSite {
  attribute :>> id="typedStagingSource";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="void *___alloc_rc_roots";
  attribute :>> role="existing-scannable-span-producer";
  attribute :>> observed="Checks byte-size bound, allocates private span, sets root_count and FAL cells, then registers under RC source";
  attribute :>> required="Reuse typed scan representation only with actual bulk owner/write/last-use admission; root_count spans are not arbitrary byte buffers";
  attribute :>> gap="Positive-index store_rc_root currently requires SFUN record kind; bulk staging ownership and interrupted-fill validity are not implemented";
  ref part :>> question=cutSource;
 }
 part rcReferenceStore:SourceSite {
  attribute :>> id="rcReferenceStore";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="static ___BOOL store_rc_root";
  attribute :>> role="canonical-native-root-write";
  attribute :>> observed="Validates current PSTATE/domain and record/loan before mutation under RC_LOCK";
  attribute :>> required="Treat canonical root updates separately from heap-interior barriers; park raw access and reload across collection";
  attribute :>> gap="Borrow lifetime and root-writer admission do not repair untracked native interior pointers";
  ref part :>> question=cutSource;
 }
 part collectionDomainRoster:SourceSite {
  attribute :>> id="collectionDomainRoster";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___BOOL ___root_round_begin(";
  attribute :>> role="current-VM-bound-collection-membership";
  attribute :>> observed="Round begin constructs a VM-bound roster and checks changing/retained sources before enrolling the union";
  attribute :>> required="A future cut declares all collected regions, incoming edges and native/root participants independently of carrier or allocation-region identity";
  attribute :>> gap="Current VM roster is not a complete cross-region barrier or multiple-independent-domain admission protocol";
  ref part :>> question=cutSource;
 }
 part takeRoundDrain:SourceSite {
  attribute :>> id="takeRoundDrain";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> anchor="___BOOL ___root_round_end";
  attribute :>> role="round-reuse-not-slot-grace";
  attribute :>> observed="Round end validates restored root members, drops joined_round and returns round state to IDLE; it has no take-slot query/writer drain check";
  attribute :>> required="Terminal claim transfer, admission seal, actual writer/query closure and old native last users precede IDLE-dependent queue or slot reuse; pre-copy refusal remains a separate proved no-effect path";
  attribute :>> gap="Root restoration cannot issue the missing take retirement receipt. Actual round-end/refusal/next-round integration and unknown-result retention are unimplemented";
  ref part :>> question=cutSource;
 }
 part takeRcDrain:SourceSite {
  attribute :>> id="takeRcDrain";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="___HIDDEN ___BOOL rc_can_close";
  attribute :>> role="vm-owned-slot-free-admission";
  attribute :>> observed="RC close excludes joined rounds, non-IDLE rounds, retained/allocating census, RC borrows and scan leases; none is a fixed take-slot last-user predicate";
  attribute :>> required="RC prepare/free must additionally consume all slot and enclosing control last-use facts before freeing embedded worker storage; unknown operation retains custody rather than erasing counters";
  attribute :>> gap="Existing RC close checks cannot certify newly introduced take users. Actual predicate and both success/refusal propagation to VM cleanup remain required";
  ref part :>> question=cutSource;
 }
 part workerStorageBirth:SourceSite {
  attribute :>> id="workerStorageBirth";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="memset(d->round,0,sizeof(*d->round));";
  attribute :>> role="vm-owned-worker-storage-construction";
  attribute :>> observed="Fresh primordial RC domain allocates and zeroes root round containing all worker records; worker vm/id/carrier are initialized afterward";
  attribute :>> required="Only fresh unexposed storage may be zeroed this way; gate/worker lifetime belongs to VM round, not an exiting carrier";
  attribute :>> gap="No general reset or unknown-thread reclamation authorization follows from zero initialization";
  ref part :>> question=cutSource;
 }
 part workerStorageRetire:SourceSite {
  attribute :>> id="workerStorageRetire";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> anchor="___FREE_MEM(d->round); d->round=0;";
  attribute :>> role="worker-gate-storage-last-use";
  attribute :>> observed="cleanup_rc frees the primordial root round and thus embedded worker gates and queue pointers after RC closing checks";
  attribute :>> required="All counted worker operations, gate holders/waiters, publishers, transient returned claims, query observers and native postludes have closed or accepted separate custody before free";
  attribute :>> gap="RC domain closure alone must not be treated as proof of every collector/control last user; unknown holders retain enclosing storage";
  ref part :>> question=cutSource;
 }
 part scanResourceDestroy:SourceSite {
  attribute :>> id="scanResourceDestroy";
  attribute :>> artifact="vendor/gambit/lib/_mem/memory-lifecycle.inc";
  attribute :>> anchor="___CONDVAR_DESTROY(scan_termination_condvar)";
  attribute :>> role="physical-scan-resource-retirement";
  attribute :>> observed="VM memory lifecycle initializes and destroys scan termination mutex/condvar; configuration.inc maps these names to VM memory fields";
  attribute :>> required="Destroy only after no waiter, late publisher, claimant or returning worker can touch either object; all source and arena lifetimes close separately";
  attribute :>> gap="Phase zero and data_closed cannot replace all-last-user proof; same-VM retention and independent-VM progress remain source/native obligations";
  ref part :>> question=cutSource;
 }

 part packetRcLeaseLayout:SourceSite {
  attribute :>> id="packetRcLeaseLayout";
  attribute :>> artifact="vendor/gambit/lib/rc.h";
  attribute :>> anchor="struct ___rc_domain_struct {";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="The existing domain stores gate/head/owner/nodes/borrows/phase/task/round/idle_activation/joined_round; it has no independent query-reader or explicit frozen-view completion fields.";
  attribute :>> required="Reuse the domain and gate; add checked view lifetime and observer admission/count. Freeze holds canonical header/slot topology through known restored/refused closure; logical reference drops cannot unlink it.";
  attribute :>> gap="Selected layout/commit design only; C implementation, selected backend ordering, complete callers and real-cut native/cost evidence remain open.";
  ref part :>> question=cutSource;
 }

 part packetCanonicalRcSpan:SourceSite {
  attribute :>> id="packetCanonicalRcSpan";
  attribute :>> artifact="vendor/gambit/include/_gambit/memory_state.h.in";
  attribute :>> anchor="typedef struct ___rc_header_struct";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="The RC header owns intrusive links, refcount, data, domain, root_borrows and root_count; root_count describes the appended canonical Scheme span.";
  attribute :>> required="Retain these canonical cells and slot extent while source view or raw/scan custody exists. No copied root words, FAL sentinel or ordinary query pin permits moving-slot payload reads; count-only ACK never owns physical free.";
  attribute :>> gap="Selected layout/commit design only; C implementation, selected backend ordering, complete callers and real-cut native/cost evidence remain open.";
  ref part :>> question=cutSource;
 }
}
