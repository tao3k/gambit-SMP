# Continuation Chunk Publication

## Decision Before Source Edits

- Direction: distinguish the producer's completed local allocation frontier
  from its committed per-processor pointer. This is publication granularity,
  separate from the existing scan-claim and copying-ownership obligations.
- Prior coverage: the continuation-copy lock is already present and documented.
  Do not repeat the rejected missing-lock hypothesis. The selected-source guard
  mismatch was not covered by the previous queue/scan models.
- Value: determine whether a completed chunk can stay private past its intended
  threshold, before attributing imbalance to queue synchronization.
- Expected benefit: earlier availability of complete continuation-copy work
  for other collector workers. No numerical speedup estimate is supported;
  significance depends on continuation-copy work's measured share. This does
  not establish a dominant compiler bottleneck or the native crash cause.

## Current Source Fact

Selected runtime026 `mark_captured_continuation` advances its local `alloc`
while copying a frame. After installing the frame links and root reference,
the chunk-end condition tests `alloc_heap_ptr >= alloc_heap_chunk_limit`.
Only inside that branch does it commit `alloc_heap_ptr = alloc`.
It also commits on function return and on msection transitions. Thus the
original code eventually publishes local allocation progress; this is not
object loss or a proof of an indefinitely stalled collector.

In contrast, `mark_array` tests the advanced local `alloc` against the chunk
limit. `mem.h` defines the normal chunk threshold as 255 words. A complete
frame may exceed that threshold; neither this policy nor the proposed local
guard splits an object or promises a strict maximum chunk size.

This source mechanism is not established as Darwin-only. No runtime change or
macOS-specific speed claim has been made.

## QNT And Extracted-C Results

`continuation_chunk_publication.qnt` models two complete frames with two
abstract words each and a threshold of three. The stale committed-pointer
control violates the desired close-at-checkpoint policy; the local-frontier
protocol exhausts six distinct / seven generated states, depth six, with an
empty queue. This is a bounded publication-policy result, not GC memory safety,
full termination, representation, allocation-failure or queue refinement.

The GNU GCC 16.2.0 source unit extracts the unchanged original condition and
its complete publication block. Complete-frame allocation and chunk callbacks
are mocked; the rest of the continuation-copy function is not executed.
At the actual 255-word threshold it observes:

| Local allocation | Committed allocation | Chunk ended |
| ---: | ---: | ---: |
| 254 | 0 | No |
| 256 | 0 | No |
| 256 | 256 | Yes |

The second row confirms the stale-frontier mechanism. The third is a control
showing that the same unchanged branch works once the committed pointer has
caught up. No real frame representation, queue stealing, OS threads or Gambit
native test is exercised by this source unit.

Receipts: `evidence/model-results/continuation-chunk-publication.json` and
`continuation-chunk-source-observation.json`; the latter's exact output is in
`continuation-chunk-source-observation.log`. The frozen policy counterexample
is `models/gambit/counterexamples/continuation_chunk_publication.json`.
Datalog records the source unit separately from native observations.

## Runtime Admission Still Open

Before applying a local-frontier guard, establish complete-frame visibility,
chunk-link publication, local-cursor exclusion and queue-claim transfer at that
exact checkpoint. Preserve the existing `MISC_MEM_LOCK`; do not create a new
lock or accept arbitrary to-space inputs. Then test the changed path with a
source-bound continuation-heavy atomic regression and compare actual worker
work availability. Complete bootstrap, native suites and Gerbil acceptance
remain independent gates. This candidate is not an accepted runtime patch.
