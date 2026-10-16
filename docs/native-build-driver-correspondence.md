# Build Driver Correspondence For The Compiled Grid

## Observed Difference

The original 023 and 026 atomic receipts and 026 vector-family receipt record
configured `bin/gambuild-C` SHA-256
`f9e3bc752ee38d7ad83d9c84049322029538a445cc431fa37995e09be0514ced`.
The retained original file was checked against that exact digest: its configured
C optimization is `-O1`, RTS optimization `-O3`. The current completed correctness
producer has C and RTS optimization `-O0`; its driver digest is
`41a5b9e739ee0fa40ef76fb533bbf4705f0473d8a7433d1de4cae786555dae4c`.
Both retain GNU macro-tracking suppression. The current driver removes the old
modulo scheduling options. This is an observed configured compiler difference,
not evidence that the registry patch explains C compilation time.

## Typed Review Contract

The existing transport accepts a `build-driver` change only for a current-bound
gsc producer. It requires an originally recorded, verified configured driver,
the exact `bin/gambuild-C` path and before hash, and actual current bytes matching
the after hash. An unrecorded original driver is not reconstructed from guessed
flags, current bytes, an unrelated binary or a model PASS.

Native Scheme DSL permits this change only for a budget failure and requires
an explicit `build-driver-cause-review` in addition to scope, relevance and
assumptions. Assertions, signals and environment denials cannot be waived by a
driver change. Original whole/atomic/group/file caps and complete inventories
remain mandatory. Any authorization is eligibility for an investigation, not
success of the suite or a claim of causal speedup.

`native_build_driver_correspondence.qnt` checks the source-bound, configured,
same-path, changed-driver, same-producer, scope and budget requirements. It keeps
unknown-original, assertion-waiver and expanded-budget negative trajectories.
The sealed native review domain passed 93/93 tests, zero skips/errors, in 51.360
seconds under its original 60-second cap. The initial syntax typo and temporary
directory alias expectation failed in a separate retained domain; fixing these
did not remove any safety assertion or widen a deadline.

## Scope And Reflection

Changing optimization for correctness investigation may alter generated code
and expose or mask bugs. This does not qualify an optimized release or its
performance. All three SMP/multiple-VM switches remain enabled. A complete
optimized source-bound correctness/performance campaign remains mandatory.

These receipts justify a fresh compiled-budget investigation on this explicitly
different driver, with the existing original caps. They do not clear historical
assertion/environment failures inside the same atomic campaign; those require
their own source/fixture or current environment review. Missing driver metadata
in the older compiler-probe and whole-suite histories remains missing, rather
than being silently filled from newer receipts.

The completed bootstrap is consumed through its exact historical policy input
archive after this policy change. No bootstrap is repeated merely to update
review policy, and the old policy review is not promoted to current admission.
