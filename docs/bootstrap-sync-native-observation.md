# Rebuilt Candidate Synchronization Observation

## Preflight Boundary

The initial eight-file campaign stopped before native execution: its selected
ASCENT provider did not support the current history DSL entry. The observed
exception was `installed ASCENT engine lacks the upstream native DSL entry`.
This is a provider/consumer mismatch, not a Gambit runtime failure. The corrected
campaign used the matching physical components provider snapshot, without
rebuilding the Library or relaxing review and execution budgets.

`evidence/fixtures/sfun-owned-unwind/bootstrap-sync-scope-review.json` binds
the rebuilt candidate, exact original fixtures and three historical aggregate
budget failures. The review does not close those full-suite failures. Known
concrete startup/interrupt failures were not selected or counted as passed.

## Native Result

The same source-lock-bound candidate that completed the two-pass bootstrap
passed eight original synchronization files in both upstream modes:

| Mode | Whole-mode seconds | Files | Budget seconds |
| --- | ---: | ---: | ---: |
| gsi | 1.829 | 8/8 | 60 |
| gsc | 8.206 | 8/8 | 60 |

The files cover mutex creation, lock, unlock, race and timeout, thread join,
thread state and current processor. Host-derived shared capacity selected
three runner shards and three processors per child VM. Every shard passed;
candidate, fixture and driver identities remained stable. SMP and both
multiple-VM flags remain in the bound bootstrap configuration.

The portable archive under
`evidence/source-results/fixtures/sfun-owned-unwind/bootstrap-sync-suite`
retains exact receipts, identity and shard logs. The archive checker confirms
those bytes; it does not re-execute the tests. These are eight-file correctness
observations, not complete threaded-GC, full native-suite, Gerbil, release or
production-performance qualification. All broad admission fields remain false.
