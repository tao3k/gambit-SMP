# GC Queue And Wait Composition

## Pre-Code Review

This checks a previously open interaction, not another native run of a denied
candidate: multiple waiters, independent queues, sequential predicate probes,
unbuffered one-waiter notification, and activity-count restoration share one
state machine. The prior notification, count and lock-order models check their
own boundaries; their local positives do not prove this composition.

The purpose is correctness admission for a possible notification repair.
Expected performance benefit is unknown until identity-matched native evidence
exists. No historical compiler crash, forced-GC failure or end-to-end speedup is
attributed to this hypothesis. No runtime change is admitted here.

## Paper And Source Mapping

Cached GHC ISMM 2008 section 3.5 and HotSpot JVM 2001 section 3.3 provide the
work-producing population obligation. Current candidate027 `mem.c` determines
the implementation protocol:

- `end_heap_chunk:3428-3456`: copied tail/link publication under Q, two barriers,
  unlock Q, then signal. Publication does not complete a pending eager head.
- `scan_movable_objs_to_scan:4502-4536`: local queued work may be drained by its
  own producer; missing a helper notification does not automatically deadlock.
- `mark_reachable_from_marked:6926-6948`: pop under Q and release Q before scan.
- `mark_reachable_from_marked:6955-6984`: decrement under M, register/unlock in
  wait, reacquire and test zero, restore activity only when nonzero.

The proposed combined policy probes each Q sequentially while holding M and
takes M for signalling only after the producer has released Q. Publication can
occur between probes; the model must not assume an atomic snapshot of all Qs.
The current-source policy does not add either proposed operation.

## Coverage And Controls

Two producers each export one fully copied tail before finishing their own
eager head. Two additional workers can wait. Every worker, including producers,
can scan either queue, wait, resume or be last to terminate. Queue-locked pop
must claim exactly once; scanning happens outside Q and M. Signals select only
one currently registered waiter. Each worker may receive one spurious wake.
Role labels are symmetric within their classes: no transition uses ordering,
arithmetic or a distinguished zero identity. This finite-role symmetry is not
a proof for arbitrary populations or source processor-dependent operations.

The positive initializer explores current and proposed policies. Both require
exact counted activity, unique tail scanning and completed heads/tails before
termination. Only the combined policy requires that a worker not register
against queued work whose notifications have already completed. That condition
does not require every waiter to wake for a single work item.

Three independent controls retain source missed-notification opportunities,
deliberately omitted activity restoration, and premature producer idleness.
The latter two are model injections, not findings against current C. Lost
notification is not equated with global deadlock; source completion must still
be checked through producer drain and protected termination signalling.

## Remaining Admission Gates

This is a coherent, one-phase, two-tail protocol. Arbitrary recursive graphs,
repeated publication, generational/weak phase transitions, allocation failures,
resize membership, condition errors, initialization/retirement and C weak memory
remain explicit open contracts. The source predicate and all relevant lock sites
still require refinement. The models do not authorize full native execution or
release. Native atomic regressions, full lifecycle/GC tests, bootstrap and Gerbil
correctness must precede any performance claim.

## Campaign History

Campaign001 was rejected during parsing because the new model omitted its state
variable declaration. It did not explore schedules or execute Gambit. Its DENY
receipt remains in the local campaign directory. The corrected model passed
`quint typecheck` before Campaign002 began; no runtime source was modified.

Campaign002 found notification and restoration counterexamples but the lifetime
control exceeded the unchanged 90-second model-check budget. It remains DENY;
no positive check or complete admission is claimed. Review found that its
lifetime property waited until global termination to detect premature producer
idleness. The refinement instead checks counted producer lifetime continuously,
which strengthens the positive invariant rather than reducing the population.

The refinement folds a single read-only Q critical section into an atomic
predicate probe: same-Q publication/pop cannot occur while Q is held; other-Q
operations commute with that read and M remains held throughout. Individual
queue probes are still separate, so publication between probes is retained.
The lock-order contract remains explicit. Completed scan owners and an unused
previous-attempt `found` flag are cleared; neither influences future transitions
or the asserted properties. There are still two publishers, two extra waiters,
both policies, one optional spurious wake per worker and the same timeout.
This is an abstraction/refinement obligation, not an implementation proof.

Campaign003 found all three intended counterexamples: 703, 1,560 and 1,506
distinct states before violation, respectively. The positive characterization
then timed out at 90.213 seconds and remains DENY. Its log begins an intermediate
temporal check at 296,413 distinct states, not a complete-state-space result.
Four framework boundary tests passed; they are not the missing positive proof.
The manifest is registered with no checked receipt, so its source/refinement and
native gates remain open. Compact portable summaries preserve all three rejected
campaigns in `evidence/model-results/`; the raw receipts stay identity-bound.

Before another attempt, inspect the supported toolchain configuration for
final-only temporal scheduling or sound complete policy partitioning. All
policies, producer/waiter roles, optional wakes and the 90-second per-check
budget must remain covered. Never substitute state-count progress for success.

The installed Quint 0.33.0 `TlcRuntimeConfig` exposes only `maxHeap`, `stackSize`
and `workers`. Its actual Java invocation forwards no additional TLC arguments.
Therefore an undocumented `lncheck` JSON field would be ignored, not an effective
optimization. Do not add it, patch the installed tool or rerun on that basis.
Complete policy partitioning is the next candidate: policy is immutable, so the
union of source and combined initial-state explorations can cover the same model
without discarding either branch. That requires explicit per-partition receipts
and an admission rule that rejects any missing partition, not a successful
single-policy run presented as the whole protocol.

Campaign004 implements this partition through explicit `protocolInitializers`:
`sourceSafe/initSource` and `combinedSafe/initCombined` each check the identical
`safe` predicate and `progress` property. Policy is assigned only by initializers
and never changes in a transition; the union of their initial states equals
`init` exactly. The model, roles, controls and per-check timeout are unchanged
apart from adding the two aliases. All five checks are required by receipt
admission; missing/duplicated partitions, swapped initializers and rejected
rows remain DENY. Other characterization manifests retain their default `init`.

Campaign004 completed all five checks with stable reviewed context. Both
positive partitions exhausted their queues and completed final temporal checks:

| Partition | Distinct states | Generated | Queued | Seconds |
| --- | ---: | ---: | ---: | ---: |
| Current source policy | 169896 | 538629 | 0 | 12.972 |
| Proposed combined policy | 185975 | 539513 | 0 | 12.768 |

All three negative controls also yielded counterexamples. Their state counts
are diagnostic stopping points, not exhausted positive exploration. Portable
logs, traces and the full five-check receipt are in
`evidence/model-results/gc-queue-wait-composition/`. The model receipt now closes
the bounded protocol-check gate, not the source-refinement, C-ordering,
resource/resize or native gates. Wall time differences versus earlier campaigns
are not attributed solely to partitioning or claimed as runtime speedup.

After publication, 22 focused partition/receipt/control tests passed. Current
fact export has 32 protocol models and 32 checked receipts. The real ASCENT
audit in `.data/gc-queue-wait-partition-audit-001/receipt.json` reports those 32
verified protocols while preserving eight blockers and five native gate classes:
three-flags artifact identity, GC regressions, VM resize/shutdown, compiler and
bootstrap, and Gerbil build/full tests. This is a successful audit, not a
successful runtime qualification.

The complete Evidence CLI attempt with the new partition inputs still failed
in the ASCENT cross-round history query with status -1 (`scheme request rejected`),
after main catalog inference. No complete Evidence receipt was produced for
`gc-queue-wait-partition-index-001`. Do not replace this failure with the separate
successful audit or retry unchanged history input/backend. The next runtime
decision must respect source-refinement, memory-order and lifecycle blockers;
these remain open even though finite queue/wait safety now has evidence.
