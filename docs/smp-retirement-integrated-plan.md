# Unified retirement model and function-level implementation plan

2026-10-22. Work item repair-9-12. Research handoff for implementing lifecycle-fault gate 9, with GC/FFI gate-10 dependencies kept explicit. Native acceptance remains **8/12**. This document and QNT are the deliverable; no runtime/framework code or other worker operation is changed.

B = vendor Gambit 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882. P = retained handler-quiet-while-pending-cumulative.patch SHA256 8d2181df5f5878c0f1ab2c321425f935ede86c0786c09f39c5636ae82f2aa8c7. P numbers are patch-file lines. Function names below distinguish existing functions from **proposed internal helpers**. This is not an audit of Grok's changing producer; first compare the selected candidate against each obligation before introducing duplicate machinery.

## One transition system, not conjunction of separate pass results

`retirement_integrated.qnt` has a single state record and step relation. P0, A and B participate in each epoch. A can reach Ready while B still invokes X; B requests GC1, then returns an error. P0 still has fallible preparation work and requests GC2 while the error is pending. Both GC rounds use arrivals keyed by `(epoch, round)`, scan representative donor/frame/RC locations, distinguish strong marking from will eligibility determination, and update the live result roots. The uncalled Y stays under the old queue owner. All old members remain in collective service through global preparation closure and current-epoch common completion. After abort they keep cohort=3, consume/release the result, and service Y exactly once. Only then can epoch 2 initialize its cursors and roots.

The second epoch leaves the first epoch's actual ack/arrival values stored, so accepting old values is a reachable mutation, not a fabricated initial oracle. Two positive campaigns abort twice or abort then successfully shrink. The latter drains Y via release(false), prepares surviving strong/frame/will ownership, completes a current-epoch decision, and only then changes cohort to one. Receiver will ownership is explicit: retaining a source will list in a withdrawn pstate does not count as coverage.

A third campaign invalidates Y and ends in opaque terminal retention after common abort. It refuses normal queue resume and further epoch admission. This is containment, not successful recovery, and its host/no-further-traversal policy still needs a native contract.

There are exactly two donors, two GC rounds **per epoch**, at most two epochs, one X per donor, and one never-invoked Y behind B's X. The two main campaigns therefore combine four collections, repeated transaction state, callbacks, queue disposition, root movement and result lifetime in one explored graph. A may finish before or after the first GC's relevant steps, but B outcome is constrained to follow A Ready. The model checks this requested scenario, not every possible callback/workload schedule. Successful Y cancellation is one finite nonallocating/no-reentry action here; a Y callback that itself fails, requests a third GC or changes other queue nodes is not explored by this graph. Real implementation must route Y through the same checked callback helper, rather than infer infallibility from this successful trajectory.

## Invariants and mutation controls

- `strongCoverage`, `framesCovered`, `resultCoverage`: a source counts only while the old cohort scans it; a registered current receiver/elsewhere continuation owner is needed on success. Request/error slots remain current until consumption; untraced payload does not qualify.
- `weakSemantics`: initial strong reachability does not strongify an isolated weak testator; will action stays strong, executability is determined before subsequent testator marking, and a surviving will-list owner exists after count change.
- `serving`, `closedDecision`: Ready/Failed does not permit early return; no common decision before both GC rounds and remaining P0 preparation close.
- `queueSafe`: callback X executes once even when self-freed, untouched Y resumes only if independently valid, and no invalidated suffix is reintroduced into usable service.
- Exact GC/abort identity and reuse: old round/epoch arrivals and acknowledgements are rejected; no new epoch before all old preparation/result/queue consumers finish.

Seventeen separately enabled mutations each require an invariant counterexample **and** a decoded discriminating state: early failed-member return; early Ready-donor source withdrawal; stale same-epoch GC round; stale prior-epoch GC arrival; stale prior-epoch abort ack; early error-root release; invoked-X replay; invalid-Y resume; weak-testator strongification; frame withdrawal; will-owner drop; premature decision; stale callback cursor; premature next epoch; unscanned RC payload; access to freed X; successful count change without typed handoff. A nonzero checker exit alone is not admitted.

Named trajectories exercise abort across both epochs and abort followed by successful typed handoff. Every positive checks safety and weak-fair conditional completion. Progress assumes each enabled modeled finite actor/callback returns; it is not a guarantee for a stuck callback, arbitrary host longjmp or OS failure.

## Function-level plan, in implementation order

### 1. Callback preparation and the untouched suffix

**Existing edit anchors:** B setup.c `release_procedural_interrupt`, `cleanup_interrupts_pstate`, `service_procedural_interrupts_pstate`, and P ___vm_resize_pstate retiring branch P:4757–4782. The raw producer export B:365–392 remains caller-lifetime controlled.

Proposed helper contract:

```text
retire_prepare_interrupt_step(ps, transaction):
    require ps is still in transaction.old_count and matches transaction.epoch
    require supported native producers drained; callback ownership contract admitted
    lock procedural_interrupts_mut
    pop one head; update head/tail; persist in-flight/progress for this epoch
    unlock
    if no node: publish queue disposition and local Ready
    else:
        invoke release(false) under local supported runtime catcher
        never dereference/requeue self after return or caught throw
        publish returned/caught error into an actual rooted slot if movable
        on error: retain untouched suffix in original queue, publish Failed
        on success: continue admitted finite cancellation, interleaving service
    keep participating until the transaction's common completion
```

Use a helper with explicit lock ownership; do not call ordinary service(true) as cancellation. The B service error branch unlocks before callback, breaks on error, then reaches the final unconditional unlock without relocking (B:190–200): retain this source-detected conditional defect as a separate review item. The cleanup(false) loop instead holds the mutex during callbacks and ignores returned errors. Neither is a recoverable preparation helper as written.

Prefer one-node pop to bulk detachment: Y remains in the original queue, so abort does not need a new linked-list rollback. On recoverable abort, preserve ordering and rearm existing interrupt service after unlocking when Y is pending (B:389–392,211–242). No callback may free/mutate another queued request under this small ownership contract. If that is allowed, the suffix cannot safely be validated by walking raw pointers; classify the outcome as opaque retained failure and do not resume ordinary service/cleanup traversal without explicit owner resolution. Callback effects are not rolled back.

**Fields:** per pstate `(retire_epoch, retire_status)` with Pending/Running/Ready/Failed/FailedOpaque, persistent in-flight/progress/disposition and any necessary rooted error handle. No detached suffix head/tail required for one-node pop. Persist progress before the external call; avoid setjmp-invalidated locals. A newly popped node being absent from the queue is not proof callback completion.

### 2. Outer dispatcher, epoch identity and common decision

**Existing edit anchors:** `current_vm_resize_admitted` P:5055–5065; ___current_vm_resize P:5070–5105; `execute_sync_op`, `execute_sync_op_loop`, `on_all_processors`, `barrier_sync_op` B:541–714,1012–1149; retained growth extension P:4920–5013.

Proposed helper boundaries:

```text
retire_begin(vm, old_count, target):
    under existing exclusive resize owner, finish/refuse prior consumers
    choose nonaliased new epoch; initialize every member's progress/root slots
    publish transaction with old_count unchanged

retire_service_member(ps, invocation_role):
    outer role: consume/suspend parent resize offer once, then serve prepare
    nested GC role: offer its own operation, return to its own caller when done
    Ready/Failed role: keep serving old cohort; ordinary NOOP cannot exit it

retire_try_decide(vm, epoch):
    collective old-cohort round validates matching statuses and no future work
    error -> Aborting; success -> validated typed handoff then Committing
    no OP_SET_PROCESSOR_COUNT while any GC/callback/fallible preparation remains

retire_common_complete(vm, epoch):
    all current members observe current decision through existing sync rounds
    abort: preserve old sources/queue disposition; authorize preparation returns
    success: handoff complete, then publish smaller count and enter OS-only tail
```

Reuse actual barrier message sequencing. A scalar acquire read of all statuses is not C2 or C3. Existing sync messages may remove the need for extra stored GC-round counters if their current-epoch association is proved; the QNT key is a specification, not a demand for another barrier implementation. Nested requests are invocation-local; suspended parent C frames are not automatically reoffered operations. Do not copy the growth path's startup boolean as a universal nested-call identity.

**VM fields:** retirement epoch/phase, old/target counts, exact decision/error attribution, and rooted saved values only when live. Epoch publication precedes member status publication; matched release/acquire or the existing collective proves observation. Do not reuse startup_epoch without equal lifetime/meaning proof. Do not reopen SFUN admission or execute the outer ON_THROW rethrow before C3. Advance an epoch only after old callbacks, result consumers and resumed suffix disposition complete; refuse unsafe wrap/reuse instead of aliasing stale identities.

**Minimize rooting after def-use audit:** B ___vm_resize_pstate reads thunk for the growth thread `data_scmobj` assignment (B:999ff), not its shrink branch; P retains that branch structure in this research source. A shrink-only implementation need not introduce a new live thunk use/root merely to copy a model field. The model requestRoot represents any actually live saved SCMOBJ. If the selected candidate does not need thunk after the new GC cut, prove that and omit its carrier; if it does, use a traced owner and reload. Immediate encoded errors likewise need no movable carrier. This prevents unnecessary allocation/fields without weakening live-root coverage.

### 3. Typed root/work handoff before withdrawal

**Existing edit anchors:** mark_rc B mem.c:3969–3991, mark_continuation B:3898–3966, register/saved/cache/processor scanners B:6508–6570, wills B:4040–4065,4996–5110, weak phase B:6872–6902; P per-member RC/root barrier P:3579–3593 and ___transfer_mem_pstate P:3301–3353.

Proposed helper boundary:

```text
retire_prepare_handoff(ps, receiver, epoch):
    before C2: finish all fallible root preparation under old-cohort scanning
    classify each live source: already traced elsewhere / supported transfer /
                               dead by source proof / unresolved -> reject commit
    preserve strong locations, frame interpretation, still/RC links and weak policy

retire_commit_handoff(ps, receiver, epoch):
    after all-member closure, at valid collective GC/work boundary
    perform only validated nonallocating ownership splices/publications
    establish receiver scanning and no outstanding borrower before source invalidation
    no callback, allocation or unproved fallible root construction remains
```

Do not simply move ___transfer_mem_pstate to the new call site: its retained comment/callers require a **joined donor and borrower drain**, and it only moves still/RC lists and counters. If extracting the mechanical splice into a shared internal helper, retain distinct joined-donor and live-but-quiescent caller preconditions and prove both. The latter requires callback/allocator/scanner closure while the old cohort still exists; a new ready flag is not that proof.

The concrete census from [the prior contract](smp-retirement-implementation-contract.md) remains binding. RC header.data is scanned, arbitrary payload is not; register locally rather than concurrently mutating another processor's RC list. Scheme frames must keep their actual RA/link/gcmap interpretation; no native C activation migration. Existing initiating-Scheme-caller migration P:956–976 is preserved, not a census of all donor frames. Will lists need typed owner/list handling preserving weak testator and strong action semantics; they are not covered by the still/RC helper. Private scan queues and incomplete frontiers need work/borrower closure, not a carrier root. Keep P's root barrier and termination recheck.

**Rooted result return:** do not release a movable error handle after copying its value into an untraced C return local. The final consumer must first install a current value in a proven caller/root location, or prove the value is immediate/no GC can intervene before the supported return convention establishes coverage. The model consume/release split is this obligation, not a new public token API. Lack of an actual caller-root proof blocks implementation sufficiency.

### 4. Join/recovery and one-time cleanup

**Existing edit anchors:** shrink join loop P:4833–4870; recover_retired_processors P:4650–4697; setup/init and cleanup call sites. Keep ___thread_join's real return code and the audited OS-only exit tail.

Proposed shared helper contracts:

```text
retire_join_once(owner, slot_record):
    verify exact VM lifetime/slot/incarnation and owner
    only JoinPending invokes OS join
    success -> persist Joined before any fallible later work
    error -> preserve actual handle/resource record under its legal error policy

retire_finish_slot(owner, slot_record):
    require Joined and required quiet/last-consumer cuts
    release/transfer remaining resources once; do not repeat precommit handoff
    cleanup -> Released; otherwise retain exact failed phase
```

Add/retain explicit distinction among JoinPending, JoinedAwaitingFinalCleanup, Released and TerminalRetained, with exact error attribution. If typed ownership moved precommit, postjoin code must not splice it again. An aggregate pending count summarizes remaining slots; it is not permission to free or proof another slot recovered. Do not automatically retry EINVAL/ESRCH/EDEADLK, normalize every nonzero to retryable, or claim a failed join proves exit. If quiet=false-after-success is excluded by the selected source, simplify with that proof instead of inventing repeated joins. Errors after cohort commit do not resurrect partly destroyed workers by increasing processor_count.

## Before merging an implementation: still-open sufficiency blockers

| Model premise | Source/native obligation still open | What fails without it |
| --- | --- | --- |
| Supported raw producers drained; finite callbacks return | Actual supported callback/enqueue/aliasing contract, origin catcher/reentry rules and native timeout policy | New work after C2, invalid suffix, nonlocal escape or stuck old participant; cannot promise recovery for arbitrary function pointers. |
| Atomic pop and outcome publication, exact current identity | Correct mutex/atomic/barrier ordering in C; same VM/slot lifetime; epoch reset and overflow/refusal | Double invoke/UAF, stale Ready/ack, admission reopening while old work is live. QNT sequential actions are not C memory-model proof. |
| Surviving strong/frame/will ownership at prepareHandoff | Full field census, supported continuation/native-origin exclusion, weak/hash/will policy, actual receiver scan and work closure | Success may omit a live root or change weak semantics. Abstract handoff is the largest remaining source-refinement assumption. |
| Result consumer owns current value before release | Actual Scheme/C result and exception propagation def-use/root path | Error survives preparation GC but becomes unrooted in return/unwind tail. |
| Opaque retained state prevents all unsafe traversal | Native host behavior, bounded capacity, affected worker/queue/error policy | A “retained” pointer can still be dereferenced by normal service or teardown; retention alone is not containment. |
| Join/refinalization consumes each exact resource once | Legal OS error classes and real same-owner/incarnation recovery evidence | Duplicate joins/transfers or unrelated-slot success masks failure. Integrated model has no OS join oracle and does not prove these outcomes. |
| Two finite donors/epochs/GC rounds represent local mechanism | Arbitrary cardinality/repetition, capacity, scheduling, real workload performance and complete 1–8/9/10 acceptance | Finite passes cannot certify unbounded liveness, all twelve gates or production stability. |

The model therefore proves useful necessary ordering/ownership constraints **under explicit assumptions**, not that four edits are already sufficient. Implementation order is callback state/ownership -> dispatcher cuts -> typed handoff -> one-time postjoin cleanup, followed by matched source-bound native fault and regression campaigns under existing budgets. This is a handoff document for review; this chat neither messages nor operates Grok.

## Execution provenance

Original combined 30-second budget per checker call, final temporal schedule for positives, 12 workers, 1 GiB heap and 8 MiB stack. Compilation is charged inside each check's budget. Mutation traces are decoded and matched to their specific witness. Source identities are checked before/after; own registered verifier children are reconciled before publication.

The first integrated run 9883c0fd0a3e4485ac07b3575b956d37 passed its narrower graph but left success will-owner placement implicit. That complete historical run is retained. The successor explicitly adds a will receiver and a missing-handoff mutation, and reruns the strengthened model under the same limits; results below apply only to that successor's hash. Existing component models and all historical failures/timeouts remain unchanged. No native run or source seal is created.


## Actual strengthened-model results

| Check | Result | Distinct states | Seconds |
| --- | --- | --- | --- |
| typecheck | PASS | n/a | 0.908 |
| initAbortTwice | PASS | 144 | 4.967 |
| initAbortThenCommit | PASS | 145 | 4.916 |
| initOpaqueSuffix | PASS | 71 | 5.127 |
| initEarlyReturn | Decoded expected counterexample | 65 | 4.937 |
| initEarlySourceDrop | Decoded expected counterexample | 85 | 4.930 |
| initStaleGCRound | Decoded expected counterexample | 133 | 4.906 |
| initStaleGCEpoch | Decoded expected counterexample | 113 | 4.985 |
| initStaleAbortEpoch | Decoded expected counterexample | 151 | 5.039 |
| initEarlyErrorRelease | Decoded expected counterexample | 65 | 5.247 |
| initReplay | Decoded expected counterexample | 65 | 8.819 |
| initDeadSuffixResume | Decoded expected counterexample | 62 | 13.027 |
| initStrongifyWeak | Decoded expected counterexample | 37 | 17.397 |
| initWithdrawFrame | Decoded expected counterexample | 2 | 6.209 |
| initDropWillOwner | Decoded expected counterexample | 2 | 4.958 |
| initEarlyDecision | Decoded expected counterexample | 111 | 5.686 |
| initStaleCursor | Decoded expected counterexample | 79 | 5.564 |
| initPrematureReuse | Decoded expected counterexample | 154 | 4.965 |
| initUnscannedPayload | Decoded expected counterexample | 2 | 6.200 |
| initFreedNodeAccess | Decoded expected counterexample | 41 | 9.160 |
| initMissingHandoff | Decoded expected counterexample | 154 | 8.817 |
| combinedAbortAcrossTwoEpochs | PASS | n/a | 1.353 |
| abortThenSuccessfulHandoff | PASS | n/a | 1.019 |

All 23 checks accepted; 17 decoded mutation witnesses. Model SHA256 `42b5a537f390d3b35ab654af7a64550a872cf9418a361992af5a88d8859ed24f`. Raw audit `.cache/tasks/repair-9-12/processes/audit/runs/0537b22a690d4206be6483e2d6be2966/outputs/integrated-retirement`; original source-window hashes stable, no runtime/native execution. See [versionable validation](../evidence/research/smp-retirement-study/integrated-validation.json).


## Concrete C return/withdrawal refinement

The [C call-chain successor](smp-retirement-c-handoff.md) resolves a narrower ordinary-return path: the checked generated c-lambda installs PSR1 through a cooperative no-GC bridge. A blanket new caller-root API is unnecessary for that path; cross-GC saved errors and raw C retention still need actual roots. It refines full GC-tail/scanner closure and separate still/RC/frame/will ownership in the unified model. Original evaluator failures and alternate-evaluator trajectory passes remain explicit.


## Active donor frame/scheduler refinement

The [donor ownership follow-up](smp-retirement-donor-ownership.md) shows THREAD_SAVE initially records a stack-backed frame; current sync interrupt register spill is not saved execution ownership. For arbitrary active donors the dispatcher surface needs a Scheme safe-point/helper, not only setup.c/header/mem.c. Existing collector materialization and private scanning can be reused. Exact C/Scheme scheduler publication and abort restore remain unproved; the new bounded model does not close native gates.


## Safe-point completion boundary refinement

See the [Scheme/C protocol and last-consumer ledger](smp-retirement-safe-point-protocol.md). Common decision completion no longer implies runnable publication or external API completion. A rooted parked execution owner survives count reduction; activation/abort restore is an explicit same-epoch obligation. The unified successor includes full helper GC under the outcome-specific cohort and 48 effective accepted checks, preserving historical failures. This is research, not a runtime implementation or native qualification.
