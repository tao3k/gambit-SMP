# Implementation contract for the consumer publication

Source lock `651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`.
Cumulative reader patch
`e0f2b46d591ecbab9156d3d0adf9c83531e9d0c64f4c617b6ceb9b286c63ba12`.
Abstract model `models/gambit/consumer_publication.qnt`
`e53be0b9b02cbed707c644370614a3c45b5d4c5e5881fae7e53fef75abdde6bd`
stays the qualified abstract check. This contract is the source-application
candidate. It is not applied, and it is not a native admission.

The source review
`abf8685601b1753e5853b62700fe9d9c31f24e8fdfa6a7a92e1d8ae9cd4aba19`
requires an indivisible representation, a phase identity, and separate
historical records. Two plain release stores are not that representation.
A wider-than-word atomic is not assumed: the GNU profile already used by the
reader patch has single-word `__atomic_load_n`, `__atomic_store_n`, and
`__atomic_fetch_add`. `___WORD_WIDTH` is 32 or 64. A ticket is a full
`___WORD` fixnum (`___FIX`). A processor index plus that ticket does not fit
one `___WORD`. The encoding is a seqlock around the fields, not a packed word.

## Widths and reuse bounds

Owner certificate, a distinct object from `___ticketlock_struct`:

- `seq`: one `___WORD`. Even is stable. Odd means a writer is between the two
  increments. The checked models do not wrap `seq`. A wrapping seq is outside
  this contract.
- `holder`: one `___WORD` holding a processor index from `___PROCESSOR_ID`
  for one VM, or `-1` when empty. It is not a pointer and not an arbitrary
  native identity.
- `ticket`: one `___WORD` fixnum, compared with `current_ticket` by the same
  equality the spin uses. Ticket wrap is outside this contract.

`___ticketlock_struct` remains `current_ticket` and `next_ticket` only.
`___DEBUG_TICKETLOCK`'s history ring is not this certificate.

Completed barrier record:

- `seq`: one `___WORD`, same even/odd rule, same no-wrap bound.
- `round`: one `___WORD`. Source is `barrier_round` on the VM, incremented
  once by processor 0 after election and before it distributes `sync_op0`.
  It is not `sync_id0`, `sync_id1`, or `sync_id2`. Those flags carry processor
  ids and can recur. Wrap of `round` is outside this contract.
- `op`: the `unsigned char` operation kind from `___sync_op_struct`, widened
  to a `___WORD`. `arg[0]` and `arg[1]` are not in the record.
- `phase`: `0` empty, `1` completed past round. No other phase value is defined.

## Owner publication

`___TICKETLOCK_LOCK2` stays the uninstrumented macro. A second macro,
`___TICKETLOCK_LOCK2_CERT(next, current, cert, holder)`, performs that same
reserve and the same acquire spin on `current`, then the seqlock:

1. fetch-add `seq` by 1 (even to odd)
2. plain store `holder`
3. plain store `ticket` (the thread-local reserved ticket)
4. release fetch-add `seq` by 1 (odd to even)

The spin does not load `cert`. The macro does not publish on the unlock path.
Unlock stays a fetch-add of `current` and remains enabled for whoever holds
the lock.

`___PRIMLOCK` is unchanged. `___PRIMLOCK_CERT` is the only caller of the new
macro. The first application sites are the processor-object interrupt lock in
`___raise_high_level_interrupt_pstate` and
`___get_next_high_level_interrupt_pstate` (`lib/setup.c`), the acquires of the
lock in the retained sample. Any other `___PRIMLOCK` site does not update this
certificate. A current-holder result therefore means an instrumented site
acquired that ticket. A holder that acquired through another site stays
unreported. That coverage bound is part of the contract.

Reader, one certificate:

1. acquire-load `seq`; an odd value is `CONFLICT`
2. plain load `holder` and `ticket`
3. acquire-load `seq` again; a change or an odd value is `CONFLICT`
4. `holder < 0` is `ABSENT`
5. `ticket == current_ticket` is `CURRENT_HOLDER` for this read
6. otherwise `HISTORICAL`

A saved status is not revalidated. After unlock, `current_ticket` advances
and the same words are no longer a live holder; a later read returns
`HISTORICAL` or `CONFLICT`. `HISTORICAL` means that processor acquired that
ticket. It does not mean the processor holds the lock now.

## Barrier publication

`barrier_sync_op` still gathers children, elects the smaller `sop.op`, and
only then distributes. The entry `*sop_ptr` is not the selected operation.

Processor 0, after election and before storing a child's `sync_op0`,
release-fetch-adds `barrier_round` by 1. Each processor that has the winner
in its local `sop` (the root after election, a child after `sop = sync_op0`)
acquire-loads `barrier_round` and seqlock-publishes `(round, sop.op, phase=1)`.
A processor blocked in `SYNC_GET_MSG` before that copy publishes nothing.

The parent still does not start the next payload until this participant has
copied and sent upward. A cohort that breaks that wait is outside the
contract; the abstract cohort control still applies.

Reader of the record uses the same seqlock rule. Status values:

- `seq == 0` and not mid-write: `ABSENT`. Absence means no completed record
  has been published. It does not mean the processor is outside a barrier.
- stable `phase == 1`: `COMPLETED_PAST`, with that round and operation kind.
  The participant may already have returned, or may be blocked in a later
  round that has not published.
- mismatched or odd `seq`: `CONFLICT`

## Report

```
struct consumer_report {
  int owner_status;    /* ABSENT, CONFLICT, CURRENT_HOLDER, HISTORICAL */
  int barrier_status;  /* ABSENT, CONFLICT, COMPLETED_PAST */
  ___WORD holder, ticket, round, op;
};
```

The report copies those two statuses. It has no same-cycle, same-VM, or
same-actor field. `CURRENT_HOLDER` together with `COMPLETED_PAST` does not
say the holder is inside that operation, that the native sample is a GC
cycle, or that unlock waited for the barrier. Missing, stale, and conflicting
reads stay the statuses above.

Finite-state safety of this protocol does not preserve the original fault
schedule. The added stores are at the named sites only. Native execution
awaits review of this contract.
