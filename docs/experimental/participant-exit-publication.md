# Participant Exit And Post-Exit Publication

## Mechanism Under Investigation

Collector-membership exit has two different exclusion obligations:

1. Incoming requests and participant removal must agree on the participant set.
2. A removed participant's later cleanup no longer inherits exclusion from a
   collector which did not enlist it.

The second does not follow from solving the first. This is an Experimental
protocol study, not a finding that the current candidate races or a decision to
add a runtime lock. Gambit's generated C, FFI and continuation semantics remain
assets to preserve.

## Source Evidence And Transfer Limits

Pinned OCaml `domain.c`:1730-1786 explicitly separates participant-set exclusion
from cleanup after removal. Domains can leave a callback while other domains
are still in it; a barrier is needed for updates which must precede mutator
reads. Cleanup after safe participant removal may run alongside a later STW,
so shared mutation there requires additional synchronization.

At :1830-1924 the requester takes `all_domains_lock`, publishes request fields,
snapshots the participant set and sends interrupts. At :2262-2352 termination
finishes/orphans work, rechecks completion, then uses the same membership lock
to exclude a newly queued request before removal. Its wait loops release that
lock to service collectors. The useful unit is a **closed work / request / member
contract**, not holding one mutex while waiting for everyone else to finish.

Chez provides a related lifetime countercheck, not the same membership algorithm.
`thread.c`:274-335 closes local work and retains `thread_gc`; :76-108 recycles
that carrier and resets its state for a new thread. `gc.c`:1042,1159,2216-2217
redirects work when a segment creator's `tc` is absent. A stable creator pointer
is therefore a collector routing carrier, not permanent authority to execute on
the original thread. Copying its address stability into Gambit would not prove
OS-thread/VM identity or reclamation. Nor does this source imply that every
Gambit carrier must live forever or use a new generation-tag ABI.

All references use the pinned `vendor/ocaml` and `vendor/chez` submodules listed
in the [current Recipe](../current-repair-research.md). They do not establish
Gambit's current overlay, weak memory, supported foreign entries or native cause.

## Reused Model And Exact Added Scope

[The QNT projection](../../models/experimental/participant_exit_publication.qnt)
imports `public_vm_retirement_composition` unchanged. It does not copy registry,
reader-lease or memory/resource release logic. Exclusive host ownership and
successfully joined direct OS users remain assumptions of that imported model.
This projection does not manufacture successful failed-join recovery.

It adds one finite collector request, work reopening during orphaning, a
membership-snapshot gate and a distinct post-exit shared-metadata guard. The
guard is an abstract critical-section contract: the study does not select a
mutex, immutable-publication protocol, RCU, new collector or TLS policy.
The shared metadata is assumed independently live; it is not a root inside
freed VM memory. Roots, descriptor completeness, lifetime of that metadata and
the memory-order bridge still need separate source arguments.

The repaired model permits a request on either side of removal. A request that
enlisted the member must finish before it leaves. A later request excludes the
member, but cannot overlap the cleanup's protected shared mutation. Work created
by orphaning must be drained after the earlier empty census. None of these
conditions requires whole-heap draining or serializing all mutator execution.

Three omission controls distinguish the boundaries:

- `initSnapshotWithoutGate`: a request enlists the member between validation
  and departure; the member leaves without acknowledgement/completion.
- `initOrphanWithoutRecheck`: orphaning reopens work after the old empty census;
  departure keeps that work outstanding.
- `initCleanupAsStwProtected`: the member has left, a later collector excludes
  it, and its cleanup write overlaps the collector read critical section.
  This is a logical overlap witness, not a reproduced corrupted native load.

The [Lean companion](../../models/experimental/lean/ParticipantExitPublication.lean)
reuses `WorkAccounting` and its root/mutation contract. Its five conditional
lemmas distinguish empty work from absent requests, reopening from a current
census, membership removal from publication exclusion, and rooted data from
exclusive mutation. They do not prove inductive refinement of the whole QNT
machine or C implementation. Atomic protocol actions are sequentially consistent;
finite weak-fair progress assumes the collector and ordinary cleanup return.

## Milestone And Current-Repair Boundary

This projection supplies one previously assumed part of the larger Experimental
retirement story, not a complete architecture. An implementable mechanism still
needs full producer/root coverage, actual C acquire/release ordering, lock/callback
effects, allocation-failure rollback, cancellation and retained-carrier bounds.
Only then is a coordinated prototype and native/cost qualification justified.

The current 9/12 owner can reuse the falsifiers to audit an existing source
boundary. A path which already drains all users needs no new guard merely
because this model has one. Conversely, a single normal collective return does
not qualify all exceptional or post-membership cleanup paths. No current source,
source lock, native manifest, checkpoint, budget or milestone count changes here.

[Validation and retained failed attempts](../../evidence/research/participant-exit-publication/validation.md)
bind the checked source identities. The existing Scheme research facts expose
the new finite interfaces but retain missing source-composition bindings and
all native obligations.
