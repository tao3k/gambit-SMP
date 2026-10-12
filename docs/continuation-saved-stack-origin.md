# Saved Stack Origin At Heap Traversal

## Path Review Before A Repair

This narrows the unresolved premise in `continuation-export-origin.md`; it is
not a collector patch or a reproduced native failure. Candidate027 retains
exactly the candidate026 `mem.c` and `gambit.h.in` hashes. The new manifest also
binds `_thread.scm`, `_thread#.scm` and the cached GHC paper.

| Source | Concrete Effect |
| --- | --- |
| `include/gambit.h.in:6314` | `THREAD_SAVE` stores the old thread's frame in its continuation and installs or preserves a break frame. It does not copy all saved frames to the heap. |
| `include/gambit.h.in:6377` | `THREAD_RESTORE` replaces the current break link with the resumed continuation, then clears that continuation's saved field. The other thread's saved field is not cleared. |
| `lib/_thread#.scm:3563` | The scheduler macros expand directly to the save/restore primitives. |
| `lib/_thread.scm:2698`, `2749`, `2834` | Rescheduling saves the current thread, selects another runnable thread and restores it. Full run-queue/stack-layout refinement is still required. |
| `lib/mem.c:4049` | `mark_continuation` scans the current active chain and current break link, not every suspended thread's continuation. |
| `lib/mem.c:3753` | `mark_array` only eagerly follows the first field for subtypes at or below `sBOXVALUES`. `gambit.h.in:2923` and `2929` distinguish BOXVALUES from CONTINUATION. Copying a continuation container is not scanning its frame chain. |
| `lib/mem.c:4247` | Heap traversal of `sCONTINUATION` invokes `mark_captured_continuation`. This can be after the existing strong-root barrier at `7083`. |

## Paper Reflection

Re-read GHC sections 3.4 and 3.5 from the integrity-checked text cache. Section
3.4 distinguishes local allocation, scanning and published pending blocks.
Section 3.5 explains that root evacuation and global work termination are
different obligations. Neither section establishes Gambit's saved Scheme-stack
coverage. Do not transplant GHC's sequential-stack premise into a runtime with
saved thread continuations and separate break-frame links.

The concrete hypothesis is now a save/restore history, not an arbitrary
`entry = traversal` choice. Its value is to stop treating the root barrier as
a complete argument that all later continuation frame inputs are forwarded.
It does not justify removing that barrier or adding a whole-scan lock.

## Model And Limits

`continuation_saved_stack_origin.qnt` chooses two distinct live Scheme-thread
identities from a finite three-ID domain, then executes save, restore, current
root scanning, continuation work publication, the root barrier and traversal.
The ID domain is a disclosed finite verification bound, not host configuration.
Raw and root-copied frames are tracked separately. Invariants derive from these
transitions; no forced-success initializer or proposed repair is present.

TLC completed **42 distinct / 48 generated states, zero queued, 27.232 seconds**,
checking `guardSound` and explicit progress. The first attempt failed parsing
because a local variable shadowed Quint's `next`; its denied receipt remains
under `.data/audit-continuation-saved-stack-001`. Only that identifier changed
before the successful 002 run. No native failed route was executed.

This models a retained-stack slice: the old thread stays reachable, its saved
stack region is not overwritten/spilled between switching and collection, and
the chosen continuation work reaches traversal. Full scheduler and physical
stack-layout refinement are not proved. Publication of a parent thread object
may delay discovery of the continuation until later traversal; that ownership
chain also needs refinement. Do not advertise this finite sequence as a native
trigger or as proof of the historic duplicate-vector-body failure.

## Next Engineering Gate

Combine this source history with actual allocation/scan ownership: the saved
chain must contain enough uncopied frames to roll to a new msection, and the old
chunk must be eligible for another worker while the producer still owns its
pending frame link. Existing local-chunk exclusion and root barriers remain in
the model. A bounded native observation must identify the frame/continuation,
GC epoch, chunk claim and writer, not merely count visits to an address.

Only after that obligation is established should a minimal publication or
ownership change be selected. Current evidence grants no native GC, bootstrap,
Gerbil test or performance acceptance.
