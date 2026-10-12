# Idle Processor Deque Lifecycle

## Source Facts

Authority is the pinned `vendor/gambit` submodule and the cumulative
`interrupt-dequeue-detachment` source lock, not an execution cache path.

`define-deq` in `lib/_thread#.scm` splices a node out by changing its neighbors;
it does not reset the removed node's links. `##wait-abort!` and the post-select
part of `##wait!` both remove a processor under the VM lock. Between these two
removals, another processor may park. Reusing the removed node's stale links
can unlink that newly parked processor. Locking alone does not prevent this
serialized schedule.

Separately, `___vm_resize_pstate` exits a retired processor directly after its
barrier and OS cleanup. That exit does not return through the Scheme select
helper. `setup_processor_scmobj_pstate` resets the same permanent processor
object on reuse; `macro-processor-init!` initializes its links without removing
old VM-sentinel membership. These facts motivate a retirement splice, but its
VM-lock versus collective-barrier ordering is not yet proved.

The existing reuse fixture pins its caller to processor zero. Its recorded
epoch-seven timeout must not be attributed to retirement of the requester.
Neither deque defect is yet proved to be the unique cause of that timeout.

## Model Checks

| Contract | Old control | Fixed safety and progress |
| --- | --- | --- |
| Idle retirement/reuse | Counterexample, 3 distinct states, 3.784 s | 5 distinct states, 3.648 s |
| Repeated removal with intervening park | Counterexample, 4 distinct states, 6.828 s | 4 distinct states, 6.783 s |
| Proposed retirement VM lock / peer GC / P0 join cycle | Counterexample, 7 distinct states, 3.733 s | 7 distinct states, 3.779 s |

Portable receipts are registered in `evidence/protocol-bundles.json`, under
`evidence/model-results/fixtures/interrupt-dequeue-detachment/`. The roles in
these finite models are not a runtime CPU limit. TLC workers are host-selected.
The repeated-removal parser error and initial loopback permission failure are
execution diagnostics, not counterexamples or accepted checks.

## Source Candidate

`patches/fixtures/idle-processor-idempotent-removal.patch` inherits the prior
17-file source slice. Its only additional change renames the SMP processor
deque's generated splice macro and wraps it with self-link initialization.
Other deque kinds and the non-SMP branch remain unchanged. This mirrors the
fixed repeated-removal transition; it does not implement retirement cleanup.

The source lock is
`evidence/fixtures/idle-processor-idempotent-removal/source.lock.json`.
GNU GCC core compilation and unchanged native regressions determine acceptance,
not the model verdict alone. Core compilation is incremental, not a fresh
two-pass bootstrap.

The candidate independently reproduced all 17 patched source hashes from the
pinned base. GNU GCC 16.2.0 core compilation passed in 149.180 seconds with no
recursive build errors; the log includes `_thread.scm` regeneration and
`_thread.c` compilation. All three VM/SMP flags remain enabled. Make used the
detected 12 available processors and inherited `GAMBOPT=p1`; 12 is an observed
host capacity, not a configured limit.

| Unchanged native regression | Result |
| --- | --- |
| Compiled migration target with GC | PASS, 0.471 s |
| Compiled strict interrupt ticket delivery | PASS x3, 0.483 / 0.013 / 0.013 s, 1152 interrupts each |
| Interpreted processor reuse and still-object survival | DENY, 30.005 s, exit -9, process group quiescent |

The reuse run completed epochs zero through three, then stopped after epoch
four's grow-return marker. This is weaker than completion and does not uniquely
identify the remaining cause. The whole receipt is DENY. No unchanged retry
or later table-GC test was run after this failure. The prior epoch-seven timeout
remains separate evidence, not replaced by this observation.

Receipts and identity are in
`evidence/source-results/fixtures/idle-processor-idempotent-removal/`.
Thirty protocol-evidence/build-capacity framework tests passed with no skips;
they do not qualify runtime correctness. The next source audit must address
retirement membership and lock ordering before another reuse campaign.

## Retirement Detachment Candidate

The lock audit found the debugging `##waiting-processors` helper allocating
list cells under the VM lock. Adding a retiring-processor VM-lock splice without
addressing that allocation admits a three-party cycle: P0 joins the retiree,
the retiree waits for the VM lock, and the active lock owner waits for P0 in GC.
The model control characterizes this unsafe proposed composition; it is not a
native reproduction or unique attribution of the current reuse timeout.

`idle-processor-retirement-detachment` therefore combines the retirement splice
with a preallocated vector snapshot in that debugging helper. All deque reads
and writes are VM-locked, but vector allocation and list conversion occur
outside the lock. Capacity grows only after releasing the lock if concurrent
membership growth exceeds the snapshot capacity. Reverse list order is retained.
The C retirement splice self-links the permanent processor before OS exit and
does not transfer or free its memory before P0 joins it.

The cumulative patch and lock use that semantic fixture name. Arbitrary-neighbor
refinement, snapshot growth fairness, full sync membership, generation drain and
failed-join recovery remain obligations. No original native timeout is retried
without this actual source change.

The retirement candidate reproduced all 17 source hashes from the pinned base.
GNU GCC 16.2.0 incremental core build passed in 20.648 seconds; the log proves
Scheme `_thread.scm` regeneration and C `setup.c` compilation. All three flags
remain enabled. The unchanged compiled migration test passed in 0.489 seconds;
strict interrupt delivery passed three runs in 0.471 / 0.016 / 0.014 seconds.

The unchanged reuse fixture passed two complete runs (0.492 and 0.042 seconds),
including every grow/join/shrink/GC cycle and still-object assertion. The third
run timed out at 30.005 seconds after epoch one's grow-return, exit -9, with a
quiescent process group. The whole candidate is DENY; table GC was not run after
fail-fast. Two positives do not establish stability or isolate either change's
benefit. Receipts and current binary identity are under
`evidence/source-results/fixtures/idle-processor-retirement-detachment/`.

A subsequent startup publication audit found that `##startup-processor!` already
initializes queues before `___processor_startup_complete`; the old cohort waits
for scheduler status for the current startup epoch. Do not repeat the already
implemented queue-initialization-before-ready fix based only on this timeout.
Further discriminating evidence is needed on scheduler/wait/wake interleavings
after readiness. Forty-one protocol/build-capacity/recipe framework tests passed
without skips. Local recipe discovery admitted 37 recipes after classifying the
archived still-survival receipt as a historical reference, not a runtime input.

## Remaining Requirements

- Refine both finite contracts to arbitrary neighbors and processor populations.
- Establish retirement splice placement without a VM-lock/collective-sync cycle.
- Drain running and queued threads, saved-stack roots and interrupt ownership.
- Preserve generation ownership and quarantine resources after failed joins.
- Pass the original reuse regression, full native suites and fresh bootstrap.
- Qualify Gerbil build/test correctness before measuring performance.

No complete SMP, GC, runtime or release admission follows from these local checks.
