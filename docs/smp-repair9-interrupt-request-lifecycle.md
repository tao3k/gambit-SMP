# Repair 9: tracing one blocked synchronous interrupt request

> Generated-source correction and successor model: see [combined request/root study](smp-repair9-interrupt-composition.md). The Scheme macro alone does not prove an immediate pre-unlock GC in this producer; emitted C and real service calls qualify the interval. The original six-check snapshot remains in its immutable audit run; the maintained model is now the combined successor.

2026-10-23; research only; native acceptance remains **8/12**. Source is the immutable build-7 origin archive (binary SHA `9eca674b79248987e67d458c9acce7941149f428616caf0aff5defdc93e49d78`), copied by the preceding audit. This study does not execute native code, instrument the runtime, or inspect/control another chat's live process.

## Finding and evidence limit

The existing data does not identify one blocked sender's request and all its transitions. The retained narrative reports iteration counts, processor samples and queue observations. None supplies a request token, matching result mutex, sender blocked-container, dispatcher-local owner and final result-consumption record for the same instant/run. We therefore cannot truthfully say the real request was lost, identify a guilty function, or prescribe another wake patch as a sufficient repair.

Source does establish two further missing distinctions. First, both processor and thread queues detach a request before its callback finishes; empty queues exclude neither an executing nor suspended handler. Second, result storage precedes `macro-mutex-unlock!`, whose first step is `##check-heap-limit`. There can be GC between result storage and unlocking, followed by a separate sender activation/restore/consumption chain. An action may itself allocate, migrate, yield, or make a nested synchronous call; the supported error/termination disposition must also be recorded. Results and exceptions cannot be flattened into a boolean "delivered".

## Concrete call chain and last consumers

Lines below refer to archived `_thread.scm` unless a file is named. The active scheduler is the `enable-smp` branch; the queue removal macro at the end of `_thread#.scm` is explicitly common code.

| State / transition | Function, fields and order | Last consumer / required record |
|---|---|---|
| Construct and establish reply owner | `##thread-intr!` 1336–1352 creates result mutex with name=thunk, specific=target; request vector `[next, mutex]`; locks mutex with target as owner; then propagates | Sender activation needs request, mutex and target roots until no longer live. Record sender incarnation, request token, target, mutex relation, synchronous/asynchronous mode before publication. |
| Sender waits | 1353–1358, synchronous branch locks result mutex for current sender, then unlocks and reads specific | Before blocking, completion may already have happened. Distinguish WAIT_ATTEMPT, actual mutex wait insertion, REACQUIRED and RETURN/ERROR; absence of a wake event is legal on the early-completion path. |
| Remove target from scheduling structures | `##thread-lock-remove-btq-toq!` 769–834; thread lock, processor queue removal or mutex/condvar trylock/retry, timeout removal, callback under target lock | Target can be temporarily absent from queues while transfer code owns it. Record lock/transfer phase; a queue-only census is incomplete. |
| Route to processor or thread | `##thread-intr-propagate!` 1360–1414; terminated check; last-processor/current-thread read; processor request send or thread interrupt queue append + runnable insertion | Record request token plus route decision and receiver. Do not classify the cached last-processor as current execution ownership without the synchronized current-thread observation. |
| Processor queue owns node | setup.c `___raise_high_level_interrupt_pstate` 364–393: linked under processor PRIMLOCK, barrier, unlock, then OTHER interrupt raise | Queue HEAD/TAIL/link are roots/links; notification is not a terminal reply. Existing single-node unlink is already implemented. |
| Dispatcher owns detached node | setup.c `___get_next_high_level_interrupt_pstate` 396–427 returns head, clears its successor and updates tail under lock; `##other-interrupt!` 1416–1448 receives it | Local `interrupt`, mutex `x`, target/thunk may outlive dequeue and GC. Record DISPATCH_ENTER and terminal TRANSFER/EXECUTE/ERROR; root maps of these native live ranges remain a proof obligation. |
| Thread queue owns node | append at 1403–1409; `_thread#.scm` common macro 4310–4329 detaches head and clears its next link | Clearing next is existing behavior, not another repair to propose. Removal transfers ownership to the current resume activation, not directly to "done". |
| Resume dispatcher owns node | `##thread-resume-execution!` 2745–2779 consumes migration target before handlers, removes thread-head under thread lock, unlocks, invokes action, loops, then resume-thunk | Record resume entry/current owner, request dequeue and action start. Nested handler activity must not overwrite the outer pending request's state. |
| Action/result stored | processor path 1443–1446; resume path 2773–2775: invoke thunk; write mutex specific; then unlock | At this point specific is a result, **no longer a reliable target identity**. Keep original target identity separately; never infer target from a result that happens to be a thread object. |
| Possible GC before unlock | `_thread#.scm` `macro-mutex-unlock!` 1740 onward calls heap-limit check before taking mutex lock | Result/mutex live roots must survive this check. RESULT_STORED, UNLOCK_BEGIN and UNLOCK_DONE are distinct. This is a source-level GC opportunity, not evidence that a particular observed hang occurred here. |
| Reply before wait | unlock macro fast path, no waiting thread | Mutex becomes not-abandoned/unlocked. Sender can acquire later without a signal/wake. A model requiring every request to have WAIT_ENQUEUED→WAKE would reject a legal execution. |
| Wake a blocked sender | `##mutex-unlock-out-of-line!` 3876 onward; first waiter removed, timeout removed, ownership transferred, resume-thunk installed, run queue insertion, locks released | The sender is runnable after insertion, but has not consumed the reply. The mutex and sender remain relevant to GC and scheduler ownership. |
| Target terminates / abandons | `##thread-end!` 1673–1681 walks owned queues; `##btq-abandon!` 1690–1713; `##mutex-signal-no-reschedule!` 3982–4062 | A real waiter gets abandoned-mutex resume action, then runnable placement. With no waiter, abandoned state is retained for later acquire. Preserve this error path; do not silently drop the request or manufacture success. |
| Sender resumes and consumes | scheduler restore 2877–2887 → resume execution; mutex acquire returns or raises at 3767–3772; successful `##thread-intr!` 1356–1358 unlock/read | Only matching caller RETURN or supported ERROR finalizes this synchronous request. Sender-side final unlock itself has a heap check; trace storage must outlive this final consumer. |

The result mutex's `btq-owner` (thread or special symbol), waiter queue, sender `btq-container`, `resume-thunk`, `cont`, `last-processor` and migration-target are different state dimensions. `specific` changes meaning. An unlocked mutex, runnable sender and returned caller are different states. For arbitrary handler exceptions/continuation escape and sender termination, the exact public semantics and cleanup path remain open; target abandonment alone is not a proof covering all such cases.

## Minimal future observation protocol, not activated

Select one blocked sender/request without altering original workload, topology or timeout. Record a bounded sequence of transitions with: process/binary/source identity, VM incarnation, stable request token, stable sender/target incarnation, operation phase, native processor owner, request/mutex relation, queue/dispatcher/action/result owner, reply status, sender wait/runnable/current state, per-owner sequence and causal handoff tokens. Include loss/overflow/torn flags; a missing event is unknown unless coverage and ordering are established.

Raw object addresses are not stable request IDs across moving GC. A possible small diagnostic change is a private immediate request token carried with the internal request, plus a properly rooted scoped handle associating the result mutex with that token. The current two-slot vector has **no such field**. Appending a private immediate field requires an actual constructor/consumer census and generated Scheme/C qualification; it is a proposal, not an authorized implementation. A raw-address native side table is not an equivalent shortcut. Handle release must follow caller consumption or supported error; finite capacity must reject incomplete evidence rather than change scheduler semantics.

Keep the carrier preallocated and bounded, without heap allocation, object pretty printing or new blocking locks in hooks. Cross-processor handoff must carry a matching release/acquire acknowledgement; timestamps or local sequence numbers alone do not prove cross-owner order. A nested callback needs its own request identity or bounded nested owner stack, so it cannot erase the suspended outer request. Unsupported escape/overflow must remain explicit diagnostic failure. The diagnostic's native compiled ordering, GC root lifetime, carrier persistence and observer cost under the existing budget need matched controls before trusting it.

Six function-level hook surfaces are sufficient to *describe the intended coverage*, not yet proved sufficient to implement it:

1. `##thread-intr!`: request/reply identity, wait attempt and final return/error.
2. `##thread-intr-propagate!`: target transfer, selected receiver, queue/runnable publication.
3. C processor queue enqueue/dequeue: node publication and dispatcher ownership.
4. `##thread-resume-execution!` and `##other-interrupt!`: detached owner, action start/return, reroute and nesting.
5. Result storage plus mutex unlock/acquire/signal: GC gap, early reply, waiting reply, sender activation.
6. Target termination/abandon and sender restore/error: retained terminal disposition and last-consumer release.

## How a retained trace would choose the next repair

| Last proven transition | Required next evidence | Candidate repair surface, conditional on that witness |
|---|---|---|
| Request queued, receiver never dequeues | Matching receiver/current target, pending flag, idle/wake acknowledgement and no later owner | Publication/notification handshake; a timeout change alone is insufficient. |
| Dequeued, no transfer/action/terminal event | Dispatcher activation and current roots; nested/exception disposition | Preserve dispatcher ownership/root lifetime or supported exception completion. Do not infer loss from queues. |
| Thread queue appended, target runs but never removes it | Exact target incarnation, resume/fast-yield/native interrupt checks and queue token | Delivery safe-point or placement/resume protocol, with migration recheck. |
| Action starts but never returns | Action-specific progress/nesting/exception, outer retained owner | Callback semantics/reentrancy; waking idle processors cannot substitute for action completion. |
| Result stored, unlock not completed | Heap-check/GC phase, mutex live root and real lock owner | Result-root/unlock transition or GC progress; preserve first-eight collector guarantees. |
| Sender made runnable, never restored | Actual run queue membership, unique scheduler owner and selection | Scheduler activation/ownership, not request queue notification. |
| Sender restored, no return/error | Acquire/resume-thunk, mutex state, final heap check and result read | Reply-consumption/error path. Do not count runnable as completion. |

No row is selected as the actual root cause by current evidence.

## QNT correspondence and remaining premises

The new `interrupt_request_lifecycle.qnt` extends the prior dequeue-versus-empty control with one synchronous request, dispatcher-local ownership across a moving collection, result storage, another pre-unlock collection, sender readiness and final consumption. A separate terminal-abandon scenario preserves completion responsibility. Two positive exhaustive safety checks and four decoded negatives cover premature completion at result storage, lost dispatcher root, stale address identity, and dropping responsibility on target termination. The validation summary gives exact source hash and native-evidence boundary.

This intentionally small abstraction assumes scanner coverage, unique owners, action/abandon progression and eventual scheduler activation. It does not prove liveness, early-reply versus waiter insertion concurrency, complete exception/continuation semantics, nested requests, multiple senders, C memory ordering, or native GC maps. Early completion is mapped from source in the table but is not an independently validated model branch here. The model's `rooted` flag is a proof obligation, not a new runtime guarantee. No further native acceptance or first-writer claim follows.
