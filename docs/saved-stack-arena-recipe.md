# Saved Stack Ownership Across Non-Collecting Shrink

## Scope And Correction Of The Source Mapping

This refines the saved-stack gap in
[the candidate Recipe](host-root-candidate-recipe.md). The candidate identity is
the unchanged mutex-return source lock
`df9277dff351209ad7b33d12589d07821089262f7cdac40b358988aea2fc0466`,
Gambit revision `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, plus patch
`49514f1819da3ca6008b07690e732a13625a54811a3e44a7da3615e25fdf0d55`.
All candidate line numbers below refer to the source reconstructed from that
versioned lock/patch. No cache path, new checkout or native test is required.

The earlier conditional-GC observation remains correct. Its missing source
premise must not be interpreted as proof that non-collecting shrink is unsafe
or that every shrink needs a forced copy/GC. The source has another ownership
boundary: **executor retirement is not VM-arena deallocation or old-half reuse**.
The prior isolated model's copy-before-retire guard represents a narrower
storage-release policy, not the only legal Gambit source implementation.
Old models and their exact-hash receipts remain unchanged.

## Actual Saved-Frame Graph

| Edge | Candidate source | Meaning and remaining premise |
| --- | --- | --- |
| Running frame to saved continuation | `include/gambit.h.in:6313-6337` | `THREAD_SAVE` invalidates overflow undo, saves RA, stores a raw stack pointer or the existing break link into `thread.cont.frame`. Saving does not heapify it. Source lifetime still depends on live frames/maps and root reachability. |
| Rooted thread to queued continuation | `lib/_thread.scm:2856-2865,2940-3108,3319-3335` | Save/reschedule and migration preserve the Scheme thread; scheduler locks protect queue removal/restore, and steal/migration can choose another processor. This is not proof that a retiring queue's every thread stays reachable. |
| Saved slot to receiver break link | `include/gambit.h.in:6386-6396` | `THREAD_RESTORE` moves the frame pointer into the receiver's `BREAK_FRAME_NEXT` and clears the old continuation field. The raw reference has moved, not necessarily ended. Thread-slot emptiness cannot discharge the break-link borrower. |
| Raw break link to receiver frame | `lib/_kernel.scm:1185-1255` | With unsafe overflow undo disabled, the break handler reads old RA/size/link, copies one frame and advances the link. Remaining frames or escaped aliases may still use the old region. Last use is per frame/borrower, not the first copy in a chain. |
| Heap continuation to captured raw frame | `lib/mem.c:4519-4523,4078-4240` | The continuation scanner follows its frame field. For a raw pointer it reads old frame metadata, copies/forwards frames and updates the actual origin slot under the existing collector protocol. It need not execute on the retired donor. |
| Active break link to captured raw frame | `lib/mem.c:4322-4390` | After active stack scanning, the collector scans `BREAK_FRAME_NEXT`. Clearing `thread.cont.frame` therefore does not by itself remove this collector path. |

The actual `THREAD_SAVE` invalidation is relevant to stack overflow undo. Do
not generalize that single macro observation to every continuation primitive
or external C activation. Rooted Scheme frames and a live native C catcher
remain distinct lifetimes.

## Backing Ownership And Reuse

Candidate `mem.c:5550-5565` clears still/RC ownership and destroys the retired
queue lock. It does **not** call `free_msections`. The arena is VM-owned:
`___cleanup_mem_vmstate:5568-5596` frees it; `free_msections:1156-1181` frees its
individual section storage. Thus `cleanup_mem_pstate` cannot be mapped directly
to the isolated model's `releaseStorage` for a saved raw frame.

For the ordinary allocator, `next_msection_without_locking:3307-3408` advances
the VM assignment frontier under caller-owned exclusion. It does not decrement
the assignment count on donor retirement. `___setup_mem_pstate:5030-5127`
initializes the new slot's cursors and obtains sections from that allocator;
it does not select the old slot's section simply because its processor ID was
reused. This is a conditional source guarantee: intact allocator metadata,
valid section capacity, actual locking, and no custom allocator violating that
ownership are necessary. The constructor initializes the custom hook to null
(`mem.c:5293`), but arbitrary later host configuration is not proved absent.

A later GC has a different reuse boundary. `setup_stack_heap_vmstate:3760-3808`
reassigns initial sections and flips to/from-space halves, then the collector
traces the current graph and forwards captured raw frames before normal
execution resumes. The old half, section allocation and processor slot are
three different identities. A stable address or an allocated VM arena does not
permit overwriting an old half still read by a mutator/scanner. Actual half
disjointness, complete root enumeration, forwarding publication and phase
barriers remain the composed C-level obligations.

There are consequently two valid *conditional* paths for a particular frame:

1. Retire/clean the donor slot while preserving its VM-owned backing; another
   processor's break handler consumes the frame without an intervening GC.
2. Preserve the backing until a later collection follows its live root,
   forwards the frame, closes every old-half borrower and permits later reuse.

Neither path retains every pstate forever or requires unconditional heapifying
at shrink. Neither has been established for every live root in the candidate.

## Chez And OCaml Source Counterchecks

Chez `vendor/chez/s/mkgc.ss:234-270` traces a continuation's stack, link and
return address separately from the executing TC. Its sweeper explicitly treats
single-owner stack segments and remote segment work separately.
`c/alloc.c:104-138` allocates or reuses stack storage through the heap/cache
contract, whereas `c/thread.c:261-341` retires the execution context and preserves
a segment-creator carrier. These do not imply that every captured Scheme frame
must be copied when its original OS thread exits, or that an ended C stack lives
as long as that carrier.

OCaml similarly has two source paths: `runtime/domain.c:2360-2420` destroys the
terminating domain's current stack/cache, while `runtime/major_gc.c:1589-1619`
marks a reachable continuation's separately referenced stack with a marking
claim/release protocol. `minor_gc.c:275-290` also scans such a stack during
promotion. `fiber.c:642-674` synchronizes continuation consumption with marking
before clearing its stack field. Its one-shot take/CAS contract is not Gambit's
multi-shot continuation semantics. Transfer the ownership/reader obligations,
not that implementation, its memory layout or its resume restriction.

## Existing Model Extension And Handoff

`models/gambit/saved_stack_arena_ownership.qnt` imports the unchanged isolated
stack model's save, detach, publish, scan, copy and safety predicates. It adds
the source-specific executor-retirement transition while keeping readable
backing. This is intentionally **not** a refinement of its old eager-copy guard.
`R.donorStorage` now denotes old frame backing in this explicit profile, not
ownership by a live pstate. New slot cleanup and frame-root movement do not
release that backing. Mutator break consumption and the modeled GC scan are
mutually phased.

Omissions separate slot cleanup/free, clearing a slot/ending its consumer, and
address reuse/same frame incarnation. Reachability controls require a safe
non-GC return after slot reuse, and copied-frame progress with old-half reuse.
The model covers one reachable saved frame and its current root location; it
does not enumerate all queue roots, a multi-frame/alias census, the actual
allocator algorithm, C weak memory or native FFI unwinding. The Lean companion
quantifies borrower closure conditionally and reuses `WorkAccounting`'s epoch
contract. It does not discharge an omitted borrower automatically.

The implementing thread can now narrow the remaining audit:

- Prove the specific saved continuation remains reachable through a survivor,
  including runnable/sleeping queues and escaping continuations. Processor
  deque unlink and zero SFUN count alone are not the complete graph.
- Bind each old-half reader through save, restore, break-frame advancement,
  captured-frame copying and forwarding. Do not equate clearing the thread slot
  with last access; include aliases and valid interpretation metadata.
- Establish default/custom allocator exclusion, old-half non-overwrite, actual
  GC phase ordering and next-epoch reuse for the fixed generated configuration.
- Keep receiver join, remote channel sender, GC borrower and native C tail
  obligations from the prior Recipe separate. This source observation does not
  close them or identify the cause of a current native failure.

These are current 9/12 research obligations, not a new runtime patch. General
host attachment, independent stack carriers, a changed root ABI or per-domain
heap/collector design remain [Experimental](experimental/host-root-registration.md).
No runtime, candidate source lock, native checkpoint, bootstrap or pressure test
is changed by this research.
