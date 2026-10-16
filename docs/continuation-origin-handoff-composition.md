# Continuation Origin And Handoff Composition

## Decision Before Runtime Changes

- Direction: source-directed investigation of producer-owned frame links becoming
  scanner-visible during section rollover; not a general scan-lock proposal.
- Prior work: saved-stack origin, export geometry and link handoff were already
  checked separately. This check composes their actual transitions; it does not
  rediscover those reports as new native failures.
- Value: eliminate repairs that address only roots, only local chunks or only
  the final link store without preserving the combined publication protocol.
- Expected performance: unknown. There is no measured speedup or justification
  for serializing collectors. Bounded delayed publication needs an actual
  implementation and performance qualification before selection.

## Checked Result

The existing framework checked the source-bound fixture contract
`evidence/fixtures/public-vm-retirement-composition/continuation-composition-contract.json`.
Quint 0.33.0 used host-derived concurrency (12 available processors observed),
with the original 15-second per-check cap. The campaign took 20.016 seconds.

| Check | Result | Distinct states | Seconds |
| --- | --- | --- | --- |
| Old early scanner read | Counterexample found | 2,007 | 6.798 |
| Old conflicting link update | Counterexample found | 2,496 | 6.775 |
| Delayed publication safety and progress | Exhausted, passed | 2,160 | 6.658 |
| Delayed publication no-stall and progress | Exhausted, passed | 2,160 | 6.546 |

Portable checked receipts and model/log snapshots are under
`evidence/model-results/fixtures/public-vm-retirement-composition/continuation-composition`.
The publisher validated the input hashes. No native gate is closed: cumulative
completion stays **3/12**, with latest-source requalification pending.

The isolated origin and geometry modules are identifier-renamed versions of
the bound original models. The origin initializer is also duplicated verbatim
for old/protocol initialization because the TLA backend rejects a shared
initializer used by both entrypoints. Their transitions are not new repairs.
Original modules and historical receipts remain unchanged.

Initial attempts are retained in `.data/model-results`: the unbound attempt,
the sandbox socket denial, the overlapping-state typecheck denial and the
shared-initializer conversion denial. They are checker/setup failures, not
Gambit runtime counterexamples and not accepted campaigns.

## Remaining Source Obligations

1. Prove that a retained saved stack can reach this frame-copy/rollover path in
   the current native collector, including parent continuation reachability.
2. Bind the queue item, GC epoch and producer/scanner link accesses to that
   actual source execution. The model is sequentially consistent and finite.
3. Design bounded publication that preserves queue conservation and collector
   progress without global scan serialization or unbounded deferred storage.
4. Compile/bootstrap and run the full GSI/GSC, PR and stress inventories on the
   exact source successor, followed by GC/FFI and Gerbil/performance gates.

There is no C patch, native witness, full-GC proof or performance claim here.
