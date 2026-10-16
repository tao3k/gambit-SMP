# Repeated Resweep And Current Candidate Qualification

## Producer Custody Repair

The old 022 seal required live pre-bootstrap checkpoint artifacts. The current
framework distinguishes retained historical ancestry from importable live
generations: historical state evidence is checked, while the final runtime
still requires its actual complete matching tree. Independent revalidation of
the fdset completed producer reproduced the exact original reference in
6.140381/15 seconds. No receipt, source lock or producer SHA was rewritten.

New seal `research-engine-chez-source-custody-023` has 2,512 files and engine ID
`fb6a7ea3e9c7839198ff741b1a5a8d0bc843445aa1a030021dbc76ba50c23245`.
It retains the same Library binary/source closure as 022. Sealing took
5.755971/15 seconds. This is a framework snapshot, not a new Library build or
full-framework regression claim. The recipes explicitly use the completed
in-place final generation, with leases and all tree/ancestry checks intact.

## Finite Repeated Resweep

Chez stays at revision `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`.
The reviewed shape paths and exact source hashes are in
`models/chez/repeated-source-map.json`. Six shape classes are bounded layouts,
not all generated shapes: scalar, pair, vector, mixed record, closure and frame.
The model preserves resolved dependencies across repeated owner handoffs and
two promotion/card rounds. These are Chez profile properties; generation/card
requirements are not imposed on Gambit's movable/still/permanent classes.

`.data/chez-repeated-resweep-004` passed at 47.193639/60 seconds; each step keeps
its original 15-second cap. Safety exploration exhausted 94 distinct states.
Five decoded negatives expose second-handoff loss, prefix loss, an invalid
worker-count bound, premature zero-mask completion and a skipped strong field.
The 37-state witness completes two rounds with four remote visits per round
among three owners. This is not unbounded progress, source fairness or native
memory-order correctness. Readback returned CURRENT/PASS; admission remains
false for runtime and source refinement.

Prior receipts remain: 001 rejected historical inventory, 002 rejected treating
the pre-configuration source as a live tree, 003 rejected the Quint built-in
`fields` name collision. The corrected 004 renamed it `strongFields`. Each
attempt has its own unchanged 60-second cap; combined costs are not reported as
one 60-second campaign. The failed no-output export CLI probe and the recipe
discovery refusal also remain in the tool transcript. Explicit recipe selection
uses the supported path interface and still validates that recipe and ancestry.

## Actual Gambit Test And Timing

The 23-file fdset-owned-rollback source lock is
`c81d31ec44b016e2d5a3ab92ea27b99d4595571f266d39b7c114d2f224c59754`.
The completed producer requires observed GNU GCC and all three concurrency
flags. `gc_shape_retention_public.scm` tests cyclic pairs, vector aliases,
records, large integers, captured closures and non-tail saved frames through
two forced collections and processor drain. Host CPU capacity was 12; the
fixture expands its own 12-processor cohort from that observed capacity.
The generic execution wrapper starts at one processor, not a claim that the
fixture remained single-processor. Width 4096/depth 128 are explicit workload
parameters, not physical segment-placement or frame-rollover evidence.

`.data/current-source-gc-shape-retention-002` passed in 25.099566/60 seconds.
Both compilations and executions exited 0, without timeout, and were reaped
with quiescent process groups. The two runs share:

- Fixture SHA: `19c945f3efdb7e6877962d6dd6d38d72425b987f9d91ac239e1d76387ab658f5`.
- Runtime identity receipt: `2bd617f492d0860950d16f564854e2a860060ea3c95474559811bbd1a44fa385`.
- Executable SHA: `c6d718d8ae2d9170542d9b3240e19b8b5d0906e316357e5048b8ac6515168e81`.

Compilation took 1.440962 and 1.239885 seconds. Actual process execution took
0.624669 and 0.509800 seconds, each under its 15-second cap. These are two
matched-input repeatability samples of the same candidate, including startup,
allocation, collection, checks and teardown. There is no changed-C baseline,
statistical speedup, GC-only pause or throughput admission. Single-VM fixture
coverage does not close complete GC/FFI, multiple-VM lifecycle or all runtime
gates. Both `nativeGcPassed` and aggregate runtime admission remain false.

## Evidence DSL Consumption

`evidence/scenarios/gc-transfer` now consumes six shape profiles, the actual
repeated witness and native step receipts with exact JSON pointers. It derives
three portable obligations, one collector-specific boundary, three recorded
counterexamples, three recorded runs and six unproven correctness/refinement
boundaries. No recorded run derives admission, authorization or causal review.
Source SHA checks run before and after actual Python/C ABI evaluation.

Candidate, shape-model and individual native-receipt source withdrawal each
remove their dependent conclusions; restoration returns identical answers.
This real DSL check exited 0 at 2.590852/15 seconds. Original facts are retained
as `history/facts-001.json`. Model verification logs/traces and native compile/
run logs are archived under `evidence/model-results/chez-repeated-resweep/004`
and `evidence/source-results/gc-shape-retention/002`, with original bytes.
These selected observation archives do not include every executable/source
tree and are not a standalone portable research-run admission certificate.

All source, native and DSL successes qualify their respective explicit scopes.
Full current-graph validation, C-level physical layout/FFI/multiple-VM tests,
unbounded resweep proof and matched optimization performance remain open.
