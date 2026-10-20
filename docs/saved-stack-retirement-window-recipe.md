# Saved Stack Retirement Window

## Scope

This refines [root closure](saved-stack-root-closure-recipe.md) for the same
versioned mutex-return candidate. It does not change runtime source, its lock,
native checkpoint or the implementing thread's qualification. Candidate line
numbers refer to that lock/patch reconstruction. No evidence here determines
whether its newer source profile already implements these obligations.

The prior arena and root-closure models, evidence and exact-hash receipts stay
unchanged. The new composition imports their transitions instead of recreating
the collector or treating a single-frame proof as complete queue coverage.

## Actual Entry And Queue Disposition

Candidate `_kernel.scm:2394-2414` wraps the SMP entry by migrating a nonzero
Scheme caller to processor 0 before entering `___current_vm_resize`. The
migration (`_thread.scm:3316-3336`) saves that thread, preserves the donor's
current-thread root while servicing a collective, enqueues on the selected
processor and later restores it. This is a concrete *caller* path, not migration
of every thread or queue belonging to every departing processor.
The direct public C symbol and global cleanup's internal admitted call do not
execute this Scheme wrapper. Global teardown also does not promise to resume
arbitrary queued Scheme work; its caller/FFI contract is a separate domain.

`setup.c:1579-1644` closes `sfun_admission_gate` and checks retiring processors'
`sfun_frame_count`. This protects its external Scheme/C activation contract.
It does not enumerate Scheme runnable, timeout, device-blocked, pending
high-level interrupt or current-thread fields. `on_all_processors:1536-1553`
raises a collective interrupt; its execution loop (:1410-1518) does not by
itself prove every independent producer or borrowed queue link is quiescent.

The shrink body (:1208-1237,1280-1308) removes the processor from the VM waiting
deque, exits its OS thread, joins, transfers still/RC lists, and clears memory
state. `___transfer_mem_pstate` (`mem.c:5499-5547`) transfers those lists, not
the Scheme queues. Scheduler stealing (`_thread.scm:3027-3108`) ranges over
the current processor count and declines pinned/migration-target threads.
It cannot be a general post-shrink rescue for queues above the new population.

Accordingly the available source guarantees do not close the entire queue
disposition. A supported empty-queue caller can be safe, but needs a scoped
witness for **every relevant queue/current activation**, valid through removal
and reset. A transfer alternative needs actual scanned survivor roots and
correct queue owner/device/timeout/pinning semantics. This is not authority to
silently discard queued Scheme work or move pinned threads to an arbitrary CPU.
If general busy-processor shrink is not a supported contract, that limit must
be explicit; it is not evidence that every real call already satisfies it.

An empty observation taken before the last admission closes can become stale.
The model therefore distinguishes scoped producer quiescence from the native
foreign-frame gate. This does **not** prescribe an extra mutex/counter: an
existing collective/ownership protocol could supply the required stable window,
but its coverage has to be bound to the actual producers.

## Raw Origins: Move Versus Non-Consuming Use

The concrete producer list has expanded beyond `THREAD_SAVE`:

| Candidate source | Effect on raw origin |
| --- | --- |
| `gambit.h.in:6323-6396` | Thread save writes its continuation frame. Thread restore moves it to the break link and clears that thread-continuation field. |
| `gambit.h.in:6607-6624` | Ordinary capture saves a raw frame in a newly created continuation and installs a break link. Both can name the same backing. |
| `gambit.h.in:6672-6684,6734-6754` | Ordinary graft/return reads the continuation frame into the break link **without clearing the captured continuation**. Its later reuse is a possible consumer even after the current invocation returns. |
| `mem.c:4078-4240` | Captured scan resolves each reached origin, follows older links and publishes target work. A second still-raw origin can require another old-metadata read even after the first forwarding link exists. |

Thus a break-handler return is a local last access, not proof that a still-
reachable multi-shot continuation has lost its origin. Conversely, if GC
rewrites that origin to a heap frame, the continuation's continued existence
does not indefinitely retain the old raw half. Required proofs are about the
actual origin *value/incarnation*, not every continuation being destroyed.

Save, capture and these no-winding graft/return paths invalidate overflow undo
(`gambit.h.in:6313-6320`). This matters because `mem.c:8084-8134` can put the
current section on a processor-local reuse list while restoring the previous
stack. `stack_msection_stop_using:3497-3510` only updates occupancy accounting;
its name does not prove deallocation or last raw use. These source guarantees
must be preserved, not replaced with forced GC on every shrink. Other paths,
generated configurations and native catchers still need their own coverage.

## From Private Work To The Next Old Half

In `mark_captured_continuation` (`mem.c:4078-4240`), a scanner holds
`MISC_MEM_LOCK`, forms private chunks when needed, resolves roots and publishes
accumulated segments before returning/unlocking. These target-space chunks are
not visible to queue probes while private. The producing scanner must still
count as active through that publication; seeing queues empty is insufficient.

`publish_heap_chunk_segment:3579-3608` links/tails under the queue lock before
notifying through the termination mutex. The scanner's idle path
(:7429-7481) rechecks public queues under their locks before relinquishing active
ownership under the termination mutex. The ordinary active scanner count is not
a count of all root aliases or all future private work: correctness requires
the publisher's active interval and the cohort to be the same phase/epoch.
No claim of a complete C weak-memory refinement follows from this sequence.

`___garbage_collect_pstate:7710-7755` places barriers after setup, strong marking,
weak marking and cleanup, then P0 calls `resize_heap` before the next barrier.
`resize_heap:6992-7014` retains the assigned-section floor before
`adjust_msections:7111`; contraction can actually free arena sections
(:1030-1060). A later `setup_stack_heap_vmstate:3761-3808` flips half assignment.
Therefore source-read closure, target-work completion, full-cycle completion,
physical section contraction and next-cycle half reuse are distinct boundaries.
Strong-phase completion alone is not authorization for either later boundary.

The assignment floor is not an unconditional final clamp: the later
`max_heap > 0` branch (`mem.c:7062-7080`) takes a minimum with the configured
section cap after the maximum with the floor. An incompatible cap can defeat
that lower bound algebraically. A source/configuration proof must show the cap
is compatible or the error path preserves live assignments before contraction.
No reachable native violating state or current failure cause is claimed; C
integer ranges, occupied accounting and overflow handling are further premises.

## Chez And OCaml Applicability

Chez `c/thread.c:270-336` closes dirty/allocation work and handles guardians
before freeing the TC; preserving its segment-creator carrier is a separate
lifetime. `c/schsig.c:48-146` explicitly promotes/splits multi-shot segments and
keeps continuation links/return addresses. This supports keeping a captured
origin distinct from an invocation's active stack. It is not permission to
import Chez's single-owner segment assumption into Gambit's aliases.

OCaml `runtime/domain.c:2262-2344` runs stop hooks, finishes sweeping, empties
minor heaps, finishes marking, orphans ephemerons/finalizers, and repeats if
that orphaning creates work. It checks pending interrupts under
`all_domains_lock` before stopping STW participation. This is stronger than a
one-time "work was empty" observation. The transferable principle is stable,
scoped closure with explicit work transfer/recheck, not forcing OCaml's collector
or heap layout into Gambit. `runtime/fiber.c:641-668` consumes a one-shot stack;
that particular state transition remains inapplicable to ordinary Gambit graft.

## Model, Source Bindings And Handoff

`saved_stack_retirement_window.qnt` imports the unchanged root/arena/isolated
stack composition. It adds a scoped queue census, one bounded possible enqueue,
a valid empty or transferred disposition, and strong/weak/cleanup ordering.
Negative controls expose stale-empty admission, foreign-frame closure mistaken
for Scheme-queue quiescence, and strong-only completion mistaken for full-cycle
closure. Finite roles/epochs are not CPU limits or a replacement scheduler.
The model's transfer and freeze actions are requirements, not claims of source
implementation. Private publication remains abstracted inside the imported
work action; actual producer accounting is an explicit unbound premise.
The pre-cleanup prefix has a ghost stage that follows the existing five
transitions; this profile omits optional later slot reinitialization. A bounded
ghost rank makes every real imported transition visible to fairness without
accessing its unexported storage or adding heartbeat transitions.

The Lean companion states stable-empty, independent foreign/Scheme domains,
non-consuming origin retention, ordered phase composition and complete-origin
last-access lemmas, plus the cap/floor arithmetic condition. None discovers
unregistered roots or proves generated C.

Current-repair handoff:

1. Identify whether the supported call is caller-only migration plus verified
   quiescent retiring queues, or actual busy-queue handoff. Bind each producer
   and each queue class through removal/reset; do not infer emptiness from join
   or `sfun_frame_count == 0`.
2. Inventory save/capture/graft/return, break and GC origin values. Distinguish
   destructive thread-slot move, reusable captured continuation and a root
   already retargeted to the heap; retain metadata and backing only as needed.
3. Bind scanner-active publication, full phase/epoch completion, section floors
   and subsequent allocation to the same candidate/configuration. Keep native
   caller/remote tails and actual pressure acceptance separate.

Changing busy-shrink semantics, redesigning queue ownership, adding an independent
root registry or changing root/continuation ABI belongs in Experimental, not
an assumed low-cost fix. The current Recipe selects none of those redesigns.

## Existing Test Scope, Observed Without Execution

The existing `models/gambit/native/resize_gc_lifecycle.scm:30-40` joins its
worker before shrinking. `continuation_rollover_public.scm:65-84` releases and
joins all parked workers before its shrink, after testing retention through two
collections. They exercise important but different boundaries; neither source
establishes busy-queue disposition or a no-GC shrink with a retained multi-shot
raw origin. Reading these tests is not rerunning them or a new acceptance result.

The window model collapses equivalent per-class empty-read permutations into
one scoped snapshot. This is justified only by its corrected cohort's frozen
producers. The stale pre-freeze snapshot counterexample remains representable.
Only the run class receives the bounded possible enqueue; other classes are
declared empty assumptions, not a physical absence proof. Prior root-model
fault cohorts stutter here instead of repeating their already-checked failure
routes. New window controls and corrected completion are still explored.
