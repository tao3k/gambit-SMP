# Continuation Export Origin

## Source-Driven Narrowing

Candidate026 `mem.c` retains both the local-chunk exclusion in `end_heap_chunk`
and the barrier after strong-root copying. Those guards must not be removed or
rediscovered as missing fixes. The new `continuation_export_origin.qnt` is a
characterization of these existing guards, not a corrected collector.

The section-rollover path in `mark_captured_continuation` commits `alloc`, ends
the old chunk and selects a new section before copying the next frame. The
previous frame's `ptr` still awaits the next `*ptr = forw`. This path exists
independently of the proposed local allocation threshold change. The scanner's
`___sFRAME` case reads, masks and restores that link without `MISC_MEM_LOCK`.

There are two relevant entry contexts:

- `mark_continuation` during root marking completes before the existing root
  barrier, so early publication is not by itself early consumption.
- `scan:___sCONTINUATION` calls the same copier during heap traversal. The root
  barrier has already completed. `scan_complete_heap_chunk` uses its own local
  cursor rather than installing that cursor as the producer's `scan_ptr`.

The second call site does not prove an uncopied saved frame reaches it. The
capture and `THREAD_SAVE` macros expose frame pointers; `THREAD_RESTORE` changes
the break-frame link. A legal history through these operations and the root
graph is still needed. It would be incorrect both to assume every saved frame
is covered by the current root chain and to assume an uncovered one exists in
the failing compiler workload without evidence.

## Checked Boundary

The model covers roots/traversal, local/nonlocal scan membership, ordinal start
and size 1..3, and every cursor position through the pre-marker endpoint. These
are disclosed verification bounds, not allocation or machine configuration.
Its marker-inclusive interval matches the order in `end_heap_chunk`.

TLC checked `guardSound` and explicit progress: **288 distinct / 405 generated
states, zero queued, 32.435 seconds**. This establishes root protection and local
exclusion in the stated abstraction and classifies any early consumption as
traversal/nonlocal. `readiness` is deliberately not an accepted invariant.
There is no `fixed` initializer and no native or release admission.

Evidence: `evidence/continuation-origin-model.json` and
`evidence/model-results/continuation-origin-model/receipt.json` bind source,
model, logs and tool identity. The prior link-handoff counterexamples remain
conditional downstream obligations, not evidence of historical native origin.

## Repair Decision

Do not change the allocation guard, add a blanket scan lock, or rerun the old
compiler failure based solely on this characterization. First establish legal
frame provenance and producer/consumer ownership across the actual section
handoff. Separately retain the original duplicate-body origin gap: a continuation
link race is not proof of a vector body being scanned twice. A native observation
must distinguish cycle, phase, allocation generation, queue claim and scan range.
