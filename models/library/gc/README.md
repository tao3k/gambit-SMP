# Shared GC Contracts

`CollectionContract.qnt` separates three safety obligations: canonical reference
identity, initialization before scanner-visible publication, and closure of
private, queued and active scan work before completion. Copying and in-place
retention instantiate the same logical-object contract. One optional re-scan
is allowed; scanning exactly once is deliberately not a shared invariant.

## Scope

The bound is one already-live object, two root slots, stopped mutators, atomic
visibility and one optional re-scan. Root relocation is not object reachability
discovery. There is no general graph, generation, remembered-set, weak-pointer,
ephemeron, allocator failure, reclamation, C memory model or liveness proof.
The copying profile allows forwarding identity before payload initialization,
but forbids making uninitialized payload scanner-visible. In-place retention
does not mean that a mark operation must initialize the object's payload: the
`initialize` transition abstracts establishing scanner-readable validity.

`CopyingChecked` and `InPlaceChecked` are positive controls. `SplitIdentity`,
`EarlyPublication` and `EarlyTermination` inject independent faults. Their
counterexamples are modeling controls, not allegations about either runtime.

## Implementation Boundaries

Chez profiles in `../../chez` instantiate these contracts without claiming
source refinement. Chez segment ownership, forwarding-marker ordering, remote
re-sweep and actual termination detection must be modeled separately against
the pinned source. The reusable contract must not require at-most-one scan.

`WorkObligations.qnt` contains pure canonical-reference, active-count and work
closure predicates. The two existing Gambit models now use these predicates
with their original state, transitions and faults. Executable equivalence checks
compare against the original formulas on their reachable finite states; the
original positive and negative regression controls are retained. Their chunk
visibility and scan ownership remain Gambit-specific.

`OwnerHandoff.qnt` models a single owner-routed ticket, including outbound,
inbound and scanning work and atomic wake accounting. It is a fixed-owner
protocol profile, not a mandatory routing design for Gambit or GHC. Lost work,
uncounted wake, premature idle and wrong-owner mutations produce decoded
counterexamples. No runtime or source admission follows from these controls.

## Reproduction

For each wrapper, run `quint typecheck`, then `quint verify --backend tlc`
with `--invariant Safe --max-steps 12 --out-itf <fresh-path>`. Preserve actual
exit codes and raw logs, including the three expected counterexamples.
The first local verification campaign has a 60-second total execution cap;
do not reset the cap per profile or interpret infrastructure failure as a
negative control. Source and model changes require new receipt identities.

## Initial Results

Raw logs and process/input receipts are retained under
`../../../evidence/model-results/gc-contract-initial`. Campaign 001 failed
because the sandbox prevented the verifier's server from binding a local port;
none of those failures counts as an invariant counterexample. Campaign 002
used approved local-server access and the TLC backend, with the same 60-second
total cap. It completed in 21.589 seconds without timeout or model input drift.
TLC exhausted the copying profile's 35 states and in-place profile's 11 states.
All three mutants exited 1 with actual invariant-violation state traces in the
raw logs. The backend did not emit requested ITF files; the receipt records that
absence instead of claiming structured trace artifacts exist. Both Chez
profile wrappers separately passed typechecking within a shared 15-second cap.
These results establish only the declared finite contract, not either runtime.

## Parallel Protocol Results

`evidence/model-results/gc-parallel-contracts` retains all campaigns. Sequential
campaign 001 exhausted the original whole 60-second cap and left controls
unexecuted: DENY is preserved. Campaign 002 changed verifier scheduling to two
isolated process lanes without changing model inputs or the whole cap. All 13
controls completed in 44.079 seconds: five positive checks and eight decoded
negative controls. The original ten Gambit regression controls completed in
24.252 seconds under a separate declared whole 60-second cap (two positive,
eight decoded negatives). Model-checking duration is not GC performance.
