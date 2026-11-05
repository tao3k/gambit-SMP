# Current shared-registry lifetime correspondence

## Source authority

The selected source is the collective-wait lock
`7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`, with
cumulative overlay
`8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`.
The source lock and pinned vendor revision, not a cache pathname, determine
the source. Older registry candidates and their receipts remain historical.

## Implemented protocol, not another proposed repair

| Current source function | Existing obligation |
| --- | --- |
| `lib/setup.c:vm_registry_enter` | Reader count and admission flags share one atomic CAS word; refuse closed, terminal or saturated admission before capturing registry pointers. |
| `vm_registry_leave`, `vm_registry_flush` | Last release and post-record publication both recheck pending bits; replay acquires a fresh reader lease and releases without recursive flush calls. |
| `___vm_registry_close` | Close admission before draining all captured readers; signal readers never acquire the writer mutex. |
| `barrier_sync_op:OP_SET_PROCESSOR_COUNT` | After old-cohort arrival, every changed count uses writer ownership and close/drain publication; unchanged counts do not write. Prepared slots precede growth publication. |
| `___cleanup_owned_vmstate` and locked cleanup | Join direct users, then close/drain registry readers before resource cleanup/unlink; do not free a VM merely because another VM completed. |
| `vm_registry_seal`, `___vm_registry_open` | Terminal shutdown cannot be reopened by an ordinary writer; exclusive global lifecycle ownership remains required. |

These repairs are already in this candidate. Reapplying a historical missing
lease or shrink-only publication patch is not a new repair and risks regressing
the accumulated source. Direct external PSTATE users still require their
documented ownership and join discipline. No global execution or GC lock is
introduced here.

## Model correspondence and assumptions

Reuse the existing models rather than copying them into another state machine:

- `vm_registry_repeated_retirement`: repeated generations, admission and replay
  ownership. A bypassed replay is not protected just because a writer reopened.
- `vm_registry_processor_retirement`: join, lease drain, resource destruction
  and unlink ordering. Old early cleanup has a retained counterexample.
- `vm_registry_population_publication`: grow/shrink/no-op count access ordering
  and prepared resources. Volatile access alone is not synchronization.
- `vm_registry_cross_vm_progress`: two independent writers, repeated cycles,
  exclusion, deferred replay and conditional temporal progress.
- `registry_capacity_writer_replay`: bounded saturation, release replay and a
  late pending-bit publication even when no future writer rescues delivery.

The finite components are not a whole C refinement or semantic composition
proof. SC atomic semantics, old barrier completion, externally joined direct
users and successful OS joins are explicit assumptions. An unbounded signal
storm, arbitrary global reinitialization, failed joins and full GC/FFI coverage
must not be silently admitted by finite progress. Model and native observations
are recorded separately from this source review.

## Native acceptance scope

The existing `registry_topology_grid.scm` derives its VM populations and
processor allocation from available host capacity. It exercises concurrent
independent owners, grow/join/shrink, rooted values across forced GC, overlapping
global interrupts, owned cleanup and later populations. It does not implement
fault injection, prove physical memory ordering or measure release P55/P99.

The original native campaign exposes a verified consumable source/configure/
seed/core prefix even though a later original suite failed. Reuse is checked
per stage; the failed aggregate remains failed. This permits the registry
continuation without repeating bootstrap. Neither this audit nor a CHECKED
report receipt closes the registry native gate.
