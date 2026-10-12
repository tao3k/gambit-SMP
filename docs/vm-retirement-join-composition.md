# VM Retirement and Join Composition

## Why This Is a New Boundary

`gc_resize_resource_retirement.qnt` assumes joins succeed before root enters
another round. `pstate_retirement_generation.qnt` treats failed-join quarantine
as a local terminal. Neither establishes the whole VM's subsequent behavior.
The current source publishes reduced population before joining retired
processors and ignores the join result. Retained mutex ownership does not
prove thread exit or VM-wide quiescence.

The new model imports and executes `sync_slot_retained_resources` transitions.
It composes population publication, receiver cleanup, physical thread exit,
join outcome, next GC, slot reuse, sender tails and VM resource destruction.
The earlier two models are comparison inputs, not executable imports.

## Bounded Results and Assumptions

The model is `models/gambit/vm_retirement_join_composition.qnt`; its contract is
`evidence/fixtures/interrupt-prefix-owned-lifecycle/retirement-join-design-contract.json`.
The portable receipt is registered in `evidence/protocol-bundles.json` and linked
from Reflection. All source comes from the pinned submodule and semantic Fixture.

The positive check explored **138 distinct / 262 generated states, zero queued**,
and completed safety and temporal progress. Three actual exit-1 controls show:

- A failed join treated as completion can admit GC before receiver cleanup.
- Reuse can precede physical exit of the prior thread incarnation.
- Joining a receiver does not drain the remote sender's remaining signal tail.

GC safety concerns incomplete receiver cleanup, not mere OS thread existence.
The finite progress contract allows at most one failed join and requires a
subsequent successful join, under weak fairness. This is **not** a POSIX recovery
guarantee. Permanent failure is an open requirement, and quarantine is not
declared a successful whole-VM terminal.

The original campaign took 15.117 seconds. Portable publication initially failed
because two comparison model hashes were context inputs without declared
snapshot dependencies. Their declarations were added; unchanged model/context
hashes allowed all four checks to be reused through the existing framework.
No TLC rerun, model weakening or timeout change was needed. The portable archive
includes the comparison snapshots as well as the actually imported dependency.

## Native Source Correspondence

`models/gambit/native/vm_retirement_join.c` projects the complete byte-locked
`___vm_resize_pstate`, injecting only the thread/join and count-publication
primitives. A successful join returns success with the retired receiver drained.
A nonzero join result while the receiver remains live still makes the actual
caller return zero after publishing population one. The negative control exits
one because the retirement contract is violated; it is not a claim that a valid
native POSIX join has been reproduced failing in production.

Receipt summary:
`evidence/source-results/fixtures/interrupt-prefix-owned-lifecycle/retirement-join-observation.json`.
This remains a characterization of uncorrected source, not runtime admission.

## Required Implementation Closure

Before a source repair is admitted, bind the reduced-population handoff and join
outcome to the actual synchronized operation loop. Prove that root and surviving
processors cannot accept a subsequent resize/GC/shutdown using an unqualified
retired slot, and that all resource users drain before VM destruction. Specify
what happens if join cannot recover; a unilateral return, ignored result,
unbounded retry, or local quarantine label is not a complete protocol.

The existing `resize_result_distribution.qnt` already checks tagged, acknowledged
P0 result publication over a fixed retained population. Reuse that contract
instead of rediscovering its local-result failure: `OP_VM_RESIZE` is noncombining,
and `execute_sync_op_loop` returns a local result only at the winning requester.
A P0-only error return cannot by itself supply the correct result when a
surviving nonzero processor originated the request. Its fixed-population result
protocol still needs executable composition with changing membership and this
join/drain contract before implementing a C repair.

Then exercise actual multi-VM/processor failures and successful retirement,
complete source-regenerated bootstrap and Gerbil tests. This model does not
discharge native GC, arbitrary population/generation, weak-memory, foreign
callback or performance acceptance.
