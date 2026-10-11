# Synchronization Resource Retirement

## Model Before Runtime Changes

This is an incomplete ownership model, not an admitted runtime repair.
The existing collector work-closure and GC membership compositions require
valid processor resources, but do not establish their lifetime. That missing
contract must be modeled before adding resource destruction to Gambit.

The unchanged selected source initializes `sync_mut` and `sync_cv` in
`setup_sync_op_pstate`. `___cleanup_pstate` does not pair those initializations
with destruction. The mocked source-unit fixture executes setup, cleanup and
setup again on the same slot and observes four initializations, zero
destructions and two reinitializations. GNU GCC compiles the extracted,
unchanged function bodies. This establishes a source mechanism only: it is
not a real pthread execution, a reproduced native crash, or a Darwin-only
diagnosis. See `evidence/model-results/sync-resource-source-observation.json`.

`SYNC_SEND_MSG` unlocks before signaling the receiver's condition variable.
A fast-path receiver can consume the published flag before signaling is
finished. Consuming a message, or joining the retiring processor itself,
does not establish that external senders have stopped using its resources.
Simply adding destroy calls is therefore not an admitted repair.

## Existing Bounded Results

`sync_resource_retirement.qnt` currently models one slot, one admitted sender
and two resource generations. Three fault controls produce counterexamples:
retaining resources but reinitializing them, destroying before a late signal,
and reusing resources while a sender retains the old generation.
The drain-before-destroy contract exhausts 13 distinct / 18 generated states,
depth 9, with an empty queue. The four admitted checks are recorded in
`evidence/model-results/sync-resource-retirement.json`; negative traces are
under `models/gambit/counterexamples/`.

Cross-generation signaling is a candidate ownership obligation, not proof
that every such signal corrupts a condition variable. Correct predicate
loops may tolerate spurious wakeups. Keeping resources for the VM lifetime,
initializing each slot only once, is another design to model rather than
discard without analysis.

## Coverage Gate Still Open

The separate [Resource Users And Setup Rollback](sync-resource-users.md)
model extends the single-counter abstraction without changing this model's
recorded bytes. Generation reuse and whole-VM composition remain separate
obligations; a passing extension does not itself admit a source repair.

The current dispose action requires `sender >= 3`. It omits retirement after
publication while the sender still holds the mutex (`sender == 2`). Its
single `users` counter also does not distinguish holders, waiters and late
signalers. The current positive result is therefore insufficient for source
repair admission.

Before runtime edits, extend the model to cover:

- Withdrawal from all future producer admission before draining old users.
- Independent lock holders, condition waiters and delayed signalers.
- Publication followed by fast-path retirement while a sender holds the lock.
- Partial mutex/condition initialization and rollback of owned resources.
- Slot reuse and whole-VM cleanup, including retained-resource alternatives.
- Composition with processor membership changes and external senders.

Use independent negative controls for each obligation. State scheduler,
memory-order and bounded-population assumptions explicitly; finite safety
exploration alone does not prove fairness or termination.

Only after these obligations pass should source correspondence select a
minimal repair and a native regression. Preserve existing forced-GC decode
coverage instead of creating a synonymous test. Keep compiler failures,
runtime failures and budget denials separate. Complete bootstrap, native
suites and Gerbil correctness remain later acceptance gates.
