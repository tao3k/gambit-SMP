# ACK disposal: collective service phases and blocked-owner isolation

This audit provides implementation instructions and conditional model evidence. It applies no runtime patch and does not authorize changes to the qualifier or historical receipts. Grok can implement the described dependencies under its own production custody. The source authority remains lock main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus the cumulative foreign-release-claim patch; vendor HEAD equality is not required. See [source identities](run-ack-source-protocol.json). The previously recorded qualification remains 8/12.

## Decision

Use mandatory **post-operation service phases**, not a normally competing low-priority cleanup opcode. A service batch may skip a busy entry; it must not wait for that entry's owner, callback, ACK or native borrow. GC reader quiescence and per-entry native-reader quiescence are separate conditions.

This fixes service starvation only when all active cohort members can reach the boundary. In the present C implementation an indefinitely blocked active member still blocks every collective. Root retention does not make a missing participant arrive. To isolate that kind of owner, implement checked **park-before-blocking** with a separately scanned frozen root domain and a committed active-membership snapshot. Never infer parking from a timeout, silence, TLS or a thread's OS wait state. Arbitrary already-blocked unprepared C code cannot be safely excluded by this proposal.

## What the locked C actually guarantees

| Source | Fact and consequence |
| --- | --- |
| `setup.c:680..696` | `OP_MAKE(priority,combining)` sorts numerically: resize priority2, GC priority3 with ADD, startup-ready6, NOOP63. Merely adding cleanup below GC permits starvation; raising it above every GC can reverse the starvation. A mandatory bounded phase avoids that arbitration problem. |
| `setup.c:751 barrier_sync_op`, `705..732 SYNC_GET_MSG/SYNC_SEND_MSG` | The tree uses logical processor id and `processor_count`, waits for children, gathers the minimum opcode, then broadcasts. Message flags are release/acquire with fences. They order payloads; they do not add an absent-member protocol or reclaim arbitrary RC readers. The broadcast is not a proof that every descendant has completed its operation. |
| Lock `lib/setup.h:53..66` | `BARRIER()` is `barrier_sync_noop` in threaded builds and empty otherwise. `setup.c:940..952` submits an OP_NOOP through the same tree. This header is an additional exact-revision evidence input; the cumulative patch does not touch it. |
| `setup.c:1540..1590 execute_sync_op` | GC calls `___garbage_collect_pstate`; resize has a separate shared result round. These operations cannot be interleaved with local RC unlink merely because a local flag is zero. |
| `mem.c:4405 mark_rc` | Caches `next=h->next`, then updates the real `h->data` through mark_array. An unlink/free while a scanner retains h or next is unsafe. |
| `mem.c:7601..7620` | RC roots are scanned before global/continuation/register/saved roots, followed by a barrier and transitive marking. That barrier ends neither the whole GC nor every later consumer. |
| `mem.c:7692 ___garbage_collect_pstate` | Strong/weak marking, cleanup, heap resize and barriers are followed by heap-fudge work, statistics, GC notification, PREPARE_MEM_PSTATE and return. The last internal barrier at7792 precedes these native tails. Reader-exit service admission must be after the full call returns, not at the strong-root barrier or inside the epilogue. |
| `mem.c:4828 free_unmarked_still_objs`, `4845/4887 ___release_foreign` | GC/cleanup can invoke foreign release. The proof that a GC finishes requires the earlier callback-classification/no-unwind contract; at-most-once callback claim alone does not make callbacks bounded or nonescaping. An escaping/blocked callback cannot publish a fictitious reader-exit ACK. |
| `setup.c:1600 execute_sync_op_loop` | Current `OP_NOOP` break, startup-role differences and nested startup/GC mean an unconditional local barrier inserted at one return is unsafe. All participating roles need one common phase schedule. |
| `setup.c:1006..1035 ___run_and_throw_error_on_processor_0`, `1716 service_sync_op` | After ___run returns, the worker remains in a native sync loop. A Scheme-only hook cannot service its retained ACK domain. |

## Concrete phase protocol and call order

New names below are implementation symbols, not existing C functions. Add a VM-owned stable cohort descriptor containing `cohort_epoch`, active member→rank/rank→pstate mappings, leader rank, phase and phase generation; keep logical `processor_count` distinct. Add per-domain pending ACK records, cursor, native borrow/readers, scan-owner descriptor and generation, plus descriptor/VM lifetime pins. Add tagged phase messages carrying `{cohort_epoch, round, phase}`. Existing release/acquire flag publication can be reused only if stale messages from an earlier phase/epoch cannot satisfy a new arrival.

The stable outer collective in `execute_sync_op_loop` should run:

```
elect ordinary operation using immutable cohort(E)
execute the selected operation and converge its result/errors
  nested startup/resize/GC retains ACK debt; no local service phase
publish local reader-exit(E, round), after full operation/native tail
sync_owner_phase(E, round, READERS_EXITED)       // all active members arrive
capture this domain's bounded ACK cutoff/cursor
owner_service_batch(local_owner, cutoff, budget)
sync_owner_phase(E, round, OWNER_SERVICE_DONE)   // all mutations published
publish local result / leave on common error / choose next election
```

`sync_owner_phase` is a fixed protocol phase, not an OP whose priority competes against GC. Use a tagged common tree round; do not let one member propose cleanup while another proposes ordinary NOOP/GC in that same phase. P0/leader cannot return or throw ahead of the common completion. A new GC request during service only records pending work and wakes the coordinator; its root snapshot starts after OWNER_SERVICE_DONE. No Scheme allocation, callback or remote wait is allowed inside the batch.

For resize, publish `STARTUP / STABLE / ROLLBACK / CLOSING` and the resulting member descriptor collectively. Service only after the old/new members have committed the same stable cohort and the startup READY/result protocol is complete. Preserve the same pending ACK entries across failed resize and nested GC. Never make a local `startup_call` boolean decide whether to participate in a new phase. On failure, converge the common status before leaving; if membership cannot be established, retain roots and enter the existing reviewed fault/retention policy rather than announce completion.

`service_sync_op` calls the same outer engine, so a native-only worker participates without entering Scheme. The `##thread-resume-execution!` hook after thread unlock may request that engine or service an already-authorized local window; it must not independently create a GC-exclusion interval. Preserve actual W_ALL/R_ALL and root-map obligations from [the preceding handoff](run-ack-source-protocol.md).

### Scanner and queue-reader boundary

An arrival for READERS_EXITED is release-published only after that member has stopped using every local GC pointer from this operation and finished its native tail. The gather acquire-observes every arrival, and its release broadcast grants the frozen window to the same cohort. The DONE gather/broadcast makes unlink and ownership changes visible before a later GC. This is the proposed C happens-before chain, not a proof that the C has implemented it.

The certificate covers the GC traversal domain, not arbitrary asynchronous queue readers. For each record the owner must still win a one-shot detach claim with the full VM/owner/activation key and check its own native-reader/borrow lease nonblocking. A busy/unknown reader leaves the record rooted and pinned and advances the cursor to another entry. No global `all_readers_zero` gate. Unlink the actual owner-local RC cell only after all readers of that cell have dropped their leases. Reclaim the separate completion descriptor only when its queue/ACK readers also have exited; the carrier and message descriptor may have different grace points. Copy next cursor/key/status before the final decrement; no post-release access.

### Persistent debt, cutoffs and GC fairness

ACK publication release-stores an admitted record and a generation-tagged pending obligation before sending a wake hint. A captures the receiver's live root before ACK; those roots remain independent of whether the native parent has returned. A lost/coalesced wake bit must not erase the pending record.

Each batch inspects at most a configured number of records and advances a round-robin cursor even when an entry is busy. `examined` is not `completed`: never advance a contiguous completion watermark over a busy hole. New ACKs published after this batch's cutoff remain pending for the next batch, even if the current batch empties its original snapshot. A no-debt optimization requires a collectively broadcast no-debt snapshot; an arrival after it stays pending and requests another service round.

After every completed stable GC, one bounded service batch precedes the next GC election. Repeated GC therefore cannot overtake an already eligible ACK indefinitely; the phase is structural rather than a weak-fairness assumption about a low-priority opcode. Conversely, a busy B entry cannot hold the service phase open: skip it and finish, permitting the next GC. Sustained ACK traffic does not force an unbounded drain. A native coordinator must retain and notice debt even when no Scheme thread runs. Wake-channel permanent failure remains a fault-coordinator/backend obligation, not solved by this phase protocol.

The temporal model assumes scheduled active participants and finite selected operations. In a real implementation the batch and selection algorithm must establish bounded work per round; the model does not turn OS scheduling fairness or arbitrary host callback return into a runtime guarantee.

## B blocked: three different cases

| Case | Safe behavior |
| --- | --- |
| B participates, but this record has a native borrow, unknown close state or unreleased reader | Keep B's carrier/domain/debt. B reports this batch visited, not detached; C drains independently. No waiting on B's entry. |
| B is about to enter an admitted potentially blocking foreign region | While B is still responsive, materialize all movable Scheme frame/register roots in traced storage; register pointer loans/pins; close B's mutation/admission gate; publish a freeze certificate; commit the cohort membership and fixed scan-owner assignment together at an old-cohort boundary. Only then may B block. Active GC scans the frozen domain; it never claims authority to free B's carrier. |
| B already blocked while still active, without that certificate | No safe exclusion is established. Existing tree and GC cannot promise progress. Retain ownership and report the unsupported/fault condition; do not remove B by timeout or count substitution. Prevent this case at checked FFI admission in a production implementation. |

Parking is a larger dependency than changing the ACK queue. `barrier_sync_op` needs dense active ranks from a frozen descriptor instead of `id*2+1` over logical slots. `setup_stack_heap_vmstate` (`mem.c:3770..3827`) currently flips/initializes every processor and sets `scan_workers_count=np`; it must distinguish active scanner count from registered frozen root domains. `mark_global_variables` (`7298..7368`) partitions by id/np; `mark_reachable_from_marked` (`7399..7455`) uses np and worker accounting; `scan_complete` wake limits (`3657`), heap accounting (`6970`), and GC debug loops (`7724`) also require a classified migration. The B domain must include still/RC/continuation roots and private GC work, not just the ACK RC cell. No parked owner may concurrently mutate those chains or retain movable raw heap addresses outside a pinned/materialized contract.

VM leader duties currently tied to logical id0 (global roots, heap resize, result/error publication) need an explicit active leader, or the first supported contract must refuse parking P0 before entering blocking host code. Do not silently assume that removing a nonzero worker proves P0 parking safe. Parked B's callback reentry must use checked REJOIN_REQUESTED; it cannot touch the old ps/heap or longjmp into the old catcher until a new stable cohort commits and republishes its root/scan authority. The model's rejoin transition is this abstract atomic commit, not an implementation of the mapping migration.

## Grok implementation and native validation sequence

1. Freeze the lock-derived production and generated-C identities. Add the tagged cohort/round/phase and stable outer-loop entry/exit protocol first. Exercise native sync-only workers, common errors and resize/startup nesting without detaching RC cells.
2. Add persistent per-entry ACK debt, cutoff and cursor. Confirm full-key validation, receiver-root-before-ACK and one-shot owner detach. Implement the reader-exit and DONE phases, bounded local service and nonblocking per-entry reader admission; retain all uncertain records.
3. Verify a scanner paused after caching `next` prevents that cell's unlink; release the scanner and verify one detach. Force a GC request between reader-exit, unlink and DONE: it must stay pending until DONE. Fail or retain safely if a member cannot reach the boundary.
4. Under repeated actual GC and resize requests, hold B's native borrow indefinitely while C has an eligible ACK. C must complete, B must remain scanned/pinned, and GC must keep completing. Publish a new ACK just after C's cutoff and ensure it survives to a later batch; repeat/delay ACK to ensure exactly one release.
5. Implement and validate park-before-blocking separately: materialization/loan freeze, old-cohort commit, active-rank GC accounting, complete frozen-domain scanning, then blocking host call. While B remains blocked, prove C and actual GC progress with roots relocated in traced storage. Invalid/unprepared park and direct parked callback entry must be refused before mutation. Test rejoin only via a jointly committed new epoch.
6. Validate the identical producer's generated roots and native callbacks/errors, including failure before park commit (old cohort/root authority retained), unknown failure after commit (frozen domain retained), and repeated epochs/late messages. No timeout expansion, fake ACK, qualifier rewrite or full-suite substitution. Formal 9/12 contract review remains separate.

Independent conclusion: the bounded post-GC window is sufficient to remove **GC-priority starvation** in the modeled responsive cohort. Per-entry skipping removes head-of-line blocking from retained borrows. Neither solves an unprepared, permanently blocked active owner. A production claim covering that case needs the checked parking/admission and GC-membership refactor above, including generated root proof and native tests. This dependency cannot honestly be reduced to one new cleanup opcode or atomic field.

## Recorded model results

`models/gambit/ack_service_window.qnt` has cyclic GC requests and a toggling GC generation witness, so the number of collections in a behavior is not bounded by a finite test counter. All 20 expected controls were accepted: 6 safety plus weak-fairness conditional-progress checks; 7 independently decoded safety negatives; 5 decoded temporal lasso/stuttering negatives; and 2 source-boundary reachability witnesses. Maximum observed case 6.347s, unchanged 30s per-case cap. Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/381be4ee82e44d14809bac17123d1754/outputs/ack-service-window/receipt.json`.

Positive scenarios cover both owners completing, a permanently borrowed B record with C progress, a pre-parked/frozen B domain with C progress, a native-only service participant, late ACK carried to a later cutoff, and park/rejoin across two abstract cohort commits. Negatives expose a service window before GC readers exit, a new GC overlapping the window, C freeing parked B's carrier, exclusion without freeze/materialization, erased late debt, duplicate detach, and dropped parked roots. Actual temporal counterexamples show strict GC priority, serial B-before-C service, a global borrow gate, an unprepared blocked active B and absence of scheduler fairness. Backend temporal-negative rejection is retained as `backendAccepted=false`; only the research receipt classifies the decoded expected counterexample. No framework admission rule was changed.

The model abstracts membership commit, frame materialization, native reader exclusion and callback finiteness. It does not prove their implementation, arbitrary token wrap/ABA, the complete resize state machine or actual generated-C roots. It refines the previous atomic service permission; it does not establish executable equivalence to C or a full product of all earlier QNT modules.
