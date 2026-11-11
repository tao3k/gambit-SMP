# Repeated Retirement Repair Campaign Validation

## Checked Scope

This is model and test-contract evidence for current stability work. It does not
increment 9/12, implement a runtime recovery API or qualify native/release behavior.
The campaign directly imports the existing exit/handoff protocol; the only
parent additions are a complete configuration projection and a distinct restart
action outside its original step relation. All imported variables remain in
the checked state and in fairness; no compiler patch or state constraint is used.

## Results

Three guarded tests passed in 241.770 s. The twelve Quint/TLC checks all passed
within their unchanged 30 s per-check watchdogs. The complete policy space has
46,924 distinct / 155,974 generated states and zero queued states.
Positive safety applies to the corrected normal/source-change/cancellation
policies; deliberately defective policies have separately selected invariants.
The seventeen printed Lean statements passed with only the existing propext and
Quot.sound dependencies where needed, no sorryAx and an unchanged 15 s guard.
The proof covers arbitrary finite event lists and logical recipient identities;
it does not establish native event authenticity or a full QNT/C refinement.

| Check | Seconds | Accepted meaning |
| --- | --- | --- |
| `corrected-policies-fixedSafe` | 23.589 | Safety and conditional progress |
| `initCancelled-noCancelled` | 19.519 | Reachable positive/retention witness |
| `initEraseFailure-rejectEraseFailure` | 17.695 | Decoded actual invariant violation for the omission control |
| `initFailedAsPass-rejectFailedAsPass` | 20.343 | Decoded actual invariant violation for the omission control |
| `initFixed-campaignNoRetainedFailure` | 18.669 | Reachable positive/retention witness |
| `initFixed-noRecipientCompletion` | 20.394 | Reachable positive/retention witness |
| `initFixed-noRepeatedSuccess` | 20.053 | Reachable positive/retention witness |
| `initLostRecipient-rejectLostRecipient` | 14.405 | Decoded actual invariant violation for the omission control |
| `initPartialInventory-rejectPartialInventory` | 22.039 | Decoded actual invariant violation for the omission control |
| `initReplayReceipt-rejectReplay` | 22.197 | Decoded actual invariant violation for the omission control |
| `initSourceChange-noStaleRejected` | 17.706 | Reachable positive/retention witness |
| `initStaleBuild-rejectStaleBuild` | 19.146 | Decoded actual invariant violation for the omission control |

The witnesses separately reach two completed cohorts with prior recipient work
still live, legitimate completion of that work, retained join failure, cancellation
before handoff, and stale-source rejection. Six defects expose stale builds,
receipt replay, subset completion, failed-as-pass, erasure of failure without a
new incarnation, and loss of the surviving recipient at donor restart.
For failure erasure, the decoded trace checks the actual before/after failed
join and join-call fields, not only the diagnostic flag.

## Audit Corrections And Retained Attempts

The earlier passing campaign omitted recipient conservation. Its pass applies
only to its former abstraction and is not transferred to this stronger property.
Separate received, owned and completed work/root ledgers now survive cohort
starts; an explicit last-consumer event discharges old obligations. The new
loss-on-restart control violates coverage. Lean also proves per-identity coverage
and exclusivity over arbitrary ledger traces, with reachability and omission
examples. Native last-reader completeness remains an external source obligation.

Initial attempts rejected shared initializer/transition actions (QNT409),
nested aliases with duplicate unassigned imported state, and an unsupported
nested export/instance compilation. Direct wildcard reuse, a complete state
projection and distinct restart action resolved the model/tool composition.
Failed attempts are retained; the compiled specification was not hand-edited.

Parallel large witnesses exceeded the original 30 s budget. Checker concurrency
was reduced to one while keeping host-derived TLC workers and all budgets.
Five witnesses then passed, and the final entire current three-test campaign
passed again. No timeout is credited, omitted or converted to success.

The parent single-cohort suite was independently requalified: ten QNT checks
(621-state positive, seven omissions, two witnesses) and its existing Lean
contract. Four final ASCENT/current-source checks passed in 15.121 s with stable
inputs and missing native requirements preserved. Old receipts are unchanged.

See [the typed receipt](receipt.json) and [test contract](../../../docs/retirement-repair-test-contract.md).
Whole-framework CI, actual native test families and complete native/Gerbil
qualification for this extension were not executed or admitted. Grok remains stopped.
