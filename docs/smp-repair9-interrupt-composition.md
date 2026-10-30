# Repair 9: early reply, nesting, exceptional exit and migration

> Successor: [minimal implementation contract and retained candidate defect](smp-repair9-interrupt-minimal-contract.md). The maintained model now includes diagnostic identity and last-consumer closure. This document's 19-check result remains bound to its immutable prior model snapshot.

2026-10-23. Research only, native **8/12**. This refines the same request model; no runtime/header/compiler/framework/Recipe changes, native execution or implementation-thread operation.

## Correction: Scheme macro versus actual generated C

The preceding request study identified a source-level `##check-heap-limit` at the start of `macro-mutex-unlock!`. That is **not sufficient to establish an immediate GC point in this producer**. The archived generated `_thread.c` result-return blocks contain the store into mutex slot 11 followed directly by `___PRIMITIVELOCK`; they contain no explicit `___CHECK_HEAP` between those operations. Header expansion maps that lock to the ticket lock, not a GC service call. The historical source-level claim and six-check abstract model remain retained, but must not be read as an observed native GC interval.

Real source-backed collection opportunities include arbitrary callback execution and the subsequent contended owner-lock path calling `##lock-scheduler-object-with-sync-participation!`, which can call `##sync-op-interrupt!`. The generated out-of-line unlock and runnable publication have additional call boundaries. A native failure PC plus actual return descriptor is needed to select the live range. No newly discovered missing root or actual failing instruction is claimed here.

## Generated root coverage, mechanically decoded

Source identity: origin archive build-7, gsi SHA `9eca674b79248987e67d458c9acce7941149f428616caf0aff5defdc93e49d78`; `_thread.c` SHA `1dd389bae153ca343cc29219180f45a5522cca9254b744dffc95db43f173b81d`, header SHA `15f39cfda23d945d393b10786a9b7030899de75cc98467989cd3cfe6fffd4802`. These bytes also match the original generation for these files; changed `mem.c` remains separately identified.

Header definitions: `FP_STK(fp,k)=fp[-k]` (6758), `FRAME_SPACE(5)=round_up(5+3,4)=8` (9237–9239). `mark_continuation` (origin mem.c 4155–4231) decodes the saved return descriptor and adjusts to the frame base before calling `mark_frame` (4074 onward). `mark_frame` starts at ordinal 1 and consumes low map bits. For a generated access `STK(k)` at the return cursor, the corresponding caller-frame ordinal is `8+k` in the cases below.

| Actual return label | Saved roots / map | Derivation and guarantee |
|---|---|---|
| `other-interrupt!` L3, callback return | Mutex `STK(-6)`; RETN fs=5, map=`0x3` | Mutex ordinal 2, selected. Callback result in R1 is stored into mutex field 11 before locking. |
| `other-interrupt!` L1, contended owner-lock helper return | Mutex `STK(-6)`, owner `STK(-5)`; map=`0x7` | Ordinals 2 and 3 both selected across helper GC. |
| `thread-resume-execution!` L2, callback return | Saved resume-thunk `STK(-6)`, mutex `STK(-5)`; map=`0x7` | Ordinals 2 and 3 selected. The detached request vector need not stay live once its mutex/thunk contents suffice; logical request ownership need not mean retaining a dead vector. |
| `thread-resume-execution!` L3, contended owner-lock helper return | Resume-thunk `STK(-6)`, mutex `STK(-5)`, owner `STK(-4)`; map=`0xf` | Ordinals 2, 3 and 4 selected. |

| Sync-participating lock helper L1 | Lock object `STK(-6)`; RETN fs=5, map=`0x3` | Ordinal 2 selected. Generated C 13106–13112 saves it before calling the sync-op hook and reloads it after return. |

After result storage, mutex field 11 is the strong result path. `scan`'s pointer-bearing default in origin mem.c 4427–4433 scans that field; skipping the already-marked first word in the movable fast case does not skip field 11. Before callback return, callback frames/registers must preserve the not-yet-published result by their own maps. That entire arbitrary callback is not audited by the rows above.

The companion JSON asserts all five slot/map memberships and saves source hashes/snippets and descriptor locations. This establishes a concrete generated-source coverage path. It does not prove all native registers/frames are intact, all earlier writes are in bounds, hardware visibility, asynchronous unsafe-C scanning, or the first corrupting writer. A direct ticket-lock stall remains a separate progress question; the presence of roots does not make that lock GC-participating.

## One model, combined paths

The updated `interrupt_request_lifecycle.qnt` keeps two distinct request tokens: outer=1 and child=2, child.parent=1. A nested call suspends the outer activation and retains its mutex root. The child can move, collect, publish and consume its own reply before the parent resumes. Normal combined paths include six modeled collection boundaries, early outer reply with **zero wake events**, and one waiting child wake.

Migration has two distinct intervals:

1. Before dispatch, a target can move after the original receiver was selected. The dispatcher must recheck the receiver/target identity and reroute before starting the action. A cached processor ID is not enough.
2. During callback activation migration, the activation is captured, the source stops running, transfer ownership is retained across GC, destination runnable ownership is published, and a single destination restore resumes it. The request stays with the activation; it is not copied into a second executing request.

The abstraction models these transitions as atomic steps and checks both no duplicate execution owner and no ownerless pending request. Native refinement still requires the real lock critical sections, queue insertion, current-thread changes and memory ordering.

Exceptional cases are deliberately separate:

- **Caught/encoded callback outcome:** a supported callback catches its error and returns a value represented as status 1. Current generic dispatch does not install a universal new exception catcher; this modeled result contract is not silently attributed to it.
- **Target termination:** responsibility passes to the existing mutex abandonment path, represented as status 2. The waiting caller must receive the appropriate error; normal success cannot be manufactured.
- **Unresolved Scheme escape or raw C unwind:** the model reaches an opaque retained state, preserving roots/ownership and refusing normal completion. This is an observation/proof boundary, not an existing native containment or recovery implementation.

Seven positive campaigns cover normal, early+nested+migration, caught, termination, Scheme-opaque, raw-opaque and fast reply. Nine mutations require distinguishing states: requiring a wake for early reply; overwriting the outer token; dropping its root while the child is active; duplicating migration execution; losing result reachability; calling opaque escape successful; dropping termination responsibility; failing to reload a moved result; and dispatching through a stale receiver.

The fast branch does not inject the previous model's assumed pre-unlock collection. The slow branch represents a supported collector-service call before completion of unlock. Callback collections, saved-parent roots and generation changes remain abstract obligations mapped to the concrete coverage above. Bounded positive safety is not a native liveness theorem. Explicit named trajectories additionally exercise combined normal completion, caught result and opaque retention.

## Native migration correspondence

Archived Scheme `##thread-migrate-to!` (3184–3206) locks the current thread, saves its continuation, acquires destination processor with sync participation **while donor current-thread still roots it**, records migration-target and resume-thunk, clears donor current-thread, inserts into destination BTQ under lock, then unlocks, wakes and schedules. Header `THREAD_SAVE` (6314 onward) anchors the frame through thread.cont; `THREAD_RESTORE` (6381–6390) installs the continuation, updates last-processor and current-thread. Resume execution (2749–2758) validates and consumes migration-target before handlers can perform a newer migration. These are reusable existing mechanisms, not new repair claims.

Before dispatch, processor handler `##other-interrupt!` (1442–1447) compares target with current-thread and otherwise calls propagation again; propagation (1377–1409) rechecks current ownership under thread/processor locks and honors migration-target in runnable placement helper (703–725). After a detached handler starts, nested Scheme calls and migration carry its live Scheme frames. No proof here covers arbitrary continuation cloning/replay, multiple generations of reused processor identities, or every direct C entry.

## Six observation surfaces: locating the real blocked request

Use one process/source/VM incarnation and an immutable request token. A moving address is only a field observation with a relocation relation. Record parent token, sender and target incarnation, receiver epoch and explicit ownership-transfer acknowledgement. Never compare local sequence numbers on different processors as global order. An overflow, missing transition, unknown root lifetime or torn record yields UNKNOWN rather than a guessed lost request.

| Surface | Required pair of events and fields | What a completed trace can decide |
|---|---|---|
| 1. Sender `thread-intr!` | CREATE(token,parent,sender,target,mutex association); WAIT_ATTEMPT; actual WAIT_LINK; REACQUIRE; RETURN/ERROR. Capture sender.btq-container and resume-thunk at already-locked updates. | Select a concrete pending sender. If no WAIT_LINK, distinguish early reply from failure to block. Actual RETURN/ERROR, not a wake count, releases the final diagnostic handle. |
| 2. Propagation / migration | ROUTE_DECISION(token,target,receiver,current-thread,migration-target,epoch), QUEUE_PUBLISH or TRANSFER_BEGIN; CAPTURE, SOURCE_STOP, DEST_QUEUE, DEST_RESTORE acknowledgements. | Was the selected receiver stale? Was the target parked, runnable or uniquely executing? Transitional absence from all queues is legal only with a retained transfer owner/root. |
| 3. Processor enqueue/dequeue | ENQUEUE(token,queue owner,link predecessor); DEQUEUE(token,next-cleared,dispatcher owner), captured at existing queue lock boundaries. | Missing wake versus already-dequeued request. Pair each removal with dispatcher responsibility; queue emptiness alone cannot complete it. |
| 4. Both dispatchers / callbacks | ACTION_BEGIN, NEST_ENTER(child,parent), GC/RA/live-frame identity, MIGRATE, ACTION_RETURN or ESCAPE/TERMINATE. Record retained outer activation separately. | Distinguish suspended outer callback from a vanished request; locate the last active nested request and receiver. Do not rerun a possibly executed action to recover evidence. |
| 5. Result and mutex / activation | RESULT_STORE(token,mutex,result generation,status), actual SLOW_GC_ENTER/EXIT with return label/map, UNLOCK, WAIT_REMOVE, RUN_QUEUE_PUBLISH. | Separate result-root/collector delay, unlock contention and sender activation. Correlate GC with an emitted native service call, not the Scheme macro name. Early reply has UNLOCK without WAIT_REMOVE/wake. |
| 6. Abandon / restore / final return | ABANDON(mutex,owner,target generation), ERROR_RESUME; SENDER_RESTORE, REACQUIRE, RETURN/ERROR; final HANDLE_RELEASE. | Separate supported target-death error from a stranded runnable sender, final acquire, or unsupported unwind. A terminal trace must retain error identity; no boolean success fallback. |

The existing two-slot request vector and generic result mutex do not carry this full diagnostic identity. A private immediate token extension and rooted scoped association remain a **future diagnostic proposal** requiring a complete consumer census, relocation support and original-budget overhead qualification. No such changes were made. The plan must cover nested identities and final consumers before native execution, rather than log raw pointers and attempt to reconstruct identity afterward.

## Remaining gate

We now have a source-grounded root path at the inspected callback/slow-lock return labels, and a combined model that explains why early replies, nested ownership, migration and errors need distinct states. We still lack the actual pending request trace, complete callback/native root refinement, cross-processor publication proof and production native regression acceptance. Current evidence chooses no actual root cause. Native remains 8/12.
