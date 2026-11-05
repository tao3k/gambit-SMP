# Participant Exit/Publication Validation

## Checked Inputs

| Input | SHA-256 |
| --- | --- |
| `models/experimental/participant_exit_publication.qnt` | `173f58e64840b9c0e75d455ad662a522e36ebdff4ed6787dc392860b0461543e` |
| `models/experimental/lean/ParticipantExitPublication.lean` | `1d6ac5bc783d59f110ce5e75a1120d144fe3ce4ae378639bf30174d54a0ee849` |
| `models/experimental/test_participant_exit.py` | `dab435d9f263f5beb0eb8247931008935ddf6f572e8cbfa092ef5d16948f7723` |
| Imported `public_vm_retirement_composition.qnt` | `8f9fd3de30a54aa0f74482f1b2d9d4cb945adefb591d5c9dbade4f7a901b6419` |
| Imported `WorkAccounting.lean` | `7d6a00be12e01ad2283469df505f4e728468356db927c6df0c2b1eecfc113f0e` |

Reproduce with the existing environment:

```sh
.venv/bin/python -m unittest discover -s models/experimental -p test_participant_exit.py -v
```

Two tests passed in 66.842 s. The existing scheduler derives jobs/workers from
available CPU and physical-memory capacity. Per-check limits remain 30 s;
guarded Lean retains 15 s, 200000 heartbeats and recursion depth 512. No runtime
build, native stress or source/configuration change was run by this campaign.

## QNT Checks

The corrected safety and final-scheduled temporal check completed with 132
distinct / 262 generated states, zero queued, no timeout, in 15.338 s.

| Check | Decoded result | Seconds |
| --- | --- | --- |
| `initSnapshotWithoutGate` | Removed member, pending enlisted request, no acknowledgement, `badCut=true`. | 14.228 |
| `initOrphanWithoutRecheck` | Removed member still has work reopened by orphaning. | 17.124 |
| `initCleanupAsStwProtected` | Removed member, later request excludes it; cleanup write and collector read critical section overlap. | 16.054 |
| `noParticipatingRequest` under `initFixed` | Reaches completion with an enlisted and acknowledged request. | 14.695 |
| `noExcludedRequest` under `initFixed` | Reaches completion with a request excluding the retired member. | 14.403 |

The final two are positive reachability witnesses, checked as counterexamples
to their negations. They show the corrected model does not merely refuse all
requests or retirement. Omission controls are finite abstract counterexamples,
not actual OS schedules, corrupted C loads or discovered native crashes.

## Lean Checks

The five printed declarations passed guarded Lean with exit 0, no timeout,
`group_quiescent=true` and no `sorryAx`. Printed dependencies were `propext`
or no axioms. They establish conditional logical contracts, not whole-machine
induction, C memory ordering or a complete collector/root inventory.

## Retained Attempts And Evidence Limits

The first run's fixed verifier could not bind its required local loopback
endpoint. Its Lean check also rejected opaque `decide` use without unfolding
the new predicates. That rejected run remains at the original cache receipt;
the final proof uses explicit unfolding/simplification. No incomplete proof,
timeout extension or successful native outcome was substituted.

Final raw receipts are retained in the existing cache at
`experimental-participant-exit/run-lmsj9xzv`; the rejected attempt is
`experimental-participant-exit/run-ind1m_iy`. These are historical receipt
locators, not model sources, fixture identities or reproduction prerequisites.
All declared source inputs stayed unchanged during qualification. Existing
models and earlier receipt hashes were not rewritten.

Source interpretation, scope and transfer limits are in the
[research design](../../../docs/experimental/participant-exit-publication.md).
The current-candidate source binding and native acceptance remain absent.
An initially empty registered Clue query with unknown bindings is not evidence
that these research facts do not exist: this research input is evaluated directly
through the existing component and is not registered as a new Session view.
