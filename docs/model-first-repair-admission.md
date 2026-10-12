# Model-First Repair Admission

## Decision Before Runtime Edits

The paper-to-source audit and QNT protocol are prerequisites, not retrospective
justification for an implemented patch. No new Gambit runtime edit is admitted
by this document. A finite positive result is not full collector correctness.

## Priority Reset: Close The Composition Before More C Experiments

The next allocator pthread component experiment is deferred. Existing ALLOC
code-generation and object-compilation receipts remain scoped observations, not
permission to modify or qualify the runtime. Preserve their evidence; do not
promote the candidate patch into the production patch set.

The next model task is the missing interaction between recursively discovered
copy work and the explicit queue/wait protocol. This is not another independent
lock model. Inspection of the current QNT transitions establishes the gap:

| Existing model | Covered | Assumed or missing |
| --- | --- | --- |
| `gc_work_closure` | Two-object cyclic discovery, copy readiness, unique scanning, two abstract phases | Queue acquisition and worker wake/count changes are atomic; no explicit POSIX registration or sequential queue recheck. |
| `gc_queue_wait_composition` | Two producers, two other workers, explicit publication, registration, notification, count restoration and predicate probes | One tail per producer, one phase, coherent visibility; scanning cannot discover another object or publish another tail. |

Checking these models separately does not establish their combined contract.
GHC sections 3.1-3.5 supply copy/scan/active-population obligations, not Gambit's
POSIX protocol. HotSpot's graph traversal and termination discussion supplies
the related producer-accounting obligation. The pinned C implementation decides
which transitions, readers and lock/barrier boundaries actually exist.

Before introducing another source candidate, extend the explicit wait model
with a bounded recursive work graph. Retain the current producer/waiter roles
and both source/proposed policies. Do not replace sequential queue probes with
an all-queues snapshot or identify a forwarding address with copied payload.
The reviewed model contract must include:

- Canonical discovery and a private unfinished copy, independently of queue
  visibility and scan eligibility.
- A scan that discovers further work; a counted scanner may become a producer
  and publish again after another worker has probed or registered for waiting.
- Exclusive ownership of each pending scan region, including the already
  scanned prefix and producer-owned unfinished eager head.
- Existing zero/nonzero wake restoration, unbuffered notification and lock-order
  constraints; no resurrection once the phase's active count reaches zero.
- No termination while reachable local, copying, queued or scanning work remains.
  Only after this one-phase interaction is checked should its exit contract be
  connected to strong/weak barriers and resize/resource retirement.

Require independent fault controls for early payload publication, duplicate
claim, premature producer idleness and omitted wake restoration. Each control
must yield its intended counterexample; a timeout is DENY, not an exhausted
search. The positive checks must cover every retained policy partition and
report safety, deadlock/progress assumptions, complete state-space status,
source/model hashes and raw logs. A bounded graph is not an arbitrary-graph
proof; coherent visibility is not a C weak-memory proof. Keep both gaps open.

The pre-edit review answers for this task are:

1. **Route:** supported by the concrete transition mismatch above and cached
   paper sections; no new native crash cause has been established.
2. **Prior exploration:** reuse both existing checked receipts. Neither contains
   this explicit recursive-copy/wait interaction; do not rerun them unchanged.
3. **Value:** close a correctness admission gap before proposing a repair that
   could lose work or terminate early under an interleaving.
4. **Expected benefit:** stronger repair discrimination; runtime speedup is
   unknown. Model state counts and published parallel-GC results do not predict
   Gambit performance.

This reset is an execution order, not a new checked-model receipt. Native GC,
compiler, bootstrap and Gerbil acceptance remain open. After model checking,
bind every relevant transition to the selected source/configuration, audit the
repair, and only then execute changed-route atomic and full native gates.

For each candidate, answer and record these four questions before source edits:

1. Is it source-backed? Name the exact revision, configuration, transition and
   paper section; separate an observed failure from an injected model fault.
2. Was it already explored? Link the prior counterexample or DENY receipt and
   explain the changed hypothesis. Do not rerun an unchanged rejected route.
3. Is it worth implementing? Identify the actual correctness or measured-cost
   boundary. A possible missed work notification is not automatically deadlock.
4. What benefit is expected? Quantify only from matching measurements; otherwise
   state unknown. Neither a paper nor a model-state count supplies a speedup.

## Current Count-Restoration Refinement

Local cached GHC ISMM 2008 section 3.5 requires reactivated scanners to rejoin
the active count. HotSpot JVM 2001 section 3.3 describes the related active-bit
protocol and a proposed count variant. Neither specifies Gambit's POSIX wait.
Pinned candidate027 `lib/mem.c:6955-6984` supplies that concrete protocol:
decrement under the termination mutex; wait atomically releases it; reacquire;
exit without increment if zero; otherwise increment before returning to work.

The existing `gc_wait_notification` explores one optional spurious wake and the
work-notification handshake. The new `gc_wait_count_restore` isolates repeated
wakes and the race between wake and mutex reacquisition, with two independent
controls: omitted nonzero restoration and forbidden resurrection after zero.
These are deliberately injected faults, not new findings against current C.
The positive policy characterizes existing C, not a proposed implementation.

This is a useful coverage improvement, not an optimization candidate: expected
runtime speedup is unknown and no runtime change is needed for this branch.
The three source-component schedules are complementary correspondence evidence,
not permission to run or release a supposedly repaired collector.

Campaign `gc-wait-count-restore-001` checked both independent controls (15 and
34 distinct states, each with a counterexample). The source characterization
checked safety and weak-fair progress over 31 distinct states, 39 generated,
zero queued, in 35.996 seconds. Reviewed context remained stable. Portable logs,
counterexamples and the receipt are in
`evidence/model-results/gc-wait-count-restore/`. The two manifest/control-boundary
framework tests passed. This is model-only evidence; runtime and release
admission both remain false.

The count-restoration and notification-lock-order receipts are now registered
as bounded `protocol_checked` evidence. Their explicit composition edges and
open obligations are exported to Datalog. Registration does not discharge any
native contract or the combined notification source-repair obligation.

## Conditions Before A Notification Repair

- Extend the protocol to multiple publishers and waiter roles; vary their
  identities instead of assuming processor zero represents every participant.
- Model the actual queue/termination lock order. Reject a fix that introduces
  queue-to-termination nesting against termination-to-queue rechecking.
- Represent condition errors, initialization/retirement ownership, repeated
  wakes and explicitly bounded fairness; do not silently assume them away.
- Compose scan-frontier ownership, copy readiness, eager producer lifetime,
  phase closure and resize membership. State which contract edges remain open.
- Bind abstract publication/acquisition to current C barriers and GNU GCC
  behavior. Coherent QNT transitions do not prove the C memory model.
- Retain #988/#1037/#1038 reports and native failures as separate obligations;
  do not attribute their remaining crashes to a notification hypothesis.

Only then admit a narrowly scoped source candidate and its atomic native
regressions. Full GC/lifecycle tests, bootstrap, Gerbil correctness and finally
performance remain separate subsequent gates. New source revisions invalidate
old correspondence claims until their bindings are checked again.
