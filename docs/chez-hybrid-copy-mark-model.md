# Chez Hybrid Copy/Mark And Gambit Repair

## Fixed Source, Not A Reputation Claim

The study uses Chez revision `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`
in `vendor/chez`. It does not establish when each optimization was introduced
or assert that the checkout is today's upstream HEAD. The explicit source/model
map is `models/chez/hybrid-source-map.json`.

The pinned collector chooses between copying and marking. Marking can preserve
an object's address and promote its segment; sparse/compact and generation
conditions affect the choice. This is not simply a copying collector with one
universal "faster" path. For `space_new`, a locked object may remain in place
while its movable neighbor is copied. The presence of `marked_mask` alone must
not select the neighbor's relocation mode; `use_marks` has a different role.

## Executable Finite Contract

`models/chez/HybridCollection.qnt` has two live objects, four alias root slots,
five mode profiles and two possible segment owners. The mixed-new profile's
two objects share one segment and one owner. It separates private preparation,
initialization, destination-address writing, forwarding-marker publication,
mark metadata, queued/scanning obligations, root updates and completion.

The contract reuses `library/gc/WorkObligations.qnt` for canonical references and
absence of outstanding work. It checks mode selection, bitmap/payload visibility,
exclusive forward/mark representation, alias identity, owner permission and
conservation of two work obligations. Compactness/eligibility are abstractions;
it does not reconstruct the collector's density thresholds or generation math.

Five mutations have independent wrappers: early forwarding, early bitmap
publication, bitmap-driven mode selection, wrong-owner processing and early
completion. No rule depends on a test name, CPU count or expected outcome.

The existing sealed v2 Recipe is
`evidence/research/chez-hybrid-copy-mark/control.recipe.json`. Its locked Gambit
source step binds the actual foreign-origin/public-cleanup comparison candidate.
That step is existing lane scaffolding, not execution of Chez or Gambit GC.
No Python feature producer, loader or inference engine was added.

## Actual Results And Failure Costs

`.data/chez-hybrid-copy-mark-003` records a complete PASS for this finite safety
campaign: 685 distinct checked states, zero queued states, five decoded negative
controls and terminal ASCENT evaluation. All declared inputs stayed stable.
Parent time is 44.262/60 seconds; each step retains its original 15-second cap.
There is no temporal/fairness or source-refinement admission.

The preceding attempts remain immutable: `-001` rejected stale completed-source
reuse before model checks (5.739 seconds); `-002` materialized the current locked
candidate but found a real `exclude` set-argument type error (13.196 seconds).
`-003` changed the model to use set operands and added explicit conservation.
The recorded prior links identify each causal change. These are distinct input
versions under unchanged per-attempt caps: their combined parent cost is
63.197 seconds, not a claimed single cumulative 60-second campaign.

Local `.data` results are recheckable observations, not automatically committed
evidence or a native acceptance certificate. Original Gambit failures, negative
receipts and budgets are neither removed nor reclassified.

## How This Helps Gambit

Chez owner routing avoids a competing sweeper copying from the same segment.
Gambit's forwarding CAS and chunk stealing use different ownership boundaries.
The useful question is therefore not "replace Gambit's GC with Chez's", but:

- Which operations may observe a forwarding destination before its payload or
  producer-owned links are ready, and which protocol makes that safe?
- Can copy/scan/private/outbound work disappear when a participant becomes idle
  or a VM/processor retires?
- Does transferring a scan obligation preserve the canonical object identity
  without imposing Chez-style fixed routing on Gambit?
- Would a change reduce contention at the cost of extra re-sweeps, traffic,
  reserved memory or single-worker overhead?

These questions connect to the existing Gambit forwarding/work-closure models,
Chez dirty-card and remote-accounting models, and the parallel-GC Evidence DSL.
Their conjunction is not yet a proved composition. A candidate repair still
needs its exact C/overlay/binary, original failure, real three-flags runtime
tests and matched performance measurements. Finite checker time is not GC speed.

Next source/model gaps are generated shape handling (including remote pointer
masks), cross-segment bitmap coverage, repeated remote re-sweeps, weak-object
fixed points, and native memory ordering. Actor/Rayon work is outside this study.
