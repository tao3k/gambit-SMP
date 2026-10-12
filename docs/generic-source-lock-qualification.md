# Generic Source Lock Qualification

## Contract

The fixed source-file allowlist was in snapshot export and offline
materialization, not the sealed `gambit.materialize` implementation. These
interfaces now share the generic source inventory validator. The canonical
Gambit repository/submodule and exact revision remain fixed; each regular file
has exact base/candidate SHA-256 and the complete overlay has its own SHA-256.
Export checks actual Git tree mode and path. Materialization rejects symlink
traversal before checking file hashes and rejects unknown, duplicate, binary or
deleting overlay entries. Noncanonical/Cache paths, invalid hashes, duplicate
JSON fields and repeated export selection are rejected. No candidate-specific
file whitelist or Python experiment producer was added.

## Local Evidence

Fresh seal: `.data/research-engine-source-lock-035`.

- Engine ID: `c95e7a62ee2f2c99fc4e54e240eeec0c38c91f9f5ec904f241e97ab6b9981d14`.
- Manifest SHA-256: `dbc1da6c96fd3633fe059dbe380b3393ee4cac98a178669eb5a8df9c6421c1a8`.
- Independent rehash: all 1293 files MATCHED. The actual closure has 14
  `gambit_smp` modules, the same module names as Evidence-034; the older prose
  count of 12 was inaccurate for these manifests.
- Provider remains the actually built Evidence-034 API, not an old failed
  provider or a loader-timeout wrapper. No old seal was modified.
- Final focused regression: 102 passed, 0 skipped, 8.070s / original 15s cap.
- Actual new-seal typed retry controls: 32 passed, 0 skipped, 55.793s / original
  60s cap. These use synthetic campaign identities and real ASCENT inference,
  not current Gambit runtime qualification.
- VM-log mechanism: parent exit 0, 11.215s / original 90s cap.
- Sync-resource mechanism: parent exit 0, 8.368s / original 90s cap. Actual
  reinitialization-negative exit 1 remains an expected negative control.
- Current 18-file lock reproduced from Git archive and its full overlay in
  0.83s / 45s cap. All candidate hashes matched, including `_kernel.scm`,
  `_thread#.scm` and build files. Source-lock SHA-256:
  `2299c44b6f7e6bf07bdd59c9f812ac0f323ac8691e505950ac3f3b7b26a57589`.
- The same 18-file lock then traversed the sealed data-only Recipe, numeric
  source projection, source binding, actual C compilation, exact controls and
  native Evidence module terminal: parent exit 0, 8.278s / original 90s cap.
  `.data/kernel-current-source-lock-vm-log-035-002` was actually read CURRENT.
- All three research parents were reaped, timeout false, process groups
  quiescent. The two independent mechanism receipts were also read CURRENT.

Raw local logs and read results: `.data/source-lock-general-035/`.

| Log | SHA-256 |
| --- | --- |
| `framework-tests-003.log` | `0e6e41ae7f70bf19b1a6c016b7ebcb61c3200443664b69275d5b086449a47bde` |
| `typed-retry.log` | `bc09140882cc8427ffbd5d0580586a5b0dad733a8c2ee7c38325eed9a0c83c1c` |
| `vm-log.log` | `7f2ada95ba1558ce396613c3a7c07568367f8e809941cce27f1e011ece457216` |
| `sync-resource.log` | `1701b85722c0e7316245fbf6380f7bcb210a659fa91cf6f7573e9009770b3194` |
| `current-source-lock-vm-log-002.log` | `0bea81157b6e16023f99a16ce335888a9acad41a5135e9e3c64470c47f1db7da` |
| `source18.log` | `88f217c757641613bc544c385bac105ab95f141fe955528c73c247d1bd93304f` |

## Retained Failures

Initial regression: 88 tests, 1 failure and 1 import error. Capsule rejection
ordering was repaired; the nonexistent test module was removed from the test
command. The observation receipt explicitly says raw logs were not archived.
The corrected and final raw regression logs remain separate.

`seal.log` is a non-qualifying no-op invocation: `python -m gambit_smp.cli` has
no module entrypoint and created no seal. `seal-002.log` records the actual CLI
entrypoint and produced engine. Exit 0 alone was not consumed as build proof.

The first 18-file Recipe retained an obsolete terminal dependency and was
rejected before execution. The exact rejected Recipe and denial log remain in
the local directory. The corrected data asset has SHA-256
`f77707cf340b9c0d42e3e8df66a96c18fb4fc02b8de4e78c293553eebf996eb5`;
its successful run has a distinct `002` output identity and unchanged cap.

## Boundaries And Remaining Gaps

These are local, recheckable source/framework/component observations, not Git
persistent native admission. `runtimeAdmitted` and `sourceRefinementAdmitted`
remain false. The mock VM-log and sync-resource components do not qualify the
full 18-file Gambit runtime, moving roots, source fairness, two-pass bootstrap,
Gerbil or complete real tests. No runtime failure was waived by these checks.

The failure-index audit separately found eight source/build observation
receipts with `accepted:false` but no normalized `status:DENY`. Existing index
validation also assumes an upstream unit-test log and requires a control log,
which does not represent arbitrary SCM observations. These remain unclosed:
do not add fake historical status, original budgets, runtime identities or
upstream log text. A separate typed observation binding must preserve original
receipt SHA/JSON pointers, source/runtime/fixture identities, actual process
exit/signal/timeout and the original budgets. Missing identities or budgets
must stay explicit gaps; differently built positive controls are not
identical-runtime controls. Recording a failure is not retry eligibility or
full native admission. Until this contract is implemented and verified, the
old index error must not be described as a valid fresh full information graph.
