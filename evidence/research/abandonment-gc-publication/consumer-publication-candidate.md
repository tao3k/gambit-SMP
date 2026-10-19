# Holder publication and completed barrier record

Source lock `651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`.
This note is the current proposal for a consumer protocol. It is a candidate
extension for source review. Current source has no shared owner word and no
completed-operation record. Native execution remains unauthorized.

## Protocol

`___TICKETLOCK_LOCK2` still reserves with fetch-add and spins only until
`___TICKETLOCK_READ_CURRENT` equals that thread-local ticket. The candidate
release-stores `(holder, ticket)` to a distinct word at that loop exit. The
spin predicate does not read the word. A consumer accepts the pair only when
the published ticket still equals `current`. After unlock, `current` advances
and the same publication no longer names a holder. A later certificate that
records the matching pair remains evidence that this processor acquired that
ticket.

`barrier_sync_op` still stores `sync_op0`, release-stores the flag, and the
child acquire-loads, resets the flag, then copies. The candidate release-stores
the copied pair `(seen round, op)` after that copy. The next payload still
waits for the post-copy upward send. The flag is not the round id. A consumer
acquire-loads the pair in one step.

The joint report copies one accepted holder certificate and one completed
pair. Those are two certificates. The report does not say the holder is the
barrier participant, and it does not say the native sample is a GC cycle.

## Checked candidate

Model `models/gambit/consumer_publication.qnt`
`e53be0b9b02cbed707c644370614a3c45b5d4c5e5881fae7e53fef75abdde6bd`.
Manifest
`evidence/research/abandonment-gc-publication/consumer-publication.manifest.json`
`3f6f64243d993c51dd1a7200160bec78665d49eb9fb793af2d2c4274db47d08e`.
Receipt `.cache/consumer-publication/receipt.json`
`b3e07b1153109c0bfa8314804abf47faada216e7bbb7fac5c928c4c9e1ae1716`:
`contextStable=true`, `accepted=true`, `runtimeAdmitted=false`,
`releaseAdmitted=false`, native status `not-run`, campaign 33.096s.
Quint 0.33.0. This receipt is the model-revision report for the live model
digest. It is not native admission.

Positive `initProtocol`, exit 0, queued 0, 254883 generated, 66668 distinct:

- `ownerConsumer`: at most one holder; a published ticket equal to `current`
  is that holder; a recorded certificate names a processor that acquired that
  ticket.
- `recordAgrees`: an atomic read of the completed pair matches itself.
- `jointCertificates`: the assembled report preserves those two certificates.
- Temporal `completion` reaches both unlocks and the second completed record.

Negative controls, each a reachable invariant violation:

- `stackSound`, exit 1, 17 generated, 16 distinct, 4 queued. Processor 2's
  stack word starts equal to `current` while that processor is idle. Same
  separation as `ticket_offpath_owner_counterexample.qnt`
  (`4c58e8fdeb25d2b67e72fb4b60108956bf2176ebe70805044cd84728d70c941c`).
- `liveSound`, exit 1, 230 generated, 136 distinct, 77 queued. A sticky read
  of the owner word after unlock still names the previous holder.
- `splitAgrees`, exit 1, 64848 generated, 18611 distinct, 4839 queued. Reading
  the completed sequence and operation in two steps straddles two rounds.
- `flagLive`, exit 1, 1327 generated, 568 distinct, 242 queued. A flag sample
  is not later live mailbox state. The stronger mixed `(op, arg)` trace remains
  `barrier_thirdparty_flag_aba.qnt`
  (`097e0eb89843c7028ddbed439039b9c057d10989d4acc21aacc92bc24e35142c`).
- `jointSameActor`, exit 1, 10740 generated, 3808 distinct, 1087 queued.
  The holder certificate can name processor 2 while the completed record is
  the participant's operation.
- `recordAgrees` under `initCohort`, exit 1, 6551 generated, 2434 distinct,
  791 queued. Overwrite before copy breaks the completed pair. The upward-wait
  premise is still required.

## Source-review conditions

The new stores are not in the candidate source. Their effect on the retained
hang is `not-represented`. `scope_review` stays empty. Prior component receipt
`fb57d01805d18ee3ae00cf5f23f30e1ee5fef5c2419bb7cc1c1dbcdc61c3c176` and
unpromoted receipt
`fd983652688f9db1fd3a727271dd4299cff164b473fe9ebe2c3222ea4745a7e5` stay
registered on `loop-exit-participant-component-limits`. The rejected offpath
value `unique-residual-slot-equals-stable-serving-word` is not a proposed
value of this protocol.
