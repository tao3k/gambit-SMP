# Cleanup Error And GC Drain Composition

## Path Review

The prior caller source-unit established ignored shrink errors; the lifecycle
model established retained-resource admission requirements. Neither connected
catcher retirement to join and independent resource users. This is the next
protocol boundary, not another run of a previously denied native route.

The expected benefit is correctness, not a quantified speedup. No performance
or complete runtime-green claim follows from the result.

## Reproducible Composition

`cleanup_error_gc_drain_composition.qnt` directly imports the conditional
cleanup-error transitions. Shutdown transitions are mechanically projected from
`shutdown_error_handoff.qnt` using the existing resolved-IR projection tool.
The projection contract binds source and template hashes and verifies generated
bytes. Names change; source protocol actions do not.

The adapter adds one abstract admitted GC borrower and one abstract publication
tail. Both can finish independently after admission closes. These are boundary
tokens, not a proof that every Gambit root, sync sender, or callback is counted.

The composition couples catcher retirement and cleanup publication. Successful
join stops the error-reporting worker only once its pending report is serviced.
Reclamation requires successful join, catcher/error closure, and both resource
users drained. Failed join gives an explicit retained-resource outcome; it does
not fabricate worker exit, successful cleanup, or permission to unload.

## Results

Published receipt:
`evidence/model-results/fixtures/scheduler-retry-sync-participation/cleanup-error-gc-drain/receipt.json`.

- Positive: 118 distinct / 296 generated states, safety and weak-fair
  explicit-outcome completion PASS in 4.022 seconds.
- Ignored GC borrower: expected counterexample, 121 distinct states.
- Ignored publication tail: expected counterexample, 121 distinct states.

The shutdown source snapshot in the bundle is context for the verified
projection. The executable model contains the projected actions; it is not
merely an adjacent copy described as composition. The cleanup source snapshot
is an actual imported dependency.

## Source And ABI Audit

Source authority remains the pinned Gambit submodule plus the cumulative
scheduler-retry source lock, not a generated build directory. The candidate
`___cleanup_vmstate` already requires admission closure and user drain in its
caller contract; current global `___cleanup` still ignores resize errors.

`include/gambit.h.in` declares both a void `___cleanup` prototype and a void
cleanup function pointer in the global function table. Replacing their types
would not be a compatible repair. A checked entry must preserve the legacy
entry; any added function-table slot requires explicit ABI/version review.

The checked operation must distinguish clean, cleaning and retained-failure
states, return the original error, and deny setup/reuse while old ownership is
retained. A legacy void wrapper must not silently claim success. Its exact
fail-stop policy and embedding contract are not implemented by this model.

## Open Requirements

This is not a full GC-chain proof. Still required are physical root/cohort and
borrower refinement; source binding for publication-tail completion; shared
VM/embedding admission; composition with the setup/unload lifecycle model;
concrete checked cleanup; actual OS join fault injection; and complete native
tests, bootstrap and Gerbil build/test/performance qualification.

Weak fairness assumes admitted users finish their modeled finite work. The
failed-join branch terminates with retained resources; it does not prove eventual
successful reclamation, leak freedom, or recovery from permanent OS errors.
