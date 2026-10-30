# Metadata Transaction Design Validation

## Scope And Identities

This records local validation of the
[transaction/callback proposal](metadata-transaction-recipe.md), not a runtime
repair, native qualification, speedup or advancement of the native milestone.
No C, SCM runtime, lock, TLS or production Python implementation was changed.
Existing Scheme relations, Session reuse, the shared verifier and guarded Lean
process adapter were used without adding an inference interface.

| Current input | SHA-256 |
| --- | --- |
| `docs/experimental/metadata-transaction-recipe.md` | `5de9f01939fab0ae7372f4daddf747b86e4bd1f488bc23fc85c8834f206e4732` |
| `models/gambit/gc_table_iteration.qnt` | `8b54044941d951085739519a118ad97246e287f9f0878194f93d5c0f48cb29b5` |
| `models/gambit/lean/RuntimeEntryContracts.lean` | `9deb99a68757ab3053eaef6bd666e3d454bf4b7bd7e284b67ce3b985026813b7` |
| `models/gambit/lean/controls/RuntimeEntryFalseClaims.lean` | `7b113b869ba8ac4b6072c1ad7e1f69c5abf46f8e32e54dd56d7aff40a215e1b3` |
| `evidence/scenarios/parallel-gc/runtime-entry.manifest.json` | `3a68626ba0d150d9abe82d4c89e4603589fb5a320e8dd70eb9e851691dca4fba` |

Source lock and cumulative patch identities were rechecked; candidate `mem.c`,
`setup.c` and `_kernel.scm` matched the locked overlay. Source authority remains
the versioned submodules, lock and patch, never a materialized cache path.

## Capture Model And Preserved Traversal

Quint 0.33.0 / TLC checked the additional projection of the existing
`gc_table_iteration` model. The positive capture check explored 59 distinct
states (89 generated), with safety and weak-fair finite completion passing.
Five expected controls were obtained:

| Omitted boundary | Expected invariant counterexample |
| --- | --- |
| Root publication for the waiting operation | `captureRootSafe` |
| Reload after wait-time relocation | `captureReloadSafe` |
| Guard release before Scheme delivery | `captureDeliverySafe` |
| Capacity revalidation after membership growth | `captureCapacitySafe` |
| Allocation failure before delivery | `captureFailureSafe` |

These controls expose missing abstract obligations, not reproduced native
failures. The root check can reject missing root ownership even before a
relocation; it is not evidence of a particular moving-GC crash.

Delivery now advances one callback at a time. Callback failure retains the
delivered prefix; it neither marks the whole capture complete nor undoes or
automatically replays earlier effects. Source membership may grow after capture
without changing captured membership. Explicit continuation reinvocation is
outside this finite model and must retain Scheme semantics in a real repair.

The original initializer/step projection was rechecked at the same final model
hash: old traversal and wrong-tag controls fail as expected; typed snapshot
traversal passes. The original key/layout abstraction was not replaced by a
second collector model.

Local raw receipts, disposable and not reproduction dependencies:

| Receipt under `.cache/runtime-entry-models/` | SHA-256 |
| --- | --- |
| `metadata-prefix-checked/receipt.json` | `1fa7df3df437cbbed72961296c04c75e856eadf1648f9801941b0ca074dc698f` |
| `metadata-prefix-original-traversal/receipt.json` | `38e5604e626b99cbabb3e689420283baa14abc1c73c3962c6d345812b9cd6217` |

The capture receipt is accepted with stable inputs, no timeout, and
`runtimeAdmitted=false`, `releaseAdmitted=false`. Original traversal also has
stable model inputs and no timeout. Neither ran native tests. Host-auto
scheduling observed 12 available CPUs and 32 GiB physical capacity, selected
two control jobs with six TLC workers each and twelve positive workers. These
are recorded host observations, not fixed workload/thread settings or free-RAM
guarantees. Per-check watchdogs were not enlarged.

The unchanged reservation and host-entry models also had nine expected outcomes
in the retained `metadata-delivery-prefix` run. That campaign as a whole is
**denied** because a later capture-model parse failed; do not relabel it as an
accepted full campaign or inherit admission from its partial successes.

## Lean And Existing Scheme Consumer

The existing guarded test checked eleven theorem declarations and their axiom
inventories; no `sorryAx` appeared, only permitted standard axioms. Five false
claims were rejected by `decide`. The three additions establish conditional
arithmetic/epoch consequences: no rewind across another reservation, a bound
for each revalidated copy index, and invalidity of a stale local after a move.
They do not establish callee root-slot ownership, real GC or C refinement.

One retained successful observation set is under
`.cache/runtime-entry-formal/run-hp18z2r2/`:

| Observation | SHA-256 |
| --- | --- |
| `build.json` | `2c5a48490b73e8a72ed31f7e0475b5907d7972edb43b36fb018d29491a70d58e` |
| `axioms.json` | `4e18f2a9c8fa5e1f0dd739b17ef4e8cf739a4210b7d860a0cfdef55454096e42` |
| `false-claims.json` | `df0b97bce8f73a28df520ddd045f77d0c041990c8138fe05f826a844ca7d7604` |

The source-bound Scheme consumer derives all three transfer conditions and
their partial model gaps using the existing `design.ss`. Session reuse returns
the same answers. Withdrawal of the recipe, capture model, reused root models
or reference failure sources exposes missing provenance; restoring facts
restores the answer. All three native obligations remain missing and
`satisfies` remains empty. Python checks these observations; it does not infer
applicability or promote a model observation into native acceptance.

Both focused test files passed: three runtime-entry checks and the unchanged
parallel-GC scenario check. This is not a full-repository/native test claim.

## Retained Failures And Review Corrections

- Initial sandbox loopback binding was denied before TLC ran. The local-only
  checker ran after explicit sandbox escalation; this was not a model failure.
- Lean initially used reserved identifier `local`. The failed observation is
  retained at `.cache/runtime-entry-formal/run-l9q_xdsn/build.json`, digest
  `0d71f2009670e981679c1b09c8033fedf444e9576258824891bca4cf0f6a4a19`.
  Renaming the binder fixed parsing, not a failed mathematical claim.
- A Scheme evidence check rejected the proposed-candidate/design-source join.
  The facts were corrected to reference the actual baseline allocating reader;
  the proposal remains a separate premise. No join or missing-source check was
  weakened to accept a proposal as current runtime implementation.
- An earlier capture abstraction delivered the whole batch atomically. Review
  found this too coarse for callback failure; it was replaced by prefix
  delivery. Its earlier passing receipts remain historical, not current.
- Prefix delivery first had an invalid comma after a Quint `val` binding.
  `metadata-delivery-prefix/receipt.json`, digest
  `5ac84cf42613cb144cd76fd23abb4c4309f337b177be34dbe8727149477ac851`,
  retains the denial. After correction, `quint typecheck` passed before the
  changed projection alone was rechecked. No unchanged native route was run.

## Cost And Compatibility Decision

The bounded first candidate is whole-operation permanent reservation/interner
consistency plus separately captured enumeration. Extra capture is O(n) space
and O(n) copy work per enumeration, not a free optimization or a new cost for
every ordinary object allocation. A shared metadata guard can add contention
to lookup; no guard algorithm is selected and no net speedup is predicted.
New-global registration can require per-VM segment preparation, so its cost
and lock ordering must be audited separately rather than hidden in a symbol
insertion estimate.

The first repair must preserve canonical identity, VM-local values, public C
ABI and ordinary generated-code allocation fast paths. A global operation guard
is not a global VM execution guard. General parallel loading or attachment is
not implied. Header/private-entry changes still require coherent producer
qualification even when the source diff is small.

Before implementation, close actual root-frame ownership and callee effects,
GC-safe wait eligibility and collector/VM-list/arena lock ordering, publication
to reverse/generated readers, size arithmetic, and real failure/unwind paths.
Before adoption, run the proposal's exact-source identity/rehash/GC/error and
callback/continuation tests plus original stress and performance gates. These
remain **open**, not replaced by these formal results.

## Reproduce Without Cached Sources

From the repository environment, use fresh configured-cache output paths:

```sh
quint typecheck models/gambit/gc_table_iteration.qnt
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json --case gc_table_iteration --out .cache/runtime-entry-models/capture-recheck
.venv/bin/gambit-smp check --case gc_table_iteration --out .cache/runtime-entry-models/traversal-recheck
.venv/bin/python -m unittest discover -s tests -p test_runtime_entry_formal.py -v
.venv/bin/python -m unittest discover -s tests -p test_parallel_gc_evidence_scenario.py -v
```

Raw historical receipts may be cleaned as caches; this versioned summary
retains their identities and limits, not their admission authority. The commands
regenerate checks from repository-owned models/dependencies, without bootstrapping
or modifying the native lane's checkpoint, failures or cumulative progress.
