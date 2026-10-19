# Predicate Lock GC Participation

## Source Identity

The canonical candidate is `evidence/fixtures/pipe-predicate-sync-participation/source.lock.json`
(`405d1b9db14bb7d8084db3c1e283ace0ab52bda890fb19a218d33dfe8b10df37`).
Its cumulative overlay applies to the pinned `vendor/gambit` revision; the
minimal two-macro delta is `patches/fixtures/pipe-predicate-sync-participation.patch`.
The materialized cache location is not the source authority.

Both macros evaluate the argument once, retain the uncontended trylock and
delegate contention to the existing scheduler-object collective-participation
helper. They are inside the existing `enable-smp` conditional; the non-SMP
implementation and unlock operations are unchanged. The parent raw-wait source
audit and all failed native observations remain historical evidence.

## Generated Root Witness

The completed two-pass bootstrap generated `lib/_thread.c` with SHA-256
`fe1612663c63c9869d24fe0fa020bdc23d9a06f0acd3b56fd3ead45291b70c83`.
In the procedure `##lock-scheduler-object-with-sync-participation!`, the generated
code stores the object register with `___SET_STK(2,___R1)` before calling
`##sync-op-interrupt!`; return label 1 reloads it with
`___SET_R1(___STK(-6))` before retrying `___PRIMITIVETRYLOCK`.
This corrects the earlier review's absence of a generated helper witness.
It is not a proof of the moving collector's root scanner or of every caller.
Generated C remains a reproducible build artifact, not a second tracked source.

## Review Boundaries

Grok's static review identified the loss of the old FIFO ticket-wait policy.
The reused CAS helper permits barging. Neither finite model proves starvation
freedom with unbounded arrivals. This is a remaining reliability/performance
obligation, not something a successful stress run can discharge universally.

`##thread-lock-remove-btq-toq!` uses a separate reverse-order protocol: it releases
the thread lock before retrying a failed predicate trylock. The new macros do
not change that branch. A claim that another caller violates this lock order
requires an actual held-lock chain; the comment alone is not such a witness.
Grok's completed follow-up traced the patched mutex/condvar acquires before
nested thread/processor tickets; thread join drops its thread ticket first,
and device checking drops its current-processor ticket before the condvar
path. It found no concrete second-ticket cycle at these sites. This is bounded
source auditing, not an assertion about every future macro expansion.
The helper already services collective requests while some thread locks may
be held, so changing its callers requires a composition audit.

`service_sync_op` participates in `execute_sync_op_loop`; the winning operation
can be GC, VM resize, startup-ready, FD-set resize or activity-log work, not only
NOOP. The selected operation and error-unwind paths must be considered separately
from ordinary Scheme interrupt callbacks. Nested-lock/resize/error-unwind
closure remains open; neither current finite model includes the complete graph.

## Model And Native Evidence

`model-observation.json` records the original finite owner/contender controls.
`retry-rooting-observation.json` records the stronger explicit failed-CAS,
collective-entry, root-spill, relocation, restore and subsequent address-use
transitions. Its stale-root negative control fails on an actual modeled stale
access, rather than merely assuming a root flag is an invariant.
The temporal formula is declared with per-action fairness; the current receipt
checks the listed invariants, not a separate temporal theorem.

`bootstrap-observation.json` establishes completed two-pass bootstrap.
`stress-gsc-observation.json` establishes one complete original compiled stress
campaign, four unchanged files with natural exit zero. Interpretation stress,
complete GSI/PR, remaining milestone suites and release performance are separate
obligations. No timeout cause, first corrupting instruction or full SMP admission
is established by this source review.

## Native Counter And Remaining Reverse Order

`complete-gsi-observation.json` records the same-source pipe timeout after the
two-macro repair: 369 files passed and 10 were not executed. The repaired macros
are therefore not sufficient to resolve that observed failure.

Grok's subsequent source audit identified a different reverse-order path:
`##thread-end-locked!` holds a thread ticket and calls `##btq-abandon!`, whose
`macro-lock-btq!` is still raw. A mutex holder may wait for that thread ticket
through the collective-participating thread helper. A failed abandon acquire
can therefore form both a lock-order cycle and a missing collective participant.
No native receipt places the timed-out TFIB or pipe worker at this path; its
relevance to those failures is an unproved premise.

Blindly releasing the terminating thread ticket is not a verified repair:
`##thread-end-locked!` already sets its end-condvar to false before abandonment.
An intervening joiner could then observe termination before resource cleanup.
A repair needs to preserve termination publication and ownership-list validation
as well as lock ordering. The repository already contains
`thread_abandonment_completion.qnt` and `exit_drain_mutex_lock_order.qnt` for
separate slices, plus a retained PR #1035 source/report snapshot. The first model
covers early join, foreign-owner revalidation and closing-owner admission; the
second covers inverse entry/slow-path waits. Their current-source collective,
alias and waiter-delivery composition remains an explicit obligation, not a
newly admitted fix. These existing artifacts must be visible from this source
gap's evidence scope instead of being rediscovered as new research.
