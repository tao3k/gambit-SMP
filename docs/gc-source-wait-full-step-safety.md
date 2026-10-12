# Source Wait Full-Step Safety Boundary

The ordered-recheck extension had deterministic mechanism checks but no
reachability check over its complete transition relation. On 2026-10-11, the
unchanged extension and imported recursive model were snapshotted in
[`gc-source-wait-full-step-safety`](../evidence/model-results/gc-source-wait-full-step-safety/receipt.json).
Quint 0.33.0 compiled `sourceWaitInit`, `sourceWaitStep` and `sourceWaitSafety`
to TLC. All 22 branches were retained, including repeated condition returns;
no state constraint, reduced role population or focused-action substitution
was used. TLC selected the detected 12 cores, without a worker-count override.

The hard 30-second process-group budget expired with exit 124. The last TLC
progress line reported depth 18, 220,687 generated states, 58,578 distinct
states and 20,470 states still queued. These are the last logged counts, not
final coverage totals. No invariant violation was reported, but the state
queue was not exhausted and there was no completed-check verdict.

The initial restricted invocation failed to bind the local Apalache port and
did not execute the model. The authorized outside-sandbox invocation used
the same snapshots, invariant and budget. Both portable logs are retained;
raw logs with private paths stay local. A post-timeout process query found
no remaining process matching the model or selected port.

## Reflection

This observation closes neither safety nor progress. It demonstrates the
full relation can be translated and explored, while confirming that the
local five-test receipt is not a substitute for its safety obligation.
It does not diagnose a Gambit defect or justify a source change by itself.

Repeating the unchanged search, increasing its budget, removing transitions
or reducing the invariant cannot qualify this route. The preserved full
relation is available for an inductive/compositional obligation with a checked
initial-state implication and preservation by every action branch. Such a
proof must still account for transition definedness, generator coverage and
the new early-unlock/return states. C memory ordering, fairness, GC phases,
resource failures and native acceptance remain distinct obligations.
