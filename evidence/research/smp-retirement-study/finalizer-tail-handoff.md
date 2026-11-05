# Finalizer lifetime handoff and shared-lock fault disposition

2026-10-23. Proposed implementation/evidence only. Count8/12; no runtime,
qualifier, recipe, milestone or historical receipt change. No native execution,
peer operation, commit or push. Processor retirement here means worker withdrawal
during SMP shrink, not retirement of SMP itself.

## Independent judgment: change the lifetime mechanism, not just the counters

Two separate counters are not an adequate reclamation certificate. Even when
the writer increments finalizer_users before decrementing native_tails, a reader
that loads the counters in an unsuitable order or without matching synchronization
can observe a combination that never represented a safe global state. Worse,
current checked teardown can perform destructive work before setup_publish_clean;
adding a condition only to that final publication would be too late.

Keep **one pre-registered per-donor resource obligation and VM lifetime pin**
continuously from accepted retirement through final reclamation. Transfer its
execution authority with a keyed atomic phase change; do not release and reacquire
the lifetime pin at join0. Native-tail accounting is an exact-once diagnostic
sub-obligation. It may end once the real worker joins, while resource debt remains.

For unknown shared-lock results, continuing the VM and bounded termination are
not both generally available. A quarantined donor can be skipped only when every
future path is independent of its uncertain object. An unknown VM misc lock,
setup guard or sync mutex is not donor-local. Do not leave other participants
waiting for a final result barrier that may itself require the broken mutex.
The safe bounded fallback is a separately reviewed **process fail-stop** path,
not a successful resize, cleanup or9/12 receipt. This intentionally sacrifices
the process, including other hosted VMs. Embedders must review that contract;
there is no proved in-process host-preserving fallback for this fault class.

## Source facts and the remaining implementation gap

Anchors refer to immutable source observation
`.cache/tasks/repair-9-12/processes/audit/runs/9a03f325fe6d44c8822ade738df7c474/outputs/post-join-transfer-observation/observed`.
The companion JSON binds the actual bytes. These are per-file observations, not
a coherent completed source/generated-C/GSI producer or native execution claim.

| Actual source | What is already present | What must change / cannot be inferred |
|---|---|---|
| `setup.c:423,1052–1070` native_tails enter/leave | VM0 aggregate increment and saturating CAS decrement; enter occurs before marker retirement at2035 | No keyed donor obligation, no finalizer ownership and no underflow attribution. CAS success does not establish which donor was accounted. Preserve worker-tail protection but bind its consumption to exact entry/K. |
| `setup.c:2089–2107` shrink join branch | Actual join0 calls tail_leave before void transfer/cleanup; error retains tail and last_join_error | Tail0 is not resource-debt0. Same entry must remain pinned over transfer, domain removal, cleanup and metadata readers. The global last error is not per-donor authority. |
| `setup.c:847–873 setup_publish_clean` | Checks context readers, native_entry_users, native_tails and outer_owner | A premature-free event is not proved just by this ordering. These checks are not a complete new finalizer certificate, and this late function alone cannot protect earlier destructors. |
| `setup.c:6356–6370 vm_native_consumers_clear` | Checks wake writers/selectors and all pstate sfun markers | Does not check a per-VM retirement ledger/finalizer debt. Add the check at actual destruction admission for every VM, not only VM0 setup phase. |
| `setup.c:6373+ ___cleanup_owned_vmstate`, `___cleanup_checked:6557+`, `___cleanup_vmstate:6335+` | VM registry close/seal and cleanup paths; host ownership/serialization comments | Factor one checked destruction-admission certificate before cleanup_pstate, cleanup_vmstate_locked or global OS/memory destruction. Preserve the raw APIs' supported caller restrictions; no direct low-level bypass may free accepted debt. |
| `setup.c:486–508,1021–1049` setup guard / entry borrow | Lock returns boolean, unlock returns void and discards native outcome | Existing entry borrow is not keyed finalizer claim and does not prove successful unlock. Add checked raw-result wrappers for these lifecycle sites; unknown release cannot be returned to Scheme as ordinary NO_ERR. |
| `mem.c:336,386,5482–5529` | Transfer holds VM misc spinlock around pointer/count writes | Shared lock is not per-donor isolation. Never wait indefinitely for it inside a collective. No claimed native progress if it is permanently unavailable. |
| `mem.c:729–832,1599–1640` RC/still APIs | register/release/addref/set_data_rc and still refcount mutate raw memory without taking the misc lock here | Misc lock alone does not exclude external native mutation. Need the supported host GC/quiescence contract or checked mutation-lease admission covering these APIs. Do not simply remove misc lock because Scheme processors are stopped. |
| `setup.c:1538–1570 SYNC_GET_MSG/SYNC_SEND_MSG`, wait1574+, barrier1588+ | Atomic message flags are coupled to sync_mut/sync_cv; lock/unlock outcomes are ignored | A generic error-to-common-barrier step may use the very mutex whose state is unknown. Each new lifecycle-critical transport site needs checked status and an independent fatal branch. Source-level read is not an observed native lock failure. |
| `setup.c:2139–2205 execute_sync_op`, loop2209–2322 | Selected operation→common result→NOOP iteration; final P0 throw is delayed to loop exit | Healthy known refusal must complete the common transcript. A local Scheme throw/return inside the window strands other members. Unknown shared transport cannot rely on finishing that transcript. |
| `os_base.c:889–926` | fatal_error invokes optional host callback or display_error, then exit_process calls exit() | These may call arbitrary host code, stdio or exit hooks. They are not a lock-independent fail-stop primitive. pthread_exit is also insufficient: it leaves the cohort waiting for the missing participant. |

The new source evidence here is the explicit omission in destruction admission,
the raw external RC/still mutation sites and the callback/exit-based fatal route.
It is not a newly reproduced use-after-free or mutex failure.

## Concrete lifetime and call sequence for Grok

Names below are proposed private helpers/fields, not installed runtime symbols.

1. **Before accepted shrink:** reserve a VM-owned entry and its typed Scheme root
   carrier; bind immutable K=(VM instance, resize epoch, donor slot incarnation,
   native-handle lifetime, join-lane generation). Register one resource pin under
   close-vs-enrol serialization before public acceptance. Record admission stays
   closed after VM teardown starts. No late finalizer can materialize an unpinned
   entry by reading an old pstate pointer.
2. `retirement_worker_tail_begin(entry,K)` publishes worker-tail responsibility
   before `___retire_sfun_stack_markers`. The entry's resource pin already exists.
   A separate exact-once tail_accounted field is diagnostic, never an admission
   substitute. Existing native_tails can remain conservatively positive on failure.
3. Actual join owner calls `___thread_join` once. After true0 and its last donor
   access, release-publish `JOINED_READY` plus immutable result/owner evidence in
   VM-owned lane control. P0 acquire-consumes it. Native helper lifetime remains
   separate from donor storage lifetime.
4. `retirement_claim_finalizer(entry,K,receiver_generation,service_ticket)` validates
   immutable identities and performs one aligned lock-free compare-exchange
   `JOINED_READY→FINALIZER_OWNED` with acquire/release ordering. Pin is unchanged.
   Reject stale/duplicate claim without decrementing another entry's tail. A
   known refusal preserves the entry and does not retry join. Require verified
   lock-free native atomic support at setup; do not silently use a hidden-lock
   fallback in this critical protocol.
5. `retirement_account_joined_tail(entry,K)` consumes the matching tail token once
   AFTER successful claim. After this point native_tails may be0 while the same
   resource pin/ledger debt remains live. Claim and native key fields must outlive
   every release; memory-order semantics need actual C/preprocessed-code review.
6. With the record/VM/receiver pinned, preflight mutation admission and last
   consumers outside the service window. Unready donorA is skipped. Do not wait
   for its native users while donorB is eligible. Slot reuse and VM destruction
   remain refused; the service pass can ACK its inspected cut while A's resource
   debt persists.
7. All stable-cohort members enter the already elected service operation. P0
   selects one eligible K or EMPTY, performs the bounded native move units, publishes
   a known result, all members ACK, then all leave. No callback, allocation, join,
   unbounded mutex wait or Scheme throw belongs in this transcript. The mandatory
   post-GC service/debt protocol from earlier research remains required.
8. Checked empty-donor destruction happens after common exit, while finalizer
   pin remains. Confirmed local destruction failure retains an isolated descriptor
   and the slot; data/root ownership is already at receiver. Do not splice back.
9. `retirement_finish_finalizer(entry,K)` waits only outside the collective for
   exact completion/native-reader grace. Mark RECLAIMED once after its LAST donor
   and receiver metadata access. Then retire the native entry through registry
   reader grace. The last VM borrow is released after all entry accesses; return
   only scalar locals. Reclaiming the slot and reclaiming the native descriptor
   can be distinct operations; no stale handle can acquire the next incarnation.

### Teardown certificate: seal before observing, check before destroying

Proposed `retirement_destroy_admit(vm,close_ticket)` first seals new record/native
borrow admission through the same mechanism used by enrolment, then acquires a
stable registry snapshot. It requires no unreclaimed accepted entry, no finalizer
or registry-reader reference, no helper capable of a future donor/completion write,
and all existing handler/GC/queue/wake/selector consumers cleared. Only then may
the destructive phase start. A raw pair of independent relaxed counters cannot
implement this snapshot. Use registry close/ticket serialization or a formally
reviewed atomic aggregate; do not fix this by changing atomic orders on two
unrelated variables and assuming it is enough.

`vm_native_consumers_clear`, `___cleanup_owned_vmstate`, `___cleanup_checked`,
`cleanup_vmstate_locked` entry and failed-setup cleanup funnels must share this
precondition before the first irreversible action. Setup failure with no accepted
retirement still uses its successful-init mask; do not manufacture entries or
destroy an uninitialized lock. Adding a check only to setup_publish_clean is
insufficient because resources may already have been disposed.

## Avoid blocking the cohort: known busy versus unknown ownership

The preferred splice core can omit a redundant VM misc lock ONLY after all Scheme
mutators are collectively stopped AND every relevant external mutator is closed
and drained. Current raw RC/still functions do not establish that premise.
Unsupported unregistered external users must obey the documented host serialization
contract, or retirement cannot be admitted for them. A lifetime borrow alone does
not make h->data mutation compatible with moving GC.

Where a backend lock is still required, proposed `retirement_misc_try_acquire`
returns HELD / BUSY / ERROR before mutation. POSIX must inspect the raw trylock
return; BUSY takes a common deferred-result transcript, with debt preserved.
Ticket-lock try must not enqueue a ticket on failure and must include an actual
acquire edge on authorization, plus matching release on unlock. Existing
`___TICKETLOCK_TRYLOCK2` at6192/6233 is a representation anchor, not proof of its
memory ordering; audit full normal/try authorization paths together. Never call
blocking `MISC_MEM_LOCK()` inside the new finalize transcript as a fallback.
Try failure does not justify bypassing exclusion. An ERROR other than documented BUSY may indicate a broken shared lock: before-mutation does not by itself authorize VM continuation; classify it through the same shared-fault policy. A permanently busy shared lock
can prevent all transfers requiring it; only bounded refusal is promised, not
successful per-donor completion under that condition. No budgets are enlarged.

Known local failure is returned only AFTER all shared transport/unlocks completed
and common exit was acknowledged. To quarantine a donor-private uncertain lock,
prove the dependency cut: no future scanner, wake writer, selector, queue user,
host mutator, callback, lane command or destructor can touch it; roots/data have
stable scan owners; the native record/VM pin remains. A field named private is
not that proof. If any future operation needs it, classify it as shared/unsafe.
DonorB can then continue independently; whole-VM teardown still refuses while
the quarantine remains. Destroy failure on a still-initialized lock and unknown
unlock outcome are recorded distinctly, not blindly retried.

## Unknown shared unlock: explicit non-returning safety branch

At each checked setup-entry-guard, VM misc or new lifecycle sync wrapper:

1. Preserve exact site/result in an already allocated process-lifetime fault
   record where this can be done using verified lock-free atomics. Diagnostics
   are best effort, never a prerequisite for stopping. A second failing thread
   must not wait for another writer to finish the record.
2. Immediately invoke proposed `retirement_shared_fault_stop(status)`. It is a
   private nonreturning direct `_Exit`/platform equivalent path with no Gambit
   cleanup, host fatal callback, stdio, allocation, mutex/condition variable,
   join, Scheme code, atexit or common barrier. Do not reuse current fatal_error,
   exit_process or pthread_exit. No audit in this task executes this path.
3. Do not release roots, publish CLEAN, report recovery, enable mutators, perform
   a second unlock/destroy or attempt another join. The OS terminates the process;
   this is not a graceful VM cleanup and never a successful lifecycle receipt.

This prevents an indefinitely stranded cohort *after a detected returned error*,
conditional on the platform's raw termination primitive. It does not prove that
an arbitrary corrupt syscall returns, nor provide a wall-clock guarantee against
OS failure. Existing outer watchdogs remain the bound for a nonreturning native
call; they are not extended or counted as successful recovery. A fault coordinator
that is a Scheme thread or waits on the same transport is unsuitable here.

If process fail-stop is unacceptable to an embedding host, reject this fault
contract at setup/integration rather than claiming a VM-local recovery fallback.
Actual host-preserving containment would require isolating the VM in another
process or redesigning every shared dependency; it is a larger architecture
choice, not a hidden assumption of this small refactor.

## Grok work order and focused native controls (future, not executed)

1. Centralize per-VM accepted-entry/resource-pin admission and keyed phase CAS;
   extend actual teardown preflight, including non-VM0 paths. Replace unkeyed
   tail release at2093 with claim→keyed tail-accounting; keep pin unchanged.
2. Add checked try-acquire/release wrappers for required lifecycle locks with raw
   result/site handling. Inspect compiled mutex/ticket configuration and actual
   acquire/release code. No locks simultaneously held across Scheme or barriers.
3. Keep all known deferred results in the selected common transcript. Select
   EMPTY/skip instead of waiting. Check new sync-mutex outcomes without sending
   a fatal report through the failed transport. Use the process-fatal branch if
   a shared result is unknown; this is a separate reviewed native policy.
4. Implement post-common-exit local cleanup quarantine and the final descriptor
   reader-grace release. A transferred quarantine still blocks new incarnation;
   no whole-VM freeing while another donor/lane/finalizer is alive.
5. Same-producer tests must pause after join0, after finalizer claim but before
   tail release, after tail release before splice, after common exit and before
   last metadata release. Attempt checked cleanup/reuse and verify refusal at
   every pause. Wrong K/receiver generation, duplicate claim, delayed reader,
   tail aggregate0 with debt, and early descriptor release must reject.
6. With A's cleanup failed/isolated or A's reader held, prove B completes, survivor
   GC remains serviceable and VM teardown retains A. With BUSY preflight prove
   every member exits its known-result transcript and original deadline stays.
7. Inject returned shared guard/misc/sync unlock errors in a separately supervised
   native fixture using the final producer. Parent must observe declared fatal
   exit without watchdog timeout; install a host fatal/exit hook that would hang
   and prove the raw branch bypasses it. These are labelled injections and fatal
   disposition controls, not natural OS failures or successful resize receipts.
   Keep actual nonzero errno and expected exit semantics separate from join0.
8. Verify the irreversible splice core remains callback-free and old first-eight
   tests unchanged on the frozen generated-C/GSI producer. Run reviewed lifecycle
   campaigns separately; no model/native fault outcome advances the current gate.

Normal cost: one already reserved record/pin per accepted donor, one keyed CAS
claim plus exact-once accounting and existing service-window work. No new OS
thread or busy polling is introduced by this handoff. Registry sealing/grace,
trylock miss rates and atomic contention remain unmeasured. Existing independent
join-lane resource costs remain separate. A process-fatal policy is a compatibility
cost to review explicitly, not a performance optimization.

## QNT scope and honest completion claims

`models/gambit/finalizer_handoff.qnt` models two donor records continuously pinned
across join→claim→tail release, keyed single claim, common result ACKs, final native
readers, independent local retention and before-destroy admission. Normal and
retained cases have separate goals; three shared-fault-site candidates require
process stop, not resource reclamation. The local-uncertain candidate assumes
the dependency cut rather than proving it from C.

Eight positive scenarios, twelve decoded safety mutants and two temporal mutants
are checked by `verify-finalizer-handoff.py` with unchanged30s/case. The temporal
mutants wait forever for a barrier or host hook after a shared fault; explicit
individual-action fairness cannot make those broken dependencies complete. A
loop/stutter counterexample is required; timeout/parser failure is not evidence.
The companion JSON contains actual results, identities and logs.

This supplement assumes atomic native phase/pin publication, valid immutable
keys, true join0, supported common election and safe isolated dependencies.
It does not prove C11 weak-memory refinement, actual cleanup call coverage,
external RC/still admission, raw termination behavior, arbitrary native-call
termination or full recurrent-GC progress. Earlier QNT and native receipts remain
separate; this is not a new integrated native proof or9/12.
