# Processor interrupt propagation candidate

The source lock is
`7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
Its 26-file cumulative patch is
`8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`.
The canonical submodule revision remains
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.

## Source correspondence

The new Scheme difference is `##thread-intr-propagate!`. Its processor acquire
uses the existing failed-trylock helper, so an unsuccessful attempt does not
reserve another ticket. Collective participation can update the traced Scheme
bindings before publication. The processor object is permanent; the interrupt
vector remains a Scheme binding rather than a saved untraced C pointer.

The running-target branch checks membership and current-thread identity while
holding the processor ticket, splices that processor's queue, releases the
processor and thread tickets, then notifies the target processor id. It does
not call the old reserving C enqueue while already holding its ticket.
The nonrunning-target branch retains the scheduler's local-delivery path.
The exported C enqueue and dequeue retain their acquire/release contract.

The diagnostic observer overlay was mechanically reversed after an exact
reverse-applicability check. Its header fields, ticket recording and report
code are not part of this candidate. Historical observer passes and the
uninstrumented failure are preserved, not transferred to the candidate.

## Qualification scope

The protocol model is `processor_interrupt_ticket.qnt`, digest
`66588609529f42c448217740126d8f5afd75edb12d495bf6bbc132dc2a049999`.
The first six-check campaign passed against its then-bound context. This new
source lock requires a separate source-bound check before native execution.

The relevant native scope is the original four stress files under fixed
processor membership. The model's `member` value is fixed per initializer;
an operation named resize does not model a membership transition. Its
non-member control does not prove arbitrary target removal, id reuse or VM
teardown. Notification after unlocking is also not a general lifetime theorem.
These remain lifecycle/registry obligations, not a reason to claim a whole-VM
repair from the bounded model or stress run.

No actual holder or barrier operation has been identified for the retained
timeout. The `___get_next_high_level_interrupt_pstate` and device-select
reacquire paths remain distinct source obligations. In particular,
`___os_condvar_select` releases its ticket before blocking and reacquires it
afterwards; the Agent's final statement that it blocks while holding the
ticket is rejected by the existing source evidence.

No new native result is asserted by this source review. Native execution must
bind the regenerated candidate, not the historical observer executable, use
the pinned Bazel GNU profile and host-derived parallelism, and retain the
completed-target/completed-file inactivity watchdogs. A single source-core
regeneration is not a repeated two-pass bootstrap or a release admission.
