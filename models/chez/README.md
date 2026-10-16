# Chez GC Source Study

Research uses `vendor/chez`, a Git submodule at full revision
`41d5ffca7a07cbfc8807e719dedcc70ed74811cd`, fetched from upstream main on
2026-10-13. The branch is not a floating research identity. Updating the gitlink
requires reviewing `source.json`, hashes, mappings and validation together.
Initialize with `git submodule update --init -- vendor/chez`. This is a research
source dependency, not a downstream ASCENT Library compile requirement.

`source.json` binds the inspected GC file and the still-unread shape generator.
It distinguishes reviewed sections from open obligations. CopyingProfile and
InPlaceProfile are initial shared-contract instantiations, not a model of the
whole generational collector or a source-refinement certificate.

The source explicitly permits copying or marking, distinct segment ownership,
remote re-sweeps and multiple scans. `run_sweeper` combines running-worker
accounting with receive-stack inspection under `sweep_mutex`; that concrete
protocol is not proved by the shared one-object closure contract. A local queue
being empty alone is not a sufficient completion rule.

`GenerationCards.qnt` now covers a two-field card, two young target generations,
direct and buffered barriers, and two stopped-mutator collection rounds. It
checks reference coverage and retained youngest-generation metadata, not full
heap reachability or reclamation. `../library/gc/OwnerHandoff.qnt` models one
owner-routed ticket and atomic publication/wake accounting; it does not prove
the implementation's mutex or unbounded source protocol.

The checked campaigns, design differences and Gambit repair obligations are in
`../../docs/parallel-gc-design-comparison.md`. Weak-reference fixed points,
actual enabledness and source refinement remain open.
Native execution, full source correspondence, progress and performance remain
unqualified. No existing Gambit counterexample or historical receipt is changed.

`HybridCollection.qnt` now covers copy/mark coexistence, including a locked
`space_new` object and a movable neighbor under the same segment owner. Its
checked wrapper and five fault wrappers distinguish forwarding publication,
bitmap initialization, relocation-mode selection, ownership and closure.
The finite campaign closes 685 states and decodes all five negatives; it does
not qualify collector source, liveness or performance. Exact mappings, retained
failures and separate-attempt costs are in
`../../docs/chez-hybrid-copy-mark-model.md` and `hybrid-source-map.json`.
# Resweep/Card Interaction

`ResweepCards.qnt` couples shape readiness, remote owner handoff, shape-specific
two-segment coverage and retained cards over two stopped-mutator rounds.
`ResweepChecked` checks safety; six fault wrappers preserve decoded negatives;
`ResweepReach` produces a marked spanning-object completion witness.
See `resweep-source-map.json` and `docs/chez-resweep-card-composition.md` for
fixed source correspondence, actual receipts, Gambit design obligations and
the explicit no-native/no-performance/no-refinement boundary.
