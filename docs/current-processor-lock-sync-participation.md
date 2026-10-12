# Current Processor Lock Sync Participation

## Reviewed Scope

The parent thread-wait repair exposed an unhandled production `thread-yield!`
processor acquisition. The distinct controlled native case timed out with a
yield waiter and peer GC sync waits. The current-processor QNT contract passed
its expected negative control and fixed safety/fair-completion checks before
this candidate changed the SMP processor-lock macro. Its uncontended trylock
stays inline and its slow path uses the existing sync-only helper.
Non-SMP code and queue mutations are unchanged. No speedup factor is claimed.

The eighteen input files reproduce independently from the pinned submodule
and cumulative `source.lock.json`; caches are not source authority.

## Native Denial

GNU source-core regeneration passed in 94.025 seconds after 1.725 seconds of
bootclean. The current-processor controlled case passed three times in
0.461, 0.011 and 0.011 seconds; the earlier thread/processor controlled case
also passed three times in 0.463, 0.011 and 0.011 seconds.

The unchanged original state/migration/GC fixture passed all three interpreted
observations in 0.520, 0.037 and 0.035 seconds. Its compiled form compiled in
1.152 seconds, but its first execution timed out at the original 30-second
cap (30.004 observed seconds, exit -9). The process group was quiescent.
Remaining compiled repetitions, strict interrupts and lifecycle groups were
**not run**, not passed or silently skipped. This candidate is **DENY**.

## Model Feedback From The Actual Failing Process

A sample of that compiled process shows peer `___sync_wait` and a processor
cycling through the production scheduler. The sampling unwinder includes
unreliable repeated frames, so frame repetitions are not recursion proof.
Disassembly maps the prominent +3744 scheduler PC to a call-return epilogue,
not to a single ticket-lock instruction. It does not establish exact ownership.

Source inspection supplies a narrower protocol fact: when run-queue head
trylock fails, `##thread-schedule-with-acquired-processor!` releases its lock
and tail-retries `##thread-schedule!` without servicing pending sync. Its own
processor acquisition may remain uncontended forever, so slow-path polling
alone cannot guarantee GC participation.

The distinct `scheduler_retry_gc_wait_cycle.scm` control queues a pinned thread
behind a running scheduler thread, then holds the queued thread's lock across
GC. This forces the actual scheduling retry path. Compilation passed in
0.921 seconds; execution reached the GC-request trace and timed out at
30.004 seconds. Same-run sampling shows scheduler retry and peer sync waits.
This confirms the controlled schedule, not exclusive aggregate causation.

`scheduler_retry_gc_participation.qnt` adds the retry boundary explicitly.
Its two-state expected old serviceability counterexample and six-state fixed
safety/fair-completion design passed. The repair design requires participation
only after releasing the processor lock, then a fresh queue lookup. It is a
standalone model, not a composed GC or arbitrary scheduler proof.

## Boundaries

Durable portable observations are under
`evidence/source-results/fixtures/current-processor-lock-sync-participation/`.
The next candidate adds only sync polling at the failed-head unlocked retry
boundary. No ordinary callbacks are dispatched. Moving queue roots, synchronous
error unwinding, other unbounded retries and mutex/condvar/timeout/VM locks,
retirement/drain/epoch composition, complete native suites, two-pass bootstrap
and Gerbil correctness remain open. No runtime or release admission.
