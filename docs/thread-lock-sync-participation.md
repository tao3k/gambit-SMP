# Thread Lock Sync Participation

## Decision Before Source Changes

The earlier processor-only repair passed its core build but failed the original
parallel migration/state/GC fixture. A new controlled source-protocol fixture
confirmed the model's missing thread-lock participant. This is a correctness
repair, not a claimed performance multiplier. Non-SMP behavior is unchanged.
The prior denied source is retained and never relabeled as passing.

The candidate gives the SMP thread-lock macro an inline uncontended trylock and
a contended sync-only helper. The shared helper does not dispatch ordinary
callbacks. Generated C stores the lock-object argument and return continuation
on the Scheme stack before calling `##sync-op-interrupt!`, then reloads them.
That is an inspected source obligation, not a whole moving-root proof.

## Actual Results

GNU GCC source-core regeneration passed in 87.158 seconds after 1.680 seconds
of bootclean. Adaptive make capacity and compiler-child sharing were used;
all three concurrency configure flags remain enabled. This is a local candidate
observation, not a fresh sealed producer or two-pass bootstrap.

The unchanged compiled controlled thread/processor/GC fixture passed three
times: 0.468, 0.016 and 0.011 seconds, after a 1.942-second compilation.
The unchanged original aggregate interpreted fixture still timed out at
30.004 seconds, exit -9, with no output and a quiescent process group.
**DENY:** remaining interpreted repetitions, compiled aggregate runs,
strict-interrupt and lifecycle groups were not run. They are not skipped
passes. The earlier retained source is not replaced.

## Model-to-Source Coverage Gap

The seven explicit processor-lock replacements did not cover
`macro-lock-current-processor!`, which expands through `macro-lock-processor!`
to raw `macro-lock-btq!`. Production `thread-yield!`, sleep and scheduler paths
still encounter that acquisition. Fixing thread waits alone cannot cover it.

The distinct `current_processor_gc_wait_cycle.scm` control exercises actual
`thread-yield!` while another processor holds its target lock across a forced
GC request. Compilation passed in 0.851 seconds; execution timed out at
30.004 seconds. Its live sample shows the internal yield wait and peer
`___sync_wait`. This diagnostic is not proof of exclusive aggregate causation.

`current_processor_gc_wait.qnt` captures this missed participant. Its expected
old progress counterexample has two states; the fixed safety/fair-completion
design has six. Both checks passed their expected outcomes within the original
90-second budget. It is standalone, not composed GC or retirement proof.

## Reproduction And Boundaries

Use the pinned `vendor/gambit` revision and cumulative patch from
`evidence/fixtures/thread-lock-sync-participation/source.lock.json`. The eighteen
locked inputs reconstruct independently; execution caches are not authority.
Portable observations and exact candidate identity are under
`evidence/source-results/fixtures/thread-lock-sync-participation/`.

The next candidate changes only the SMP processor-lock macro's contended
path, preserving its inline fast path. Remaining mutex/condvar/timeout/VM lock
waits, synchronous error unwinding, arbitrary moving-root refinement,
resize/drain/epoch composition, complete native suites, two-pass bootstrap and
Gerbil acceptance remain open. No complete runtime or release admission.
