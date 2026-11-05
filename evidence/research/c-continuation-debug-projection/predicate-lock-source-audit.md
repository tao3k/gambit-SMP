# Predicate-Lock GC Participation Audit

## Identity And Observation

This audit concerns source lock
`evidence/fixtures/darwin-stack-debug-projection/source.lock.json`
(`7e59221a1e7497dcf0222e1bf4d10e2a3f2ae7f8235baba8a8b7741b8b3020a8`).
Reconstruct it from the pinned `vendor/gambit` revision and
`patches/fixtures/darwin-stack-debug-projection.patch`; an execution cache is
not the source of authority.

`complete-gsi-observation.json` retains 369 completed files, a pipe timeout
and ten unexecuted files. Its runner has one processor; its fixture children
inherit three through `GAMBOPT`, confirmed by the population probe.
`pipe-progress-observation.json` retains a separate eleven-processor public
diagnostic with at least 1000 checked echoes, followed by no further recorded
chunk before timeout. Neither receipt identifies the stalled instruction.

## Source Gap

- In `lib/_thread#.scm`, `macro-lock-mutex!` and `macro-lock-condvar!`
  expand to raw `macro-lock-btq!`, hence `##primitive-lock!`.
- In `include/gambit.h.in`, `___PRIMITIVELOCK` uses `___PRIMLOCK`, then
  `___TICKETLOCK_LOCK2`. This primitive wait does not invoke the Scheme
  collective-sync helper.
- Thread and processor waits instead retain an uncontended trylock path
  and call `##lock-scheduler-object-with-sync-participation!` on contention.
  That helper retries from a Scheme-rooted object and services only a
  pending `___INTR_SYNC_OP`, not ordinary callbacks.
- `lib/_io#.scm` maps port locking to Scheme mutex locking. The pipe
  constructors in `lib/_io.scm` share a predicate mutex; pipe waits in
  `##mutex-signal-and-condvar-wait!` also acquire a low-level condition-variable
  lock. Stack-only checks can reach collective GC in interrupt-disabled code.

A possible cycle is an owner retaining a predicate lock while awaiting
collective GC, and a peer spinning for that lock without acknowledging the
collective. Existing thread/processor wait repairs do not cover this class.
This is a source-supported hypothesis, not attribution of either timeout.

## Repair Obligations

Related retained models are
`models/gambit/thread_processor_lock_gc_cycle.qnt`,
`models/gambit/current_processor_gc_wait.qnt`, and
`models/gambit/scheduler_lock_moving_root.qnt`. They cover earlier lock
participants and root obligations, not this predicate-lock composition.
The existing isolated-model interface is
`.venv/bin/gambit-smp verify --help`; a new protocol manifest can select only
the new model and its counterexample without running native or old failed routes.

A candidate can reuse the existing trylock/sync-only helper for the two
predicate-lock classes. It must preserve mutual exclusion, single evaluation
of the object expression, moving-root recovery, and the uncontended path.
It must not dispatch ordinary callbacks under held scheduler locks.
Replacing a ticketed wait with retry does not establish starvation freedom:
any finite model must state its scheduling and finite-contender assumptions.
VM, timeout-queue and thread-group lock classes are outside this candidate,
not silently covered by the two-macro change.

No source change, bootstrap, original stress pass, first-header-writer finding
or native admission is established by this audit. Current-source qualification
and the cumulative 6/12 milestone ledger remain distinct.
