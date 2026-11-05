# Scheduler device return: materialized results before unlocked SYNC

2026-10-24. Grok implementation handoff for the same `procedural-suffix.lock.json`, main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, cumulative patch `6aca28e02e43991b90c17784c758f953541cc7feec06f799bb0681eae2c905cf`. Only evidence/QNT is changed here. Source snapshot/hashes come from `prepared-signal-native-commit.json`, not another thread's build or vendor HEAD. This refines `delivery-service-roots.md`; it supersedes the suggestion to retain an unconditional native P reacquire.

## 1. What the current source establishes, and what it does not

- SMP `##thread-check-devices!2869..2899` is called with P held and calls `##wait!2774..2790`. The latter also acquires the VM waiting-processor deque lock. The C selector keeps `condvars[MAX_CONDVARS]` and `devs[MAX_CONDVARS]`11727..11728, drops P11774, waits11776, **blocking-reacquires P11782**, then publishes ready bits11784..11790. There is no SYNC service at that reacquire.
- `##sync-op-interrupt!` in `_kernel.scm1468..1485` saves RA/registers, enters `service_sync_op`1477 and restores afterwards. `setup.c2080..2090` enters `execute_sync_op_loop`; its barrier1974 requires collective participation. `##lock-scheduler-object-with-sync-participation!690..700` already demonstrates try/fail/SYNC/retry, but its comment does **not** prove all its callers have zero other locks or correctly mapped native wait arrays.
- Feasible dependency cycle: waiter A has returned from OS wait but blocks reacquiring P; owner B cannot release P until its collective completes; collective needs A. The reacquire edge is proven source; *a specific historical B holding P at that GC* is not captured. This is a structural deadlock hazard/diagnostic target, not a new claim that the real hung request has been identified. Even without a collective, blocking reacquire can starve service.
- Simply adding `service_sync_op` to that C loop is unsafe. `condvars[]` contains moving SCM values without a registered map for this new GC boundary; device pointers/descriptors require independent lifetime protection. A native reference count is not a Scheme root.
- A second, concrete contract mismatch is visible: caller2893 unlocks P before `##device-condvar-broadcast-no-reschedule!2894`; callee4477..4485 says it assumes P held, immediately removes/self-links the device deq, then calls generic condvar signaling. Generic signaling4520..4565 blocks on C/W, removes BTQ/TOQ and adds runnable threads. It is **not** a proved no-GC native result commit. Do not copy that detach or invoke this old callee as the new unlocked completion helper.

## 2. Selected finite change: capture, poll, try-publish, drain

Add one **scheduler-specific** wait activation; do not change arbitrary FFI or port read/write waits. All Scheme orchestration enters and returns with zero primitive scheduler/VM locks. Native helpers own their complete try-lock scopes and return with zero locks. No new generic event framework, coordinator, result-mutex polling or new task.

Proposed internal entries (new names, not existing symbols):

```
___scheduler_wait_try_capture(ps, capsule, timeout)
___scheduler_wait_poll(ps, capsule)
___scheduler_wait_try_deliver_one(ps, capsule, signaled_action)
___scheduler_wait_finish(ps, capsule)
```

`try_capture` and `try_deliver_one` are no-GC/no-callback/try-only leaves. `poll` blocks only in the already bounded scheduler OS wait, does not reacquire P, invoke Scheme or participate in GC. `finish` is a checked native state transition; actual device close/release callbacks execute later, outside locks and with rooted Scheme context. Do not hide virtual destructors in finish.

### Capsule fields and root installation

Prepare storage before taking scheduler locks: a scanned Scheme capsule contains state, VM incarnation, wait epoch, owner processor SCM, original user deadline, effective deadline, record count/cursor, status/errno, records, pending destination and exact ownership-unit flags. Each preallocated record holds condvar SCM, foreign-wrapper SCM, registration epoch, native device/handle identity token, observed/valid readiness, and disposition (Unpublished/Delivering/Acked/ClosedAck/Retained). Native-only bits/tokens may use preallocated byte/typed storage; raw native pointers are never mistaken for mapped SCM roots.

Allocate maximum `MAX_CONDVARS` record capacity during processor preparation, before OPEN/GO, not on the P-held fast path. Publish the capsule in a **named processor Scheme field** scanned by `mark_processor_scmobj(mem.c7786..7799)`, and keep it mapped lexically while servicing SYNC. Current processor has21 fields plus type word (`_thread#.scm1994..2040`, header `___PROCESSOR_SIZE=22`6519); append a field and update constructor/size/setup/generated accesses consistently for the selected SMP layout. Do not assume the C native structure is scanned, reuse user `specific`, or silently commandeer `unused-field15`. Allocation failure occurs before wait admission and preserves the old runnable cohort.

Only one active capsule per processor/owner activation. Reentrant service must see Busy and retain the old capsule; it cannot reuse/clear its banks. Generation is a nonwrapping immediate token validated with VM incarnation; exhaustion refuses a *new* capture before mutation. Retained old-token completion never clears current state. Do not allocate bignums in a leaf.

Device condvar registration also needs an internal epoch/owner stamp (append internal fields to the selected condition-variable layout, not a user field). New registration under C/P in `##wait-for-io!4401..4464` assigns the next stamp; unchanged membership keeps its stamp. Claim/close/dequeue checks that stamp. The field ABI/header/type constructor/generated code must migrate together. It is not valid to validate only a numeric fd or the same condvar address.

### A. Capture: no borrowed view is allowed to escape half-built

`try_capture`: try P, traverse exactly the current device deq, validate each condvar/foreign wrapper and registration under its protecting lock. Use try for every additional lock; never wait on C with P held. On contention unwind all acquired locks/native reservations and return Retry without changing registration readiness. Reservation rollback only adjusts protected counters; any last-release destructor is deferred to rooted unlocked cleanup, never run during that unwind. It is acceptable to read candidate C under P then try C because no acquisition waits; revalidate the deq after acquisition. No writes to shared queue until the entire capture validation succeeds.

Copy all SCM references into capsule records and obtain native device/descriptor wait borrows before unlocking P. Initialize validity masks/status before publishing Captured. If over capacity, retain the existing immediate-recheck overflow semantics; do not truncate a ready suffix or extend the wait. VM waiting-processor deque insert/remove in old `##wait!` must use separate no-GC try-only VM transactions, never block on VM while holding P. Registration/abort remains an acceleration hint; finite wait return is independent.

**Lifetime prerequisite must be implemented, not assumed:** POSIX `device_add_ref1601..1610`/`___device_release1613..1631` use plain increments/decrements outside USE_PUMPS, and release can call a virtual destructor then free. They are not a safe concurrent wait lease. Add checked wait-borrow/close-admission to the existing device lifecycle: device mutex/atomic closed+waiter count serializes admission, close marks Closing and defers actual descriptor destruction until last borrowed poll ends. Capture uses try only; close/release/group cleanup must consult the same guard. Do not call device_release or a virtual close under P. `___device_group_cleanup189..198` currently frees the group after breaking on cleanup failure; a live wait borrower requires retaining its descriptor/group instead. Direct close `___os_device_close(os_io.c9946)`, foreign release via `___device_cleanup_from_ptr1685` and `___device_cleanup1635`, group cleanup189, and final `___device_release1613` must converge on that guard. `##close-device(_io.scm1794)` is a direct-close caller; foreign one-shot release in `c_intf.c1683` does not by itself protect a wait borrower. If a selected backend cannot guarantee descriptor stability/guarded close, reject its capability before VM OPEN/delivery acceptance; an already accepted activation must retain its debt and report the existing scheduler fault, never pretend not-accepted; do not claim foreign-wrapper reachability prevents explicit release.

### B. Poll: return results, not ownership of P

`___scheduler_wait_poll` enters with no scheduler locks and the processor still a managed **active GC participant**. It uses native device borrows and current SCM references only in this synchronous no-SYNC/no-GC call. Do not mark it GC-passive while its raw arrays are live. D_eff is the existing proposed min(original deadline,now+50ms); all EINTR retries reuse that absolute value.

On every OS return, copy all actually observed per-entry readiness and validity/status/errno into the preallocated capsule **before leaving the C call**. Preserve partial readiness independently of an error return. Use the current `devs[i]==NULL` convention only for backend entries whose completion semantics are established; unknown/unwritten entries remain Retained, not invented Ready or silently discarded. `devs[]`/`condvars[]` and all interior SCM addresses end here. There is no P lock reacquire. Mark the native poll-reader borrow finished, but retain ownership needed by delayed close/destructor until finish/context-safe cleanup. Publish Returned only after payload is complete; no second poll overwrites an unconsumed result.

### C. Retry and SYNC: rooted capsule, no native array continuation

The Scheme wrapper now checks pending SYNC and calls `##sync-op-interrupt!` with zero M/T/C/P/VM locks. On failed try-publish, do the same and retry from freshly loaded capsule/processor/record values. Repeated GC can move every SCM object; retain no pre-GC `condvars[i]`, vector interior pointer or raw processor-id lookup. No ordinary hint/thunk callback runs before the capsule/partial suffix has a durable owner. If SYNC selects resize, existing active-wait debt must make owner removal refuse before membership commit or perform an explicit rooted handoff; keeping a C local token alone is not admission protection.

This removes A→P while A owes GC participation: a failed try returns rather than reserving a ticket, so A can join the collective B is waiting for. It does not make a permanently nonparticipating member or nonreturning callback recoverable.

### D. Publish/drain: one native ready record / waiter at a time

`___scheduler_wait_try_deliver_one` enters/returns unlocked. It reloads one record through the current mapped capsule; validates VM/wait token, C registration, foreign/handle identity, and owner P. Use C/W then sorted unique processor set `{registration-P, W.toq-P, runnable-D}` with only tries and revalidation. D is migration-target, else pinned, else current P. W is actual C.leftmost; no W means finalize that record under C/registration-P. Contention releases every lock and returns Retry **without clearing readiness, advancing cursor, detaching C or settling a borrow**.

For a valid waiter, reuse the *planned pure native* BTQ/TOQ/runnable kernels from the result-release proposal, not their Scheme procedures. Set `##thread-signaled-condvar-action!` as data, remove W's BTQ/TOQ membership, insert it once into admitted D, install any rooted pending-D before unlocking. Source4520..4565 provides semantics, not a callable leaf. This call wakes one waiter, not an unbounded broadcast under one lock set. After unlock, checked best-effort notification uses the prior durable-D contract; reload before next record/waiter.

Keep C on the registration-P device deq while it has pending waiters/results. When actual C wait queue becomes empty, atomically detach/self-link its registration deq under C/P, mark record Acked and release locks. A concurrent new waiter either joins the same live registration/readiness episode or registers a fresh epoch after detach; it cannot splice a new incarnation into an old record. Do not call the old `##device-condvar-broadcast-no-reschedule!` to detach again. Native mutation is no-GC/no-escape; partial list/tree mutation does not return Retry.

Close, unregister and owner migration cannot silently erase a Returned/Delivering record. A verified close outcome may mark ClosedAck only after affected waiters have an owned close/error outcome. Unexplained generation mismatch is Retained and blocks capsule reuse; it is not “nothing to do.” Serialize re-registration or explicit handoff until that old obligation is acknowledged. This is the narrow admission change needed to avoid stale readiness waking a new fd/registration.

When all records are Acked/ClosedAck and pending-D/native users are settled, finish drops capsule-owned references/borrows. Device destructors/close retries execute in the legal rooted, unlocked cleanup context. On error/nonlocal escape, keep unacknowledged suffix, capsule, epoch and native protection; repeated entry resumes the cursor without another OS poll. An old completion after reuse fails token/incarnation validation and touches neither new records nor new borrow counts. No “return success” on unknown cleanup.

## 3. Callers which must migrate together

| Current selected SMP path | Required lock contract / ordering |
|---|---|
| `##thread-check-devices!2869` and `##thread-poll-devices!2849` | Replace with unlocked capsule orchestration; poll uses timeout=#f but same result ownership. Neither assumes P held on return. Do not retain old `let loop` deq cursor across SYNC. |
| `##thread-schedule-with-acquired-processor!3247..3268` | Drop P before entering the new wait orchestrator. After it returns, service only unlocked; reacquire/recheck current runnable/TOQ through a legal try/SYNC boundary. Do not execute the old unconditional unlock3262 after a helper that already returned unlocked. Reload next-sleeper/condvar after any GC/retry. |
| `##thread-heartbeat!2906..2929` | Move device polling outside its old P-held region. Timeout work gets its own clearly scoped lock acquisition; no wrapper called under a leftover P lock. Audit its tree mutation generated calls separately; this wait change is not a no-GC certificate for the old timeout routine. |
| `##wait!2774` | Scheduler-specific capsule path replaces P-held VM-deq/wait/reacquire. Bare idle may keep its existing finite, unlocked path provided waiting-deq borrow/admission is consistent. Do not modify unrelated port I/O waits. |
| `_kernel.scm4558` / `os_io.c11703` | Add a separate scheduler capture/poll/finish bridge and migrate every selected SMP scheduler caller. Leave non-SMP/legacy ABI separate; no hand-edited `_thread.c`. No native SYNC call inside poll. |
| `##wait-for-io!4448..4454`, device close/release/group cleanup | Common registration epoch and checked wait borrow. All detach/close/re-register paths use it; otherwise stale event/last-consumer proof is incomplete. |

## 4. Generated C roots and ordinary-error paths

For each actual emitted label, certify `ADJFP`, frame size/map, RA, live registers/stack slots and the rewritten location after each `##sync-op-interrupt!`/allocation/exception edge. `_kernel.scm1474..1480` and4558..4593 show the existing RA/W_ALL/R_ALL pattern; preserve the real convention but do not copy unrelated offsets or infer maps from `targ-use-all-res`.

Required roots: capsule, owning processor, timeout value until deadline snapshot, record vector/selected C/foreign wrapper, resumed action/outcome, pending remote D and live sender/request units. Processor named field roots capsule independently of a transient C stack; copied record fields root condvars/wrappers even after detach. The C poll arrays are valid only before returning to a safepoint; they are **not** repaired by W_ALL. Try-publish uses direct SCM arguments freshly loaded after each GC and no native locals persist between attempts.

No CHECK_STACK/CHECK_HEAP/POLL, allocator, indirect callback, virtual release, blocking primitive lock or SYNC edge may occur inside capture/publish locks. Inspect configured macro expansion, transitive call graph, actual optimized object and acquire/release instructions in B. A generated Scheme check may run before calling these helpers, because their entry owns no primitive locks; this is the reason for changing the full caller contract rather than inserting C SYNC into the old array frame. Release status is an immediate private code, never a newly allocated tuple under locks.

Snapshot error, timeout, partial-ready and overflow outcomes into the capsule before raising/reporting. A Scheme escape after two of N acknowledgments retains N-2 records and exact loans. Actual caller frame root coverage at that escape is mandatory. Unknown lock-unlock result enters the existing retained/terminal policy; do not resume GC over a half-mutated tree.

## 5. Reflection and falsification

| Chosen change | Failure edge removed | Still depends on / what refutes it |
|---|---|---|
| No ticket reacquire after select | OS-return→P-wait→missing collective participant | Every caller really enters/returns unlocked. Capture a failed try that owns no lock, then SYNC completes before retry; a leftover lock refutes it. |
| Materialize before C return | New GC boundary sees stale native condvar array | Real maps and scanned capsule. Move C/wrapper/P twice between results; untouched raw address or missing root refutes it. |
| Per-record ACK, no repoll | Retry/error erases ready suffix or consumes an event twice | Partial observed-result validity and receiver responsibility. Block second record through GC; first stays once-only, second remains until delivered/closed. |
| Registration token and checked borrow | Old ready bit targets a reopened fd; close frees native device during poll | All close/unregister/re-register/group cleanup entrants must honor guard. Numeric-fd reuse or plain refcount shortcuts refute it. |
| Pure native one-waiter commit | Lock-held generic broadcast triggers GC or detaches without P | Same kernels/lock set/codegen certificate as release plan. Old4477 helper or uninspected callback in body refutes it. |

This blocks a concrete *possible* wait-for cycle and two source-visible unsafe boundaries; it does not identify the historical stalled R by itself. Runtime proof still needs the same-B record showing poll-return, failed P try, pending SYNC participation, moved roots, post-SYNC publish and terminal reply. Pure kernels plus finite obstruction/fair scheduling remain conditions; QNT cannot prove C maps, OS behavior or every unrelated P-lock caller.

## 6. Same-B native acceptance (existing bounds)

No native test is run in this evidence-only task. Grok uses the existing30s focused cap and original pressure budgets from `delivery-integration-native-plan.json`.

1. Freeze B's lock/source/compiler/config/ABI constructors, regenerated `_thread.c`/`_kernel.c`, configured preprocessed units, object/archive/GSI/UUID and helper/hook identities. Add passive events at capsule admission, poll-return mask, failed try, SYNC entry/exit, each record claim/ACK and final release. Hooks execute the linked helper, not a stand-alone copy.
2. Deterministic contention/SYNC handoff: real nonready-device wait returns; a passive hook exposes finite P contention while an admitted member requests real GC from a legal unlocked safepoint. Never add a P-held GC request as test machinery. Waiter must return a failed try, enter real SYNC with zero primitive locks, then publish after P is released. A test hook must not itself invoke GC under P or manufacture a production-validity claim; if source owner cannot legally enter GC with P held, report that cycle precondition absent and test legal contention + pending SYNC instead. Do not fake a deadlock by unsafe test code.
3. Two ready records, force contention/GC after the first ACK. Force two moving GCs. Verify first delivered once, second still retained and eventually delivered, all capsule/condvar/wrapper/processor references rewritten. Persistent EINTR retains D_eff; scheduler RECHECK changes no user deadline.
4. Close/reopen same numeric fd, registration replacement, processor instance replacement, new waiter during drain, same-epoch retry, exhausted generation, recursive wait and stale completion. Old result cannot wake the new registration or settle its borrow. Real close rejection/retention must be visible and preserve affected waiters.
5. Readiness plus backend error, partial/overflow result, exception before claim/between ACKs/cleanup error. No re-poll before suffix disposition. Last descriptor release outside P/C/W/VM; unknown close leaves root/epoch/native protection and blocks reuse, not GC progress of unrelated owners.
6. After focused source/codegen/native certificate, use same B for existing100000/p11 two8-round batches (12s per round) and original two interrupt stress files inside unchanged shared3600s window. Do not rerun full inventory, change topology/heap/caps, or claim TFIB/lifecycle closure.

The resulting change is larger than adding a SYNC check, because the original C arrays were the lifetime boundary. It is finite and directly implements that missing boundary. Current actual generated-C certificate remains absent; count stays8/12.

## Retained QNT result and limits

Quint/TLC14 controls matched expected results:2 safety/conditional-progress positives,9 decoded safety mutants,1 temporal deadlock-shape counterexample and2 completion witnesses. The two positives explore12 distinct states/24 generated each; both include two GCs interrupting two-result publication, result completion, cleanup and a second epoch rejecting an old completion. Every check used the original30s cap. Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/f12ec6dce9024caaa13d6c252a4aa7c4/outputs/device-relock-sync/receipt.json` (SHA256 `ab95c808bbb0a35dba5a01a0b16392b7e58755248c942aa943adf3b39b689fbb`).

`Current` models an external P owner waiting for this participant, while old reacquire cannot service SYNC. It establishes the conditional cycle, not that such an owner was observed in the historical hang or remains legal after all lock-holding callers are fixed. `SyncHeld`, `LosePrefix`, `MissingMap`, `StalePointer`, `StaleEpoch`, `EarlyFree`, `RetryClear`, `OldCompletion`, `LockLeak` each remove a named guarantee. ClosedAck is assumed to be a real owned close disposition, not a Boolean replacement for waking blocked callers.

Fair progress assumes per-action weak fairness, finite backend wait and lock obstruction after collective service, and a participating cohort. QNT versions represent relocated addresses; no C11 memory model, actual frame-map proof, real fd/virtual-destructor behavior or native pressure is claimed. The model abstracts one ready waiter per record and two records; multiwaiter tree correctness still uses the preceding same-B differential/native controls. Native runs0; actual generated certificate null; source refinement/native admission false.
