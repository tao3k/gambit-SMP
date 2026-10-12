# Interrupt Prefix Owned Lifecycle Fixture

## Source Identity

Authority is `evidence/fixtures/interrupt-prefix-owned-lifecycle/source.lock.json`:
the pinned Gambit submodule and cumulative overlay, not a cache directory.
Relative to `sync-slot-retained-resources`, only `lib/setup.c` and
`include/gambit.h.in` change. The new ownership bit changes the processor ABI
and requires a coherent rebuild.

The repair retains procedural-interrupt mutexes across processor slot reuse.
Private VM constructor rollback releases its own interrupt prefix; VM setup
preserves the global P0 prefix borrowed from earlier global initialization.
Global cleanup owns that prefix, including the early OS/memory failure path.

## Actual Observations

The portable receipt summary is
`evidence/source-results/fixtures/interrupt-prefix-owned-lifecycle/observation.json`.
It hashes recipes, source locks, overlays, harnesses and sealed execution
receipts without publishing host paths.

| Campaign | Execution Time | Result |
| --- | --- | --- |
| Interrupt helpers | 9.179 s | 40 positive checks; injected parent negative exits 1 |
| VM constructor caller | 15.809 s | 10 threaded + 10 single-threaded checks; parent detects two leaks |
| Full memory/setup objects | 45.753 s | GNU GCC, SMP + multiple VMs + multiple threaded VMs |

These are component campaign times, not runtime performance measurements.
The helper harness projects the actual setup, posting and cleanup functions.
The POSIX variant uses two actual producer threads and joins them before queue
cleanup; the two actors are a protocol bound, not a machine worker limit.
The constructor harness projects the complete actual VM constructor and injects
returning allocator/publication/resource callees. It covers log, OS/memory,
P0 and publication failures, plus success, in private and global contexts.
The negative control uses the locked parent, not a fabricated success path.

Recipe preparation initially retained the previous fixture's declared input
inventory and was rejected before execution (`declared source lock required`).
The inventory was corrected; two subsequent CLI calls mistakenly used a recipe
path rather than its ID and were rejected without launching work. None is an
accepted model counterexample or native failure. No source, assertion or budget
was relaxed to obtain the accepted execution.

## Model and Remaining Requirements

`interrupt_prefix_retained_composition.qnt` already composes actual retained-sync
model transitions with borrowed/private prefix ownership and early global OS
failure. Its existing 208-state receipt remains bound to its original parent
context; the new C observations do not silently change that proof's identity.

This fixture does not prove admission closure or all-user drain before cleanup.
It does not exercise the complete global cleanup caller, live resize, failed
joins, queue payload GC, foreign callback reentry, C weak-memory refinement,
source-regenerated linked runtime, complete bootstrap or Gerbil acceptance.
The corresponding Reflection requirements stay open.

## Next Source-Model Boundary

The same locked `lib/setup.c:___vm_resize_pstate` publishes the smaller processor
count with `OP_SET_PROCESSOR_COUNT` before calling `___thread_join`, whose result
is explicitly ignored. `___cleanup_vmstate` then relies on caller quiescence
before destroying retained resources. The current constructor repair does not
establish that quiescence.

The existing `pstate_retirement_generation.qnt` treats a failed join with retained
resources as a terminal quarantine. That proves only its local no-reclamation
contract, not that the remaining VM can safely run another GC, resize or shutdown.
The next composition must include published population, live retired threads,
admission, and VM cleanup. A local error return or quarantine flag alone is not
a source-grounded implementation of this protocol.

The POSIX `___thread_join` also converts ambient `errno` instead of the returned
join error. The pinned `os_base.c:___err_code_from_errno` maps zero errno to
`___UNKNOWN_ERR`, not success. Therefore an error-identity repair is distinct
from restoring join completion, drain, or safe lifetime ownership; do not claim
that fixing error translation establishes the full retirement contract.
