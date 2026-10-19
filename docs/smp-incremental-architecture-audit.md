# Existing Models And Incremental SMP Architecture

## Status And Ownership

The central reference-research direction is now documented in
[Experimental SMP Design Foundations](experimental-smp-design-foundations.md).
The implementation-oriented milestone options below are not a selected runtime
plan or a substitute for comparing Chez/OCaml mechanisms and transfer premises.

This is an experimental architecture audit and a milestone proposal, not a
selected replacement collector, an implementation instruction or native
acceptance. It was prepared on 2026-10-19 against tracked HEAD
`ca5c93ad4b28f5ab957baa77516348f1bcdec8b4`.

The native owner continues current SMP qualification independently. Historical
6/12 completion is retained; this audit neither resets it nor advances it.
Research milestones below are not additional mandatory gates imposed on that
owner. Existing successful execution checkpoints remain reusable under their
actual source/tool/input dependencies, not merely because a milestone name
matches. Changed generated/runtime code requires its affected qualification;
unchanged bootstrap is not repeated just to produce a research report.

This audit changes no QNT transition, Lean proof, source patch, Python module,
runtime configuration, historical receipt or acceptance threshold. Concurrent
uncommitted datagram-observer/framework work is excluded, not rejected.

## Inventory And Review Method

Read-only enumeration of Git-tracked assets found:

| Inventory | Count | Interpretation |
| --- | ---: | --- |
| Gambit QNT files | 301 | Includes protocol, composition, proof-adapter and control assets. |
| Chez QNT files | 38 | Includes reference profiles and fault wrappers. |
| Library QNT files | 55 | Includes shared GC contracts and evidence/research-framework models. |
| All tracked QNT files | 394 | Not 394 independent protocols or completed proofs. |
| Lean files | 6 | Two main assets and four controls; file presence is not proof admission. |
| Protocol-extension manifests | 150 | The `gambit-protocol-extensions.v1` schema only. |
| Case declarations / distinct case IDs | 164 / 148 | Multiple contexts may legitimately register the same model. |
| Registration-only case declarations | 8 | Not executable temporal qualification. |
| Nonempty `composes` declarations | 72 | Metadata references, not automatically transition-preservation proofs. |

All 148 distinct extension-case primary models exist under `models/gambit`.
The other 153 Gambit QNT files are not thereby missing or invalid: they include
dependencies and models driven through other schemas. Of the 150 manifests,
134 declare the pinned Gambit revision and 16 omit that top-level field; the
latter need their actual context/lock contract inspected, not an automatic
source-unbound verdict. A declared temporal property is not an observed PASS.

Inventory covers the tracked model set. Semantic review below covers the
architecture families, their recorded assumptions, source mappings and
qualification boundaries; it is not independent rechecking of every theorem
or a claim that every invariant in all 394 files has been proved. Existing
checker/native campaigns were not repeated.

Useful inventory entrypoints remain `evidence/protocol-bundles.json`,
`evidence/protocol-extensions.json`, the scenario DSL and their existing
manifests. No second registry or workflow engine is introduced.

## Source Authorities

- Gambit vendor revision: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
- Chez reference revision: `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`.
- Current tracked collective-wait source lock:
  `evidence/research/processor-interrupt-collective-wait/source.lock.json`,
  SHA-256 `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
- Its cumulative patch:
  `patches/fixtures/processor-interrupt-collective-wait-cumulative.patch`,
  SHA-256 `8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`.

The common vendor revision does not make different overlays equivalent.
For example, `evidence/protocol-source-correspondence.json` explicitly binds
`evidence/runtime-source-026.lock.json`, and the parallel-GC comparison binds
the vendor baseline while intentionally leaving its current candidate unbound.
Neither can silently admit the newer collective-wait candidate.
An older document's word "current" is local to that document's source identity;
its 3/12 or 5/12 observation does not replace the retained later 6/12 record.

## Coverage, Assumptions And Open Connections

The results in this table are recorded evidence, not newly executed campaigns.

| Family and existing authority | Existing coverage | Assumptions / source correspondence | Unclosed connection |
| --- | --- | --- | --- |
| [Poll and stack coverage](stack-write-poll-coverage.md), `gvm_poll_dominance.qnt`, `exec_gc_polling.qnt` | Generated-code poll dominance, stack-write boundaries and a blocking child-wait participation obligation. | Particular compiler/runner paths; abstract flag visibility and successful participation. | Coverage of all relevant nonallocating retries, foreign blocking intervals and exceptional exits on the selected generated binary. A poll in one macro does not cover every caller. |
| [Scheduler root/cohort composition](scheduler-lock-moving-root.md), `scheduler_gc_root_cohort_composition.qnt` | Thread wait, processor wait, scheduler retry and moving lock-argument roots share two GC commits. The recorded positive has 351 distinct states and five fault controls. | Finite roles, root relocation/lock preservation, successful collector and weak fairness. Projection contracts bind canonical components. | Physical root scanning, C memory ordering, synchronous collective errors, arbitrary populations and retirement are not proved by that composition. |
| [GC membership](gc-sync-membership.md), `gc_sync_membership.qnt`, `sync_tree_rounds.qnt` | Old-population GC, root completion, resize commit and startup rendezvous; recorded positive explores grow and shrink in 129 states. | Finite population; abstract root copying and barriers; no collection in the modeled intermediate resize window. | Failed initialization/join, nested foreign borrowers and work/phase/retirement composition on the same current candidate. |
| [Work closure](gc-work-closure.md), `gc_forward_publication.qnt`, `gc_work_closure.qnt` | Private work, two copy stores, export, claim, scan and two abstract phases; 254-state recorded safety check. | Canonical forwarding identity is assumed in the work composition; queue visibility/count updates are atomic contracts. | Actual forwarding consumers, unfinished stack/chunk regions, weak phases, failure and weak memory are not one implementation proof. |
| [Recursive wait and rank](gc-ranking-obligations.md), `gc_recursive_queue_wait.qnt`, `gc_source_wait_induction.qnt` | Original 22-branch candidate safety/rank records, actual-initial-state bridge, and separate source-wait extension checks. | Candidate-state generator, source scheduling/fairness and retry abstraction are distinct obligations. | The source-wait extension's filtered induction record explicitly leaves 20 actions uncovered. Original-branch rank checks cannot be transferred to it without dependency evidence. Rank is not enabledness or native termination. |
| [Callback/retirement](callback-retirement-composition.md), `callback_retirement_composition.qnt` | Owned result, Scheme frame retention, live C activation, slot generation and retirement interaction. | Atomic interface pairing, fair callback completion and supported embedding admission. | Real nested SFUN versus runtime-entry classification, error/unwind, C-frame drain and supported shrink reachability. A copied continuation is not a surviving C stack. |
| [Public lifecycle](public-vm-retirement-composition.md), `public_vm_retirement_composition.qnt`, `vm_constructor_rollback_composition.qnt` | Public admission, retained joins, registry readers, initialization ownership and teardown barriers in bounded profiles. | Specific parent/successor locks and successful primitive contracts; rejection retains resources. | Whole public multi-VM lifecycle, raw failure correspondence and current-source native qualification. Historical adapter/fixture failures are not current successes or reasons to reset progress. |
| [Chez reference](parallel-gc-design-comparison.md), [hybrid](chez-hybrid-copy-mark-model.md), [resweep/card](chez-resweep-card-composition.md) | Copy/mark coexistence, owner handoff, segment re-sweep, retained cards, bounded repeated shapes and rounds. | Pinned Chez source; stopped mutators in card profiles; finite objects and owner roles. | Not a Gambit collector adapter. Shape-generator, arbitrary-graph, weak/ephemeron, actual mutex/fence and current-candidate correspondence remain separate. |
| [Experimental collector alternatives](experimental-concurrent-generational-gc.md), `ConcurrentSATB.qnt`, `ConcurrentCopyWrite.qnt`, `ColoredReferenceRelocation.qnt` | Snapshot logs, versioned copy/retry, FFI lease, colored references and later repeated-relocation/visibility profiles. | Sequentially consistent atomic actions, finite writes/objects, abstract barriers and epoch stamps. | The initial three-profile campaign is incomplete/DENY; later two-round checks do not retroactively close it. No concurrent Gambit collector, complete compiler barriers, arbitrary roots or matched performance is admitted. |
| [Joint quality contract](performance-reliability-stability-model.md) | Configuration retention, bounded useful work, no forced serialization, borrowed-root lifetime and generation reuse. | Abstract independent tasks and successful join acknowledgement. | Counts are not wall time; no machine scalability, cache-line, arbitrary join-failure or complete GC composition proof. |
| [Lean supplement](lean-work-accounting-obligation.md), `WorkAccounting.lean`, `ResearchFunnel.lean` | Conditional work-accounting/resource algebra and separate research-evidence properties are represented as assets. | WorkAccounting requires producer lifetime, exact active count and empty-queue premises; QNT projection equivalence is not established. | Repository docs retain WorkAccounting as unqualified. No Lean capability implementation was found in the inspected Python driver; retaining `.lean` inputs alone is not elaboration or proof admission. Research-funnel proofs do not prove GC. |

The root/cohort receipt was also read back without running the checker:
`evidence/model-results/fixtures/scheduler-retry-sync-participation/shared-root-cohort/receipt.json`.
It records accepted controls and stable context; its model SHA matches the
present tracked model (`15313faed88ea318f5be67d7e22e8e505f568fd79fec1a4f7c3a3136e8c9cfb8`).
This verifies that particular record-to-model identity, not all current source
premises. Earlier text saying root/cohort composition is absent is superseded
by the same document's later shared-cohort extension, not grounds to rebuild it.

## Gaps That Matter To An Incremental Refactor

1. **Call-site coverage:** the candidate already has
   `##lock-scheduler-object-with-sync-participation!` and processor/two-/three-
   thread helpers. Do not add another generic helper. Record which production
   waits use them, which retry without contention, and why any raw C lock is
   safe. A raw lock is not automatically a defect or permission to service GC.
2. **Permitted participation:** each entry needs its held-lock set, published
   roots, allowed synchronized operations and ordinary-callback exclusion.
   "Poll sync" alone does not establish that collection or a nonlocal error
   is safe at that particular point.
3. **Return and error closure:** GC may move arguments; scheduler decisions
   must be reread after participation. Collective error, cancellation, partial
   acquisition and retirement must not leave ownership or participation behind.
   Successful-return models cannot discharge these paths.
4. **Composition and implementation:** shared cohort, moving roots, membership,
   work closure and lifecycle already have models, but their scope/fairness,
   primitive effects and physical source mapping are not interchangeable.
   Discharge the specific missing interface premise; do not demand a new giant
   model or infer composition from matching requirement names.
5. **Actual progress and cost:** completed GC, emitted output, CPU activity and
   target computation are different observations. The retained report-framing
   failure does not prove a queue deadlock. Instrumentation must be qualified
   separately and cannot manufacture natural test completion or a speedup.

These are architectural acceptance gaps, not established causes of every
remaining TFIB/pipe/compiler failure. Native observations may select or reject
a proposed refactor. If a wait path is already covered and satisfies its
contract, it needs no edit merely to make this proposal look implemented.

## What OCaml And Chez Contribute

The [OCaml parallelism manual](https://ocaml.org/manual/5.3/parallelism.html)
and [Retrofitting Parallelism onto OCaml](https://anil.recoil.org/papers/2020-icfp-retropar.pdf)
support examining domain-local allocation, safe points outside allocation,
GC rendezvous, retiring-domain ownership and C API compatibility together.
They do not require Gambit to copy OCaml's generation layout or major collector.
OCaml remains a reference/research question here, not an existing faithful
source-bound OCaml runtime model.

Chez contributes the already-modeled distinctions between identity and payload
readiness, local ownership and remote work, and queue emptiness and completion.
Shared Scheme objects and continuations are compatible with those distinctions;
shared-nothing is an optional language/VM interface decision, not the admission
criterion for current shared-memory SMP.

Prefer reducing shared coordination on common paths and making transfer
explicit. A new per-VM epoch, shared counter, read barrier or ownership scheme
still needs initialization, wraparound, cost and retirement analysis. Similarity
to a reference design is motivation, not proof that the change is necessary.

## Proposed Milestones

These are bounded deliverables for discussion, not a mandatory Agent plan or
automatic progression to a collector rewrite. Costs below are scope limits,
not unsupported person-day or speedup estimates.

### A. Existing Protocol Baseline

Deliver the coverage/assumption/source/receipt map above and select one exact
candidate for any implementation proposal. Preserve historical results and
the native owner's checkpoint. Reuse existing models and independent negative
controls. Only add or extend a model after identifying an uncovered premise
that matters to an observed path or a concrete proposed source change.

Exit: reviewers can distinguish historical PASS, current applicability, open
assumption and a new implementation hypothesis without scanning raw caches.
This document supplies a baseline audit, not acceptance of all its assumptions.

### B. First Runnable Stable Slice: Synchronization Participation

Proposed small-refactor boundary: reconcile the existing scheduler wait/retry,
root-publication, sync-entry and exit protocols, using the existing helpers and
actual source paths. It is not "insert a poll everywhere" or "add one wrapper".

For the selected paths, describe entry ownership, root publication, permitted
sync service, fresh-state retry and normal/error exit as one reviewable contract.
Preserve the inline uncontended fast path. Implement only proven mismatches or
duplication whose removal preserves those contracts; no normal callback may be
introduced under locks. A general C-lock rewrite is outside this slice.

Do not change heap representation, copying/scanning algorithm, introduce a
nursery/read barrier, replace the compiler or change public Scheme/FFI semantics.
If the required repair crosses these boundaries, return to design review and
split a larger milestone instead of silently expanding this one.

Exit requires the same candidate with all three requested concurrency flags,
the affected atomic regressions and the original interpreted AND compiled
four-file stress inventory completing naturally. Retained parent passes can
be reused only with their real dependency checks. Repeated healthy/failure
observations and relevant live-processor topologies use host-derived capacity;
finite model role counts never become runtime worker limits. A timeout or
unreached file is not a pass. Validate the observer separately from the target.

This is a proposed first meaningful runnable slice, not guaranteed resolution
of the currently unlocated TFIB failure, whole 12/12, or an industrial-stability
claim. Establish matched single-/multi-processor costs against retained gates;
do not trade correctness for serialization or claim latency percentiles from
an insufficient population. Unknown performance remains unqualified.

### C. Work Ownership And Lifecycle Closure

Only where evidence selects this boundary, reconcile private/exported/scanning
work, participant generations, root ownership, wait registration and retirement
using the existing work/membership/lifecycle models. Keep the current collector
algorithm unless a concrete counterexample requires more.

The deliverable is a source-bound protocol across actual handoff/error sites,
not a globally locked collector or a new counter presented as a complete fix.
Affected multi-VM, resize, GC/FFI, rollback, current inventories and Gerbil
acceptance remain explicit. This slice can address later open milestones
without turning all research into a prerequisite for the native owner.

### D. Optional Collector Evolution

Generations, concurrent old/Still collection, concurrent relocation, an entirely
different owner-routing policy and shared-nothing isolation are separate
experimental alternatives. Promote none by default. Compare only the concrete
workload problem, compatibility/FFI changes, barrier/code-generation cost,
pause, throughput, memory and multicore scaling on matched successful runs.

Decision: select, revise or reject a costed design before runtime work. Reuse
the existing SATB/copy/colored/epoch and Chez controls; extend only the missing
assumption. A complete redesign needs its own reviewed milestone and rollback
boundary. Neither a finite PASS nor a fashionable collector obliges adoption.

## Audit Validation

Only read-only Git/JSON inventory, source/document inspection, lock/patch hashes
and the named receipt-to-model hash correspondence were checked in this audit.
No solver, Lean elaboration, bootstrap, stress test or benchmark was rerun.
No old failed campaign was retried or its outcome changed. Native 6/12 work and
the concurrent observer changes remain with their existing owner.
