# Collective Resize Heap Guard

## Review Before Repair

The existing repeated still-object reuse test stalls at its second grow. That
observation is retained as DENY, not a unique causal diagnosis. The read-only
heap probe failed its unchanged compiler budget and supplied no native snapshot.

Source review found a separate concrete protocol risk: every old processor
independently tests shared free-section counts before deciding whether to enter
collective GC. P0 can start setup and consume sections before a late peer reads
the condition. These members can then choose different branches. This route
was modeled before implementing a candidate; expected benefit is correctness,
not a package-build speed claim.

## Model and Source Correspondence

`resize_collective_heap_guard.qnt` retains the old nonuniform decision
counterexample (7 distinct states) and exhaustively checks the bounded fixed
contract (68 distinct states, safety and temporal progress). Its two/three-member
populations are verification bounds, not runtime CPU limits. The model assumes
collective GC succeeds once all members participate; it does not implement the
collector or prove C memory ordering.

The candidate uses a private `OP_VM_RESIZE_HEAP_GUARD` with boolean MAX
combination. All old members vote through `barrier_sync_op` while
`processor_count` remains `initial`. Upward messages publish payloads before
release flags; downward messages distribute the common decision before callers
read it. P0 may allocate sections only after that common decision. New members
are created later and are not members of this vote round. `OP_VM_RESIZE` remains
noncombining: its argument is a Scheme thunk, not a boolean.

The guard reuses the existing tree message slots. It precedes optional nested GC
and the existing processor-count and resize-result rounds. Slot retirement,
nested GC barrier composition, allocation failure, and new-member startup are
explicit source obligations, not discharged by the abstract atomic decision or
successful `finishGC` transition. Native reuse testing is required next.

## Reproduction and Admission

Source authority is `vendor/gambit` at the pinned revision plus
`evidence/fixtures/collective-resize-heap-guard/source.lock.json` and its
cumulative overlay. Only `lib/setup.c` differs from the retired-memory transfer
parent. Cache directories are execution outputs, not source references.

Runtime capacity is selected from currently available CPUs. One runtime process
uses that selected population; outer make jobs share the host CPU budget with
single-processor compiler children. No fixed 12-worker configuration is used.

The model is registered for Datalog recovery with its retained counterexample,
source inputs and open obligations. No real-runtime, full bootstrap, upstream
suite, Gerbil, or release admission follows from the model receipt alone.

## Native Result and Feedback

The candidate incrementally rebuilt and relinked with GNU GCC in 39.316
seconds, after checking parent input/artifact hashes and all 14 locked overlay
files. This is not a fresh configuration or full two-pass bootstrap.

| Component | Exit | Seconds | Result |
| --- | --- | --- | --- |
| Original repeated still reuse | -9 | 30.107 | DENY |
| Still survival after shrink | 0 | 0.530 | PASS |
| Mixed-key forced GC | 0 | 0.257 | PASS |
| Reuse with thread-start boundary | -9 | 30.083 | DENY |

Both reuse runs keep the original whole-process budget and end with quiescent
process groups. The changed runtime passes second grow, unlike the parent, but
does not complete the second worker. The diagnostic enters `thread-start!`
without returning. This narrows the stage to enqueue/start rather than join;
processor-lock versus VM wait-queue lock and a unique cause remain unproven.

`resize_scheduler_readiness.qnt` separates result/NOOP completion, Scheme queue
initialization, unlock, resize return and enqueue. The existing processor lock
guards actual insertion, so return-before-ready does not by itself prove queue
loss. The prospective readiness handshake is not implemented. Its source must
avoid new startup/collective deadlocks and respect retired idle-queue ownership.
The old readiness control found a counterexample after 10 distinct states;
the prospective fixed contract checked 8 distinct states with safety/progress.
Both checks completed within the unchanged 90-second per-check budget. These
are finite design checks, not evidence that a physical readiness handshake
exists in the candidate. The published receipt is registered for Datalog
recovery together with five remaining source/native obligations.

Portable evidence preserves the parent compiled RC PASS (0.825 seconds), parent
reuse DENY and heap-probe compile DENY alongside all candidate observations:
`evidence/source-results/fixtures/collective-resize-heap-guard/observation.json`.
These component results are not whole-runtime correctness or speedup admission.
