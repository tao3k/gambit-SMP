# Shutdown Error Handoff

## Current Source And PR793

[Issue 792](https://github.com/gambit/gambit/issues/792) reports a worker error
being forwarded to processor 0 after its last catcher has been removed, during
shutdown. The cached issue and comment snapshot is digest-bound to the report
ledger; this is an upstream report, not a new local crash reproduction.

The pinned current source matches these relevant facts:

- `include/gambit.h.in:9986-9987`: setjmp `END_TRY` restores the old catcher;
  `THROW` dereferences `catcher->buf`. A restored NULL catcher cannot receive it.
- `lib/setup.c:3414-3439`: `___run` ends the protected region before returning.
- `lib/setup.c:4871-4890`: cleanup publishes global setup state 2 before resizing
  to one processor, which executes synchronous operations.
- `lib/setup.c:1062-1117`: the synchronous operation loop collects a worker's
  processor-0 error and unconditionally throws it on processor 0 at loop exit.
- PR793 changes that final condition to skip throwing when setup state is 2.
  This guard is absent from the pinned source. The PR is open and unmerged.

The inspected cleanup route services operations *after* publishing state 2.
Accordingly, the guard addresses that specific source-ordered throw condition;
we do not claim the PR fails the reported reproduction. Whether embedding APIs
can service an error with no catcher while state remains 1 requires a separate
source/caller-contract audit. An abstract interleaving alone is not that proof.

## QNT Obligations

`shutdown_error_handoff` separates catcher removal, cleanup publication,
worker reporting, synchronous delivery, worker stop and reclamation. It checks:

1. The current unguarded condition, with dispatch constrained to the inspected
   cleanup order rather than an invented pre-cleanup service call.
2. A wider guard-only scenario that permits dispatch between catcher removal
   and cleanup publication. Its source reachability remains unproved; the
   counterexample is a conditional hardening obligation, not a PR793 defect.
3. An injected catcher-only suppression policy that avoids NULL throws but
   discards an error previously admitted while execution was live.

The positive protocol seals admission before removing the catcher, drains
previously admitted errors while the catcher is live, and gives late reports
an explicit shutdown outcome. Loss-free admission is a proposed design contract,
not a claim that existing Scheme cleanup semantics require delivery of every
shutdown error. It is not yet an implementation or an accepted patch.

Bounds: one worker, one error, one VM and atomic lifecycle actions. This does
not prove C memory ordering, exception-unwind continuation, nested catchers,
embedding contracts, multi-VM shutdown, OS join/resource disposal, fairness or
deadlock freedom. The loop's two-pass interrupt reset and rendezvous remain
distinct source obligations, not omitted work that can be claimed as covered.

The syntax-only first attempt remains DENY. Attempt 002 is historical to the
wider dispatch abstraction; attempt 003 binds the source-constrained current
model. Complete bootstrap and native correctness remain open. No global runtime,
unchanged failing compiler route or full-build retry is used to validate this
model. Audit the teardown/caller contract and add a source-unit/native regression
before deciding whether to adopt PR793 or implement a stronger handoff protocol.

Attempt 003 exhausts 22 distinct states, 31 generated, zero queue in 22.090
seconds for the positive design. The frozen current-source control fails at
cleanup phase 2; the guard-only conditional control fails at phase 1, while
catcher-only suppression loses an admitted error at phase 2. These are three
different obligations, not three locally reproduced native crashes.
