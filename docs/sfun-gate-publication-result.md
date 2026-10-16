# SFUN Gate Publication Result

## Retained Inventory Failure

`sfun-gate-count-publication-order`: DENY in 7.897120375 seconds.
All eight trajectories actually passed, but the Recipe listed only the two new
ones, omitting the six imported tests. Exact inventory validation rejected that
mismatch. No test was skipped or disabled to repair the declaration.

Original child receipt SHA-256:
`30663831ef07d6dcbee946d837fb8a506b0c71cf55f4e161868dd18fe41f34ef`.

## Corrected Inventory And Exhaustive Checks

`sfun-gate-count-publication-controls`: PASS, all 9 steps, 28.308355292 seconds.
It uses the unchanged model and explicitly declares all eight trajectories.
Its ceiling is 42 seconds, so both attempts together remain within the original
50-second model campaign: actual total 36.205475667 seconds.

| Check | Result |
| --- | --- |
| Current count-before-gate ordering | 11,522 distinct states, 23,879 generated, queue empty |
| Early gate release | Expected safety violation, decoded 7-state trace |
| Missing processor count publication | Expected safety violation, decoded 4-state trace |
| Double temporary gate release | Expected safety violation, decoded 5-state trace |
| Existing and split-publication trajectories | 8 passed, none failed or ignored |

Negative checks stop when a counterexample is found; their remaining queues are
not exhaustive completion claims. Only the positive run is reported exhaustive.
TLC used 12 available CPUs through framework auto-selection, not a fixed runtime
capacity in the model.

The early-release counterexample exposes a reserved call whose gate has already
been dropped. The closer seals, scans a zero count and retires its origin before
count publication. The source's opposite order excludes this modeled schedule:
before count publication, the temporary gate blocks closing; afterward, the
published count blocks retirement even after the gate reservation is released.

The new model reuses the existing lifecycle actions, rather than replacing them
with a second implementation. Its intermediate-count projection establishes a
population correspondence invariant, not a full transition simulation proof.
All assumptions and excluded obligations remain in sfun-gate-publication-order.md.

## Identity And Durable Counterexamples

Engine ID:
`fc943732ddf04239f2dd9426f57ad71f00af2b384ff04ecd77337fadffa7ff2b`.
Outer receipt SHA-256:
`41e5cd72fd0282fe21302c14d1ba3e2b8f1ec3ee76c652871b53cd3f55e1c859`.
Child receipt SHA-256:
`58ef3fcdd79fa5f2c7b3a0f45183db26a23a8aebb8fa712aee3a7f90ff66fb09`.

The framework re-read reports CURRENT identity and evidence bindings, with all
published outputs available. runtimeAdmitted and sourceRefinementAdmitted are
both false. The same retained source tree was reused; no extra source checkout
or native executable was built.

Counterexamples copied byte-for-byte under
`evidence/fixtures/sfun-marker-explicit-context/`:

- gate-early-release: `317d5878cde58712053d3784699875753e2b91f15c8495d45d15a8f85c8056f3`
- gate-missing-count: `de1ee25252e179d31b8ebc7bffce7fdcc0c0473741cec374d198d8c3bf9e850d`
- gate-double-release: `81c5556a1dd6eb7f76f59ac55d8d7e71c8944fb04a9449756b34186d349c0930`

## Source Check And Native Gates

GNU GCC 16 preprocessing of the configured current header selects
___USE_sync_builtins: COMPARE_AND_SWAP_WORD expands to
__sync_val_compare_and_swap; FETCH_AND_ADD_WORD expands to
__sync_fetch_and_add. The observed configuration is not using emulated or
sequential synchronization. This identifies the selected backend; it is not a
machine-code memory-model proof or a performance measurement.

No runtime patch follows: the source already has the required modeled order.
Do not insert an extra fence, serialize Scheme execution or disable SMP merely
because a deliberately reordered control fails.

Cumulative native milestone remains 3/12. Complete and PR GSC, GSI/GSC stress,
registry lifetime, lifecycle faults, GC/FFI, Gerbil correctness and release
performance remain open. Bootstrap and native requalification of the latest
SFUN header successor are still required. The original qualification ledger is
unchanged at 468.695876834 / 600 seconds; the user did not authorize a fresh
bootstrap allowance. Model evidence does not close any of those native gates.
