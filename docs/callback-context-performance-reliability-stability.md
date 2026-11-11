# High Performance, Reliability And Stability

These are simultaneous design constraints, not interchangeable scores. A fast
incorrect run fails. A correct but globally serialized redesign is not a
performance success. A single passing schedule does not establish stability.

## Model And Native Contracts

| Dimension | Model questions | Native admission |
| --- | --- | --- |
| High performance | Count redundant scans, copy attempts, probes, shared updates, synchronization and wakeups alongside useful work. Identify fast versus exceptional paths and the assumptions behind bounded progress. | Match source/configuration and complete test inventory; measure startup, build and test separately against retained gates. Record CPU allocation, wall time and repeated-run distribution. Abstract operation counts are not elapsed-time predictions. |
| Reliability | Preserve payload/result identity, current roots, phase/processor ownership and explicit error outcomes. Reject premature publication, reclamation and false-success rollback. | Exact-source fault controls, forced GC, migration, join/resize errors and complete bootstrap/tests with all three requested switches. Do not disable a requested feature to obtain green. |
| Stability | Include adversarial ordering, repeated operation, unbounded environment assumptions, lifecycle reuse and failure retention. Distinguish a model counterexample from a host/tool denial. | Repeated same-identity runs, varying supported populations and overlapping work under a shared host-derived CPU budget. Retain every timeout, signal and incomplete teardown. No single-file silence rule or changed timeout can manufacture acceptance. |

QNT can establish bounded protocol properties and produce schedules. It cannot
prove cache-line placement, GNU GCC TLS cost, Mach-O loading time or OS latency.
Those require source/compiler inspection and real observations. The GHC paper's
section3.7 false-sharing discussion specifically warns against deriving speed
from apparent work balance alone; see the pinned [paper notes](papers/ghc-parallel-gc-2008.md).

The executable [joint QNT contract](performance-reliability-stability-model.md)
conjoins work/configuration bounds, root/result/error ownership, repeated
generation safety and fair completion. It includes independent negative
controls for serialization, redundant copying, premature reclamation, false
success, stale reuse, deadlock, disabling SMP and relaxing the budget. This is
a bounded reference design, not yet composition of the whole source GC chain
or proof of native elapsed time.

## Current Callback Repair

The source-shaped return-value loss is addressed by retaining the result as a
Scheme argument while migrating back to the C-frame owner. The normal owner
return branch does not acquire a new global lock or execute a new save/restore.
The cross-processor branch adds one result-register save and a second argument
to its existing helper; that helper returns the retained value after the
unchanged one-argument migration hook. This source-path audit is not a measured
zero-overhead claim. Generated frames/roots and slow-path allocations still
need compiler/runtime inspection.

The [callback audit](callback-return-owned-result.md) records deterministic
baseline failures, model controls, fresh source-core regeneration and repaired
integer/heap-string return controls. They establish a concrete correctness
improvement, not full SMP stability or user-visible build/test acceleration.
Repeated arbitrary callbacks, actual relocation, nesting, hook errors,
processor retirement, full suites and two-pass bootstrap remain open.

## GC Redesign Selection

Compare the [minimal Q/M handshake and generation/ownership hypothesis](gc-design-decision.md)
on the same requirements. Do not fix a race by holding a global mutex through
copying, scanning or allocation. Any added shared counter/epoch needs ownership,
publication order, wraparound, contention and failure rollback analysis. Private
work must still be counted; a notification epoch alone is not termination.

Record a source-backed cost hypothesis before implementation, including where
extra traffic occurs and which repeated work is removed. Measure only after
the relevant correctness chain qualifies. Neither stronger fairness nor a
smaller model domain is a runtime performance or stability improvement.

All CPU concurrency is selected from available host capacity and divided among
simultaneous VM/checker processes. Finite model roles are semantic identities,
not a hardcoded machine thread count. Existing performance gates are retained;
this document neither replaces the baseline nor relaxes a threshold.
