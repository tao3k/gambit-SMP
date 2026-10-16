# Shared Section Undo Bounds

The model now follows the same word-level stack/heap partition through GC
reservation, late relocation and undo. The unexecuted undo-only prototype
was expanded before checking; no earlier PASS or failure is replaced.

## Pending GC Frames

`setup_stack_heap_vmstate` installs a fresh stack section with its allocation
pointer at the top. Active contiguous frames are copied only by
`move_continuation` in the weak-mark phase. Between them, `next_heap_msection`
may share that new stack using the empty pointer for its quarter-gap split.
Pending contiguous frames are not included in that split.

Valid source frame coordinates can therefore collide with copied heap payload
when the delayed move installs them. The candidate reserves that range in the
new stack allocation pointer at setup, keeps old-frame coordinates for root
marking, and copies to the unchanged stack start at relocation. No other GC
call site acquires a new stack section between these operations. Adequate
residual sharing capacity remains a native obligation; fatal allocation failure
must not be relabeled PASS.

The GC negative control keeps the original empty-pointer allocation, valid
frame lengths, the actual quarter-gap split and available heap fudge. It does
not inject a bad frame pointer or a header write. The corrected control covers
both boundaries; the undo negative control holds GC reservation correct to
isolate the later boundary loss.

## Source Finding

The current locked source's `___stack_overflow_undo_if_possible` requires that
the **current** stack section differs from the current heap. It does not require
that the **previous** section stored in the first break frame differs from it.
`set_stack_msection` then resets the restored stack allocation limit to the
section's to-space beginning. `prepare_mem_pstate` uses that limit directly;
it does not reestablish a stack/heap partition.

The source supports this sequence:

1. During GC copying, `next_heap_msection` can exhaust unassigned sections and
   share the current stack section. The sharing helper divides the available
   range; `prepare_heap_msection` reserves chunk markers inside the heap side.
2. `resize_heap` retains assigned sections and adds allocation headroom. GC
   relocation does not create an eligible undo marker itself.
3. A later mutator stack overflow moves from that shared section into a fresh
   section and can retain a first-break undo marker. Its preceding section is
   still the processor's current heap until that heap moves elsewhere.
4. Undo passes the existing current-section check and restores the old shared
   section, but ordinary stack installation removes its stack-side lower bound.

This is a source-derived conditional sequence, not an observed trace of the
captured TFIB failure. The earlier allocator model records section identity and
comments that sharing splits bounds, but does not model word-level partition
restoration or copying-time heap sharing followed by mutator undo. Its PASS
cannot establish the missing partition premise.

## Candidate Obligation

If the restored stack section equals the current heap section, its stack
allocation limit must be no lower than the current heap allocation limit.
That heap limit remains meaningful while the processor continues using that
heap section. A constant-time restoration to that boundary avoids saving new
metadata or changing section layout. It retains the undo fast path and does
not serialize processors or disable SMP.

The proposed Darwin/GNU-only correction is after recovering the saved stack
pointer and before `prepare_mem_pstate`: set `alloc_stack_limit` to
`alloc_heap_limit` only when the restored stack and heap section are identical.
The default separate-section path and Linux source must remain unchanged.
The shared-partition invariant is checked before source application; bootstrap
and original stress acceptance remain mandatory. No native repair or performance
benefit is admitted before those checks.

## Prechange Review

- Relevant: an actual undo eligibility/install boundary loses a concrete shared
  allocation partition. This is not another pointer-mask or pool-layout change.
- Explored: repository search found no earlier shared-undo partition correction;
  rejected owned-undo metadata and pool-link layouts are not inherited.
- Worth: restoring a required range invariant is O(1), adds no normal logging,
  no allocation, no new lock, and preserves the existing fast path.
- Expected benefit: prevent overlapping stack/heap allocation in this conditional
  path. No percentage speedup or attribution to the captured header damage is
  known. Independent native stress failures must remain active if they recur.

Model: `models/gambit/shared_section_undo_bounds.qnt`. It uses abstract relative
word coordinates and the original/corrected restoration controls. Its modeled
headroom is a logical section resource, not a host CPU configuration.
The separate-section control retains the original reset to zero; it must pass
without the proposed conditional restoration.

## Execution Status

The ASCENT coordination window has ended. The sealed model Recipe passes in
24.377 child seconds: 486 distinct legal states, zero queued; original undo and
original GC reservation produce their expected counterexamples. Negative runs
stop at counterexamples and are not exhaustive coverage claims. The unchanged
separate-section control passes with three distinct states.

`darwin-shared-stack-reservation` changes only `lib/mem.c` from the parent lock:
reserve pending active frames at setup, relocate to their original destination
top, and restore the shared undo boundary. All three changes are Darwin/GNU-only;
Linux preserves its original statements. The existing source tree is reused
under an exact-hash lease; no new full source cache is created. Its full bootstrap
and pressure tests are not yet accepted. Parent failures remain active History
for review, and no sixth milestone gate is closed by the model or source edit.
