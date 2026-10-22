# Current Producer: TFIB Cost And GC Repair Handoff

## Scope

This is a source-grounded research Recipe, not native acceptance or a runtime
patch. Preserve the historical 6/12 and 8/12 observations. Closing the complete
GC/FFI contract still requires its two applicable full native inventories; neither
this analysis nor a completed numeric compilation supplies them.

The current producer is declared by
[the numeric-host source lock](../evidence/fixtures/vm-registry-reader-lease/resize-grace-numeric-host-source.lock.json)
and [its cumulative patch](../patches/fixtures/vm-registry-resize-grace-numeric-host.patch).
The older producer and declared observer are distinct inputs in
[the original interpreted observation](../evidence/research/processor-interrupt-collective-wait/gc-datagram-native-observation.md).
Do not transfer that producer's successful stress result or timing to this one.
Transient logs, binary identities and query checkpoints stay in task cache.

## Reproducible Workload And Capacity Audit

The pinned [TFIB source](../vendor/gambit/tests/unit-tests/06-thread/tfib_stress.scm)
defines `T(0) = T(1) = 1` and `T(n) = 1 + T(n-1) + T(n-2)` delay calls.
Consequently `(go 15 5000)` performs 9,865,000 delay calls and 59,190,000,000
recursive busy-loop decrements. It starts 4,935,000 Scheme threads, including
the outer 5,000. These are source operation counts, not elapsed-time bounds.
The original comment calibrates a compiled delay; it does not calibrate GSI.

The retained [sequential delay diagnostic](../evidence/research/processor-interrupt-collective-wait/native-observation.md)
measured 1,000 interpreted delay calls in 2.110121 seconds on the older producer.
Applying that coefficient to the full delay count gives about 20,816 sequential
CPU-seconds, or about 10,408 seconds with ideal two-way parallel execution.
This is an illustrative historical capacity estimate, NOT a lower bound,
current-producer prediction, scaling theorem or substitute for original stress.
Different source, observation, warm-up and CPU conditions remain material.

The historical inventory explicitly selected two processors and one driver.
The [current inventory Recipe](../evidence/research/ci/bazel-profile-gc-ffi-inventory.recipe.json)
now leaves processor selection to the existing host-capacity default, with one
driver. Existing `capacity` in
[suite_primitives.py](../src/gambit_smp/suite_primitives.py) already derives a
population from available host capacity when `processors` is omitted. With one
driver, that existing policy assigns `max(2, available_cpu) - 1` VM processors;
it does not require a new Python policy or a hardcoded replacement population.
The outer runner's `p1` option is deliberate: tested children inherit their
separate `GAMBOPT` topology. Check the actual child probe, not just runner argv.

A topology change is a changed test condition, not a runtime repair or inherited
PASS. The corrected declaration is a new consumer of the retained producer;
old attempts and their fixed-topology receipts remain unchanged. Do not edit a
running Recipe. Inspect each PR fixture's topology contract
separately; do not remove all explicit two-processor controls indiscriminately.
Keep the original workload and the existing 3600-second qualification budget.

## Current Source Already Excludes Two Simple Explanations

1. `___DEFAULT_MIN_HEAP` in `lib/mem.h` is a lower bound, not a fixed total heap.
   `___setup_mem` can select a larger cache-derived value. Current `lib/mem.c`
   initializes a processor-count floor plus allocation headroom, and
   `resize_heap` accounts for live data, assigned sections, history and headroom.
   A small initial minimum alone does not establish repeated collection.
   Reuse `heap_floor`, `heap_allocation_headroom` and `gc_postcopy_headroom`;
   measure actual heap/live/free state before proposing a larger minimum.
2. Current `end_heap_chunk` releases the queue lock before taking the scan
   termination mutex and signalling. Current `mark_reachable_from_marked`
   rechecks queues under that mutex before decrement/wait. The older
   [notification proposal](gc-recursive-progress-source-obligations.md) is
   therefore not an unimplemented repair on this producer. Reuse its existing
   controls; do not repeat the same signal/recheck patch as a new hypothesis.

The numeric-host patch's O0 condition applies above 8,000 module labels.
Generated `_eval`, `_thread`, `_kernel` and `_system` in the inspected producer
are below that threshold. This excludes direct application of that condition
to those modules; it does not prove all compiler/profile effects irrelevant.

## Missing Discriminating Observations

Use one exact producer and host-derived topology. Reuse unchanged build stages.
Diagnostics must be declared separately from the unchanged acceptance workload.

| Question | Necessary observation | What would refute the proposed explanation? |
| --- | --- | --- |
| Is interpretation itself slower? | Same original delay definitions, startup measured separately, process CPU and wall time; compare matching old/current producer controls. | Similar delay CPU cost with a large difference only in threaded execution. |
| Are there too many collections? | Actual collection count, allocation, current heap/live values and completed workload, with observer effects disclosed. | Comparable collection frequency per completed work despite much larger elapsed time. |
| Is one collection taking too long? | Per-phase entry/exit and actual population; active copier/producer, waiters and their queue/work state. | Normal phase completion latency with a large cost outside GC. |
| Is GC re-entering without useful mutator advance? | Distinguish physical GC completion from completed TFIB roots or another source-bound mutator witness. | Root/work advance continues at normal throughput between collections. |
| Is this a missed wake or delayed participant? | Same-phase wait predicate, signal/publication order, live participant identity and an actual runnable producer/last consumer. | Every expected publication is received and the delay precedes phase arrival. |

`##process-statistics` in `lib/_kernel.scm` exposes process/GC CPU and wall
times, collection count, and latest heap/live fields. Use the producer's actual
field semantics. Process CPU already includes GC CPU: do not add both as disjoint
costs. Summed waiter times across processors likewise are not elapsed wall time.
A stack sample dominated by `pthread_cond_wait` does not identify the delaying
participant, prove deadlock, or distinguish many collections from slow collections.
Do not extrapolate an unseparated short test's whole wall time linearly.

## Existing Model And Source Obligations

- `sync_wait_handshake.qnt`: protected predicate and atomic wait registration;
  one-shot delivery does not prove repeated-epoch latency or scheduler service.
- `gc_scan_termination.qnt`, `gc_work_closure.qnt` and
  `scan_barrier_quiescence.qnt`: active private work, queued work, phase closure
  and participant lifetime. Bind the observed state to these actual transitions
  before treating a model counterexample as the native failure.
- `gc_queue_wait_composition.qnt`: multiple publishers, sequential queue rechecks
  and activity restoration. Preserve the already passing current/combined policy
  controls; an older unprotected-source assumption must not describe this producer.
- `gsi_child_progress.qnt` and `gc_datagram_witness.qnt`: fresh source-bound
  observation is not mutator attribution or completion. GC-only progress can
  coexist with low useful throughput; it does not earn a native gate.
- `lean/WorkAccounting.lean`: ownership/count conservation needs a complete
  producer census. It does not supply collection frequency, a scheduler latency
  bound or a missing physical source witness.

Only extend the uncovered mechanism after the phase/ownership observations
identify it. A bounded-latency claim needs explicit environmental assumptions;
weak fairness alone supplies no 3600-second completion bound. Do not invent a
latency proof, remove a GC participant, serialize SMP, or widen a watchdog.

## Coordinated Implementation Boundary

First restore the existing configurable host-capacity path and compare costs on
the same producer. Then, if the observations identify GC frequency, review
allocation headroom and heap growth; if they identify phase delay, review the
actual owner/arrival/publication/notification path. A phase-scoped change must
retain private-work accounting, roots, weak phases, resize and failure cleanup.
Keep the C backend, supported continuations, FFI and all requested VM/SMP flags.

An unchanged configuration can reuse applicable bootstrap checkpoints. A changed
runtime source must rebuild affected products and requalify their dependencies;
checkpoint reuse cannot certify a new binary. Only after the original stress,
PR fixtures and complete GC/FFI inventory pass twice on the bound producer may
that gate close. Lifecycle, Gerbil causality and release performance stay separate.

## Task Storage Audit Boundary

The registered repair work item already has one task root. A new observation
does not justify another mutable source/runtime tree beneath a suffixed fixture.
Keep attempt records separate from the maintained build product; a read-only
suite view can reference that product without copying it. Failure retention
does not require retaining every disposable build tree indefinitely.

The original audit found an unrecognized task-owned fixture hierarchy, import
launches omitted from maintained-storage admission, and imported build keys
derived from archive envelopes rather than native products. The coordinated
implementation now rejects complete attempt copies, requires maintained import
storage, and authenticates the original workspace before borrowing it. Source
materialization for that import is a bound projection, not another source tree.
If a different host genuinely lacks the producer workspace, its archived native
generation installs once; a changed existing workspace is not silently replaced.
See `task-workspace-lifecycle.md` for the shared storage and retirement contract.

The correction belongs to the existing work-item/build-product and artifact
contracts, not a new command, task name or hardcoded repair workflow. Retain
configuration isolation where actually required, exclusive mutable ownership,
unchanged historical receipts, and explicit missing-cache observations. Do not
hardlink mutable build products, edit old receipt paths after relocation, or
silently fall back to bootstrap when a reusable producer cannot be validated.
Focused storage tests exercise real leases, unchanged file inodes, envelope-only
changes, source drift, safe retirement and failure preservation. They are not
TFIB correctness, full framework CI, performance qualification or a native gate.
