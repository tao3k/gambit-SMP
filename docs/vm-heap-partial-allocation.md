# Partial Heap Acquisition Contract

## Route Review

The source-backed issue is caller rollback, not `adjust_msections`' documented
partial-growth API. No unchanged failed native route runs. The expected benefit
is eliminating retained constructor allocations and invalid destruction, not a
measured speedup. The previous two-section VM model did not distinguish an
allocated descriptor with zero sections; this model closes that local gap.

## Source Boundaries

Pinned candidate027 `lib/mem.c` is bound by hash in the manifest. In
`adjust_msections`, descriptor allocation can succeed and publish `*msp` before
the first section allocation fails. Every successful section updates the count
and chain before the next allocation. Failure preserves a consistent partial
allocation. `___setup_mem_vmstate` detects a null descriptor or an incomplete
count, then returns heap overflow without freeing the retained allocation.

`free_msections` visits every counted section, frees the descriptor afterwards,
and nulls `*msp`; zero counted sections still require freeing a nonnull descriptor.
It does not call P0 cleanup or unlink the VM. Those remain distinct constructor
rollback steps. The VM constructor must not use the normal VM destructor blindly.

## Checked Obligations

`vm_heap_partial_allocation.qnt` distinguishes descriptor allocation failure,
descriptor-only ownership, one retained section, and a complete two-section heap.
It records the helper's count separately from live sections during destruction,
matching the source's destructor loop rather than pretending that it decrements
the stored allocation count after every free.

Four controls independently test legacy empty/partial constructor failure,
a proposed count-positive-only cleanup, and a proposed descriptor-first cleanup.
Only the legacy controls characterize the source. The latter two are repair
review controls, not observed native defects. Positive checking includes helper
shape, caller failure rollback, descriptor lifetime, successful ownership, and
progress under weak fairness and returning primitive calls.

The source's loop releases sections in reverse index order. The model allows any
section order to check the stronger descriptor-last lifetime requirement; it does
not prove address sorting or doubly-linked pointer integrity. The bound is a fresh
constructor with two sections. Nonfresh expansion, GC resizing, custom allocators,
concurrent readers and C weak memory remain outside this model. Native allocator
failure injection and actual source correspondence remain required.

The VM constructor model now separately owns descriptor resource 5, checks its
lifetime, and includes descriptor allocation failure in addition to both section
failure points. Its aggregate heap release is justified only by this local
destructor contract; a bounded submodel result is not a source-refinement proof.
The Datalog dependency points to the real model rather than deleting the remaining
native obligations. No runtime patch is admitted by these checks alone.

The first stable campaign `.data/vm-heap-partial-model-001` rejected all four
controls and exhausted 23 distinct / 27 generated positive states, zero queued,
with safety and temporal progress completed in 21.454 seconds. Portable logs,
counterexamples and the source-bound receipt are under
`evidence/model-results/vm-heap-partial-allocation-model/`. This is model-only
evidence, not native allocator failure injection.
