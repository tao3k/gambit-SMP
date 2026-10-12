# Nested Termination And Result Ownership

## Source Authority

The source authority is the pinned Gambit submodule and the cumulative overlay
`evidence/fixtures/thread-completion-contract/source.lock.json`, not a cached
runtime path. The overlay binds `lib/_thread.scm` to
`691c0930ea7de9e43d4ed166349511b14619879d986b9237bd00ba8abd9cb308`.

`##thread-end!` sends a synchronous interrupt when terminating another started
thread. `##thread-intr!` constructs a result mutex owned by that target, then
the initiating thread waits for the result. `##thread-end-current-thread!`
enters `##thread-end-locked!`, whose owned-queue loop calls `##btq-abandon!`.
This must abandon both the original callback result A and the later termination
request's result T when they are still target-owned. The termination initiator
recovers through the inactive/abandoned exception catcher in `##thread-end!`.

The self-termination diagnostic does not exercise this second result mutex:
`##thread-interrupt!` directly invokes its action for the current thread.
Successful self-termination therefore does not qualify external termination.
The current `##thread-end!` fast-path comparison names the current processor,
not the current thread; the later `##thread-interrupt!` comparison still gives
self-termination a direct action path. This mismatch is an audited inefficiency,
not evidence of the observed external-termination deadlock or a tested fix.

## Model Boundary

The current model is the checked staged exit-drain revision at SHA-256
`8512e9f88acff343a68204a841fc472bdf227f8a775e6939df3e725a6e46c90b`.
Typechecking and all 17 deterministic trajectories passed. Full TLC checking
completed with 444 distinct / 1,019 generated states and zero queued states;
joint safety, bounded strict progress and weak-fair completion passed. Seven
hypothetical fault initializers produced decoded expected invariant
counterexamples. Those controls stop at their counterexample and are not
exhaustive passing state-space checks.

The whole campaign took 32.071 seconds within its original 90-second deadline.
Host-derived capacity selected twelve available processors and two concurrent
control checks based on 32 GiB physical memory; each control used six TLC
workers, and the positive check used the full host allocation. No host count
is hardcoded in the model or launcher. Input hashes matched before and after;
every observed process parent was reaped and process group was quiescent.

The first monitor draft failed syntax preflight. The next passed typechecking
and trajectories but failed TLA conversion: Quint 0.33.0 rejects a shared action
helper across selected and alternative initializers. Direct initializer
declarations corrected that tool boundary without changing protocol semantics.
Both DENY observations remain under `staged-exit-denials`; they are neither
native regressions nor passing model checks. No expired deadline was reset.

The current snapshot, logs, decoded controls and hash-bound archive are under
`evidence/model-results/research/interrupt-nested-termination/staged-exit-drain`.
Shared `protocol_evidence.portable` removes host diagnostic paths, retaining
raw and portable log digests. Reinterpreting the portable logs produces the
same decoded traces and checker verdicts. The registered protocol list and
native retry policy were not changed; this archive grants no native admission.
The later historical-results section refers only to its immutable older
snapshot, not this revision.

Source inspection requires distinguishing target-owned A/T result abandonment,
target-lock release and join notification. `##thread-end-locked!` clears the
end marker before draining its owned queue, while holding the target lock;
`##thread-join!` and `##thread-state` acquire that lock before observing exit.
A termination initiator may recover after its own result is abandoned, before
all target-owned results are drained. A new join can observe completion after
target unlock, whereas an already queued join depends on the condvar signal.

The revised model represents these stages separately and permits both A/T
drain orders as an overapproximation. Additional hypothetical controls cover
premature unlock, unsynchronized join, loss of a woken requester's root and
loss of join notification. They are protocol fault controls, not newly observed
source bugs. The monitor checks a bounded, strictly increasing progress measure
for nonterminal steps without disabling protocol transitions. Every transition
updates the ghost monitor, including deterministic trajectories; terminal
stuttering is allowed. Actual lock retries and collector work are excluded
from this finite measure, so it does not prove bounded native execution time.

The strong-root source chain is processor current-thread field 14, thread-owned
deque fields 2/3, result-mutex structure fields and generic structure scanning.
`garbage_collect_mark_strong_phase` calls `mark_processor_scmobj` before scan
completion. Source `##thread-end-current-thread!` clears the processor's current
thread only after drain and notification return. Generated `_thread.c` for the
same source-core identity confirms the order and saves the target thread and
end-condvar in Scheme stack slots across abandonment calls. Its observed hash
is `1dd389bae153ca343cc29219180f45a5522cca9254b744dffc95db43f173b81d`,
matching that producer's identity record. This is a generated-artifact audit,
not new source authority: regeneration uses the pinned submodule and overlay.

Root retention after waiter removal additionally depends on saved continuations
and run-queue publication. The model's root flags remain explicit assumptions;
they do not prove physical relocation, weak-memory visibility, arbitrary heap
graphs, multiple joiners or whole-GC/source refinement. The entry remains the
canceled-requester suffix, not an executed composition with the delivery prefix.

## Unclosed Primitive Lock Requirements

The staged model assumes each abandonment primitive can complete. Source audit
does not yet establish that assumption. In the source-lock-bound SMP branch:

| Source operation | Locks held while acquiring the next lock |
| --- | --- |
| `macro-mutex-lock!`, `lib/_thread#.scm` | Mutex M, then the supplied owner thread T |
| `##thread-end-locked!`, `lib/_thread.scm` | Terminating thread T, then owned blocked queue M through `##btq-abandon!` |
| `##lock-scheduler-object-with-sync-participation!` | Retries T and services sync operations, without releasing the caller's M |

The public `mutex-lock!` accepts a third-party owner thread. Its initialized
thread check releases T before entering `macro-mutex-lock!`; it does not hold T
through the subsequent acquisition of M. The out-of-line slow path releases T
only after both low-level locks have already been acquired, so that release
does not resolve a cycle at the macro entry.

A source-shaped candidate schedule therefore needs checking: T logically owns
M; another processor acquires M while requesting ownership for T; T acquires
its own low-level thread lock for termination; the peer waits for T while T
waits for M to drain its owned queue. Logical mutex ownership and low-level
lock ownership must be represented separately. The pinned upstream source
already contains both nesting orders; this audit does not establish that the
sync-participation overlay introduced the inversion. Interrupt suppression
alone is not a demonstrated exclusion of cross-processor execution.

This is an unresolved reachability/progress obligation, not a reproduced
native failure or a checked QNT counterexample. The checked 444-state model
does not contain these low-level locks. Required follow-up is:

1. Extend the exit-drain protocol with processor actors, separate low-level
   lock owners, legal third-party owner calls and the actual entry checks.
   Check enabled progress and wait cycles, not just eventual abandonment.
2. Model sync participation without assuming that it releases another held
   lock. Include queue mutation and target termination between retries.
3. Evaluate release/reacquire and revalidation on contention as a candidate,
   preserving the uncontended path, roots and queue ownership. A global lock,
   disabled SMP or an unbounded retry is not an accepted repair.
4. Bind any counterexample and changed source to the framework's typed
   current-producer review and native path. Do not synthesize a native failure
   record from the hypothetical schedule, or reuse a cached runtime as a new
   producer. That capability remains owned by the existing framework task.

All formal checks and native acceptance must use the shared framework. This
audit adds no private runner, new runtime patch, execution authorization or
passing model result. References are the pinned `vendor/gambit` source,
`evidence/fixtures/thread-completion-contract/source.lock.json`, its declared
patch, and [the producer-review contract](current-producer-review-step-design.md).

The separate `exit_drain_mutex_lock_order.qnt` now expresses this primitive
boundary without changing the checked staged model. It initially declared five explicit
trajectories: original wait cycle, candidate escape with fresh terminated-state
inspection, peer-first completion, target-first completion and independent
logical/low-level ownership. Its proposed contention fallback drops M, waits
for T, reacquires M and revalidates under both locks. This models one mutex and
two actors only; it does not establish general multi-object lock ordering,
collector participation or implementation correctness.

Further source inspection of `##mutex-lock-out-of-line!` found a second
acquisition boundary: it releases the new-owner thread lock while retaining M,
then calls `##lock-2-threads!` when inspecting or queuing the waiter. An
entry-only change therefore cannot establish progress across the slow path.
The current model includes that release and reacquisition, an `initEntryOnly`
policy and two additional trajectories: the remaining slow-path wait cycle
and the candidate slow-path escape. The recipe now requires all seven tests.
The model abstracts only the target member of the two-thread lock operation;
current-thread locking, aliasing, waiter insertion, timeout and signal transfer
remain explicit unclosed requirements. No production implementation of the
candidate fallback is claimed.

The v2 data-only recipe
`evidence/research/exit-drain-mutex-lock-order/controls.recipe.json` binds the
locked source, parse/typecheck, exact five-test inventory and terminal ASCENT
evaluation. The initial sealed run was DENY in 2.681 seconds within 90 seconds:
`native execution requires host --allow-native and --gcc`. The CLI omitted
`--allow-native`; terminal ASCENT evaluation requires that authorization even
though the recipe does not execute a Gambit runtime. No step executed, and no
typecheck or trajectory PASS is claimed. The immutable engine identity was
`17266faf4ff470044cee6da122ab6a39ddcacff460428facc33c65b654d5a55a`.
The raw denied receipt remains in the local fixture cache, not source authority.

There are two framework requirements before this can be called checked:
the sealed retry contract must bind and validate an explicit host authorization
change (currently it rejects identical input/engine retries regardless of that
change), and the v2 capability set must support exhaustive Quint/TLC checking
with decoded negative traces, positive completion and process teardown evidence.
It currently exposes parse/typecheck/test, not TLC verification. Both gaps are
assigned to the existing framework task; no shared Python, bypass checker,
dummy input delta or budget reset is introduced here.

The substantive slow-path model revision enabled a prior-bound attempt with
the missing host permission supplied, keeping the original 90-second budget.
The outer framework accepted the real model/recipe input delta and bound the
initial denied receipt. The child then failed before any step with
`'toolInputs'`: its prior reader unconditionally accesses that field, although
the initial authorization preflight denial occurs before it is written.
This second DENY took 3.344 seconds, without timeout; no model check executed.
The framework must validate and preserve partially populated preflight failure
receipts without fabricating absent tool observations. This is distinct from
a model safety violation. Both denied runs remain retained, and no unchanged
retry is scheduled until the responsible framework task fixes the contract.

## Framework Repair And Checked Lock Protocol

The human subsequently assigned the three framework interfaces to this task.
The existing Python framework now distinguishes an absent authorization
preflight tool observation from an observed hash-bound tool manifest. It
preserves the denied receipt, rejects absent observations for other outcomes,
and rejects changed manifests. A host authorization repair is narrowly limited
to the actual empty-step authorization denial. The outer sealed retry also
checks the prior child receipt hash; original whole and per-step budget checks
remain. Focused framework/checker tests passed 64/64 in 0.917 seconds. The first
sandbox run had eight localhost-bind errors; those are environment failures,
not silently removed assertions, and the same tests passed with local binding
permitted.

The v2 framework has a typed `quint.verify` capability, using the shared
Quint/TLC interpretation and counterexample decoder, matching parse dependency,
host-derived processor count and the same process/deadline recorder. Positive
completion requires zero queued states and temporal completion when requested;
negative completion requires an actual decoded invariant counterexample.
Timeouts and missing parent/group teardown evidence fail closed. This is not
an extensible data-supplied Python handler or a private runner.

Actual framework execution exposed a missing explicit stuttering assignment
in test assertion tails, then the TypeScript runtime's unsupported `enabled`
operator. Both failed observations remain in the fixture cache. The model now
enumerates action guards for executable tests, while its TLC invariant also
checks equivalence with actual `ENABLED(step)`. The seven-test run passed but
its terminal ASCENT evaluation exceeded the original ten-second step budget;
that timeout remains DENY, without changing that limit.

The subsequent typed-checker recipe completed all eight steps, including
terminal native ASCENT evaluation, in 44.239 seconds within the unchanged
90-second whole budget. Engine identity:
`3ad01b61676fe4dbea513578b5819ae148cc8fce40474c0773461cfed7f051ba`.
Original and entry-only policies produced decoded invariant counterexamples.
The candidate protocol completed safety, guard equivalence and weak-fair
progress checking with 50 generated / 41 distinct states / zero queued states.
Every verification used the detected twelve processors, not a fixed setting.
The full failed-run chain is preserved via hashed prior receipts.

These results establish only the finite lock protocol and the observed v2
framework execution path. The low-level candidate has no production source
patch or native acceptance. Current-producer causal review, fresh Scheme
compilation, complete runtime suites, bootstrap and Gerbil acceptance remain
open. Checker tool/resource sealing and wider capability negative-control
coverage also require further audit before whole-SMP admission. None of these
requirements is discharged by the 41-state model or the focused Python tests.

## Historical Snapshot Results

`models/gambit/interrupt_nested_termination.qnt` checks the suffix beginning
with A's callback in flight and its requester already canceled. This entry
matches an established state of the earlier cancellation protocol, but the new
model does not execute that imported protocol or reprove delivery and unlink.
It must not be registered as a full composition merely because the entry is
plausible. The earlier checked 192-state model and its receipts are unchanged.

The suffix distinguishes T publication, queue extraction, target exit and
initiator recovery. Callback return/throw may race with these stages. It retains
A's result owner after requester cancellation, abandons only still-owned results
on exit, preserves a completed return, and checks no late requester continuation.
Two abstract collection events interleave independently; explicit root flags
are assumptions about physical scanning, not a moving-collector proof.

Three hypothetical fault controls retain T's owned result on exit, remove its
root, or resume the canceled requester. They expose required protocol guarantees,
not three newly reproduced source bugs. Safety includes one termination delivery.
Weak-fair progress assumes terminating primitives and queue/lock participation;
this does not prove C weak-memory ordering, every collector phase, lock retry or
processor retirement. There is no global lock or disabled SMP in this model.

Typechecking and all seven deterministic trajectories passed. The trajectories
cover nested termination after collection, return before termination, throw
before dispatch, an already inactive target and the three fault controls.
This is not exhaustive state-space or native external-termination acceptance.

Subsequent complete Quint/TLC checking passed safety and weak-fair completion
with 42 distinct states, 89 generated states and zero queued states. The three
fault initializers produced decoded expected invariant counterexamples. The
whole campaign took 6.578 seconds within a 90-second cap; host-derived capacity
selected four independent check workers from twelve available processors.
Each model snapshot matched the source hash before and after checking.

Portable model snapshots, complete checker logs, decoded counterexamples and
source-lock-bound archival receipt are retained under
`evidence/model-results/research/interrupt-nested-termination`. The registered
protocol list was not changed during the framework task's DSL migration. This
archive is not a canonical failed-native-route record or retry eligibility.

The existing cancellation fixture now has a prepared
`external-terminate-after-cancel` mode. After the second GC, the callback
validates its payload and publishes an atomic ready milestone. It then yields
while awaiting a flag the orchestrator never sets. Only after that milestone
does the orchestrator synchronously terminate the target. That call must return
and target join must report termination, while the original requester stays
joined and its continuation absent. Existing one-callback and assertion-failure
exit checks remain. This mode has not executed or qualified a native outcome.

## Closure Order

1. Check complete finite safety and weak-fair completion with the existing
   Quint/TLC backend; retain all three expected counterexamples and original caps.
2. Link each abstract transition to the exact source functions and record entry,
   locking, root-scanning and scheduling assumptions as unclosed requirements.
3. Use the generic current-producer review interface assigned to the framework
   task before claiming formal native admission. Author causal review against
   preserved original failures; never synthesize a reviewed label from model PASS.
4. Run external termination with the current producer and actual blocked caller,
   callback/GC milestones, both join outcomes and bounded teardown, then proceed
   to complete same-artifact suites/bootstrap/Gerbil gates.

No runtime source patch, canonical failure deletion, timeout expansion, previous
binary import, release admission or performance claim is made by this suffix.
