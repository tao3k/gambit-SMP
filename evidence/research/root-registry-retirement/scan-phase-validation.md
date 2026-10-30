# Root Scan Phase Continuation Validation

## Checked Inputs

| Input | SHA-256 |
| --- | --- |
| `models/experimental/root_registry_callback.qnt` | `faef44afee654d04d720900eba84225f5c7f773348582e1880d02a6dfc1453bb` |
| `models/experimental/lean/RootRegistryCallback.lean` | `561345f76e45f2a447ef7f7ad716cbc9509626c3e73bedec386c5b06b190bd6f` |
| `models/experimental/test_participant_exit.py` | `bd66e23f41b47dcedc1fd0be7cf36610da2aa101e0419ce5c8925b68006d55a1` |
| Imported `vm_list_reader_retirement.qnt` | `7bb56b5964657b7b7f7f41096c629a0882e00a89f6dbf9fffde5407cf27f5952` |
| Unchanged `participant_exit_publication.qnt` | `173f58e64840b9c0e75d455ad662a522e36ebdff4ed6787dc392860b0461543e` |
| Unchanged `ParticipantExitPublication.lean` | `1d6ac5bc783d59f110ce5e75a1120d144fe3ce4ae378639bf30174d54a0ee849` |
| Imported `public_vm_retirement_composition.qnt` | `8f9fd3de30a54aa0f74482f1b2d9d4cb945adefb591d5c9dbade4f7a901b6419` |
| Imported `WorkAccounting.lean` | `7d6a00be12e01ad2283469df505f4e728468356db927c6df0c2b1eecfc113f0e` |

The pinned source revisions are Gambit
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, Chez
`41d5ffca7a07cbfc8807e719dedcc70ed74811cd` and OCaml
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`. Their relevant file identities
and source sections are separately bound in the existing
[Scheme research input](../repair-and-redesign/facts.json). They explain the
abstraction; this run is not a source-refinement or native-runtime check.

Command:

```sh
.venv/bin/python -m unittest discover -s models/experimental -p test_participant_exit.py -v
```

Final result: four tests passed in 173.430 s. All fifteen TLC checks were
accepted: three corrected safety/progress checks, seven omission controls and
five completion witnesses. All checker inputs remained unchanged during the
run. Resource selection was host-auto: twelve available processors selected two
control jobs and six TLC workers per job. No processor count was configured in
the runner; the two domains in the new finite projection are logical roles,
not the machine population. Limits stayed 30 s per TLC check and 15 s per Lean
process, with 200000 heartbeats and recursion depth 512.

## Root Registry QNT Recheck

The existing scanner/delete projection again passed safety and final-scheduled
conditional progress with 23 distinct / 25 generated states in 14.092 s.
Its three omission controls and both same-owner/external completion witnesses
also passed. These controls retain their original source/abstract boundaries.

## Global Root Scan QNT

| Check | Result | Seconds |
| --- | --- | --- |
| `initScanPhaseFixed`, `safe`, `completion` | Exhaustive finite safety/progress: 43 distinct / 65 generated, zero queued, no timeout. | 17.924 |
| `initLocalScanAsGlobalCompletion`, `safe` | Expected omission counterexample: global scan phase remains 1, one domain has resumed and written, `overlap=true`. | 18.400 |
| `initScanPhaseFixed`, `noPostScanMutation` | Expected non-vacuity witness: phase 2, no parked domains, both domains have written, `lateWrite=true`, `overlap=false`. | 18.172 |

Local-root readiness is a premise at the resume decision; local root enumeration
is not modeled. The projection distinguishes that readiness from global scan
completion. The scanner model and phase model are separate projections, not a
proof of their whole-runtime composition. No physical relocation, same-slot
writer serialization, generational barrier or C weak-memory refinement follows.

## Participant Recheck

The unchanged participant model and proof were rechecked because their shared
test adapter changed. Positive safety/progress completed with 132 distinct /
262 generated states in 18.766 s; all three omissions and both request-order
witnesses passed. These are not new native acceptance results.

## Lean

Eight root-registry declarations and the five unchanged participant declarations
passed. Both processes exited 0, without timeout, with `group_quiescent=true`.
Printed axiom sets contained only `propext` or none, with no `sorryAx`.
The three added declarations separate local from global completion, exhibit
independent domain entry ownership without global exclusivity, and require
global completion for the defined release predicate. They are conditional
logical contracts, not a complete inductive refinement of the QNT or C code.

## Preserved Failure And Receipt Custody

The first integration run failed one Python trace assertion after its QNT
checks and Lean checks passed: the test interpreted TLC's `{"$integerSet":
[0, 1]}` encoding as an ordinary list. The failure and original test identity
remain in `experimental-root-registry/run-tn9k9slv` and
`experimental-participant-exit/run-s3ys8ie4`. The correction reads the existing
typed-set representation; it changes no model, invariant or limit.

The corrected full campaign receipts are in
`experimental-root-registry/run-by0pjgnn` and
`experimental-participant-exit/run-tw50b3qa`. These are cache locators, not
source fixtures or prerequisites for reproduction. The preceding
[validation](validation.md) remains bound to its older model/adapter identities;
it was not rewritten into a current pass.

The [source audit and Recipe](../../../docs/experimental/root-registry-retirement.md)
records Gambit's existing phase barriers and the architecture gate on dynamic
C closures as counterevidence to premature fixes. No runtime source, current
model algorithm, native inventory, source lock, checkpoint, watchdog budget,
bootstrap or native stress run changed. This research does not recount 9/12 or
close the outstanding current-native gates.
