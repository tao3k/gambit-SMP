# Closed Research Kernel

The active experiment interface is a typed artifact graph, not a registry of
feature-specific Python runners. A v2 Recipe cannot name an executable, import
a handler, embed a script or call the historical raw C-file builder. Unsupported
operations fail closed. New experiments within the existing capability contracts
add Recipe/Evidence, QNT and native C assets only.

## Ownership

| Layer | Responsibility | Not Admitted |
| --- | --- | --- |
| `gambit.materialize`, `source.overlay` | Git archive from an immutable lock; checked patch inventory and before/after identities | Dirty checkout or archived producer outputs |
| `source.project`, `source.bind` | Explicit workspace inventory; whole-source hashes, ordered numeric byte spans and provenance | Token-based protocol assertions or semantic source refinement |
| `native.workspace-build` | Matching workspace/binding; GCC input closure must actually consume every required source projection | Unused source attachments or outside-workspace non-system headers |
| `native.test`, Quint capabilities | Exact local observations and model controls | Runtime correctness from fixture/model success |
| `evidence.evaluate` | Mechanical observations become facts; native ASCENT evaluates declared rules and exact query inventories | Python protocol judgment or fallback rule interpretation |
| `gambit.suite` | Same-producer runtime/identity, exact inventory, bounded processes and native known-failure review | Automatic retry authorization or waived previous failures |

The terminal evidence evaluator observes the complete graph, including failed
dependencies. A missing obligation stays missing; it cannot disappear because
an earlier process failed. Negative controls retain their actual nonzero exits.
Unexpected stderr, timeout, signal or missing exact output is not a passing
negative control.

## Execution Boundary

`research --seal` copies the static implementation closure, installed ASCENT
binding and receipt-bound native API into a fresh read-only directory. Its
manifest hashes every file, rejects added files, and binds selected Python/GCC
(and optional Quint/Node) identities. The Evidence-034 and source-lock-035
manifests contain 14 `gambit_smp` Python modules,
not the historical producer CLI modules. Static forbidden imports fail sealing;
the worker also rejects escaped implementation paths and historical imports.
Execution uses an isolated Python process with the sealed package first, not the
editable checkout. Supplying a seal path to an editable executor is rejected.

This is an implementation/API reproducibility boundary, not a security sandbox
against a malicious host or a hermetic SDK. Host transitive libraries, system
shared caches and the entire linker/toolchain distribution are not copied into
the seal. Actual selected tools, compiler backend and input closure are bound in
run receipts; that does not establish portable distribution qualification.

```sh
gambit-smp research --seal .data/research-engine-new \
  --gcc /opt/homebrew/bin/gcc-16 \
  --ascent-api .data/ascent-api-native-rule-reader
gambit-smp research --run vm-log-source-derived-controls \
  --engine .data/research-engine-new --allow-native --out .data/vm-log-new
gambit-smp research --run sync-resource-source-derived-controls \
  --engine .data/research-engine-new --allow-native --out .data/sync-resource-new
gambit-smp research --read .data/vm-log-new
```

`gambit-runtime-source-lock.v1` accepts an explicit nonempty inventory of
existing regular tracked files at the fixed `vendor/gambit` revision and
canonical repository URL. C, headers, Scheme and build inputs use the same
contract; no candidate-specific file allowlist grants access. Each entry binds
base and candidate SHA-256, and the lock binds the complete patch SHA-256.
Noncanonical paths, Cache paths, symlink traversal, malformed hashes and
duplicate JSON keys are rejected. Git archive supplies the base; the complete
patch inventory must stay within unique locked existing files, and all candidate
bytes are checked before publication. Snapshot export, offline source checking
and sealed materialization share the validation. This proves source bytes only,
not configuration, bootstrap, runtime correctness or retry eligibility.
Changes to this contract require a fresh implementation seal and matching
receipts, never replacement of implementation files in an existing seal.

Use the actual Recipe `id` when selecting a run. Fresh seals and run directories
never overwrite history. Parent exit, child receipt, source/tool identities and
whole-run deadline must agree. stdout identity and stderr warnings are retained
separately. `--prior` records the previous receipt, denies unchanged failed
routes, and rejects larger whole or matching-step budgets. Changing a directory
name is not a cause. `--read` rechecks identities without executing research.

## Mechanical Acceptance

Two distinct mechanisms have run through this entire source-to-rule path with
one seal, with only research assets added between runs:

- Activity-log array/mutex controls: fresh locked source and overlay, three C
  compilation branches, exact local controls and native rule evaluation.
- Sync-resource initialization/reuse: the same candidate source, independent
  projections and two controls, including a real exit-1 reuse negative control.

Each retains its original 90-second whole budget. Local receipts live in
`.data/kernel-vm-log-001` and `.data/kernel-sync-resource-001`, using
`.data/research-engine-002`. They are local observations, not committed or CI
qualification. The source-origin first attempt's DENY receipt remains in
`.data/kernel-source-origin-001`; the separate stdout/stderr process-contract
repair was retried under the same 45-second budget in a new directory.

Regression tests reject executable/archived inputs, raw builder bypasses,
cross-workspace bindings, synthetic-only workspaces, incomplete verdict graphs,
legacy imports, missing native providers, identity drift, unchanged failed
retries, budget expansion and unused/external compiler inputs. Process tests
cover both streams, ordinary nonzero exit and process-group timeout propagation.

## Remaining Gates

Byte-origin binding does not prove that a projection captures the complete
protocol, caller lifetime, concurrency, enabledness or fairness. QNT/C contracts
and native source evidence must establish those obligations separately.

The sync-resource reuse negative control demonstrates an open resource issue;
it does not qualify the actual runtime. Full same-candidate GNU GCC flags,
GC/multiple-VM, bootstrap, Gerbil and actual complete suites remain independent
native gates. No fixture/model receipt can substitute for them.

Known failed suite routes yield `REVIEW_REQUIRED` before runtime probing unless
the [typed native retry review](typed-native-retry-review.md) binds the original
failure/log, actual before/after inputs, exact candidate/campaign and original
budget. Native ASCENT expands transitive obligations and derives conditional
`RETRY_ELIGIBLE`; it does not admit runtime correctness or grant host permission.
Missing historical fields remain unsupported. Removing the known failure,
substituting a reduced inventory or switching to an old CLI is not a valid bypass.
No native/release/source-refinement admission follows automatically from PASS.
