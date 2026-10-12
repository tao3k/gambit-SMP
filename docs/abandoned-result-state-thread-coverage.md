# Current Artifact Standard Thread Coverage

The exact final two-pass bootstrap artifact now passes another 15 unchanged
upstream standard thread files in both modes. The existing isolated suite
adapter observed gsi 1.564 seconds and gsc 14.472 seconds, each under the
unchanged 60-second whole-mode budget. Three shards each covered five files,
with child processor populations derived from available host capacity.
All source/artifact identities remained stable and child groups were reaped.

Portable receipts and logs are in
`evidence/source-results/fixtures/abandoned-result-state/remaining-thread-native`.
The exact inventory, previous coverage and pending routes are recorded in
`evidence/fixtures/abandoned-result-state/remaining-thread-plan.json`.

| Default standard directory coverage | Files | Status |
| --- | ---: | --- |
| Earlier original synchronization files | 8 | Both modes passed on this artifact |
| New original thread files | 15 | Both modes passed on this artifact |
| Known completion-order fixture failures | 2 | Explicit repaired-fixture review pending |
| Total default upstream thread inventory | 25 | Not complete admission |

The two pending original files are `thread_start.scm` and
`thread_interrupt.scm`, retaining failure IDs `021-thread-start-completion`
and `018-thread-interrupt`. Existing model-bound join/completion-gate patches
preserve the assertions, but those patches are not applied or counted in this
campaign. An unchanged known failed route was not executed merely to fill the
coverage count. The ended-interrupt fixture is a separate regression asset,
not an extra original file in this default directory inventory.

Upstream excludes `*_stress.scm` by default; the planner preserves that rule.
Stress runs remain a separate open gate, not covered by 23/25. Inspection found
the original interrupt stress performs six million requests and termination
stress two million, so reduced samples would not be equivalent complete runs.
No test population or timeout was changed here.

## Admission Boundary

These are actual native diagnostic observations archived by the historical
isolated suite adapter, with the scope058 native ASCENT preflight. They are not
a sealed `gambit.suite` typed-review execution, and neither that preflight nor
the smaller inventory discharges canonical complete-suite failures. The active
closed research kernel must bind the complete candidate/runtime producer,
canonical failures, causal review and original budgets before final acceptance.
No historical CLI result substitutes for that gate. Runtime, release, full
thread suite and performance admission stay false.

Next closure is the model-bound completion fixtures and complete sealed native
suite, then same-artifact Gerbil correctness. Queue/GC/cancellation/retirement
refinement and production performance remain separate requirements. No new
runtime source patch was introduced by this coverage campaign.
