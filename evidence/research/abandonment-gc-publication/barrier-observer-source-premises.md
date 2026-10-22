# Barrier publication and the observer's role

## Bound sources

Candidate source lock:
`651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`.
The cumulative reader patch is
`patches/fixtures/abandonment-gc-publication-reader-cumulative.patch`, SHA-256
`e0f2b46d591ecbab9156d3d0adf9c83531e9d0c64f4c617b6ceb9b286c63ba12`.
The base `vendor/gambit/lib/setup.c` alone is not this candidate's implementation.

The current candidate changes `SYNC_SEND_MSG` to publish its flag with release
ordering and `SYNC_GET_MSG` to load it with acquire ordering. `SYNC_INIT_MSG`
resets the flag to `SYNC_WAITING` using a relaxed atomic store. In
`barrier_sync_op`, each receive is followed by that reset and then a copy of
`sync_op1`, `sync_op2`, or `sync_op0`.

## Distinct obligations

Publication orders the preceding payload writes before a matching receiver's
reads. It does not by itself prove that the payload cannot be overwritten
during a later read. The participants' tree round trip may establish that
additional property: a child sends its proposal, waits for the parent, consumes
the selected operation, and only then can participate in a subsequent round.
That correspondence still requires an explicit model, including cohort changes.
This observation is not a claim that the participant protocol is broken.

A third-party diagnostic reader is not automatically a participant in this
round trip. Its reads do not acknowledge consumption or prevent reuse. The
published processor ID may recur in another round; equal flag values at two
samples are not, without additional premises, a round identity or proof that
the intervening payload is stable. Processor lifetime identity and mailbox
round identity are separate concerns.

An adequate correspondence therefore has to state which role is reading, what
identifies the publication round, and why a writer cannot overwrite the observed
payload before its read completes. Merely assigning a `publishedOp` and a stage
bit does not model these obligations. Release/acquire alone is not a complete
third-party snapshot protocol.

## Evidence boundary

`ticket_offpath_witness.qnt` at
`ae4f56066388c95c1481b0e37acab300793f9ead0fd6e8f0927cde9a8e716238`
assigns `barrierStage` and `publishedOp`; it has no message reuse or participant
versus third-party-reader transition. The missing coverage is source-bound
review evidence, not a new runtime failure or an instruction selecting a repair.
No C change, debugger, stress repeat or native acceptance is inferred here.

## Reachable third-party counterexample

`models/gambit/barrier_thirdparty_flag_aba.qnt` isolates two publications with
the same sender flag. It grants stronger conditions than unsynchronized C
payload reads: every payload field access is SC atomic, and the participant has
consumed the old message before mailbox reuse. Only the diagnostic reader lacks
that acknowledgment role.

Typecheck exited 0. The existing `quint_backend.check` checked `init / step /
coherent` with the TLC backend and accepted the expected reachable invariant
violation in 5.460 seconds: 67 generated states, 49 distinct, 0 queued. The trace
has nine states. The diagnostic reader reads flag 1 and old op 1; the participant
consumes the old publication, then the writer stores op 2, arg 22 and flag 1.
The reader then obtains arg 22 and flag 1 and accepts the mixed pair (1, 22).
It is neither the old (1, 11) nor the new (2, 22) publication.

This is an abstract counterexample to flag equality as a third-party snapshot
certificate, not a C refinement or observation of this interleaving in the
recorded native hang. It does not invalidate the participant's own round-trip
protocol or choose a replacement design.
