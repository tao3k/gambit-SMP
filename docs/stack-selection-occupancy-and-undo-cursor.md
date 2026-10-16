# Stack Selection Occupancy And Undo Cursor

## Native Observations

The active source remains `darwin-stack-selection-origin-baseline`. Reuse the
same core; do not inherit the rejected pool-link or section-owned undo layout.
The host supplies available CPU capacity and the framework separately supplies
its actual VM processor allocation. These quantities need not be equal: this
host has 12 available CPUs and the existing policy assigns 11 processors plus
one driver. The fixture checks the actual processor count against that allocation.

The first atomic attempt failed its erroneous capacity-equality assertion before
TFIB ran. Keep that DENY as fixture history, not as a native allocator failure.
The corrected runs preserve upstream depth 15, delay 6000, recursive thread
creation and joins, and assert every result is 987:

| Root population | Native execution | Outcome |
| --- | --- | --- |
| 1 root per available CPU: 12 | 2.676818 seconds | PASS |
| 8 roots per available CPU: 96 | 27.093713 seconds | PASS |
| 32 roots per available CPU: 384 | 94.144447 seconds | PASS |

These are atomic occupancy contrasts, not the unchanged 5,000-root workload.
The full-workload timeout and unsuccessful sampler remain retained. Neither a
timeout nor these small passes establishes a deadlock, a corrupting writer,
an accepted repair, or full stress completion. Do not extrapolate their times
into a claimed full-workload result.

## Full Workload Completion Watchdog

The existing Python framework now accepts an exact `completedUnits` contract.
Only newline-terminated, consecutive, result-bearing records renew the original
inactivity window. The complete inventory, exit status, final output, source and
executable identity must still match. Heartbeats, wrong totals, incorrect
results, duplicate records and a final marker without all units do not pass.
This is not a performance-gate waiver or native correctness admission.

The full ordered-join observation timed out after 304.821746 native seconds,
with only one observed completion. That means the next ordered join did not
finish, not that all other root tasks stopped. Its portable historical record
is `ordered-join-progress-observation.json` in the source fixture evidence.

The successor observes completion inside each root after it returns 987. A
public mutex serializes only the completion record; TFIB recursion, child
creation, joins, allocation and GC remain concurrent. It keeps all 5,000 roots,
depth 15, delay 6000 and the same host-selected processor population. It is an
instrumented full-workload observation, not an unchanged upstream suite. Its
terminal result must be recorded before claiming full completion.

The worker-completion successor is now terminal TIMEOUT: 503/5,000 roots have
checked results, followed by an original 299.995435-second no-root-completion
window. Native execution took 1,073.300641 seconds; the process was killed and
its group was reaped/quiescent. The record and exact portable completion log
are `worker-completion-progress-observation.json` and
`worker-completion-progress.stdout.log` in the source fixture evidence.
This is not a total-wall timeout. It also does not establish that internal
thread or GC work stopped; slow internal work, starvation and deadlock remain
unseparated. There was no stack-section selection diagnostic in stderr.

`native-progress-model-feedback.json` binds this new failure class to the
existing completion-watchdog model and identifies the allocator model's finite
prefix limitation. Do not import this timeout as another illegal-section
counterexample or repeat an unchanged full native run. The next source/model
requirement is internal work and root-dependency liveness correspondence.

## Composed Model

`stack_allocator_undo_cursor.qnt` imports the existing allocator ownership model
and executes its actual `undo` transition. Under the explicit assumption that
the relevant break cursor advances while undo remains eligible, restoring a
fixed snapshot violates cursor correspondence. The negative control has three
distinct states; restoration from the live cursor passes all three states.
The sealed framework and ASCENT accept both checks in 24.703017 seconds.

This is a conditional source-audit envelope, not an established native path.
`handler_break` attempts undo before copying a caller frame. Thread save and
continuation capture invalidate undo eligibility. A nested break's NEXT update
must not be confused with an update to the first break's NEXT. Before changing
the runtime, establish that the modeled cursor advance affects the eligible
first-break record, rather than an unrelated or already invalidated record.
The failed section-owned candidate saves `stack_previous_fp`; this deserves
the correspondence audit, but the model does not prove it caused its crash.

## Open Requirements

- Bind the actual first-break cursor advance and eligibility together.
- Bind selected raw section, selection origin, allocation lifetime and native PID.
- All unchanged interpreted and compiled stress files must pass.
- Registry, lifecycle fault, GC/FFI, Gerbil correctness and release performance
  gates remain open. Overall milestone remains 5/12.

Reproduction uses the existing research recipes and sealed engine. Source
revision, source locks, model files and portable observation hashes are kept in
Git; cached executables and run directories are not evidence identities.
