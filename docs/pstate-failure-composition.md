# Processor Setup And Outer Failure Composition

## Route Review

The initialization-error path is source-backed, but it is not new:
`pstate_setup_transaction.qnt` already covers all five initialization stages,
borrowed interrupt ownership and ordered rollback. Its isolated candidate
patch and source fixtures are retained. A simplified sync-only transaction
draft was checked locally, then excluded from the versioned model set because
it repeated that work and omitted borrowed ownership. Do not rerun that draft
as a new correctness or performance improvement.

The unresolved interface is worth checking: the existing
`pstate_vm_failure_handoff` model assumes that failed processor setup has
self-unwound. The current constructor publishes processor count 1 before P0
readiness; global cleanup then uses that count as permission to clean P0.
Setting count 0 alone skips outer resources. Neither behavior is fixed in
source031. The expected benefit is reliable failure recovery, not a measured
startup or GC speedup.

## Composition And Evidence

`pstate_failure_composition.qnt` imports the existing processor setup actions
without changing them. It connects their actual success/failure terminal state
to VM construction, count publication and outer global cleanup. The new generic
protocol manifest binds the imported model hash and selects `composedStep`;
the shared verifier snapshots declared imports and rejects step mismatches
when reusing a receipt.

All three independent controls produced counterexamples: cleaning an already
unwound P0, a VM-only correction which leaks outer resources, and count-zero
early return after VM helper failure. The fixed contract exhausted 125 distinct
states (143 generated, zero queued), passed safety and completed temporal
progress checking in 4.266 seconds. Control checks took 4.426, 4.431 and 4.044
seconds, under unchanged 30-second caps with host-derived concurrency.
Portable receipts, logs and traces are in
`evidence/model-results/pstate-failure-composition/`.

The initial draft was rejected by the parser for an imported initializer name
collision, then by typechecking for a heterogeneous fairness set. The final
model uses its own initializer and a joint `(s, o)` state tuple. These were
model wiring errors, not Gambit failures or successful source repairs.

The contract assumes a fresh exclusive slot, initially owned outer resources,
successful destructors and quiescent setup. It excludes live-slot reuse,
partial VM-helper allocation, C memory refinement and native ABI behavior.
No source patch has been promoted. Resource retirement, native fault injection,
bootstrap and Gerbil acceptance remain required before complete SMP green.
