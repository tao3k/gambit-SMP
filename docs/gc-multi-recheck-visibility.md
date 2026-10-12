# Multiple Publishers And Waiters

## Route Review

The checked one-producer visibility model leaves multiple waiters and sequential
queue rechecks open. Existing recursive GC models assume coherent reads; they do
not cover this handoff visibility distinction. This extension combines two
publishers, two waiting attempts, descending per-queue probes and non-buffered
condition signals. It does not rerun known native failures. Expected benefit is
finding notification/count defects, not a quantified speedup.

## Source-Shaped Protocol

Publication has already released Q before the modeled signal-M acquisition.
A waiter captures completed publication handoffs when acquiring M. Every probe
uses the original `gc_recheck_visibility.allowedRead` predicate: no fabricated
work, and visibility of work whose publisher completed its M handoff. Work
published behind the waiter's M may still be missed by a predicate read, but the
publisher must acquire M after atomic registration/release and signal a waiter.
The first visible queue returns active immediately. Empty observations advance
the descending queue cursor; only after all probes may active count decrease.
Notification chooses one currently registered waiter, never a future waiter or
one already woken. Reacquisition restores the count before returning active.

Controls respectively release M before registration, and omit handoff visibility.
They must exhibit a registered sleeper after all protected notifications finish.
They are assumption/repair controls, not attribution of an observed C failure.

This is a new population extension, not a proved simulation of either prior
model. The original read predicate is imported and hash-bound; the qualified
single-waiter contract is a composition reference, not a universal theorem.
Two producers and two waiters are semantic roles, not runtime CPU limits.

## Limits

Both producers remain counted and their published queues remain pending through
this finite notification campaign. There is no payload consumption, producer
retirement, recursive discovery, GC zero-count termination or strong/weak phase
transition. Successful primitives, stable population, valid resources, mutex
handoff ordering and eventual scheduling are explicit premises. The count lower
bound cannot be generalized past producer retirement. Completion means all
notifications and these two waiting attempts finish, not whole-GC closure.
No C memory-model refinement, native correctness, throughput or release admission
follows. These gaps remain in the full GC requirements and real acceptance gates.
