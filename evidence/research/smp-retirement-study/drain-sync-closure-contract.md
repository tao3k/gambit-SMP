# Drain-before-GO: implementation closure contract

This is an implementation handoff, not a prohibition on Grok implementing it. This research turn changed evidence/models only. Runtime, qualifier, recipes, milestone and historical receipts remain unchanged; no other-thread action, native campaign, commit or push. Source authority is the cohort-ack-rc lock, main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, patch `3597ad3f5dd3223ad54f567bc9b542741812c2623bf0abda3e0b9b4b2359c7c7`, lock `c5b2e0bd4db5b8b99dee274d3d5cfbdec8df387eb7ca9d4df4b6d971a3b8686d`. Vendor is a separate project. Companion JSON binds the immutable candidate, all33 file hashes, compiler controls and TLC receipts.

## Decision: one implementation, explicit completion criteria

Use one native-word atomic admission gate, persistent registered per-member drain obligations, full phase capabilities, native root-bearing operation records, and scheduler-scope error deferral. Preserve drain-before-GO. Do not add a second independently controlled queue/channel reclamation path. Implement the following units together; admission alone is insufficient.

The new source audit finds more than migration: two/three-thread ordered locking can service sync while holding one/two earlier tickets, termination can hold its own thread and a waiter ticket, and run-queue insertion carries locks inherited from its caller. Existing `execute_sync_op_loop:1911..1912` can throw on P0 after the loop. It has no scheduler-lock-depth test. This is an incompatible interface for the proposed universally lock-held service, not proof that a native failure actually occurred on that branch. Atomic entry alone cannot repair it.

The proposal can establish safety for this protocol if the implementation meets all obligations below. Eventual completion additionally needs cooperative members, terminating native phases and fair scheduling; it cannot promise progress after a stopped owner or arbitrary foreign callback never returns. Those paths retain roots/debt or use an explicit fatal policy. This protocol does not explain away the observed TFIB SIGSEGV or interrupt loss, and cannot certify all12 gates by itself.

## 1. Target-native atomic word, not the generic fallback

Candidate `include/gambit.h.in:11074..11168` selects `__sync_val_compare_and_swap` when the target width macro is advertised; otherwise POSIX selects `___USE_emulated_sync`. `os_thread.c:719..743` implements that CAS using a hashed `___MUTEX_LOCK`. Therefore using `___COMPARE_AND_SWAP_WORD` unconditionally does not establish the no-new-blocking-lock property.

The new standalone compiler controls use an aligned unsigned-long64 word, `_Static_assert(__atomic_always_lock_free(sizeof(W),0))`, acq_rel compare-exchange/acquire failure, and acq_rel fetch-sub. Both local GCC16 and Apple Clang compile them to `casal` and `ldaddal`, with no call instructions. Only assembly was produced: no object/link/runtime execution. These controls use each compiler's default target flags, not a producer's configured CFLAGS/header. They establish a feasible local mechanism, not production binding, portability or a latency bound.

Grok must use a dedicated naturally aligned unsigned native word in the actual VM record, static width/alignment/always-lock-free assertions under the configured build, and inspect the real setup.o disassembly/undefined symbols. Do not select the mutex-emulated generic fallback for the locked entry. If unsupported, reject that SMP configuration before worker startup, or separately implement a lock-free target backend; do not silently substitute a mutex. All accesses to this gate must use the same atomic discipline. Do not mix plain loads/stores or reset mode by erasing the count.

Use low mode bits and a separately bounded count field; define its arithmetic unit and overflow test explicitly. Reserve capacity for already-issued drains. A concrete implementation may serialize each member's phase use and allow one explicit nested native-service frame; then prove the actual maximum grants from member count plus coordinator/extra writers. Do not assume the large64-bit space itself proves this bound, and do not support arbitrary reentrant nesting by overwriting one TLS record. Unsupported recursion refuses before acceptance, or becomes retained debt after acceptance.

## 2. All syntactic Scheme entry sites and inherited ownership

The table inventories every direct call expression of this helper family/explicit sync invocation in candidate `lib/*.scm`, excluding procedure declaration lines but including macro bodies:24 in `_thread.scm` and5 in `_thread#.scm`. The companion macro-entry inventory additionally hashes every scanned file and records all syntactic uses of thread/mutex/condvar/processor/current-processor lock macros. It retains definition/disabled-alternative expressions as such; it is not an expanded CFG/whole-program lockset proof. The kernel interrupt vector is an additional asynchronous entry.

| Source | Enclosing procedure (blank in macro bodies) | Entry |
| --- | --- | --- |
| `lib/_thread#.scm`:1065 | `` | `(##lock-scheduler-object-with-sync-participation! mutex))))` |
| `lib/_thread#.scm`:1073 | `` | `(##lock-scheduler-object-with-sync-participation! condvar))))` |
| `lib/_thread#.scm`:1081 | `` | `(##lock-scheduler-object-with-sync-participation! thread))))` |
| `lib/_thread#.scm`:1093 | `` | `(##lock-processor-with-sync-participation! processor))))` |
| `lib/_thread#.scm`:1711 | `` | `(##lock-scheduler-object-with-sync-participation! new-owner)` |
| `lib/_thread.scm`:699 | `##lock-scheduler-object-with-sync-participation!` | `(##sync-op-interrupt!))` |
| `lib/_thread.scm`:703 | `##lock-processor-with-sync-participation!` | `(##lock-scheduler-object-with-sync-participation! processor))` |
| `lib/_thread.scm`:715 | `##add-thread-to-run-queue-of-current-processor-preferably-out-of-line!` | `(##lock-processor-with-sync-participation! processor)` |
| `lib/_thread.scm`:738 | `##add-thread-to-run-queue-of-some-processor-out-of-line!` | `(##lock-processor-with-sync-participation! processor)` |
| `lib/_thread.scm`:754 | `##add-thread-to-run-queue-of-some-processor-out-of-line!` | `(##lock-processor-with-sync-participation! processor)` |
| `lib/_thread.scm`:805 | `##thread-lock-remove-btq-toq!` | `(##lock-processor-with-sync-participation! btq)` |
| `lib/_thread.scm`:827 | `##thread-lock-remove-btq-toq!` | `(##sync-op-interrupt!))` |
| `lib/_thread.scm`:944 | `##lock-2-threads-with-sync-participation!` | `(##lock-scheduler-object-with-sync-participation! t1)` |
| `lib/_thread.scm`:946 | `##lock-2-threads-with-sync-participation!` | `(##lock-scheduler-object-with-sync-participation! t2)))` |
| `lib/_thread.scm`:948 | `##lock-2-threads-with-sync-participation!` | `(##lock-scheduler-object-with-sync-participation! thread1)` |
| `lib/_thread.scm`:983 | `##lock-3-threads-with-sync-participation!` | `(if t1 (##lock-scheduler-object-with-sync-participation! t1))` |
| `lib/_thread.scm`:985 | `##lock-3-threads-with-sync-participation!` | `(##lock-scheduler-object-with-sync-participation! t2))` |
| `lib/_thread.scm`:987 | `##lock-3-threads-with-sync-participation!` | `(##lock-scheduler-object-with-sync-participation! t3)))` |
| `lib/_thread.scm`:1017 | `##mutex-unlock-no-waiter!` | `(##lock-scheduler-object-with-sync-participation! owner)` |
| `lib/_thread.scm`:1484 | `##thread-intr-propagate!` | `(##lock-processor-with-sync-participation! last-processor)` |
| `lib/_thread.scm`:1797 | `##thread-end-locked!` | `(##lock-scheduler-object-with-sync-participation! tgroup))` |
| `lib/_thread.scm`:1826 | `##btq-abandon!` | `(##lock-scheduler-object-with-sync-participation! btq))` |
| `lib/_thread.scm`:2232 | `##thread-state` | `(##lock-processor-with-sync-participation! last-processor)` |
| `lib/_thread.scm`:2974 | `##thread-schedule-with-acquired-processor!` | `(##sync-op-interrupt!))` |
| `lib/_thread.scm`:3324 | `##thread-migrate-to!` | `(##lock-processor-with-sync-participation! p)` |
| `lib/_thread.scm`:3842 | `##mutex-lock-out-of-line!` | `(##lock-2-threads-with-sync-participation!` |
| `lib/_thread.scm`:3844 | `##mutex-lock-out-of-line!` | `(##lock-scheduler-object-with-sync-participation!` |
| `lib/_thread.scm`:4036 | `##mutex-unlock-out-of-line!` | `(##lock-3-threads-with-sync-participation!` |
| `lib/_thread.scm`:4158 | `##mutex-signal-no-reschedule!` | `(##lock-scheduler-object-with-sync-participation! new-owner)` |

Ownership obligations by family:

* `_thread#.scm:1060..1093` routes contended macro-lock-mutex!, macro-lock-condvar!, macro-lock-thread! and macro-lock-processor! into these helpers. Thus ordinary lock macros throughout their callers can enter sync; this is broader than the explicit helper-site list.1711 is macro-mutex-lock!'s new-owner path: it drops M before taking T, then reacquires M while holding T. The generated CFG/native scope inventory must include these expanded edges. A pre-lock check-heap-limit comment does not prohibit explicit sync service from collecting while a different ticket remains held. TOQ/tgroup/VM raw macros do not independently poll, but their ownership can span an edge and must be tracked.

* 705/726 run-queue helpers: pinned/migration-target and idle-P branches take destination P; the VM lock is released before the idle-P wait. They inherit thread ownership. Call sites1536 (`thread-intr-propagate!`),1641 (`thread-start!`),4108 (`mutex-unlock-out-of-line!`),4224 (`mutex-signal-no-reschedule!`),4461 (`condvar-signal-no-reschedule!`) must be checked with expanded macros and their actual outer tickets. A P helper cannot assume it is the first lock.
* 769/805 `thread-lock-remove-btq-toq!`: holds target T while waiting for P. Retry827 explicitly drops T before sync. Preserve both distinct scopes.
* 941 and978 ordered helpers: address ordering prevents duplicate tickets, but waiting for second/third T retains earlier T tickets.3840/4035 drop the mutex before invoking them. Do not add a control mutex or dispatch callbacks while those earlier tickets remain held.
* 1017 `mutex-unlock-no-waiter!`: drops mutex before waiting for owner, then reacquires and rereads head.1484 interrupt propagation holds target T;1797 termination holds current T;1826 abandonment inherits that termination scope;2232 state query holds T;3324 migration holds current T and saved continuation.
* 4158 `mutex-signal-no-reschedule!`: drops mutex while waiting for a distinct new owner, retains waiter T, and may inherit terminating-current T. This is a multi-ticket entry, not the no-lock retry path.2974 scheduler retry explicitly drops P before sync; do not infer another helper's scope from that safe retry.

Implement native-owner scheduler scope accounting at successful low-level lock acquisition and committed unlock, including thread, processor, mutex/BTQ, tgroup, TOQ and VM locks that can span these entries. Hooks must neither allocate nor callback, must handle trylock failure/duplicates correctly, and must not decrement on unknown unlock outcome. Debug locksets check the source inventory; release builds need the scope/deferred-error rule, not necessarily the expensive debug lockset. A lone boolean `holds_thread_lock` is insufficient for the ordered helpers. Track native owner and nesting explicitly; Scheme thread migration must not transfer an active native lock-scope journal.

## 3. Registered capabilities at every C engine entry

| Source path | Required registration / allowed behavior |
| --- | --- |
| `on_all_processors:1931..1948` and call sites1113,1967,2000,2055,2084,2103,2123 | Create stable operation record before wake. Preserve stack-owned sop/result until execution or explicit accepted failure. Late ordinary work remains pending while accepted drain is serviced; no false successful return. |
| `service_sync_op:1916` from kernel, locked poll and post-run loop1122 | Resolve existing per-native-member obligation under a counted lookup pin. Do not invent DRAIN authority from OP_NOOP or an interrupt bit. Post-run native loop has no Scheme helper to do this for it. |
| `start_processor_execution:1126..1148` direct `execute_sync_op_loop(...,0)` | Parent issues startup/member capability before child can enter; bind self/VM/incarnation from that accepted record. It is not an old active-member token. Keep staged/startup publication and abort/reap ownership explicit. |
| `execute_sync_op_loop:1786`; `sync_owner_phase:1690`, `ack_service_window:1757`; `barrier_sync_op:794` | Carry a native activation/phase journal and count each actual tail. Distinct phases/rounds have distinct one-shot claims. Nested GC pushes a child activation, retains parent debt and restores parent identity on every exit. |

Proposed fields: VM gate/lifetime ledger, immutable transition manifest/full keys, per-member persistent service-needed atomic, per-native-owner activation stack, phase claim/writer token, tagged completion record, and scheduler scope/deferred-error record. Existing channel pins/ACK1/RC intent are not substitutes. A foreign C entry needs a checked VM/member borrow; TLS or a raw pstate pointer is not proof of lifetime.

Count protects metadata before it is read; full `{VM,member,operation,epoch,transition,round,phase,use}` validation authorizes use. A phase is claimed atomically once; registration itself must have storage lifetime before that claim. Persistent registration and GO reader refs are outside the short zero-gate count. `service-needed` is published before CLOSING and wake, stays until completion, and is polled independently of the coalescible interrupt hint at699/827/2974 and the ordinary interrupt path.

## 4. Root and error contract: fix the actual interface

`_kernel.scm:1474..1480` and archived `_kernel.c:12380..12386` execute RA-store/W_ALL/service/R_ALL/RA-load. `mem.c:7231,7246` scans actual pstate register/saved arrays. This confirms the old wrapper's register-save sequence. It does not register new C local variables or new native records. The bound `_thread.c` has no participation-helper symbol or migrate symbol; it cannot prove the changed Scheme helper call frames. Regenerate after the implementation, inspect each real save/restore and return map, and bind generated hashes to the same producer.

Use stable root-bearing operation records with opcode-specific root masks; all movable Scheme values must be read from GC-updated slots after nested service. Do not retain pre-GC `SCMOBJ`, frame pointer, object-body address or lock-field address in a C automatic across a moving collection. W_ALL does not update arbitrary C locals.

| Operation | Argument representation requiring explicit handling |
| --- | --- |
| VM_RESIZE | arg0 is Scheme thunk then Scheme status; arg1 is native target count. Root/reload only the Scheme slot. |
| PROCESSOR_0_THROW_ERROR | arg0 is SCMOBJ error; retain through common disposition and deferred propagation. |
| GARBAGE_COLLECT | arg0 is requested native word count then boolean result, not a generic Scheme root. |
| STARTUP_READY | native processor id and word epoch; no blind mark_array over them. |
| FDSET_RESIZE / ACTLOG | native maxfd or no used arguments; preserve actual opcode contract. |

Modify the engine to report a native disposition through a stable record instead of calling `___throw_error:1912` into a held scheduler scope. Ordinary native service returns only after its collective result/tails converge. Record error as rooted pending debt; never discard it to manufacture normal completion. The scheduler operation then either completes its consistent local unlock epilogue or enters a reviewed retain/fatal path. Only at outermost committed scheduler unlock, with no live native grant/tail, can it propagate the error. Void helpers cannot silently erase rejection/error; thread the disposition or a checked deferred-error record through them.

Do not merely wrap arbitrary collective work in a local catch: a member that escapes mid-barrier can strand peers. Classify elected phases before execution. Locked-service phases may perform reviewed native GC/communication but no Scheme callback, user yield, allocating completion landing, or acquisition of a scheduler lock held by a participating peer. Resize preparation/callbacks require an explicit lock-free Scheme landing and may not be smuggled into the locked drain. Reject incompatible transition preparation before acceptance; after acceptance preserve its obligation and use common failure disposition. Worker thread_exit/VM fatal exits must use their dedicated registered teardown path, not the ordinary caller's success ACK.

On unknown unlock/ownership state, do not claim scope zero, reuse the slot or throw back into normal resize. Keep pins/root records and use the existing reviewed shared-fault policy. On recoverable pre-acceptance refusal, balance the lookup grant without mailbox mutation. Every caught error, normal return and nonlocal exit needs a journal consumer; record cleanup in stable storage, not a modified non-volatile setjmp automatic. GC-safe root records remain until the last native reader and result consumer finish.

## 5. The single ordered publication protocol

1. Acquire valid VM/member lifetime; initialize root-bearing operation/phase registrations and completion storage. Publish manifest and persistent service-needed before close/wake. No raw lookup before a lifetime pin.
2. Entry acq_rel CAS increments count preserving mode; acquire-read current metadata, validate full key and one-shot claim. Mismatch drops count without queue/channel writes. OPEN-word ABA still fails full-key validation.
3. OPEN→CLOSING preserves count. Ordinary requests arriving later wait as debt; pre-issued drain phases can enter. Service uses per-native-owner nested activation journal and refreshes GC-updated roots.
4. Common result ACK: claim EMPTY→WRITING, initialize tagged payload, release READY. Leader acquire-observes READY. Writer pin remains through its final native access.
5. Seal admission by acq_rel CAS preserving count. Existing puts remain legal. Acquire-zero includes lookup/communication/writers, not persistent GO readers. Only sealed zero permits metadata/ACK reset; no fresh writer can enter then.
6. Initialize successor/result/resume state, release tagged GO/ABORT, exact-generation readers acquire and ACK. Reopen OPEN with release after common resume predicate. Old completion/root readers still own their separate lifetime refs. No carrier reclaim follows merely from GO or n==0.
7. Commit local scheduler unlocks and consume deferred errors at scope zero. Complete root installation/reader grace and owner-local reclamation using the earlier carrier protocol; RC intent alone is not an installed root acknowledgment.

## Grok implementation and native acceptance sequence

Implement as one coordinated change to `include/gambit.h.in`, scheduler lock macros in `_thread#.scm`/actual expansion owners, `_thread.scm`, `_kernel.scm`, `setup.c`, and the real root-registration/scanning owners in mem.c/mem.h. Regenerate `_thread.c`/`_kernel.c` and any changed generated FFI/map output. The new names are interfaces to implement; this report does not claim those symbols already exist.

* Freeze lock/main/patch/config/compiler/header/generated/object/lib/gsi identities in one receipt; retain the last working binary before replacement. Verify dedicated gate lock-free assertions and actual setup.o instructions under production flags; reject emulated or unexpected helper calls pending audit. These checks are before any campaign.
* Exercise first startup and repeated setup on P0/p1/p11, staged worker startup/abort and post-run native sync. Verify registration precedes wake and every direct engine entry has exactly one accepted context. Reject forged/stale/consumed/nested-parent tokens before writes.
* Instrument the entire source-site inventory, then force contention in run-queue, interrupt delivery, migration, state query, termination/abandonment, ordered2/3-thread locking and mutex/condvar wake. Record actual lock-scope depth/kinds at every sync; prove no new blocking control lock, callback or Scheme throw there. Do not test migration alone.
* At the same producer pause entry before pin/across repeated OPEN, after pin/before key validation, after READY/before put, and after zero/before reopen. Inject nested GC at each legal root point, compare GC-updated root cells and values actually used after R_ALL, and prove no access after last put. Keep original watchdogs.
* Inject an error while one/two/three scheduler tickets are held; require common phase convergence, rooted pending error, balanced native tails, committed unlocks, then one propagation. Also inject child-service error and native caller return; require restored parent activation/no duplicate phase execution. Unknown unlock takes retained/fatal disposition with no success ACK.
* Exercise close/ABORT/GO/two epochs, old completion reader surviving reopen, continuous GC and pending ordinary operation. Confirm service-needed cannot be erased by resetting an interrupt hint; count/phase/use overflow/refusal preserves already accepted debt. Existing root installation, final reader grace and reclaim assertions remain separate mandatory checks.
* Only after targeted native checks pass, run the unchanged previous-eight regressions and independent remaining gates under their normal acceptance authority. Formal9/12 still requires the lifecycle contract to be reviewed independently: pending→same-owner/same-incarnation real join0 preserves safety but is not the current OS-error predicate. Do not rewrite history, invent errno, or increment the milestone from these tests.

## Proof and performance limits

The combined model extends the prior admission/close/ACK/reopen model with a movable root cell and stale native copy, nested child/parent claim restoration, counted nested tail, one/two held-lock scopes, pending error and delayed handling. The inherited constant heldT denotes the service-entry assumption; the new locks field describes the modeled remaining scope count and reaches zero before finishNative handles error. It does not prove actual C unlock hooks. The positive cases require safety plus weak-fairness completion. Negative controls violate explicit obligations for blocking entry, root loss, stale post-GC use, throw-under-lock, dropped error, lost parent claim, post-put access, premature carrier drop and duplicate execution. These are abstract protocol counterexamples, not generated-C or weak-memory executions. Scope accounting, root scan correctness, hardware latency, arbitrary nesting and competing same-capability native claimants are not proved by the finite model. DuplicateExecution deliberately injects a second execution; it checks the invariant can reject it, not an implemented concurrent claim CAS. It composes these obligations with the prior state machine; it does not turn them into C refinement automatically.

Expected cost is one/few atomic RMWs and full-key checks per native phase, branch/atomic polling on existing contention paths, native scope hooks and root reloads, plus bounded preallocated per-member records. This is a structural cost estimate, not measured performance. No new heap allocation or mutex on locked entry; measure contention throughput, tail latency, GC pauses and memory high-water on the final producer. Reject regressions against unchanged budgets, rather than hiding stalls by increasing heaps/timeouts.

Independent conclusion: there is now one actionable implementation/acceptance contract for this drain interface. It still cannot prove9/12 before C/generator implementation and native tests, nor cover unrelated SIGSEGV/request-delivery/TYPEID/performance gates. A nonreturning owner cannot be made to return by this contract; safety retains its resources while progress is conditional. The exact remaining work is implementation/refinement and the tests above, not another unbounded series of model-only passes.

## Recorded verification

12 controls matched:3 safety/conditional-progress positives and9 independently decoded safety negatives. Per-case cap30s; maximum 12.863s. Verification receipt: `.cache/tasks/repair-9-12/processes/audit/runs/de2c88091e434876b36545feb1d57370/outputs/drain-closure-audit/receipt.json`. Two assembly-only compiler controls passed; runtime executions0. Source33 and protected20 hashes rechecked. Macro inventory binds 5 scanned files and 66 macro-call expressions. The initial run with unrecognized positive initializer modes is retained as a harness failure, excluded from this final result.

Causal limitation: [TFIB/interrupt failure alignment](repair9-failure-causal-alignment.md) shows why this drain contract is not an established fix for the original SIGSEGV or blocked request. Use its failure-selected diagnostic/native order before attributing either fault to this refactor.
