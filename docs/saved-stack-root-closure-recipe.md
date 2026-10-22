# Saved Stack Root Closure And Reuse

## Identity And Scope

This continues [arena ownership](saved-stack-arena-recipe.md), using the same
versioned mutex-return source lock and cumulative patch. Candidate line ranges
refer to that reconstruction, not the current native acceptance candidate.
No runtime implementation, native checkpoint or source lock is changed.
Chez and OCaml are pinned source comparisons, not a proof of Gambit behavior.

The three outstanding obligations are now more precise: a physically stored
pointer need not be an actual GC edge; a forwarded head is not an entire chain
or all aliases; and old-half access, target work and executor return have
different final consumers. The previously verified single-frame model and its
receipts remain unchanged. The new composition imports it instead of replacing
its semantics or reporting those receipts as a complete root census.

## Root Graph After Shrink

| Candidate path | Source | Actual guarantee and missing premise |
| --- | --- | --- |
| GC direct roots | `mem.c:7226-7258,7490-7580` | P0 explicitly scans the VM object's fields; each surviving processor explicitly scans its own processor payload, registers, saved cells, type cache and active continuation. After the population shrinks, this does not itself scan a retired processor's payload. |
| Embedded processor and VM objects | `setup.c:622-668`; `gambit.h.in:11752,12073-12082` | Their C storage persists and headers are `___PERM`. A normal reference to such an object does not recursively trace its payload: `mark_array:3920-4073` handles movable/still/forwarded objects, with no PERM payload enqueue. Storage, pointer reachability and explicit payload enumeration are distinct. |
| Waiting-processor deque | `setup.c:1210-1233`; `_thread#.scm:2167-2219` | Shrink removes the departing processor from the VM waiting deque; the VM fields are not a vector of every processor. An additional reference to the same PERM processor does not replace its explicit payload scan. |
| Runnable, timed and device-blocked threads | `_thread#.scm:2008-2110`; `_thread.scm:2682-2701,2940-3108` | Processor fields hold run, timeout, blocked-device and interrupt queues. Each live thread must have an admitted survivor root path, or a justified termination/discard condition. Join alone proves neither migration nor closure of these queues. |
| Saved continuation | `gambit.h.in:6323-6396,6485-6527`; `mem.c:4519-4523,4595-4604` | Once a thread/continuation is actually reached through scanned storage, its payload and raw frame are interpreted. Structure-layout traversal does not establish that the containing object is reached in the first place. |
| Slot reinitialization | `setup.c:622-645,5277`; `_thread#.scm:2093-2110` | Setup clears processor payload and initializes queue heads. Same-address reuse is not a root transfer. Any required queue handoff or valid absence witness must precede this destruction of the old anchor. |

This is a concrete missing *source composition obligation*, not a native
counterexample. The retained source alone does not establish that a supported
shrink currently leaves a nonempty retired queue. Conversely, a comment saying
borrowers are drained is not a witness that the queues are empty or transferred.
The implementing thread should identify its supported shrink callers and prove
the corresponding queue disposition rather than adding a universal permanent-
object scanner or retaining all retired slots indefinitely.

## Old Half Reuse And Last Consumers

Ordinary allocation advances the VM's assigned-section frontier
(`mem.c:3307-3408`); if exhausted, it can share the requesting processor's
stack/heap section. It does not establish ownership of an arbitrary retired
section. That fallback still requires the existing non-overlap/fudge bounds.
Slot reuse and arena existence do not prove those bounds.

GC setup (`mem.c:3760-3808`) flips the surviving processors' from/to offsets
and resets their assignment frontier. This is a *phase-wide* reclassification,
not permission to overwrite live raw frames in the old half. The full collector
sequence (`mem.c:7670-7755`) orders setup, strong roots/reachable work, weak
work, cleanup and resizing with barriers. The next cycle may assign the old
physical half again: half parity cannot authenticate a saved incarnation.

The actual resource-specific read tails are:

| Consumer | Actual tail | What it does not discharge |
| --- | --- | --- |
| Break handler | `_kernel.scm:1185-1255`: reads RA/map/link, copies one frame, updates `BREAK_FRAME_NEXT` or carries the section's next link | The older chain, another continuation into it, or an escaped raw origin. Ordinary resume is not one-shot ownership of all captured continuations. |
| Captured-frame scanner | `mem.c:4078-4240`: reads old RA and link, copies body, writes forwarding/origin links, follows older frames, retags origin and publishes accumulated target chunks under `MISC_MEM_LOCK` | A different root still containing the old pointer. Even an already-forwarded origin is resolved by reading metadata in old storage. |
| Reachable target scan work | `mem.c:7360-7485,7550-7585`: drains/steals target chunks and accounts for workers before the phase barrier | Old-frame copying and target-object tracing are different resources. Ending raw reads is not whole-GC completion; target work must be traced before the cycle ends. |
| Native/host tail | Existing caller/FFI Recipe | A live Scheme frame does not extend an exited native C activation. Join and the remote sender/GC/host lifetimes remain separate obligations. |

In particular, a forwarding value being installed is not a substitute for the
complete scan/publication/barrier protocol. Nor does pending target work prove
an old raw frame is still needed: permissions must refer to the actual resource,
not a single global "done" flag. No new lock, TLS or eager collection is selected.

## Chez And OCaml Counterchecks

Chez `c/thread.c:270-336` removes the live thread and closes its dirty/allocation
work under the existing locks, migrates guardian entries and preserves a
segment-creator `thread_gc` carrier before freeing the TC. The preserved carrier
is not a promise to scan all of the dead TC's payload. Its separate root map
(`s/mkgc.ss:961-1024`) and reachable continuation traversal (:234-270) remain
essential. In the latter, stack contents, continuation link and return-address
interpretation are separate edges, with explicit remote-segment handling and a
single-owner assumption. Import the closure obligation, not that assumption
without a Gambit ownership proof.

OCaml `domain.c:2320-2420` removes STW participation only after its termination
protocol; a domain slot can then be reused but teardown retains the domain lock.
`fiber.c:321-334` scans stack frames, handler values and the parent chain;
`major_gc.c:1589-1619` claims/scans/publishes continuation marking, and
`fiber.c:641-668` synchronizes consumption before taking its stack. The stack
cache later reuses storage/metadata (:573-627), which cannot revive a previous
owner's root or generation. OCaml one-shot consumption is *not* a compatible
replacement for Gambit's multi-shot continuations.

## Current Model And Handoff

`saved_stack_root_closure.qnt` imports the unchanged arena model and its existing
stack component. It adds an enumerated survivor anchor, an older tail and a
second raw origin into that tail, target scan work and cycle closure. Deliberate
omissions admit a permanent pointer as a payload scan, a head as the whole chain,
or forwarding as work completion. Positive witnesses require both a non-GC head
return with retained aliases and a closed-chain next-cycle reuse. A finite
declared census is not the actual complete Gambit graph or a C memory model.

The Lean companion proves scan-edge closure, a permanent-pointer counterexample,
conditional completeness of declared consumers, the pending-tail obstruction
and non-restoration of generation after two cycles. These are conditional
protocol lemmas, not a refinement proof from generated C.

Current-repair handoff, in dependency order:

1. Bind a supported shrink call to its actual surviving thread/queue/continuation
   roots. For any retired anchor, show transfer through an actual scan edge or
   a justified absence/termination witness before unlink and reinitialization.
2. Bind every saved raw origin and its frame descriptor through break traversal
   and GC copying, including aliases. Establish old-half non-overwrite until
   those origins are resolved; preserve the target-work/phase completion edge.
3. Bind complete collector barriers, allocator bounds, join and all last callers
   for the same source/configuration. Neither successful prefix bootstrap nor
   local formal checks closes this native obligation.

Mechanism-level registration/attachment, an independent permanent-root registry,
changed continuation/root ABI or different stack carriers remain
[Experimental](experimental/host-root-registration.md). This research does not
choose such a redesign, change the current 9/12 count, or repeat native tests.
