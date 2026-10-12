# Scheduler Retry Sync Participation

## Model-First Decision

Earlier repairs serviced sync only when thread or processor lock acquisition
was contended. A failed run-queue-head trylock followed by an uncontended
processor reacquisition can cycle indefinitely without taking those slow paths.
The preceding compiled aggregate timeout was sampled, then a distinct controlled
queued-head fixture reproduced this actual scheduler retry. Source and native
evidence motivated the standalone scheduler-retry QNT contract before editing.
Its old serviceability counterexample and fixed safety/fair-completion checks
passed. No arbitrary scheduler/GC composition is inferred.

The candidate polls only the sync flag after releasing the processor lock on
that failed-head branch, before restarting scheduling. It invokes no ordinary
interrupt callback and does not carry the old queue-head decision through GC.
All changes are within the SMP branch; non-SMP code remains untouched.
No Darwin-specific speedup factor is claimed for this correctness repair.

## Source And Native Observations

The pinned submodule plus the cumulative eighteen-file source lock reproduce
independently. GNU GCC core source regeneration passed in 114.017 seconds after
4.434 seconds of bootclean, within the existing180-second operation budget.
Capacity is selected from the actual host, not a fixed processor count.

On this exact regenerated local binary:

| Selection | Actual executions | Result |
| --- | --- | --- |
| Controlled scheduler retry / GC | 3 | PASS, 0.517 / 0.019 / 0.014s |
| Controlled current processor / GC | 3 | PASS, 0.481 / 0.019 / 0.017s |
| Controlled thread / processor / GC | 3 | PASS, 0.501 / 0.012 / 0.011s |
| Original compiled state / migration / GC | 3 | PASS, 0.785 / 0.119 / 0.068s |
| Original compiled strict migration / interrupts | 3 | PASS, 0.561 / 0.024 / 0.028s |
| Original compiled resize / GC lifecycle | 3 | PASS, 0.622 / 0.072 / 0.070s |
| Atomic-observer interpreted state / migration / GC | 3 | PASS, 0.615 / 0.041 / 0.037s |
| Original interpreted resize / GC lifecycle | 3 | PASS, 0.047 / 0.046 / 0.078s |

These are24 completed native observations, not a complete upstream suite.
All use the exact candidate identity and the original30-second process caps;
compilation uses60 seconds. Fail-fast groups not executed in an earlier attempt
are not reported as skipped passes. Controlled role pins do not extend to the
aggregate acceptance fixtures.

## Interpreted Observation Failure Is Preserved

The first original interpreted aggregate run failed in0.507 seconds, exit70:
`migration changed target 8 27 11 9`. This result is retained unchanged.
It does not establish mis-migration: `vendor/gambit/doc/gambit.txi` explicitly
states that the interpreter ignores compiler declarations. Therefore the
fixture's `(declare (not interrupts-enabled))` does not make an interpreted
post-return processor-ID read atomic.

The new `migration_return_observation.qnt` models the omitted scheduling window:
a thread can return on the correct destination and be rescheduled before a
non-atomic observation. The expected old observation counterexample has six
states; the compiled-atomic abstraction has four and satisfies safety/fair
completion. Existing migration resume-gate model bytes and receipts are not
rewritten or claimed to cover this extension.

For interpreted schedule coverage, the separately named
`thread_state_gc_lock_paths_atomic_observer.scm` loads
`migration_observe_atomic.scm` compiled as a dynamic module by the exact tested
GNU/Gambit runtime. `GAMBIT_SMP_ATOMIC_OBSERVER` supplies its execution path;
the helper source and artifact hashes are bound by the observation receipt.
The worker, query, forced-GC, payload, target-ID and exception assertions remain
unchanged. No aggregate pin, assertion removal or timeout relaxation is used.
The old failed fixture is neither overwritten nor relabeled as passing.

## Fresh Producer Reproduction

The host-temp-authorized sealed source-core Recipe passed all five steps in
156.576 seconds total (original420-second cap). Seed compilation took13.118
seconds; bootclean2.503; full source regeneration95.872. The actual sealed
readback returned `PASS` / `CURRENT` before and after the new native observations.
The exact source lock is
`ed741962e364a887f415ee312d2daae79649c897bf6f8d4d137ae9c6f54f583a`.

That independently constructed new binary completed24 native executions and
seven compilation operations, with zero skips. The original compiled aggregate
passed in0.550 / 0.035 / 0.035 seconds; strict compiled interrupts in
0.544 / 0.014 / 0.014; compiled lifecycle in0.573 / 0.042 / 0.048.
The corrected interpreted aggregate passed in0.924 / 0.037 / 0.038;
interpreted lifecycle in0.058 / 0.049 / 0.048. Three controlled wait fixtures
each passed three executions too. These results are separately bound to the
new producer identity; none were transferred from the earlier local binary.

The one-off console summary initially counted only six interpreted executions
because its substring filter also excluded `compiled` stages. Exact receipt
classification by the `-compile` suffix confirms24 native passes and seven
successful compilations. No test was rerun or receipt rewritten to correct
that display counter.

## Shared GC Cohort Composition

The three canonical wait models are now composed using the existing resolved-IR
projection tool. Source bindings are renamed, not rewritten; each projection
contract verifies its source, template and generated bytes. One shared cohort
and atomic collection completion coordinate all three protocols for two epochs.
The five role placements are finite model bounds, not native CPU limits.

Each missing-participation control produces its expected counterexample
(3 / 2 / 15 distinct states). The fixed composition exhausts 122 distinct
states, passing safety and fair completion. This assumes stable roots, a
successful collector, participation by other processors and weak fairness.
It does not prove physical roots, memory ordering, error unwinding, retirement
or arbitrary cohort cardinality.

Direct module aliases failed because Quint effect checking conflates the three
canonical variables named `s`. A shared initializer helper subsequently failed
conversion as both an init and a step. Both construction failures are retained;
the accepted projection uses distinct state bindings and explicit initializers.
The canonical component models and old receipts remain unchanged.

The new compiled `gc_wait_cohort_composition.scm` exercises all three production
wait paths across two forced-GC epochs on the independently built producer.
Its three executions passed in 0.686 / 0.010 / 0.010 seconds, with the original
30-second caps and host-selected processor count. Compilation passed in 0.898
seconds under its original 60-second cap. Producer identity checks passed
before and after. These remain diagnostic observations, not sealed full-suite
admission. Portable results are in the `shared-cohort` evidence subdirectory.

An earlier compile failed during linking with unresolved system symbols.
The diagnostic command had omitted the framework's existing GNU environment
sanitizer. The failed receipt is preserved; the successful command uses
`gnu_compiler` and `gnu_build_driver` without changing assertions or budgets.

The source-correspondence audit also exposed an obsolete source-unit executor
binding. The original eight source-fragment checks were actually rerun with
the unchanged source lock and current executor. The new semantic receipt is
`evidence/source-results/fixtures/sync-retirement-lock-binding/receipt.json`;
the old receipt remains untouched. Source correspondence now validates 14
bound inputs locally. This is not complete graph export or native GC proof.

## Evidence And Remaining Gates

The subsequent [moving-root audit](scheduler-lock-moving-root.md) distinguishes
actual thread-object relocation from an assumed collector transition, preserves
a held-lock observer timeout, and records the remaining collective-error path.

Portable records are under
`evidence/source-results/fixtures/scheduler-retry-sync-participation/`.
The source-core Recipe performs fresh materialization, GNU configuration,
seed build, full regeneration and native rule terminal under the existing
420-second total budget. Local observations cannot qualify its new binary.

The first sandboxed Recipe attempt was denied before configure: m4 could not
create its required temporary diversion in `/var/tmp`. That environment denial
is preserved. The separately authorized host-temp attempt uses the same sealed
engine, recipe, source and budgets; it is not an unchanged denied source retry.

Publishing the observation model initially exposed a missing context snapshot:
the older QNT context file was hash-bound but not copied by the runner. The exact
matching context bytes were copied for evidence publication. This file is not
an imported transition system or additional executed/composed proof; the
manifest retains `composes: []`. No checker receipt or original log was altered.

Complete native suites, physical moving-root/source refinement, synchronous
error unwinding, other retry and mutex/condvar/timeout/VM paths, retirement/drain
composition, two-pass bootstrap and Gerbil acceptance remain open. This is a
promising local candidate, not complete SMP, runtime or release green.
