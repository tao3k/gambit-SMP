# Thread Start Fixture Completion

Runtime021's six-thread campaign passes all six interpreted files in 23.104 s,
but compiled execution fails `thread_start.scm` with `var=0` (5/6 files,
75.056 s). This is an assertion failure, not a budget denial.

The original fixture starts a worker that performs 200 work iterations before
writing `var=1`; main performs 400 iterations and then asserts the value.
Relative work counts do not synchronize independently scheduled SMP threads.
This source observation alone does not prove a scheduler defect or PR988 bug.

`thread_start_completion.qnt` freezes a main-finishes-first counterexample.
Explicit join before the assertion exhausts 11 distinct / 16 generated states
with zero queued. The model assumes correct join/completion visibility; it
does not prove those runtime semantics or unbounded scheduling fairness.

`test-thread-start-join.patch` adds exactly `(thread-join! t2)` after the existing
main work. It deletes no lines and preserves every original exception and value
assertion. The framework unit test checks that exact addition-only boundary.
Native interpretation and compilation must still accept the derived fixture;
model success alone is not native admission.

The repeated same-six-file campaign on the same runtime021 now passes both
modes: interpreter 20.856 s and compiled execution 67.780 s, within the unchanged
120-second per-mode budget. The receipt binds both test-only patches, all
original/derived source hashes and actual runtime artifacts. This is six-file
correctness evidence, not a full-suite or performance improvement claim.
