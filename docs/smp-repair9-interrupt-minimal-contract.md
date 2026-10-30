# Repair 9: minimal request diagnostics and current candidate control-flow defect

> Later stable-cut update: [both branches corrected in current Scheme/C](smp-repair9-reply-replay-current-status.md), with scratch/object machine-transfer correspondence and first-eight impact review. The defect below remains evidence about snapshot 863e, not a claim that later live bytes still contain it. Prior QNT results remain bound to their immutable model snapshots.

2026-10-23. **Design only; not activated.** Native acceptance remains **8/12**. The incremental workspaces contain real repair changes and are part of this audit. Reading their bytes does not establish that a particular historical binary/run used those bytes. No runtime, build or peer process is changed or operated here.

## First: the incremental repair code is present

At the first read, `4463…/source/lib/_thread.scm` had SHA `6ca2d0ad…` and `_thread.c` SHA `6e17bf31…`; the main `gsi` was still origin SHA `9eca674b…`, while `gsi.lastq` was a distinct binary SHA `ce806f64…`. Later retained snapshot **863e886c269f4fe9828556208f9e4565** has Scheme SHA `481c2a0feadc4698aed3ad5a8371b4a3e340e477a30492bb771dd1096c97ba48`, C SHA `ae2f27f65b72d290a6f28a44e5dffed452361da60c06b3d71cf6620a4791e1de`, main gsi unchanged and scratch binary SHA `27bfbbc3…`. Files changed during observation. These are successive observations, not one atomic source/binary generation.

The second incremental directory `c86d…` had the original `_thread.scm`, generated C, setup and header hashes at the bounded read. The selected `4463…` Scheme changes include target placement/wake, unlocked running-processor lookup, a new current-thread interrupt drain and a yield fast-path change. Earlier live C reads included `gambit_intr_flight_*` calls; those were absent from the retained 863e snapshot. They must not be retroactively described as the same candidate. A binary filename or common build-directory key cannot replace a receipt binding.

### Confirmed defect in the retained candidate

In **both** mutex arms of snapshot 863e `##other-interrupt!`, `##thread-intr-propagate!` is a following expression in the target-binding `let`, outside the two-argument `if`. If the target is current, the callback executes, its result replaces mutex.specific, the mutex is unlocked, **and the same request is then propagated again**. Propagation still reads specific as the target thread. A nonthread result enters the wrong representation path; a thread-valued result can target a different thread. These are consequences of the inspected control flow, not a claimed reproduced crash.

The retained generated C confirms the successful paths:

- Thread-queue drain: callback return L2 → result store → unlock fast/slow paths → L16 → **fall-through L17** → `thread-intr-propagate!`.
- Processor queue: result/unlock paths → **L26** → `thread-intr-propagate!`; the separate mismatching-target path also propagates.

Original archived Scheme uses the intended three-argument `if`: execute-and-reply **or** propagate. The source-only minimal correction is to put propagation back in the **else** position in both arms, then regenerate affected C and qualify that exact candidate. This audit makes neither edit. Static branch shape and generated edges are retained in the evidence JSON; they do not bind this newer defect to the old TFIB crash, nor certify the current live file after the snapshot. The new QNT reply-replay mutation represents this precise forbidden transition.

This is a concrete candidate defect to resolve before adding further repair behavior. Diagnostic code must observe; it must not rescue, replay, drop, reroute or run an action to make the trace complete.

## Chosen minimal representation: no new native root handle

Use the **existing private result mutex** as the association anchor. Its name currently holds the action thunk and its specific field changes from target to result. In a future explicitly enabled diagnostic candidate, replace only that private name value with a Scheme vector descriptor:

```scheme
;; Proposed private representation, not installed:
;; [private-marker request-id parent-id original-thunk hop-serial]
;; request remains [next result-mutex]; mutex.specific retains its old semantics.
```

Two dispatchers and sender helpers unwrap the action through one private accessor. Generic procedure-targeted processor interrupts retain their existing representation. The marker and length must be checked at safe Scheme boundaries; do not interpret arbitrary mutex names as descriptors. The original action is invoked exactly once on the original semantic branch. No new mutex/processor/thread structure field, generic header-size change, RC carrier or unrooted native SCMOBJ map is required by this proposal.

This choice adds a small descriptor allocation before the result mutex is locked. It also changes the private mutex name's diagnostic representation. Error/printer paths that expose that name need a consumer census and original-action projection, or the resulting run must remain diagnostic-only. Cost, generated maps and exception-display compatibility are unproved. This is a concrete small instrumentation design, not a production repair or permission to implement it now.

Existing RC APIs are not a free alternative: origin mem.c `___addref_rc` uses plain `refcount++`, release uses plain decrement and intrusive-list unlink, and `set_data_rc` is a plain assignment. A cross-owner RC table would require explicit synchronization/lifetime refinement and would add strong roots that can conceal the bug under investigation. The proposed descriptor follows existing Scheme reachability instead.

## Stable ID and cross-owner association

1. Allocate a session UUID before VM execution and record binary/source identities and VM incarnation in the carrier header. One process-wide atomic monotonic serial yields a fixnum request ID. The ID is never derived from an object address, OS thread ID, processor number, timestamp or array slot. Stop issuing qualified IDs before fixnum/serial wrap; mark an observation gap and continue original program semantics.
2. The full identity is `(session, VM incarnation, request-id)`. Use the same immediate ID in the descriptor, all events, callback context and sender wait record. Uniqueness from the atomic counter establishes issuance, **not** cross-processor execution order.
3. The descriptor and mutex may move. Dispatchers reload the current descriptor from the currently rooted mutex; events retain only immediate identity/status fields, never a native pointer used after its lifetime. The original saved-frame/mutex.field11 coverage audit remains the applicable starting point; new generated maps must be checked after instrumentation.
4. A route hop serial is updated only by the unique transport owner before queue publication, under the applicable existing ownership/lock protocol. Events pair `PUBLISH_INTENT`, actual `PUBLISH_DONE`, and `DEQUEUE_ACK` by request ID + hop + receiver incarnation. An intent without acknowledgement is not proof of queue membership. This new scalar protocol needs actual C/lock-order validation.
5. A migration moves the Scheme activation/context, not the ID. Capture/source-stop/destination-queue/restore records refer to one activation generation. `last-processor` alone is not current ownership; recheck actual target/current state before dispatch. No native TLS variable may be the sole request-context owner.

The proposed nonallocating native event sink accepts **already decoded immediate fields** from private Scheme/C adapters. It must not decode an arbitrary object graph while holding C queue locks. Preserve existing public C queue signatures; a private adapter may bracket the existing call and supply the scalar token. The returned request is decoded at the normal safe Scheme dispatcher boundary. A gap between native dequeue and Scheme acknowledgement remains UNKNOWN until captured; it is not repaired by inventing an atomic event.

## Nesting and exceptions

During callback invocation, bind a private diagnostic parameter in the target thread's **existing Scheme dynamic environment**. Its value carries the current request/activation ID and previous context. Migration then carries it with the continuation; nested synchronous sends get distinct IDs and preserve the outer context. The parameter is not native-thread-local storage and must not replace existing current-thread/scheduler state.

Record the parent relation kind: a callback's inherited causal ID is not automatically a blocked parent. A `nested-sync` edge additionally needs the observed sender activation and wait relation. Threads spawned with inherited dynamic environment must not be mistaken for the suspended caller. Continuation capture/reentry needs a new activation generation and explicit REENTRY/UNKNOWN coverage; do not suppress or duplicate user actions in the name of diagnostics.

Normal wrapper return records ACTION_RETURN, then the existing dispatcher stores the result and unlocks. A supported user handler may return an error value; record it without imposing a new universal exception catcher. Target termination follows existing result-mutex abandonment. A nonlocal Scheme exit may unwind the private binding; absence of normal return records ESCAPE_UNKNOWN, not successful delivery. A raw C unwind may bypass Scheme cleanup entirely: retain an unfinished observation until the writer group is quiescent. Do not pretend a `dynamic-wind` after-thunk proves all native unwinds were finalized.

## Record ownership and last release

Separate three lifetimes:

| Resource | Live owner / consumers | Last release condition |
|---|---|---|
| Scheme descriptor + mutex association | Request queue, detached dispatcher frame, callback/continuation, sender result-mutex frame | Ordinary GC after **all actual roots** cease to reach it. No manual C free or forced rooting table. Sender return alone does not prove a concurrent dispatcher has stopped using it. |
| Logical diagnostic request | Queue/transfer owner, dispatcher completion acknowledgement, sender RETURN/ERROR; parent context if a child is still returning | CLOSE only after matching caller consumption/error **and** dispatcher terminal acknowledgement; for nesting, child context has returned to parent and the child's closure is recorded. UNLOCK, RESULT_STORE or RUNNABLE alone is too early. |
| Native event-carrier bytes | Live event writers and the external forensic reader | Unmap/delete only after all writer processes are reaped/quiescent and readers finish. An uncertain escape never triggers an invented final CLOSE. |

Committed event slots may be reused only as ring storage with monotonically increasing writer sequence/commit generations; **request IDs are never recycled**. Historical events can fall out of a bounded ring. Every loss/overflow/torn read is explicit and prevents complete-chain claims. The latest pending sender cut and unclosed request status must be retained or the verdict is UNKNOWN. No guarantee that a finite ring captures any arbitrarily late hang is claimed.

No arbitrary Scheme objects are retained by the native journal. Stale raw address bytes are forensic observations only. Physical Scheme reclamation can occur later than logical CLOSE, and keeping a journal record does not keep the Scheme object alive. The old request/result/continuation roots must remain sufficient without diagnostic pinning.

## Six implementation surfaces, narrowed

| Surface | Minimal proposed edit boundary | Required events / why needed |
|---|---|---|
| 1 Sender | `##thread-intr!`: private descriptor construction/accessor; bracket existing wait and final return/error | CREATE, WAIT_ATTEMPT, actual WAIT_LINK, REACQUIRE, RETURN/ERROR. Preserve async mode separately; caller return is not async action completion. |
| 2 Route/migration | `##thread-intr-propagate!`, migration capture/restore and existing queue-publication adapters | Token/hop, target/current receiver, migration-target and transfer acknowledgement. Separate execute and reroute; never replay after reply. |
| 3 Processor transport | Private adapter around existing high-level enqueue/dequeue; no generic callback or GC inside native logger | PUBLISH_INTENT/DONE, DEQUEUE_ACK and dispatcher owner. Keep the C-return-to-Scheme gap visible rather than assert an unimplemented atomic cut. |
| 4 Dispatch/nesting | `##other-interrupt!` and `##thread-resume-execution!`, shared private action accessor and dynamic-context wrapper | ACTION_ENTER/RETURN/ESCAPE, parent+activation, detached-owner terminal acknowledgement. Both actual drain sites, including the newer candidate drain, must be covered. |
| 5 Reply/activation | Targeted name-descriptor detection at existing result-store, mutex waiter insert/remove and runnable-publication boundaries | RESULT_STORE, real GC-service call/return label, UNLOCK, WAIT_REMOVE, RUNNABLE. Do not add a fictitious GC point from a macro that compiled away. |
| 6 Terminal/consumer | Target abandon, sender restore/error and diagnostic closure | ABANDON, ERROR_RESUME, CALLER_CONSUMED, DISPATCH_DONE, CONTEXT_POP, CLOSE. Mark unsupported exit incomplete; do not alter program error behavior. |

These are six code surfaces, not six magic logging calls. Allocating/descriptor lookup/parameter binding occurs at safe Scheme boundaries; only scalar commit occurs inside constrained native hooks. Exact lock ordering, generated frames, initialization failure, ring writer uniqueness and overhead need qualification before any activation. Same-thread interrupts that directly invoke the action bypass the queued result-mutex protocol and need a distinct DIRECT event if selected; do not falsely match them as a pending queued request. Async requests require their own final-consumer rule; this minimum qualifies only the synchronous queued path.

## Starting from a real blocked sender

1. In an authorized future owned diagnostic run, take a cooperative cut or retained completed snapshot using the existing supervisor; no live peer/debugger action is part of this study. Identify a sender whose actual `btq-container` is the private result mutex, or whose latest qualified wait event has no matching return/error. Read the marker/ID from mutex.name **before interpreting specific**, because specific may already be a result.
2. Establish the exact session/source/binary, sender incarnation and request ID. Validate the trace's commit sequences and coverage. Inspect the dynamic/activation context only through its saved rooted representation, never stale pointer arithmetic after the cut.
3. Follow that token+hop through publication, dequeue, dispatch, nested child IDs, action return, result/unlock and sender restore. If the parent is suspended, recurse into the observed `nested-sync` child; do not count the active child as evidence the parent vanished.
4. Classify the **last acknowledged transition**: queued with no dequeue; detached with no transfer; action or nested child unfinished; result stored but unlock incomplete; runnable sender not restored; restored sender not consuming; or supported error not returned. If PUBLISH_DONE/DEQUEUE_ACK coverage is missing, report the corresponding interval as UNKNOWN rather than select a root cause.
5. Check illegal edges first: second execution owner, source/destination incarnation mismatch, root-generation mismatch, CLOSE with live consumers, or propagation after RESULT_STORE/UNLOCK. The retained 863e candidate already contains the last control-flow edge statically. Its presence does not require a new full-inventory run to recognize the source defect.

## Model and evidence boundary

The same maintained QNT adds immutable session/VM/token association, independent dispatcher/caller acknowledgements, nested context-pop before closure, opaque-exit retention, explicit coverage gaps and no post-reply replay. New negative controls reject early release, opaque release, request-ID reuse after child closure, native-TLS parent loss on migration, raw-address association across GC, claiming a breakpoint despite a coverage gap, reply replay and child closure before returning to the parent context. Existing early/nested/error/migration/root controls remain in that transition system.

The first extension run found the intended early-close violation on the **inner** request before the original witness matcher reached the outer one; it was rejected rather than counted as a pass. The corrected matcher and child-context closure guard are revalidated. Named trajectories distinguish caller consumption from dispatcher completion and final closure. This models the contract's value; descriptor implementation, all callback/continuation semantics, atomic native publication and actual failure-run binding remain unproved. No runtime fix, original first-eight regression or native 12/12 qualification is claimed.
