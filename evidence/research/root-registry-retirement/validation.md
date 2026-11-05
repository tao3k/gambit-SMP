# Root Registry And Participant Continuation Validation

## Checked Inputs

| Input | SHA-256 |
| --- | --- |
| `models/experimental/root_registry_callback.qnt` | `b0fbd9f0808cb92d31c81f7decae435e589dace27587c074ae85476fd95098f7` |
| `models/experimental/lean/RootRegistryCallback.lean` | `e35b815d466d0d0fa179bb44ae2b14b67754d62c2e5ef10f627675441cda6d22` |
| Imported `vm_list_reader_retirement.qnt` | `7bb56b5964657b7b7f7f41096c629a0882e00a89f6dbf9fffde5407cf27f5952` |
| `models/experimental/test_participant_exit.py` | `07c51d7fd29cb23440692a860247b86bbc6f678fbe8d1bcf94aad2a05de6032c` |
| Unchanged `participant_exit_publication.qnt` | `173f58e64840b9c0e75d455ad662a522e36ebdff4ed6787dc392860b0461543e` |
| Unchanged `ParticipantExitPublication.lean` | `1d6ac5bc783d59f110ce5e75a1120d144fe3ce4ae378639bf30174d54a0ee849` |
| Imported `public_vm_retirement_composition.qnt` | `8f9fd3de30a54aa0f74482f1b2d9d4cb945adefb591d5c9dbade4f7a901b6419` |
| Imported `WorkAccounting.lean` | `7d6a00be12e01ad2283469df505f4e728468356db927c6df0c2b1eecfc113f0e` |

Command:

```sh
.venv/bin/python -m unittest discover -s models/experimental -p test_participant_exit.py -v
```

Four tests passed in 164.550 s. Both classes share one test adapter using the
existing checker, process guard and host CPU/memory scheduler. There is no new
production Python inference, runner, dependency or CLI. This machine selected
two control jobs and six TLC workers per job from twelve available processors;
these observed values are not configured constants. Each checker retains its
30 s limit. Lean retains 15 s, 200000 heartbeats and recursion depth 512.

## Root Registry QNT

Corrected safety and final-scheduled conditional progress completed with 23
distinct / 25 generated states, zero queued and no timeout in 18.017 s.

| Check | Actual decoded distinction | Seconds |
| --- | --- | --- |
| `initRelockInsideScan`, `noStall` | Same scanner holds the lock, waits to acquire it again, and still owns the reader; no modeled step is enabled. | 20.460 |
| `initForeignDepthBypass`, `safe` | External owner mutates under another scanner's lock/depth and acquires false deletion authority. | 20.355 |
| `initUnlinkAsLastUse`, `safe` | Storage is freed while a reader remains in `use`. The lifetime invariant rejects this before an actual dereference; `invalidRead` is still false. | 13.412 |
| `noOwnerCompletion` under `initFixed` | Deferred same-owner deletion completes with reader and writer both done. | 16.044 |
| `noExternalCompletion` under `initFixed` | Ordinary external deletion completes without borrowing scanner depth. | 16.643 |

The last two are non-vacuity witnesses, checked as counterexamples to their
negations. Negative controls are abstract protocol omissions, not native fault
injection, reproduced C races or corrupted-memory observations.

## Participant QNT Recheck

The shared test adapter was changed, so both declared campaigns were checked.
The participant model/proof sources were unchanged. Its corrected safety and
conditional progress again completed with 132 distinct / 262 generated states,
zero queued and no timeout in 16.275 s. All three original omission controls and
both request-order witnesses were accepted under the original check limits.
The original [validation](../participant-exit-publication/validation.md) and its
older harness identity remain historical evidence, not rewritten current inputs.

## Guarded Lean

Both companions passed with exit 0, no timeout and `group_quiescent=true`.
The new five declarations distinguish owner-specific deletion, rejection of
another owner, lack of insertion permission, registry membership versus live
slot storage, and roots versus mutation authority. Their printed axiom sets
contain only `propext` or none, and no `sorryAx`. The unchanged five participant
declarations also passed. These are conditional logical contracts, not whole-
machine induction or C refinement proofs.

## Scope And Custody

Final receipts are retained in the existing cache at
`experimental-root-registry/run-ce83l_9e` and
`experimental-participant-exit/run-xhcca0uk`. These are receipt locators, not
runtime source trees or reproduction prerequisites. All campaign input hashes
remained stable. No runtime source, native manifest, checkpoint, flags, budget,
native build or stress execution changed. The owner's 9/12 is not recounted.

The [source audit and Recipe](../../../docs/experimental/root-registry-retirement.md)
separates root-list topology, root-slot lifetime, payload updates and callback
effects. Actual slot last use, complete roots, moving collection, C ordering and
current candidate correspondence remain open. The older participant model and
current-runtime models were imported without algorithm changes.
