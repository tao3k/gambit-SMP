# Defined consumer: remaining source correspondence

This review does not retract the finite checker results or identify the native
timeout's cause. It separates their abstraction from an implementable consumer.

Bound inputs:

- `models/gambit/owner_defined_certificate.qnt`:
  `0b1304a900dd9e73400a1c9489d32b790788e05430b27ff64581e07a4db3b9b3`.
- `models/gambit/barrier_local_winner.qnt`:
  `e640b817c211103365c9cdcb701c45b425cf6066bc0d54f7f7c04dded61fdfbe`.
- `consumer-defined-access-contract.md`:
  `632a0e411c4f40b283598339652aa93eb5af3f3c0e1c2cd0d5c716e0142f89d1`.

## Ownership observation is not yet a source implementation

The owner model's read action obtains `obsP` directly from `s.p1` or `s.p2`,
and its `ownerImpl` property uses `obsP == 2` to justify CURRENT_HOLDER.
These are scheduler truth variables, not fields of the proposed C certificate.
They are useful ghost state for checking a consumer, but the consumer cannot
consult ghost state to decide its returned status. An implementation needs an
observable, validated ownership relation that implies the ghost predicate, or a
weaker explicitly scoped result. Merely adding `observed_phase` to the returned
structure does not supply that relation.

The certificate's first application sites cover two C interrupt acquires only.
The lock is also acquired by Scheme and other C paths. A missing or historical
certificate cannot identify the current holder on those paths. In addition,
the remote interrupt function's `___ps` names the target processor, not
necessarily the executing caller. A source proof must establish its actor and
VM lifetime before treating that argument as publication ownership.

## Fence explanation and memory abstraction

The contract's final paragraph under Defined accesses incorrectly pairs the
writer's second release fence with the reader's second acquire fence, although
that acquire fence precedes the final sequence load. This is not the required
reads-from ordering for that pair.

For the stated sequence algorithm, two distinct candidate edges need analysis:
the final even sequence publication to the reader's FIRST sequence load and
subsequent FIRST acquire fence; and a concurrent payload publication to a
reader payload load followed by its SECOND acquire fence, which must prevent
acceptance of an intervening odd sequence. Atomic modification order, sequence
reuse and the precise reads-from cases remain part of that source argument.
This correction is not itself a complete weak-memory proof. The current QNT
interleavings and fence flags do not enumerate the C memory model.

## Barrier and progress boundary

A coherent completed-past barrier record remains historical. It does not
identify the operation or phase of a participant now waiting before election;
an elected winner may not exist at that point. Combining that record with an
owner observation does not establish a same-actor, same-round wait cycle.

Unlock remaining enabled in the abstraction does not establish that the real
holder can execute it while collective participants are waiting. These remain
open source/progress obligations; no C repair or native stress result follows
from this review alone. Previously observed observer-induced fault changes and
the original uninstrumented failure remain separate retained evidence.
