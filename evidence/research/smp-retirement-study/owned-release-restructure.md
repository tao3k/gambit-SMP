# Selected restructure: prepared request release, real waiter, exact pin ownership

2026-10-24. Concrete Grok implementation decision against `procedural-suffix.lock.json`, main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, cumulative patch6aca28e0. This refines steps1/3 of [delivery-integration-handoff.md](delivery-integration-handoff.md). The later user instruction explicitly requests QNT to distinguish the algorithm; no new lifecycle/FFI/wait framework is proposed. Runtime implementation and native tests remain for Grok; this chat edits evidence/models only.

## Selected design, not a menu

Create a request-specific `##thread-intr-release-owned!` with prepare/revalidate, prepared mutation and finish. Make `##thread-intr-abandon-owned!` a checked entry to it. Do not call the current `##mutex-signal-no-reschedule!` after unlocking. Do not use its lock-dropping acquisition path inside commit. Factor its mutation semantics into a prepared helper (proposed `##thread-intr-signal-prepared!`) whose required locks are already held; leave ordinary non-request mutex callers unchanged.

The correctness mechanism is: ownership/link changes and runnable publication happen under one validated lock set; any contention/GC occurs before mutation, after releasing that set; units outlive publication until actual wake/result/abandonment. This eliminates the *specific* wrong-neighbor/wrong-waiter/unlocked-signal choices in the current code. It does not itself prove the earlier lost-request hang has this cause. That attribution still requires the same producer's R trace and original tests.

## 1. Fields: these are two different structures

| Meaning | Current SMP fields/macros | Protection |
|---|---|---|
| Mutex membership in the owner's list | `_thread#.scm967..970`: struct slots2 next /3 prev, accessed by `macro-btq-deq-*`; owner slot8 | Mutex M plus actual owner T protect removal; owner T protects the containing list and neighboring entries. |
| Threads blocked on M | slot4 color,5 parent,6 left,7 right/leftmost; `macro-btq-leftmost M`, `macro-if-btq-next`1040 | M protects tree/head; selected waiter W must also be locked before removal/state changes. |
| Waiter's proposed new owner | `macro-thread-result W` | W; acquire the distinct new owner N before checking termination/relinking. |
| Timeout membership | `macro-thread-toq-container W`, TOQ parent/links | W plus actual TOQ P; use current containers after retries. |
| Result request | `[next,mutex,target,phase]` | T for enqueue/pop; M and explicit current execution owner for release/terminal transition. Diagnostic IDs are not object addresses. |

`macro-btq-deq-next M` is never the waiter selector. For a singleton owned-mutex list it can be the owner thread sentinel itself; mistaking it for a waiter can select the target instead of the blocked sender. Empty blocked tree is `W == M`, not null.

## 2. Exact prepare/retry order

At entry know the held-lock set. Ordinary entry requires no T/P/M locks. If called after an exception while a known lock is held, unwind only that recorded lock set to a consistent pre-mutation boundary first; unknown/half-mutated state is retained and does not enter this helper.

1. Before any locks, check/reserve heap/stack and prepare rooted request, result, unit and wake state. No allocation/logging/callback will be introduced later in the commit region.
2. Acquire M using the existing participating helper while no T/P is held. Read owner T and blocked-tree leftmost W under M. If W!=M read its intended owner N only after W is locked; provisional observations are rechecked.
3. Use nonblocking, address-ordered thread-lock acquisition, removing #f and duplicate identities. Existing `##trylock-3-threads!961`, `##unlock-3-threads!914` implement alias handling for up to three thread identities. Do not call them assuming they tolerate an already-held duplicate ticket. Include expected old target T, W if present and N if a thread. If N was learned after locking W, release/retry the whole set to acquire the complete set in order. Any try failure releases all acquired tickets and M **before** wait/SYNC; restart from step2 and reload every value.
4. With W locked, discover its current TOQ P and choose D using migration-target, then pinned, then current-P, matching source705..721; do not substitute current-P for a pinned/migrating waiter. Try these P locks in address order, coalescing aliases. A failed P try releases P tickets, thread tickets and M, then services only legal unlocked SYNC and restarts. Never wait holding M/T/W. No source helper that blocks or drops/reacquires a lock belongs after this point.
5. Revalidate M.owner==expected T, request execution eligibility, W still current leftmost and `W.btq-container==M`, N still `W.result`, W's timeout membership/container, destination membership, and old-owner deque reciprocity. Recompute termination/new-owner disposition under N's lock. Check previous/next links point back to M; self-linked with old owner is a partial state, not evidence to repeat removal. If any observation changed, release all and restart. Relocated values must come from live mapped Scheme roots after every SYNC/GC.

This follows current mutex→thread→processor ordering and avoids the inverse T-held wait at1514..1516. It also removes the generic signal's4235..4246 drop-M/keep-W acquisition branch from this request's commit. A retained ambiguous phase5 stays retained; no fake completion or pin decrement.

## 3. Exact owner unlink and waiter commit

For a linked M, under validated M+T:

```
P = M.deq_prev; Q = M.deq_next
require P.deq_next == M and Q.deq_prev == M
P.deq_next = Q
Q.deq_prev = P
M.deq_next = M
M.deq_prev = M
```

The first two writes are missing from the current C helper. `P==Q==T` for singleton is legal: these update different fields of the same sentinel. Head, tail and middle are the same algorithm. Do not clear the owner's list wholesale, take locks on arbitrary neighbors, or invoke `macro-btq-deq-remove!` a second time after native removal. These stores do **not** modify M's blocked-tree slots4..7.

Implement this in `___thread_intr_release_commit295` or its prepared replacement, using current header `___BTQ_DEQ_NEXT_FIELD`, `___BTQ_DEQ_PREV_FIELD`, `___BTQ_OWNER_FIELD`; check all refusal conditions before the first neighbor write. Pass/revalidate the already prepared expected owner/neighbor context; no raw pointers survive GC. Current macro-derived field addresses and selected no-GC/no-escape object code must be inspected on the final build. A hardware fault midway has no rollback guarantee.

Then, still with the prepared set held:

- No waiter: set M.owner to abandoned and phase to terminal abandoned; finish without any signal call.
- Waiter W: reuse the **mutation semantics** of4221..4312: remove W from M's blocked tree; determine N's live/terminated/not-owned disposition; link M into live N's owned-mutex list or set abandoned/not-owned state; clear W.result; install abandoned-mutex resume action for an abandoned request; remove timeout membership under the already-held TOQ lock; insert W into the validated runnable queue exactly once under its P lock. Do not infer successful result from the abandoned resume path.
- Publish request terminal/release stage only after consistent owner/tree/runnable state; drop P/thread/M locks exactly once, respecting aliases. Do not release the target delivery unit while a wake obligation is still pending. Physical unlock and sender's actual lock2 result remain separate observations.

Grok should factor a prepared variant of the tree/timeout/runnable update rather than call generic helpers that reacquire locks. In particular `macro-thread-toq-remove-if-in-toq!1431` acquires P internally and must not be called with that P already held; use its underlying `##thread-toq-remove!` only with its required lock already held. Likewise use the existing without-locking runnable insertion only after the correct destination lock is held. Preserve current red-black tree algorithm, priority and terminated-new-owner behavior; do not replace them with a one-link shortcut.

This commit must have no recoverable throw/GC/participating call. If generated code still inserts one, move reserve/checks outward or inline/refactor that specific prepared operation. Do not declare the region atomic based on a QNT step. The exact final generated-C region and transitive machine-call certificate is a finite implementation gate, not yet present.

## 4. Pin implementation: three units, explicit transfers

Reuse VM `delivery_admission`; do not create a new global lifetime framework. For a synchronous request the maximum required roles are construction→target unit R, sender unit S and each concrete hint unit H. Async has no S. A role transfer does not decrement then increment the VM word.

Preallocate a tiny Scheme unit cell and request/hint objects before taking their pin where possible. A unit cell starts Empty; after `___delivery_enter` succeeds it becomes Acquired. Guarded release uses the current four-argument vector CAS **(vector,index,new,old)**, e.g. `##vector-cas! unit 0 0 1`, checking the returned old value. Only the winner calls delivery_leave. This preserves source header5484 `(v,i,val,oldval)` order. Bind generated operands/maps and actual lock-free implementation; no bignum/allocator path in release. A counter underflow/inconsistent unit is a fault, not an ignored successful release. Crash between unit claim and count decrement is retained debt, not grounds to reopen/free.

For concrete private layout: keep existing slots0..3; retain diagnostic immediate ID at4; put target unit at5, yielding `[next,mutex,target,phase,id,R-unit]`. S stays in the sender's rooted lexical guard; H is captured by its procedure closure. Migrate constructor/propagate/drain/execute/abandon and diagnostic shape checks together. Ordinary procedure/hint nodes remain their existing two-field shape; no unconditional unit/ID read on them. This refines the preceding five-field diagnostic-only plan, not public API or non-SMP layout.

| Path | Exact responsible release/transfer |
|---|---|
| Object/unit allocation before pin fails | No pin exists; propagate allocation error without decrement. |
| First admission fails | Not accepted; caller retains payload, no decrement. |
| R acquired, synchronous S acquire fails | Construction guard consumes R once; no target enqueue or lock2. |
| Any supported error before T enqueue | Local guards consume acquired R/S/H; settle a locked result mutex through real abandonment if already installed. Never proceed to lock2 waiting for unpublished work. |
| T enqueue commits | R transfers from construction to queue, then pop to execution. Sender/constructor may no longer release it. |
| H made but target terminated/stale/self/non-running | H's local guard releases once on every branch, including exception. Runnable insertion is not H publication. |
| H enters P queue | H transfers to queue→callback; callback cleanup guard releases it even if wake/forward/drain raises. A newly forwarded hint owns a distinct H cell. |
| Thunk/result/release completes | Execution consumes R only after actual owner transfer/abandon plus wake settlement; partial commit retains R. Dynamic-wind after cannot unconditionally decrement. |
| Sender lock2 or result decoding raises | S's own unwind guard releases once after last required mutex/result access, including abandoned-mutex raised by lock2 itself. It never releases R. |
| Continuation reentry/duplicate cleanup | Consumed unit cannot reacquire or decrement again. Request phase rejects a second execution; unit guard prevents repeated unpin. Unsupported native escape retains rather than inventing a decrement. |

Keep units rooted while semantically needed; unit CAS is not a root registration. Every participating retry must reload request/M/T/W/N/P from generated maps. Allocation failure while forwarding an already accepted R retains its queue/target unit and records a real fault; it must not erase R or be counted as completed. This narrow plan does not promise arbitrary allocation-failure recovery.

## 5. Existing research and selected trade-off

The repository's `result-mutex-mailbox-source-contract.json` supports one queue owner; `stable-delivery-domain-source-contract.json` requires committed responsibility rather than wake-only progress. The integration/source audits already distinguish result nodes from procedure hints and actual release from body completion. Their old source identities/native receipts are references, not this lock's proof.

The pinned OCaml `domain.c` reference sets a persistent pending state before notifying and executes its handler without the interruptor lock held. That supports “durable work plus notification” and outside-lock callback boundaries, not importing its STW algorithm into Gambit. Pinned Chez `thread.c` serializes list/resource updates under its declared mutexes; it is not evidence that Gambit deque and waiter-tree fields are interchangeable. Companion JSON binds exact immutable reference bytes and excerpts.

Trade-off: a small request-specific prepared path and up to3 distinct thread locks plus coalesced P locks, local retry under contention, and rooted unit cells. In return there is no half-unlink rollback, duplicate pin consumption or signal with missing locks. More retries and small per-request allocation are accepted; no speedup/production-stability claim is made before matching B's original pressure. No global serialization lock is held through Scheme thunks.

## 6. Same producer: decisive native acceptance

Keep the existing main native plan, one frozen B, original fixtures and budgets (30s focused,12s flood rounds, shared3600s original pressure; no raised heap). Add the following short controls **before** pressure, all reaching the actual helper:

1. Owned list singleton, head, tail and middle; retain two unaffected mutexes as witnesses. After normal and abandoned release, traverse both directions: neighbors reciprocal, target no longer owns M, unrelated mutexes unchanged. Negative old self-link-only implementation must fail this check.
2. Owner sentinel/next owned mutex deliberately different from true blocked W. Verify selected `M.leftmost`, W.container, resume action and sender lock2 result. Include no-waiter; N==W, N==old T and distinct N; terminated N; duplicate thread/P locks acquired and released once.
3. Contend each needed thread and P lock before mutation. Force the legal unlocked SYNC/GC retry; change head/timeout/route during it. Verify M is untouched before successful revalidation, old tickets released, current W chosen, and no sleeping with M/T held.
4. At signal entry prove actual M/W/N/TOQ/destination ownership, not a boolean event written by the fixture. Mutation negative releases M/W first; detect the missing-lock precondition before accepting output. No diagnostic hook waits while holding a lock required by its observer.
5. Every pin table branch: actual constructor failure, second-acquire refusal, unused H, forwarded H error, sender lock2 abandonment, nested/reentered cleanup, and partial commit retained. Compare expected outstanding units with the VM word after the real last consumer; no reset-to-zero or blanket fault clearing.
6. Result relocation and generated maps across prepare retry and return; inspect the exact no-GC commit and case-specific branches. Then run the bound flood and original two interruption files from `delivery-integration-native-plan.json`. On failure produce the actual R committed prefix and stop unchanged reruns.

Safety of these stores, fairness/eventual lock acquisition, callback return and root correctness are separate obligations. This design removes the three concrete wrong transitions; it does not promise starvation freedom under an adversarial scheduler or a forever-blocking callback. A native failure remains a rejected implementation even if the finite model is green. Do not report9/12 or amend join/qualifier/receipts from these results.

## Focused QNT decision receipt

`models/gambit/owned_release_algorithm.qnt` checked15 controls against the current procedural-suffix identity:4 positive safety,7 decoded mutant counterexamples and4 successful reachability controls. Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/5b5e9c1723d1446598d02dd4d8d4186b/outputs/owned-release-algorithm/receipt.json`; existing30s cap per case. Neighbor positions cover singleton/head/tail/middle. This finite abstraction does not prove actual red-black/TOQ operations, new-owner aliases, generated frame maps, callback termination, weak-memory implementation or starvation freedom. These remain named native/source obligations; no new broad model framework is introduced.

### Concrete native boundary refinement

[prepared-signal-native-commit.md](prepared-signal-native-commit.md) selects one nonblocking native try-commit containing acquisition, prepared tree mutation and unlock. Both normal/abandoned release use it; Scheme retries only after ordinary return with zero scheduler locks. It replaces the preceding split Scheme-held-lock implementation suggestion. Native BTQ/TOQ remove and runnable insert mirror current generated algorithms; no generic signal/composite TOQ/current-only runnable helper is called under the prepared set. Target unit becomes [armed,pending-D] so notification retains a scanned destination root. No implementation/native certificate is claimed.

The final native entry passes the unit explicitly: R for target Normal/Abandon, S for SenderFinal. SenderFinal checks actual private-M ownership/no-waiter and preserves terminal request outcome before S release. Truthy invalid N is not silently treated as anonymous. See the prepared-signal document for the final signature.
