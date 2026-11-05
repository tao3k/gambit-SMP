# Result-mutex handoff: source boundaries, visibility and last consumers

2026-10-23. Research only. Native remains **8/12**. No runtime/compiler/header, build, Recipe, budget, native inventory or peer operation is changed. This extends [the structural mailbox candidate](smp-repair9-mailbox-handoff-design.md), not the separately maintained measured-failure obligation model.

## What this establishes

Four handoffs can be placed at existing scheduler boundaries. The minimum candidate is an authoritative target mailbox plus a pending-aware suspension commit and an acknowledged runnable/park handoff. Two prerequisites cannot be hidden inside the word “lock” or “wake”: the raw C ticket-lock grant lacks a completion acquire, and the nonblocking abort write ignores errors. Saved object instructions substantiate the first pattern. Neither finding identifies the first corrupting writer in the reported flood.

The Scheme thread/processor lock helpers are materially different: they retry a successful trylock CAS while participating in SYNC_OP. Their successful CAS is a barrier after observing the available ticket. They must not be described as the raw prefix-fetch-add spin loop. Existing generated GC maps also provide more coverage than previously established: both resume's result mutex and wait's processor survive their call boundaries. They do not prove a newly invented C helper is rooted.

## Source cut and evidence authority

Frozen source and setup.o: audit `9fe4ebd681704f46a1a6cc76f67ab2fb`, output `mailbox-boundary-source-audit`; `readIntervalStable=true`. Source root is the existing incremental `build/gambit-core/4463d6b544c156ad648f6ff26f8786afbe3e9b73032d924e664dfc98200ba624/source`. The receipt contains full hashes, including Scheme `f987f557…`, generated C `52bd0c33…`, setup.c `9d028d74…` and setup.o `0a30cc8c…`. This binds static observations, not a launch of a particular reported flood.

Static audit `bf83f4bbfd894a8780ed0004dee09df3`, output `mailbox-boundary-static`, contains `/usr/bin/otool -tvV` output, function extracts and generated return descriptors. Homebrew llvm-objdump failed because its libz3 dylib was unavailable; that failure is retained. No toolchain repair, gsi execution, sampling or debugger attachment followed.

All line numbers below refer to frozen installed/generated source, not an unbound upstream file. The canonical header template would need a separate source-generation binding before implementation.

## Four handoffs and their last consumers

T = target thread lock; P = selected processor lock; V = VM idle-list lock; M = result mutex lock. No ordinary callback may run while any of these low-level locks is held.

| Boundary | Actual C/Scheme chain and existing fields | Existing guarantee | Missing contract / smallest candidate change | Last consumer and QNT correspondence |
|---|---|---|---|---|
| Publish request and notify | `##thread-intr!` → `##thread-intr-propagate!` (1360ff). Running branch unlocks T then calls `##raise-high-level-interrupt` → setup.c `___raise_high_level_interrupt_pstate` (364). Noncurrent branch appends the two-slot node under T; thread queue macros at `_thread#.scm:4310ff`; request next is vector slot0. | Sender creates a result mutex owned by target; existing thread queue links are under T. | Publish every thread-targeted result-mutex request only under T; keep processor procedure interrupts separate. Recheck route/current/migration state while protected; notification carries no node. Preserve destination intent. No publication after dropping T. | Pending thread queue owns request until claim. `acquirePublisher/publishMailbox/releasePublisher/notifyOnly`; wrong-destination mutation. Notification is not a GC root or a reply. |
| Claim, execute, store, unlock | `##other-interrupt!` (1475ff) and `##thread-resume-execution!` (2836–2870) pop under T, unlock T, obtain mutex-name thunk, execute, store mutex-specific, unlock M. Slow unlock wakes sender through scheduler insertion. | Both generated dispatchers retain the result mutex across the thunk; result store precedes unlock on normal return. Queue pop clears next. | Common claim/dispatch contract must preserve mapped activation before withdrawing queue root; consolidate semantics without moving arbitrary callbacks under locks. Specify terminal abandonment separately. No replay to compensate for an escape. | Queue → mapped Scheme activation → result mutex / sender continuation. `claimAtCheckpoint/executeThunk/storeResult/collectBetweenStoreAndUnlock/unlockReply/consumeResult`; lost-root, stale-local and premature/fabricated-reply mutations. |
| Current to blocked or migrated | Thread join/yield/sleep/reschedule/migration, slow mutex/condvar/I/O waits save state and relinquish current ownership; `THREAD_SAVE/RESTORE` in gambit.h6317ff. Slow unlock → runnable insertion helpers705–757. | Existing continuation storage and thread/mutex/processor queues provide roots. Scheduler holds P then only *trylocks* T, releases P on failure. Migration intent precedes resume handlers. | A T-protected commit must recheck mailbox before final blocked state. Preserve operation-specific BTQ/TOQ changes, timeout/result semantics and migration destination; no second simultaneous membership. Reuse saved Scheme continuation, not raw C pointers. | Current activation → saved continuation and actual wait/run queue; service debt must survive. `commitTargetBlock/migrate/postReady/restoreTarget`; stale-block/destination mutations. Terminal thread-end is a distinct transition. |
| Runnable to park and wake | Insertion uses P, then releases P before `##wait-abort!` (2659ff). `##wait!`2641–2657 registers idle under V, releases V, calls kernel `##os-condvar-select!`, unregisters under V. Idle scheduler3108–3113 already released P. Kernel bridge4520–4550 → `___os_condvar_select` → device select; abort→`___device_select_abort`1537ff. | No P/V lock spans select. Wait frame roots processor. Nonblocking pipe can carry/coalesce a persistent byte. | Couple ready publication and park validation under the same P. Cover every normal select return with park cleanup. Do not equate ignored write failure with delivered wake. | P runnable queue plus committed wake obligation; idle-list membership alone is not service responsibility. `prepareParkAt/commitParkAt/cancelParkAt/observeWakeAt/returnSelectError`; wake-consumption, no-validation, write-EINTR and error-cleanup mutations. |

## Lock order and an implementable park sequence

Source `_thread.scm:33–39` orders object classes M, condvar, T, thread group, P, V. Unknown lock sets use trylock/retry. Helpers690–701 service only SYNC_OP while waiting for thread/processor locks; do not add ordinary handler service there. `macro-lock-thread!` / `macro-lock-processor!` (`_thread#.scm:1042–1059`) trylock first, then these helpers. The scheduler's reverse P→T observation is a trylock, not blocking acquisition.

Preferred runnable publication705–718 holds or receives T, acquires P, inserts, releases P, then uses V through wait-abort. The “some processor” helper742–757 selects/removes idle under V but **releases V before acquiring P**. Keep this property. Do not add a waker holding V while waiting for P opposite a parker holding P while waiting for V.

Candidate idle sequence, deliberately without nested P/V acquisition:

1. Under P, establish PREPARED and save the publication generation; release P. Existing scheduler already has P at its idle decision, so reuse that acquisition when possible.
2. Under V, register on idle list; release V.
3. Reacquire P through the Scheme helper. Check runnable/current work and generation. Cancel if work appeared; otherwise set COMMITTED. Release P.
4. Enter native select without P/V. Publication after step3 must see COMMITTED under P and leave an effective wake before the publisher relinquishes wake responsibility. Publication before step3 is caught by validation.
5. On *every normal C return*, clear/revalidate park under P, release P, then unregister under V and release V. Only then propagate error or service ordinary Scheme interrupts. A prepared cancellation must also remove any idle registration. A raw nonlocal C unwind is not a normal return.

Runnable insertion, publication counter and committed-wake decision form one P critical section. The actual abort syscall occurs after P release. Existing `##wait-abort!` may also take V; no P must remain held. There is still an interval with a publisher responsible for its wake: production proof must establish the syscall outcome and publication incarnation, not just a boolean “wake requested”. Multiple publications may coalesce while durable ready state remains visible.

## Raw C ticket grant: a concrete visibility prerequisite

Installed `gambit.h:6260ff` / `___PRIMLOCK` fetch-adds next with `__sync_fetch_and_add`, then waits on a **volatile ordinary read** of current. The full barrier on the reservation precedes any wait for the predecessor to finish. It cannot acquire the predecessor's future protected writes. Unlock's atomic update and the barrier before it publish the writer, but the successor still needs acquisition after observing its grant. Volatile alone supplies no ordering of unrelated data.

Saved setup.o has the same pattern in both actual queue functions:

- raise: `ldaddal` at0xd10; `ldr current`0xd20, compare/branch0xd24/28; `ldr tail`0xd2c; first following `dmb ish`0xd48 is after link stores.
- get-next: `ldaddal`0x45c; `ldr current`0x464, compare/branch0x468/46c; `ldr head`0x470; `dmb ish`0x494 follows queue updates.

There is no post-grant LDAR/DMB at those entries. This is a concrete weak-memory proof defect, not proof a stale tail was observed in this flood. A source-shaped two-node litmus permits: reserve B ticket while predecessor holds lock; remember old tail A; predecessor pops last A and clears head/tail; accept grant without refreshing tail; enqueue B by setting tail=B and A.next=B while head remains empty. This uses the actual queue assignments, with an explicit weak-visibility premise; it does not inject a `drop` action. A grant-completion acquire profile and successful-trylock profile exclude that observation in the bounded model. This is **not** a complete ARM axiomatic execution or a native litmus.

Scheme helper success uses `___PRIMTRYLOCK`: observe current, then successful CAS on next. Its full barrier is at acquisition, unlike raw C reservation-plus-spin. A minimal portable candidate for raw lock entry is a completion barrier after the spin; alternatively use architecture-correct acquire loads / a proven acquire helper. This belongs to the canonical header generation path, not a one-off generated-header patch. Audit every raw-lock caller and supported atomic fallback. Changing the shared primitive affects the first eight gates and requires their same-producer requalification.

Primary semantics: [GCC legacy sync builtins](https://gcc.gnu.org/onlinedocs/gcc/_005f_005fsync-Builtins.html), [GCC volatile accesses](https://gcc.gnu.org/onlinedocs/gcc/Volatiles.html), [Linux control-dependency ordering](https://kernel.org/doc/html/latest/core-api/wrappers/memory-barriers.html). The model states its stronger synchronization premise explicitly instead of inferring it from lock names.

## Abort errors and park cleanup

`os_io.c:1537ff` makes a one-byte nonblocking `write` and ignores its return. Device select1478ff drains the abort fd, retrying interrupted reads; a consumed abort normally returns EINTR. A successful write before entering select persists and is useful. EAGAIN with a full pipe can coalesce because readability already exists. **Correction to the previous correspondence:** neither “before select” nor “pipe full” alone proves lost wake. A write interrupted before success, or a different write error, does not certify a byte; the current void API conceals that distinction.

A committed-wake implementation must at least handle interrupted writes and classify success/coalescing versus permanent failure. A permanent pipe failure needs an explicit error/stop contract or another proved persistent mechanism; leaving a sender blocked while claiming success is unacceptable. This study does not choose unbounded retries, wider timeouts or a new rescue loop. The write-EINTR mutation demonstrates the missing premise, not an observed syscall cause. The normal select-error positive clears park before retry; skipping that cleanup leaves a reachable node unserviceable.

## GC coverage and exceptional consumers

The bridge in `_kernel.scm:4520–4550` stores RA, uses W_ALL before native select and R_ALL after. Idle arguments #f/#t are immediates. `_thread.c` wait saves processor in STK2 before ADJFP8; return uses STK(-6). Its fs5/map0x3 selects slot ordinal2. This roots the processor across select and subsequent idle cleanup. It does not justify new raw SCM locals in C, nor cover arbitrary nonidle FFI callbacks.

Resume's callback frame saves resume-thunk STK2 and mutex STK3; return uses mutex STK(-5), fs5/map0x7 selects ordinals2 and3. Contended helper return uses STK(-4), map0xf also selects ordinal4. Other-interrupt's mutex STK(-6), fs5/map0x3, is selected as well. Result assignment itself is followed by raw M acquisition without an emitted heap check in that small sequence. Where SYNC participation or calls can collect, mapped locals must be updated, even if an owned-mutex list independently keeps the object alive. The stale-local negative deliberately distinguishes retention from pointer relocation.

| Exit | Existing consumer | Allowed conclusion / change boundary |
|---|---|---|
| Callback handles exception internally and returns | Normal mapped dispatcher frame stores value then unlocks | Same ordinary result contract; caught-exception model is observationally ordinary return. |
| Target terminates before dispatch or during callback | `##thread-end-locked!`1700ff, owned mutex traversal1755–1763, `##btq-abandon!`1772ff and mutex-signal path | Sender obtains abandoned-mutex behavior, not a fabricated normal value. Model uses a typed abandonment outcome; it does not execute a discarded thunk. |
| Uncaught callback exception | No universal catch in three dispatch sites | Only paths reaching target-end inherit abandonment. Do not claim every exception completes the sender. |
| Continuation escape or raw C unwind bypasses normal return while target remains live | Owned mutex may remain, but an executable mapped activation is not established generally | Opaque-escape model retains its activation by assumption and checks safety only, **no completion**. Actual escape retention/unwind support remains unrefined. Fake reply is rejected. No replay or global strong-root registry. |
| Select returns EINTR/another error normally | Mapped wait processor, then cleanup and return code | Candidate needs park cleanup before service/error propagation. Nonlocal unwinds need a separate cleanup bridge; excluded from native sufficiency. |

SMP current→noncurrent census (before the non-SMP copy): thread-end-current1697, join1915, yield2010/2038, sleep2096, reschedule2822, migrate3287, mutex-lock-out-of-line3905, mutex-signal-and-condvar-wait4184, wait-for-io4273. These are transition sites to refine, not ten identical textual substitutions. Sleep's TOQ insertion follows current withdrawal; saved continuation must cover that interval. Condvar wait/I/O void-resume behavior aborts the wait, whereas mutex/join/sleep have their own retry/timeout contracts. Preserve those distinctions in the pending-aware helper. Terminal end must not run pending callbacks on a dead target.

## Minimum implementation surface and performance trade-off

This is a proposed coherent source change, not permission to implement it now.

| Surface | Minimum responsibility / fields | Cost and regression exposure |
|---|---|---|
| Canonical `___PRIMLOCK` implementation and generated header binding | Acquire after observed grant; preserve ticket layout/ABI and fallback behavior | Full completion fence per raw acquisition for the conservative implementation; architecture-specific acquire may cost less but needs proof. Global primitive means broad first-eight exposure. |
| `##thread-intr-propagate!`, thread queue macros, other/resume dispatch | Authoritative thread next/head/tail; common rooted claim and reply/abandon contract | O(1) link work, no extra per-request allocation; may increase T contention and change batching latency. No processor-wide scan. |
| Suspension commit helper and all census callers | Pending recheck under T; saved cont/resume thunk; preserve BTQ/TOQ/migration-target | Constant check on each suspension; operation-specific rollback work. No ordinary callback under scheduler locks. |
| Both runnable insertion helper families, scheduler idle branch, `##wait!`/abort wrappers | Same-P ready publication and park state/validation; optional private scalar generation + park phase | Constant field work; up to two added P acquisitions on idle entry/exit if existing acquisition reused. No new per-request P acquisition promised without tracing each branch. O(P) scalars; cache-line contention possible. |
| `___device_select_abort` and its internal callers | Observable success/coalesced/error contract; interrupted-write handling; no false handoff completion | One normal syscall as today, retries only for classified interrupted calls; exceptional errors cannot have a certified latency bound here. |
| Kernel bridge / frame maps | Reuse current Scheme mapped frames; regenerate/inspect maps for changed helpers | No new GC pointer fields in park bookkeeping. ABI/layout proof required if native pstate fields are chosen. |

Do not reuse `scheduler_status` (startup pending/ready/failed). A generation counter is not automatically necessary if existing synchronized pending state can prove the same contract. If used, define width, wraparound, reset and processor incarnation; no silent bounded-model integer→machine-word substitution. The model has one request, two processors, bounded park/migration and one relocation; repeated generations, multi-request nesting, arbitrary escapes and all platform memory models remain open.

No measured throughput/latency improvement follows from O(1), counts or model state totals. Preserve 100000-send/-:p11 baseline topology and original budgets when a future qualified implementation is authorized. First-eight regressions, GC/FFI/migration semantics, flood repetition and two same-contract receipts remain required; an8/8 flood is not9/12.

## Validation and what it buys

`result_mutex_mailbox_handoff.qnt` now separates callback execution, result storage, mapped-local relocation, unlock, normal error cleanup, target abandonment and unsupported opaque escape. Nineteen TLC cases: eight safety+conditional-completion positives, one opaque safety-only positive and ten decoded negative witnesses. Twenty named TypeScript trajectories test these mechanisms explicitly. New `result_mutex_ticket_visibility.qnt` has one source-shaped stale-tail negative and two acquire controls: three TLC cases. Original 30s/check,12 workers,1GiB heap,8MiB stack limits are unchanged. Earlier draft mode5 incorrectly disabled result storage after select-error recovery; its liveness failure is retained, corrected and not counted as a runtime fault.

A separate two-case P/V lock-order model rejects nested reverse acquisition with an explicit cycle witness and admits the split-acquisition sequence. These are44 checks in total. Its positive is an order control, not a proof of runtime GC or primitive fairness.

Together these controls reject candidate implementations that keep nodes alive but cannot serve them, unlock without storing, retain stale locals, invent replies on escape, skip error cleanup or assume an unsuccessful write woke a sleeper. They provide executable review criteria. They do not prove the reported first writer, exact C refinement, native GC correctness, production performance, TFIB SIGSEGV, lifecycle join or full12/12. Receipt JSON records exact run paths and source identities; measured-failure obligation files stay untouched.


## Subsequent acquire/abort refinement (2026-10-23)

[Ticket profiles and abort responsibility](smp-repair9-acquire-abort-contract.md) captures a fresh changed setup/os_io source cut, while the prior object remains bound to its original generation. The missing ticket completion acquire is specifically the normal branch; debug already has a completion barrier and successful trylock CAS is distinct. The emulated barrier is empty. Abort-if-blocking now exists in source, but final write errors remain ignored. Twenty-four new controls distinguish coalesced EAGAIN, bounded EINTR retry, hard-fault retention and epoch acknowledgment. Previous44 checks and receipts remain historical and unchanged; no native qualification follows.
