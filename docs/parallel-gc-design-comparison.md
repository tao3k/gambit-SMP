# Parallel GC Design Comparison

## Objective And Evidence Boundary

The purpose is to repair Gambit's SMP, multiple-threaded-VM and parallel-GC
protocols, not to select a runtime by reputation. Chez and GHC are design
controls. A finite counterexample is not evidence that a corresponding native
failure is reachable; a checked model is not source correctness. No change in
this study repairs Gambit's C runtime or admits a native candidate.

The source bindings are `models/chez/source.json` and
`evidence/parallel-gc-source-comparison.json`. Gambit correspondence in this
comparison is the pinned vendor baseline, not an unnamed current repair
candidate. Existing combined notification/recheck candidates must be reviewed
under their own locks; do not rediscover their old baseline gaps as new bugs.

## Three Designs, Not One Algorithm

| Dimension | Gambit pinned baseline | Chez pinned source | GHC ISMM 2008 paper |
| --- | --- | --- | --- |
| Work unit | Completed heap chunks and local incomplete allocation regions | Segment ownership, local sweep stacks and remote referencing objects | Private scan/allocation blocks and exported pending blocks |
| Load distribution | Processor-local FIFO with chunk stealing | Route remote referencing objects to the target segment's owner for re-sweep | Shared Pending Block Set protected by a mutex |
| Object claiming | Destination CAS can precede payload copy | Local segment owner copies or marks; marking can retain address | Claim header, copy, publish forwarding pointer by unlocking |
| Visibility | Chunk contents/link before visible tail, paired fences and queue lock | Remote-stack publication and wake under sweep mutex; initialized mark bitmap before inspection | Completed pending regions and publication/claim ordering; paper-level protocol |
| Completion | Active count, local scan completion, queue acquisition and condition-variable protocol | Running sweepers plus receive-stack inspection and outbound flush obligations | Empty shared set is insufficient; running-thread accounting and polling |
| Generations | Do not assume Chez-style dirty cards merely because both move objects | Collected/target generations, conservative dirty bytes, buffered remembered writes and retained cards | Section 4 adds per-generation/step allocation and promotion |
| Repeated scanning | Existing finite Gambit work model restricts scan count | Remote dependencies can cause repeated sweeps | Pending-frontier discipline, not Chez owner routing |

The GHC paper explicitly describes one shared pending-block list in section
3.3. Per-thread work-stealing queues are a discussed alternative, not the
implemented queue in that paper. This is not a claim about current GHC RTS.
The PDF pin and original extracted-text hash are retained; sections 3.1-3.5
were re-read for this comparison. No new paper was downloaded.

## Contracts Extracted From Gambit

`models/library/gc/WorkObligations.qnt` now owns canonical-reference validation,
active-worker cardinality, completed-work predicates and absence of private,
outbound, inbound and scanning obligations. The first three predicates replace
the same formulas in Gambit's forwarding/work-closure models. Executable
original formulas remain as `identityExtractionEquivalent` and
`workExtractionEquivalent`; extraction must preserve them on reachable states.
No Gambit transition, initializer, fault mode or historical receipt is changed.

The Gambit at-most-one-scan invariant stays implementation-specific. Atomic CAS,
frame links, chunk boundaries, weak-reference phases and VM membership also
stay outside the pure common predicates.

`OwnerHandoff.qnt` models one conserved ticket transferred between two owners.
Its private/outbound/inbound/scanning phases and counted wake reject dropped
tickets, unaccounted wake, premature idle and wrong-owner processing. Fixed
owner routing is a protocol profile, not a required architecture for Gambit or
GHC; those may legally transfer scan ownership rather than route back.

`GenerationCards.qnt` models two mutable fields on one older card, younger
generations 0/1, two collections (cg=0 then cg=1), direct conservative card
marking and buffered remembered-set transfer. Promotion must retain the next
younger-generation obligation. Missing barriers, discarded buffers, skipped
fields and prematurely cleared cards have independent negative controls.
This is not a full reachability/reclamation model. It excludes weak fields,
mutations during sweeping, multiple cards and generated machine-code barriers.

## Gambit Repair Requirements

| Obligation | What must be established in the actual candidate | Native validation requirement |
| --- | --- | --- |
| Private work cannot vanish at idle | Every copy, local scan, discovered root and outbound chunk is covered before decrement | Delayed producer/export schedules under the candidate's exact root/queue identity |
| Publication cannot lose a wake | Queue publication, notification and waiter predicate recheck have a coherent lock/visibility protocol | Original lost-wakeup controls, repeated rounds, spurious wakes and teardown |
| Forwarding is not scan readiness | Every consumer of a forwarding address obeys payload and producer-owned-link readiness | Shared/recursive graphs, duplicate roots, continuation frames and actual GC execution |
| Membership does not invalidate accounting | Registration, retirement, drain and GC phase agree on participant generation and resources | Shrinking requester, partial initialization rollback, independent threaded VMs and retained roots |
| Completion is global | Local queues, private frontiers, active scanners and handoffs are all included | GC regression plus lifecycle, bootstrap, Gerbil and complete real tests on one GNU/three-flags candidate |

For each proposed repair, bind an observed failure and exact source/overlay,
state the causal change, preserve the original failure receipt and budget, then
run through the existing sealed review/admission path. Neither an owner-count
model nor a Chez design pattern grants retry permission or proves fairness.

## Performance Is An Independent Acceptance Gate

Correctness is necessary, not sufficient. Do not copy Chez owner routing or
GHC's shared pending list into Gambit without quantifying the trade-off against
its existing chunk stealing. Owner routing can avoid concurrent object claiming
but may increase cross-owner traffic and re-sweeps. Fine work units can improve
balance but increase queue/atomic overhead. A single queue may reduce metadata
cost yet become contended; processor-local queues can increase stealing cost.
Neither structure has a source-independent performance advantage.

Matching baseline/candidate runs must use the same workload bytes, graph/root
shape, live heap, allocation volume, compiler/options, processor/VM topology,
hardware and execution cap. Keep instrumented and uninstrumented measurements
separate. Include single-worker cost and multi-worker scalability, both successful
and failed/timeout trajectories, and full test denominators. No budget widening.

Measure end-to-end elapsed time and throughput, total collector CPU, pause
distribution and peak/RSS or heap reserve. Diagnostic counters should separately
report claim/CAS failures, queue lock contention, private/exported bytes, steals,
cross-owner sends, re-sweeps, worker active/idle time and termination waits.
Avoid hot-loop logging or shared counters that create false sharing; evaluate
instrumentation overhead with matching controls before interpreting counters.

Paired repeats must bind exact source/overlay and binary identities. Source
drift, environmental changes, missing denominators or failure remain separate
outcomes, not silently dropped samples. The finite campaigns below measure
checker execution only; they are not runtime GC benchmarks or speedup evidence.

## Executable Evidence DSL

`evidence/scenarios/parallel-gc/design.ss` expresses sources, outputs, typed
relations, reference joins, missing-obligation negation and aggregation through
the existing ASCENT Library. Its source facts distinguish pinned Gambit baseline,
pinned Chez source and GHC's 2008 paper. Finite controls cannot derive
same-candidate satisfaction. Python only transports facts and checks identities;
the scenario requires no downstream Scheme imports or compilation.

The real consumer test completed in 3.517 seconds under the original 15-second
cap. It checked four reference comparisons and five open obligations, actual
decoded negative receipts, retained-session reuse, source withdrawal/restoration,
independent explanations and close rejection. It uses the existing sealed
Library, not a new producer build. It is not yet a full current graph admission.

Model campaign 002 completed all 13 declared controls in 44.079/60 seconds;
the original ten Gambit controls completed in 24.252/60 seconds. Both retained
all decoded negatives. Campaign 001's timeout and unexecuted controls remain
archived and denied. See `evidence/model-results/gc-parallel-contracts` and
`evidence/scenarios/parallel-gc/README.md`. These timings are verification costs,
not Gambit runtime performance.

## Open Work

The concrete Chez remote-stack protocol still needs explicit mutex/fence and
multiple-ticket refinement; GHC is paper-bound, not a current-source adapter.
Gambit needs current-candidate mapping, source enabledness/fairness, moving-root
and retirement composition, C memory-order checks and full native acceptance.
Keep local model results separate from these gates. Wall-clock improvements
require matching inputs/hardware and full successful denominators, not a
work-balance estimate or correctness-control PASS.
