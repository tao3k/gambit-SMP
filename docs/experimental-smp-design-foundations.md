# Experimental SMP Design Foundations

## Purpose And Status

This is reference-architecture research: extract mechanisms from pinned Chez
and OCaml source, connect them to existing Gambit evidence and models, and make
the remaining transfer assumptions explicit. It does not select a replacement
collector or a runtime patch. Native qualification continues independently;
historical 6/12 progress is neither reset nor advanced by this document.

The working architectural hypothesis is that Gambit's difficulty lies in
contracts distributed across generated frame/root metadata, moving objects,
scheduler/GC service, VM/processor/C activation lifetimes and publication
ordering. Existing evidence shows these contracts interact. It does not prove
that every failure has one cause, or that CPS, first-class continuations or a
shared heap are inherently incompatible with reliable parallel execution.
"Historical integration debt" describes this research hypothesis, not a claim
about the original designers' intent.

In particular, TFIB names a threaded Fibonacci stress workload, not an
allocation subsystem. STW is a synchronization strategy, not itself a defect.
Same-VM Scheme threads, OCaml domains and independent Gambit VMs are different
boundaries. Success at one does not establish isolation or progress at another.

## Reproducible Sources

| Source | Exact revision | Evidence boundary |
| --- | --- | --- |
| Gambit | `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` | Vendor baseline; current repaired overlays have separate source locks. |
| Chez | `41d5ffca7a07cbfc8807e719dedcc70ed74811cd` | [Source inventory](../models/chez/source.json) and later subject-specific source maps. |
| OCaml 5.5.1 | `46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91` | [Source inventory](../models/ocaml/source.json); selected sections reviewed, no OCaml runtime requalification. |

The gitlinks and [.gitmodules](../.gitmodules) are the source dependency
contract. Restore them with `git submodule update --init --recursive`; branch
names and moving release tags do not replace the pinned commits. Reference
source is not a disposable build fixture. No copied source tree or cache path
is required by this document.

Only Gambit uses the user's fork. Its unchanged baseline commit is published
at `tao3k/gambit:research/pinned-gerbil-gambit`; the fork's `master` is not the
research pin and was not changed. Chez and OCaml retain their upstream URLs.

The [parallel-GC comparison](parallel-gc-design-comparison.md),
[transfer boundary](gc-design-transfer-boundary.md),
[paper/source obligations](paper-source-obligations.md) and
[existing-model audit](smp-incremental-architecture-audit.md) remain the detailed
evidence. Paper accounts explain designs; pinned source determines what the
reviewed implementation does. A historical source map is not silently rebound
to the latest repaired candidate.

## Experimental Questions

Each family below identifies a reference mechanism, existing model assets,
missing premises and a Recipe brief. These briefs are research inputs for the
existing registry/Session/Recipe system, not new executable Recipes, mandatory
Agent steps or claims of native acceptance.

### Participation During Blocking And Retirement

OCaml's [domain contract](../vendor/ocaml/runtime/domain.c) at lines 84-153
registers participants before mutator execution and transfers STW service to
a backup thread during blocking sections. Lines 1740-1810 describe safe
participant removal and why join/leave waits must release the membership lock.
Importantly, no-mutator exclusion depends on the appropriate barrier, not just
being inside a callback called "STW".

Gambit's existing `gc_sync_membership.qnt`,
`scheduler_gc_root_cohort_composition.qnt` and `sync_wait_handshake.qnt` already
cover parts of membership, roots and service obligations. Their finite
participants/epochs and scheduling assumptions are not an OCaml implementation
model. The [audit](smp-incremental-architecture-audit.md) records existing
composition results and their limits; do not create another equivalent model.

Recipe brief: compare who owns GC service before blocking, during a wait,
after wake and during retirement. Bind roots and outstanding requests to that
ownership. Check lost service, double service, late join and premature exit as
negative schedules. Before transfer, inspect all foreign blocking/reentry paths
and failure rollback. A backup OS thread is an option with resource and handoff
costs, not the selected Gambit fix.

### Forwarding Identity Versus Payload Readiness

The [pinned comparison](../evidence/parallel-gc-source-comparison.json) maps
Gambit `lib/mem.c:3570-3631`: destination claiming can precede payload copying.
Chez's [hybrid source map](../models/chez/hybrid-source-map.json) instead binds
generated copy-body publication and initialized marking metadata. These are
different protocols; changing the order of one store is not a justified port.

Reuse `models/library/gc/ForwardingVisibility.qnt`, `WorkObligations.qnt` and
the existing Chez hybrid controls. Their atomic visibility and bounded objects
do not establish machine-level ordering, every object shape or concurrent
consumer behavior.

Recipe brief: classify identity readers separately from payload scanners and
producer-owned link readers. Show the readiness obligation for each actual
consumer, including frames and weak-reference phases. Record whether the
proposed mechanism is a publication fence, delayed visibility or an ownership
rule. Require source correspondence before proposing a C change; compare its
extra loads/fences and copy contention rather than assuming it is cheaper.

### Conserved Work And Global Completion

Chez [gc.c:137-185](../vendor/chez/c/gc.c) routes remote referencing objects to
the target segment's owner for re-sweep. Its sweeper protocol at lines
3164-3280 combines running-worker accounting, send/receive and counted wake.
Repeated scans are legal there. Gambit's comparison maps completed chunk
publication at `lib/mem.c:3250-3308` and stealing/completion at `6665-6774`.

Reuse `WorkObligations.qnt`, `OwnerHandoff.qnt`, Chez resweep/card controls and
Gambit's queue/wait compositions. The common contract conserves private,
outbound, inbound and scanning obligations; it does not require fixed owner
routing or at-most-one scan across implementations. Existing recursive safety
and rank proofs must not be imported into a changed wait transition system
without checking their coverage.

Recipe brief: expose work that can exist while queues look empty, including a
producer about to export. Compare owner routing with chunk stealing under the
same reachability/completion obligation. Account for resweeps, remote traffic,
idle transitions and wake costs. Neither an empty queue nor a worker count
alone proves completion or explains a native timeout.

### Heap Ownership Across Lifecycle Changes

OCaml [shared_heap.c:148-207](../vendor/ocaml/runtime/shared_heap.c) explicitly
orphans swept pools under a global pool lock and adopts them into another
owner's unswept lists, updating ownership and statistics. This is shared-heap
ownership transfer, not Erlang-style shared-nothing. Chez's segment-owner
contract likewise describes reassignment when an allocating thread has no
associated sweeper.

Reuse `OwnerHandoff.qnt`, Gambit's membership/resize compositions and cleanup
lifecycle models. They are partial contracts: they do not yet compose every
allocator state, retained root, failed join and concurrent collection.

Recipe brief: distinguish execution owner, allocation owner, scanning owner and
resource lifetime. Inventory what remains reachable after an owner retires and
what establishes safe reclamation. Test lost/duplicated ownership and cleanup
before quiescence as model counterexamples. Source-level allocation failure,
join failure and orphan/adopt races remain required transfer premises.

### Roots, Execution Context And Foreign Reentry

OCaml [minor_gc.c:630-722](../vendor/ocaml/runtime/minor_gc.c) includes promotion,
local-stack/register root scanning and a split arrival/leave barrier. Writes
before arrival are ordered before departure; code after arrival may race with
mutators. This is a concrete boundary for reasoning about root visibility, not
proof that a runtime's entire callback is protected.

Reuse `RelocationEpochRoots.qnt`, `ContinuationVMTransfer.qnt`,
`ForeignPayloadPublication.qnt` and Gambit's stack/return-address models.
Chez's heap-stack/thread-context design is useful comparison material, but
its activation/deactivation implementation and Gambit's foreign C activation
mapping still require detailed review. Continuation migration must not be
described as inevitable TLS corruption without a concrete failing protocol.

Recipe brief: map root ownership and publication at Scheme/C entry, suspension,
GC service, migration and return. Separate movable Scheme roots, opaque foreign
payload and native resources. Check stale roots and return-owner mismatches;
do not infer independent-VM sharing permission from a same-runtime thread test.

## Reuse Before Extension

The inventory already contains collector-specific and shared contracts. Start
with their source maps, assumptions and retained counterexamples rather than
counting model files or rebuilding a second reference library. An OCaml source
inventory is not an OCaml QNT model: currently no faithful full-domain/collector
refinement has been established here.

Existing Chez hybrid, resweep/card and remote-accounting Recipes are usable
research assets under their recorded locks and budgets. Existing experimental
concurrent-GC and relocation/lifecycle campaigns have distinct completion
boundaries. A later passing sub-profile does not erase an incomplete parent
campaign or authorize a current native binary. See the linked audit for the
recorded distinctions; this turn did not rerun those campaigns.

New evidence/associations belong in the existing Scheme DSL and registry.
Python remains the host observer, transport and execution adapter; reference
research does not require a new Python inference engine or workflow interface.
Return facts, applicability conditions, contradictions and expandable references,
not a prescribed next action. A failed route may be revisited when its premises
change; the changed premise and old failure must remain visible.

## Research Milestones And Acceptance

| Deliverable | Closure criterion | Not established by it |
| --- | --- | --- |
| Source/mechanism map | Pinned sections, identities, assumptions and unreviewed obligations for each comparison. | Full source audit or runtime correctness. |
| Model correspondence | Reuse existing transitions; extend only a demonstrated semantic gap; positive and negative controls share the stated scope. | Source refinement from model names or manifest composition metadata. |
| Reusable comparison Recipe | Registered evidence connects reference mechanism, Gambit observation, model scope and transfer conditions without cache dependencies. | Permission to execute, selected architecture or performance gain. |
| Optional Gambit design proposal | Costed bounded change, compatibility/rollback analysis, affected native obligations and original reproducer identified. | Acceptance before exact-candidate native results. |

These are research discussion milestones, not an enforced Agent sequence or a
new blocker for the native owner. No expected speedup is quantified yet. A
candidate must measure throughput, pause distribution, GC CPU, memory, startup
and coordination cost on exact-source native runs with machine-adaptive
parallelism. Faster model checking is not faster GC. Reliability and stability
cannot be obtained by serializing execution, disabling SMP or widening a
performance threshold.

A nursery redesign, collector replacement or shared-nothing VM architecture
requires a separate experimental proposal: object sharing, continuation/FFI
semantics, migration cost and compatibility cannot be assumed away. The first
research milestone can be useful without choosing any of those large changes.
