# Ticket Investigation: Source Identity And Query Failure

## Bound Candidate

The candidate is complete source lock
`651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`.
The vendor revision alone is not that candidate. The cumulative patch changes
scheduler lock acquisition and processor startup as well as other protocols.
The retained bootstrap receipt binds the materialized source and binary;
its successful compilation does not establish full native qualification.

## Observed Investigation Failure

The resumed Grok investigation issued 59 tools across 24 assistant turns.
Its one Clue query included a caller-owned selector containing
`(not (lit-skip N))`, without declaring `lit-skip`. The native Scheme engine
rejected it with `ascent.EngineError: undeclared relation`; the CLI exited 1.
This was not a hit, an empty matching scope, or evidence that no support exists.
Sixteen subsequent file reads targeted the unmodified vendor source. Reading
the base is useful for comparison, but cannot establish candidate behavior
without the exact patch or materialized-source comparison. No native test,
source repair or new QNT result was produced by this bounded turn.

The supervisor supplied the actual query error and receipt-bound candidate
source location to the same session. Its following turn acknowledged the
identity distinction and began reading the correct materialized source.
This is observed recovery, not proof of autonomous discovery or lower cost.

## Interpretation Boundary

The prior sample establishes the C interrupt queue's ticket wait site only.
The ticket holder and collective operation kind remain unobserved. A finite
model may explore a holder parked in a collective, a stale ticket, startup,
and GC alternatives; it must not select one as this run's observed cause.
The existing abandonment model does not cover this C acquisition path.

Query validity, candidate identity, model scope, source repair and native
completion are separate obligations. Preserve the failed query and original
stress failure; neither a corrected query nor a model pass supersedes them.
No repeated bootstrap or widened watchdog is justified by this investigation.

## Rejected Draft And Native Branch Counter-Evidence

The following draft incorrectly described the definition at `_thread.scm:6426`
as another definition in the active SMP branch. Its proposed removal is rejected.
The exact candidate has its `cond-expand` clause boundary at line 5554; that
definition belongs to `else`, the non-SMP scheduler.

`models/gambit/native/processor_interrupt_branch_scope.scm` checks the complete
outer form with Gambit's reader and counts direct definitions separately in
each clause. Both the complete candidate and the vendor control produced:

```scheme
(scheduler-clause enable-smp thread-check-devices-definitions 1)
(scheduler-clause else thread-check-devices-definitions 1)
```

Both emitted `BRANCH-SCOPE-PASS`, exited naturally with code zero in about
0.018 seconds, and had quiescent process groups. This is a source-structure
check, not runtime synchronization acceptance. It reused the retained native
reader without bootstrap. The earlier argument-binding attempt exited 70;
its receipts are retained separately and are not counted as passing controls.

The draft `processor_interrupt_ticket` verifier also failed with QNT404:
`Name 's' not found`. Independently of that syntax error, its deterministic
phase counter and `saw*` flags do not represent acquire/release interleavings,
collective progress, ticket reservation or object relocation. Adding a state
declaration alone would not make that model a protocol qualification.
The source assessment and protocol draft were returned for correction before
any native source edit. No native stress was repeated on unchanged bytes.
