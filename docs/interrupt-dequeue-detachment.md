# Detached Interrupt Dequeue

## Source Defect and Model

`___get_next_high_level_interrupt_pstate` removes the processor queue's head
but previously retained the extracted vector's successor link. The processor
queue still owns that successor. When `##other-interrupt!` forwards the extracted
request into a thread queue, `##thread-intr-propagate!` assumes it is a detached
node and preserves its link. The successor therefore becomes reachable from
two queues. Thread resume does not recheck each imported successor's recipient,
so wrong-thread and repeated callback execution are possible.

This is a concrete source ownership defect consistent with the separately
observed same-request duplicate failure. It is not a unique causal explanation
for every historical SMP or GC failure.

`thread_interrupt_queue_detachment.qnt` models two linked request identities,
processor extraction, forwarding, and independent processor/thread dispatch:

- Old policy reproduces duplicate delivery: 12 generated / 9 distinct states.
- Detachment preserves recipient and single-delivery safety and fair complete
  delivery: 10 generated / 7 distinct states.

Processor and thread queue operations are abstract atomic. Arbitrary lengths,
physical memory ordering, GC roots, exceptions, acknowledgment and target
retirement remain explicit obligations. The source/failure-bound checker
receipt is registered in `evidence/protocol-bundles.json`.

## Source Repair

The 17-file source lock and cumulative overlay are in
`evidence/fixtures/interrupt-dequeue-detachment/source.lock.json` and
`patches/fixtures/interrupt-dequeue-detachment.patch`. Mechanical application
to the pinned submodule blobs reproduces all authority hashes.

Only `lib/setup.c` changes relative to locked migration publication. The
dequeue clears the extracted request's link under the existing processor lock,
after publishing the successor as the new queue head and before the memory
barrier/unlock. It does not suppress a callback, add an arbitrary retry,
reset request results, or weaken test assertions. The Scheme thread dequeue
already follows the same detachment discipline. Prior public thread fields
and processor layouts remain unchanged by this C repair.

## Actual Native Results

The identified isolated GNU GCC core rebuild passed in 2.093941 seconds.
This is incremental, not a cold/full-bootstrap speed claim. Source/binary
identity checks surround every native run; population is host-detected.

- Unchanged compiled migration: 0.531116 seconds, PASS, all host transitions
  and per-round forced GC.
- The exact same strict request-ticket fixture that failed on the parent:
  three compiled runs PASS at 0.525813, 0.012872 and 0.013455 seconds. Each
  reports all 1,152 requests for the detected host. Unique send-token and
  per-request callback tickets prevent the earlier marker-only false green.
- Original interpreted `resize_still_reuse`: DENY at 30.005169 seconds.
  Epochs 0 through 6 completed grow/join/shrink/GC; epoch 7 reached
  grow-return but not worker-joined. The process group was killed/reaped by
  the original 30-second cap and is quiescent. No unique timeout cause is
  claimed from its last log line.

The combined native receipt is DENY. The fail-fast runner did not execute the
following table-GC control. No complete native, bootstrap or release acceptance
is claimed. Do not repeat the unchanged timeout or widen its cap.

## Remaining Closure

The duplicate request path now has model and matched-fixture native evidence,
but processor retirement/thread draining is still unimplemented. The saved
stack retirement and migration-retirement-cancellation models explicitly keep
those requirements open. Audit caller and queued-worker ownership through
grow/shrink before changing source, then return to the denied reuse fixture.
Complete upstream suites, two-pass bootstrap, native Datalog/source binding
and Gerbil build/test remain required for the full goal.
