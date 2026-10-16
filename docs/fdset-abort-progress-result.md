# FD-Set Setup Progress Result

## Property And Assumptions

fdset_abort_setup_progress imports the unchanged fdset ownership transition
relation and checks safe together with weak-fair eventual completion. Atomic
allocation/OS actions are assumed to return; exclusive setup/cleanup ownership
and the original drained-user premise remain. This is not an OS hang guarantee,
a real-time bound, arbitrary concurrency or C refinement.

No existing model was rewritten or earlier safety receipt reclassified. The
new wrapper also retains an old-cleanup counterexample. Other independent
controls remain in the previously checked safety Recipe; they were not rerun
as unchanged native failures.

## Verification And Publication

The existing verify interface completed the old-cleanup control in 3.978 seconds
and positive safety plus temporal completion in 3.958 seconds. Positive TLC
exhausted 119 distinct / 139 generated states, queue empty, and explicitly
finished temporal checking. The framework executor completed in 8.168968542
seconds, exit zero, no timeout, parent reaped and process group quiescent.

The existing publisher returned PROTOCOL-EVIDENCE-OK and preserved both model
snapshots, raw-log hashes, portable logs and the decoded counterexample under
`evidence/model-results/fixtures/fdset-abort-owned-rollback/progress/`.

Published receipt SHA-256:
`04a2584ce813a4f1f165018082a193c5bff0ef45b1d2441245a7db7f8cc050be`.
Ownership model SHA-256:
`abcc4e64f877c570bc1a3ff63a4bb4f3a48b3618a56ca91ef73ae1ea1ad21621`.
Progress wrapper SHA-256:
`d6b23b39bcbd0d15b65fc383e6c86951e7e1ac8034320ba614ce6c291d7b9c24`.

Scheduling is host-auto: 12 available CPUs observed, 12 positive TLC workers,
6 control workers and capacity-derived parallel-control limit 2. Only one
control was required in this wrapper. These counts are observations, not CPU
constants in either model.

## Real ASCENT Consumption

The progress contract is registered in the existing protocol bundle registry.
The complete evidence CLI query completed in 4.696373417 seconds under its
10-second ceiling, with DATALOG-COVERAGE-OK, zero exit, no timeout and quiescent
process group. Catalog totals are now 123 protocols, 113 complete checked model
protocols and 10 without complete checks.

fdset_abort_setup_progress is in recorded_protocol_checks and absent from
protocol_extensions_without_checks. The six earlier safety-only registrations
remain separate; this wrapper does not manufacture their missing receipts.
Its three native/refinement assumptions remain in protocol_open_obligations.

Query receipt SHA-256:
`8d82ca084c5a306bbe45f580222de105bfd09409560e16d689d6ede7e29e0506`.
Fact export SHA-256:
`372637d0e4fb911d4ae587198d98cc946087fdd2fcdb2b00e8da8335c311b87b`.

The existing protocol readback binds 11 durable inputs, none under the local
disposable .data tree. A regression forbids opening that tree and still verifies
the published proof. Model-only/native-not-run fields and the separately open
base registration are also checked. Focused regressions: 30/30, 0.065 seconds.
No shared Python framework implementation was changed.

## Budget And Milestone

Earlier fdset safety execution (26.202354916), this follow-up (8.168968542) and
catalog validation (4.696373417) total 39.067696875 seconds, below the original
45-second model campaign. Follow-up caps were 18 seconds for verification and
10 for catalog validation; per-check cap remained 15. No qualification ledger
was reset and no bootstrap was launched.

Cumulative native milestone remains 3/12, not 4/12. The source candidate still
requires bootstrap and all nine open native gates remain open. The original
qualification ledger remains 468.695876834 / 600 seconds. Acceptance here is
bounded model safety and weak-fair completion only; runtime/release admission
remain false.
