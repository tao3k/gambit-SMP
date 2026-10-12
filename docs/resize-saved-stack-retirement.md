# Saved continuation storage and retirement

## Source facts

The source authority is the pinned submodule with the cumulative
`startup-sync-flag-handoff` overlay and lock, not a runtime cache.

`___THREAD_SAVE` places a frame reference in the current thread's continuation.
The saved reference can point to the raw stack. Capturing the continuation is
not equivalent to heap-materializing it, relinquishing processor execution or
publishing it to another run queue.

`##thread-migrate-to!` saves the thread, inserts it into the target queue, then
uses a fixed busy loop before clearing the source processor's current-thread.
The target can observe the publication before that execution ownership clears.
The existing scheduler can select queue entries under processor/thread locks;
a time delay is not an acknowledgement protocol.

`mark_captured_continuation` recognizes a raw stack frame, copies frames into
heap storage under the memory lock, leaves forwarding references and rewrites
the captured reference. Seeing a GC request is not evidence that every reachable
captured frame has completed this process.

`___cleanup_mem_pstate` releases still objects, RC state and an initialized scan
lock. It does **not** directly free the VM's stack msections. VM cleanup frees
the shared msection set separately. Accordingly, this audit does not claim that
processor cleanup directly frees the saved frame. Reassignment, reuse, VM teardown
and collector treatment of retired stack sections require their own refinement.
The new model's `releaseStorage` abstracts invalidation of backing storage, not
a claim about a particular already-observed C free.

`mark_processor_scmobj` and `mark_vm_scmobj` scan Scheme structures. Root retention
and runnable ownership are distinct: an object remaining reachable does not
prove a retired requester's continuation will resume.

## Model and controls

`resize_saved_stack_retirement.qnt` separates capture, execution detachment,
queue publication, scan start, frame copy, retirement, storage release and
requester return. A scan borrows donor storage until copy completes.

The queue-only negative policy permits retirement before frame materialization;
the publication-first policy exposes a queued thread while execution still
belongs to the donor. These are unsafe design controls, not claims of newly
observed native failures. The fixed design requires execution detachment before
publication and materialization before retirement/release. It retains the
original source lock as context without claiming implementation of the design.

The design assumes the saved continuation is rooted during handoff and collection
has exclusive access to the relevant backing frames. Those assumptions are
explicit source-refinement obligations. The existing thread-drain model also
requires admission closure, pinned-thread cooperation and running/queued/parked
ownership transfer; this model does not silently discharge those conditions.

## Native requirements before implementation admission

- Resume donor-origin continuations before and after retirement, including
  nested frames and shared continuations, in interpreted and compiled modes.
- Force GC during capture, queue handoff and repeated donor-slot reuse; verify
  frame contents and exactly-once continuation return rather than only markers.
- Bind actual frame pointers, forwarding/copy completion and storage lifecycle
  to the selected source and runtime identity.
- Inject transfer/GC/join failures and verify rollback or quarantine retains
  roots and storage without double release.
- If storage is retained instead of copied, establish a finite reclaim condition
  after borrowers finish. Permanent retention is not full lifecycle correctness.

The known unchanged unpinned resize timeout is not rerun until a source handoff
repair exists. Full native coverage, bootstrap and Gerbil acceptance remain open.

## Exhaustive design evidence

TLC reproduced queue-only invalid storage in 16 distinct states and
publication-before-detachment in 12 distinct states. The fixed design passed
safety and temporal completion over 13 distinct / 18 generated states. These
checks took 24.048, 25.359 and 29.417 seconds including backend startup.

The source-bound portable receipt is
`evidence/model-results/fixtures/startup-sync-flag-handoff/saved-stack-retirement-contract/receipt.json`.
The Datalog bundle retains both controls and five unresolved obligations. Native
and release admission remain false. No candidate source change or runtime test
is inferred from this design result.
