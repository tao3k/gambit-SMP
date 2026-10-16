# Section-Owned Stack Undo

## Review Before Implementation

| Question | Evidence-Based Answer |
| --- | --- |
| Relevant path? | Undo restores `prev_msection` from first-break payload, then that section can enter the single undo pool push. Pool successor separation did not eliminate the native first-stack-write failure. |
| Already explored? | Capture invalidation and GC pool reset are present. The failed pool-link layout candidate is retained, not inherited. The prior model assumed valid saved section identity and did not distinguish first-break payload from owned undo metadata. |
| Worth changing? | Preserve the O(1) fast path while removing raw allocation ownership from scanned stack storage. No lock, section discard, SMP disablement or defensive-abort substitute. |
| Expected benefit? | Protection against a separately labeled saved-payload alias envelope. The first corrupting native writer remains unknown; no speedup or complete repair claim. |

## Model And Source

The existing allocator model adds a distinct first-break saved-pointer fault
envelope. The in-band control reaches an invalid selected section in three
states. Section-owned metadata passes the same envelope in three states.
The original ownership/generation/GC protocol exhausts 6,048 states with safety
and weak-fair completion. The sealed framework and ASCENT pass in 35.336 child
whole seconds. These are conditional model results, not native qualification.

Only `include/gambit.h.in` and `lib/mem.c` differ from the heap-identity parent.
Darwin GNU stores previous section, previous break and previous frame pointer
in the raw section header. Eligibility is cleared at fresh stack selection,
initial setup, GC stack replacement, continuation move and the existing capture
invalidation macro. The first-break NEXT link still represents the continuation;
the raw allocator restore no longer reads it as owned undo state.
The original in-band pool implementation is retained; the failed pool-layout
candidate is not silently combined into this successor.

Linux keeps the original layout and save/restore branch. Allocation extent
continues to use `sizeof_msection`; every ABI consumer needs fresh bootstrap.
Three saved raw values remain O(1); no throughput benefit has been measured.
Direct raw-header/PSTATE corruption and stale generation remain distinct gaps.

## Native Qualification

The framework reuses the existing full source workspace under an exclusive
lease. Exactly two locked files were replaced; a new custody record binds its
state, not old executables. No extra full fixture was created. The current
GNU Bazel profile and all concurrency flags remain enabled; build workers are
chosen from available host capacity. Both native bootstrap passes now complete:
254.307 stage seconds, 237.819 make seconds, exit zero and exact phase inventory.
Every declared step, including final ASCENT review, passes. The old sealed
worker nevertheless changed the overall result to DENY using its original
300-second total-wall deadline during owner teardown (419.364 outer seconds).
The owner exited zero, was reaped and completed every review; no native timeout
or failed stage is recovered by correcting this accounting decision.

That obsolete decision is now History, not an active gate. The checked
completed-producer reference binds its original receipts, successful journal,
final ASCENT answers and normally reaped owner, and explicitly records
`supersedesHistoricalDecision`. The current runner uses the last real
progress-stage review window for teardown. Wall-policy runs retain their
original limit. `producer-decision-rules.ss` derives retired versus active
historical decisions and requires a checked current producer. Removing the
supersession evidence revokes current admission; a new native DENY remains
missing even when the historical accounting decision is retired.

The complete compiled stress consumes the existing artifact through that
updated sealed framework. No second bootstrap was performed to repair the
framework verdict. Current stress is DENY: two pass, tfib fails with signal 11,
and `thread_interrupt2_stress` times out at its unchanged 300-second window.
Native stage time is 306.829 seconds, outer time 336.862 seconds. ASCENT returns
the old accounting decision as retired, current producer as admitted and the
new stress as missing. These are distinct decisions, not a blanket green.

The candidate is not accepted and no unchanged stress retry is admitted.
The exact matching image again faults at `___stack_limit +140`; x0=524292 has
alignment remainder 4. The write site joins both pool and fresh allocation
paths. A PC at that site is not proof of the pool producer, and the current
incident lacks the selected pointer/semispace snapshot needed to bind it.
That gap must be resolved before another layout repair is proposed. The owned
frame-pointer snapshot also requires correspondence with break-handler NEXT
advancement; the additional timeout does not establish that as its cause.

**Milestone remains 5/12.** Seven open gates: interpreted stress, compiled
stress, Registry lifetime, lifecycle faults, GC/FFI, Gerbil correctness and
release performance. This source candidate is neither accepted nor published.
