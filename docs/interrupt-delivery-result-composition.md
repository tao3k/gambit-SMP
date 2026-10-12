# Interrupt Delivery And Result Composition

## Source Projection

This combines two previously separate source contracts on the locked
`abandoned-result-state` candidate. Both requests are already registered; A
targets a thread that may terminate, B remains addressed to the source
processor. Processor dequeue must detach A before thread-queue insertion.
The propagation helper locks A's target, handles an ended target by releasing
that lock, and otherwise forwards the detached node. Target termination
abandons target-owned result mutexes. The requesting caller must observe that
abandonment rather than a successful result.

Authority is the pinned submodule and cumulative source lock, not generated
cache paths. Source locations are `lib/setup.c` processor interrupt dequeue,
`lib/_thread.scm` `##thread-intr!`, `##thread-intr-propagate!`,
`##other-interrupt!`, `##thread-end-current-thread!`, and
`##mutex-lock-out-of-line!`. Prior component models are
`thread_interrupt_queue_detachment.qnt` and
`ended_interrupt_result_lifecycle.qnt`; this new model uses one shared state
so termination, queue transfer and observation can interleave.

## Controls And Acceptance

The combined policy requires detached handoff, recipient/single-delivery
safety, target-lock release, ownership abandonment and matching result
observation. Three controls restore independently reported failure contracts:
linked transfer, leaked ended-target lock, and lost abandoned exception.
Linked transfer is checked both at handoff and at the callback recipient.
Completion has explicit weak-fair scheduling and terminating atomic primitive
assumptions. No elapsed-time or parallel speedup theorem is asserted.

## Open Requirements

This is a two-request, post-registration, abstract-atomic projection. It does
not prove source simulation, native memory ordering, arbitrary queue lengths,
GC root publication/relocation, requester cancellation, callback exceptions,
retirement or physical draining of a dead thread's retained queue. An abandoned
result can be observed while the dead target retains its queue; terminal here
means both callers resolved, not whole-heap quiescence. The complete GC model
must account for that retained graph before making reclamation claims.

Native evidence for the individual components and completed bootstrap is not
an execution witness for this combined interleaving. A matching native fixture
and same-artifact complete suites remain required. No runtime patch is added
or justified by this model alone; broad admission remains false.
