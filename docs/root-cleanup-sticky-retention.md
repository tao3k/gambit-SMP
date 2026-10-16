# Root Cleanup Sticky Retention

## Source Contract

The current locked candidate's `lib/setup.c` records the original join error
and retained cleanup phase before returning. Later checked cleanup and setup
must return that error before destruction or setup parameter overwrite. Root
processor population reduction alone is not a completed join witness.

`models/gambit/root_cleanup_sticky_retention.qnt` models repeated checked calls,
rejected setup and retained pending resources. Error reset and setup overwrite
are distinct unsafe policies. Its finite bound is two repeat calls; successful
checking is not an unbounded API proof or a physical heap/memory-order proof.

The native fixture uses the completed vector-arity producer, its actual cleanup
and setup functions and a checked executable-local POSIX join interposer. It
requires effective injection, exact EINVAL encoding, one pending join, retained
module/PSTATE identity, sticky repeat results and rejected setup. It then exits
its isolated process via `_Exit`: this observes retained failure, not successful
teardown, safe unloading, recovery or leak freedom. Destruction helpers are not
replaced by success stubs.

## Native Failure Completes The Scheduling Premise

The first executable admission check failed with exit 83 before injection.
The diagnostic successor reported exactly:

```text
root admission p0=0 processors=11 setup=1
```

The processor count is an observation from available CPU capacity, not a fixed
configuration. `_thread.scm` defines `##thread-pin!` as a pinned-field update.
Pinning an already executing thread and yielding once is not an observed P0
dispatch witness. Those failed fixtures and original budgets remain retained.

The successor creates a separate retainer thread, pins it to P0 before start,
and still checks actual PSTATE identity on entry. The model now separates pin
metadata from actual dispatch; `initMetadataOnly` must yield a counterexample
if cleanup assumes metadata is sufficient. The positive initializer cannot
begin cleanup without dispatch. Existing error/setup controls are unchanged.

An earlier shared initialization action failed Quint's TLA+ conversion with
QNT409. A pure state constructor fixes that translation boundary without
changing safety predicates. Editing after that failure while the campaign was
finishing produced STALE, which is retained and not called a passing campaign.

## Combined Acceptance Boundary

The dispatched-retainer campaign is DENY in 96.621251 seconds under the original
300-second cap. Root parse/typecheck, positive contract verification, three
unsafe-policy counterexamples and all four trajectories pass. However,
`retirement-safe` reports exit zero and exhaustive completion but
`processGroupQuiescent: null`; its strict teardown requirement is not met.
Both owner and root native steps are BLOCKED, not passing or executed failures.
No unknown teardown state is promoted to green, and no native result is inferred
from the model. Outer receipt SHA-256:
`d71ecd18dcf4a6b29a8ac0445ec834b0f0e537793b7b7de99cc60b77c1843255`.

At that denied revision, the immediate requirement was a framework process-observation contract
that obtains an actual terminal group witness within the original deadline;
permission errors must remain unknown unless a subsequent authoritative probe
proves absence. The native retainer correction was still unverified there; the
successor result below is a separate observation, not a rewrite of that DENY.

## Terminal-Observed Successor

`smp-vector-arity-root-sticky-terminal-observation` adds the required
[process-observation model and framework contract](process-group-terminal-observation.md)
without removing any owner/root checks or changing budgets. All 46 steps pass
in 117.474838 seconds under the original 300-second cap. Inspection is
PASS/CURRENT; runtime and source-refinement admission remain false.

| Native fixture | Compilation seconds | Execution seconds |
| --- | ---: | ---: |
| Owner pending-join recovery | 2.502297 | 0.591922 |
| Root sticky retention | 1.108193 | 0.505505 |

Both native commands exited zero without timeout or stderr under their original
120-second step caps. Every recorded command has an actual `absent` process-group
probe. The bounded permission-error recovery path is covered by focused tests;
this successful campaign does not claim to have reproduced that transient error.
The root fixture's effective injection, two sticky checked calls and setup
rejection assertions are now observed on the actual current runtime. Its explicit
process exit still does not establish successful cleanup or leak freedom.

Outer receipt SHA-256:
`0c262857c8a6abe6fc2f30c7b2e78736107566d089dd6a0396196ba2e0d64d17`.
Child receipt SHA-256:
`53a4b81c9719bb1b1febce3375d0655bc3dbbde8d176bef3c4c5112b80ef104e`.
Engine:
`5b21e52dd89061d16338cee80d164a92548fc72765b58859ce7949063892e0d4`.
Earlier translation, native admission and unknown-teardown failures remain
retained. Full lifecycle acceptance is still open, not promoted by this result.

The declared `smp-vector-arity-root-sticky-and-owner-recovery` recipe retains
all preceding owner-recovery model/native steps and adds the root checks. Its
whole budget remains 300 seconds and each native step remains 120 seconds.
The existing sealed Python framework and native ASCENT provider are reused;
there is no new bootstrap or alternative evidence engine. A failed model or
native predicate blocks the exact-step ASCENT verdict.

Source/recipe: [model](../models/gambit/root_cleanup_sticky_retention.qnt),
[native fixture](../models/gambit/native/root_cleanup_sticky_retention.scm),
[combined recipe](../evidence/research/vm-registry-reader-lease/vector-arity-root-sticky.recipe.json).
Remaining scope: host embedding quiescence, legacy fatal callback, arbitrary
host concurrency, constructor rollback, direct ownership and API reentry,
GC/FFI, full compiled/stress suites and release performance. No claim of full
lifecycle or SMP admission follows from this bounded retention test.
