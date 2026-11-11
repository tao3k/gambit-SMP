# Defined-access contract for source application

Source lock `651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`.
This replaces plain payload accesses in the seqlock candidate. It is the
contract offered for source review. It is not applied and not a native run.

Preserved, and not rewritten by this contract:

- Plain seqlock contract
  `5855673c5066c5d73c2eee81bc52d65eba981f99d29a98e9e51178b60b96e040`.
- Failed owner assertion
  `evidence/research/abandonment-gc-publication/owner_seqlock_publication.failed-current-assertion.qnt`
  `a00de3f00eb28eada0fc6d91da0cf8fe578c5d61c45e072b9751b3a765a5a7aa`.
  Its `ownerImpl` required a saved `CURRENT_HOLDER` to keep `p == 2`.
- Memory review
  `f7ff1756f5253a8475f0d991cc9d6f6e124ea8f4e248194f3ad450617d94db13`.
- Abstract model `e53be0b9b02cbed707c644370614a3c45b5d4c5e5881fae7e53fef75abdde6bd`.
- Successful plain-seqlock models `57dac1d45d13478aa7d41ec5fe32d298c42454d4be8a9a79581638d3ed480471`
  and `095dca8521b774b269d197984f87d2288b0465fa2e7c09d96b1bd443955476ba`.

## Defined accesses

Every word of the owner certificate and the completed-barrier record is
accessed only with the single-word GNU builtins already used by the reader
patch: `__atomic_load_n`, `__atomic_store_n`, and `__atomic_fetch_add`.
There is no plain load or store of those words, and no wider-than-word atomic.
Overlapping relaxed atomic accesses are defined. A later sequence mismatch
discards the values; it is not what makes the accesses defined.

Writer, in this order:

1. `__atomic_fetch_add(seq, 1, __ATOMIC_RELAXED)` makes `seq` odd.
2. `__atomic_thread_fence(__ATOMIC_RELEASE)`.
3. Relaxed atomic stores of the payload.
4. `__atomic_thread_fence(__ATOMIC_RELEASE)`.
5. `__atomic_fetch_add(seq, 1, __ATOMIC_RELAXED)` makes `seq` even.

Reader, in this order:

1. Relaxed load of `seq`. Odd is `CONFLICT` for this call.
2. `__atomic_thread_fence(__ATOMIC_ACQUIRE)`.
3. Relaxed atomic loads of the payload.
4. `__atomic_thread_fence(__ATOMIC_ACQUIRE)`.
5. Relaxed load of `seq`. A change or an odd value is `CONFLICT`.

The payload is installed only after step 5 matches the even `seq` from step 1.
That is the reads-from edge for the payload: both payload stores are
sequenced before the writer's second release fence and the even increment,
and the reader's second acquire fence is sequenced before the matching load.
A reader that uses the payload without those fences is not this contract.
`seq` still does not wrap in the checked models.

## Observation-time ownership

The call snapshots `ticket`, `current_ticket`, and the holder's phase.
`CURRENT_HOLDER` means those snapshots agreed and the phase was holding.
The saved enum is not a live assertion. Unlock may follow the call; a later
call can return `HISTORICAL` for the same ticket. Requiring the saved enum
to keep `p == 2` is the failed `a00de3f` assertion, not this reader.
A reader that relabels a coherent `HISTORICAL` snapshot as `CURRENT_HOLDER`
is rejected.

`HISTORICAL` means the named processor acquired that ticket. It does not
mean the processor holds the lock now.

## Coverage in the returned record

```
struct consumer_report {
  int coverage;        /* always INTERRUPT_SITES_ONLY */
  int owner_status;    /* ABSENT, CONFLICT, CURRENT_HOLDER, HISTORICAL */
  int barrier_status;  /* ABSENT, CONFLICT, COMPLETED_PAST */
  ___WORD holder, ticket, seen_current, round, op;
  int observed_phase;  /* phase snapshotted with CURRENT_HOLDER, else -1 */
};
```

`coverage` is `INTERRUPT_SITES_ONLY` on every return, including `ABSENT` and
`HISTORICAL`. Publication remains `__TICKETLOCK_LOCK2_CERT` at the
processor-object interrupt acquires in `___raise_high_level_interrupt_pstate`
and `___get_next_high_level_interrupt_pstate` only. Scheme primitives and
other `___PRIMLOCK` sites do not update the certificate. `ABSENT` and
`HISTORICAL` do not mean that lock is free. A sampled waiter at an
instrumented site does not imply the holder acquired at an instrumented site.

## Local election winner

`barrier_sync_op` starts from the caller's `*sop_ptr` and replaces it only
when a child's `sop.op` is smaller. The local proposal can be the winner.
The completed record stores that elected `sop.op` and the VM `barrier_round`,
after election and after the copy. Equality with the entry proposal is the
local-winner case. Publishing the entry value before election is a different
event and is not a completed record. `arg[0]` and `arg[1]` stay out of the
record. The report still has no same-cycle field.

The spin in `___TICKETLOCK_LOCK2` is unchanged and does not load the
certificate. Unlock stays a fetch-add of `current` with no dependency on the
barrier. Fault preservation of the new atomic operations is not claimed.
Native execution waits on review of this contract.
