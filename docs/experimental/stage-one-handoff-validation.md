# Stage-One Research Handoff Validation

This validates the [research Recipe](stage-one-handoff-recipe.md), not a runtime
implementation. No runtime source, native-owner fixture or native acceptance
checkpoint was modified in this research follow-up. No native build, bootstrap,
stress, installation or performance measurement was launched.

## Bound Inputs

| Input | SHA-256 |
| --- | --- |
| Research Recipe | `9bb4c95f35c16345a5e40cfda4f20a5f24f21452d669a340aa6a0bad5d8a6294` |
| `predicate_lock_retry_rooting.qnt` | `fb22f40731548dda4816e3611e16c2af0fd8a32035760a8449d595d8c1cff35f` |
| `RuntimeEntryContracts.lean` | `b929f1d4e90a230b77c2367dd926399a4cb3543ea765b11d1ef6e41e98d1f178` |
| `RuntimeEntryFalseClaims.lean` | `c2522feba1f98e7338609bfb0433e43f2da62c0dbda73051d44fc1df19aa8502` |
| `runtime-entry-wait.manifest.json` | `d0d5d72a0ff0bb4bc43b2fef08d36a722479484a38b8323db4d387237ba2cd3a` |

The wait manifest binds the existing overlay lock/patch and pinned reference
sources, including actual OCaml installed hooks and Chez collector rendezvous.
It does not bind the unadopted implementation candidate. Earlier model receipts
retain their original bytes and scopes; extending the model does not make those
old receipts certify its new digest.

## QNT Outcomes And Actual Traces

The wait projection has **two expected counterexamples**. The corrected finite
histories passed safety and weak-fair completion over **35 distinct / 53 generated
states**, with stable model/context inputs and no timeout:

- The two-state collecting-owner trace ends with `ownerHeld=true`,
  `ownerNeedsGC=true`, `requested=true`, `gcDone=false`, and a raw waiting
  participant unable to join. Owner work cannot proceed until collection,
  collection cannot proceed until the waiter participates, and the waiter cannot
  acquire until the owner releases. No reversed resource acquisition is needed.
- The seven-state stale-index trace ends with `length=4`, `bucket=1`,
  `wrongBucket=true`, owner released, and the waiter finished. Neither a GC request
  nor collection occurred. Bucket 1 is still in bounds; the wrong canonical
  lookup follows mutator rehash alone. This is stronger than merely observing
  an out-of-bounds copy or stale movable address.

Receipt: `.cache/runtime-entry-models/handoff-wait-local-endpoint/receipt.json`,
SHA-256 `ec28cc44c2c78e17ff6985726f9a2755af8fd49c275450cb770035adfca86a1f`.
It explicitly reports native `not-run`, `runtimeAdmitted=false` and
`releaseAdmitted=false`.

The existing service-effect projection was rechecked at the extended model's
new digest: **four expected controls**, fixed safety/completion over **16 distinct
/ 20 generated states**, stable inputs and no timeout. Receipt:
`.cache/runtime-entry-models/handoff-existing-service-envelope/receipt.json`,
SHA-256 `524b7f7575f883c100cb2bb7b16982195bc43c1143ce5b688c20d91cc93d2059`.
No old failure or native outcome was rewritten.

The original retry projection's `releaseOwner` is conditional on `gcDone`.
Consequently, its raw-wait counterexample does not establish that every raw
noncollecting leaf wait is incorrect. The new projection separates that premise:
a leaf owner may finish independently; a collecting owner needs explicit parked
participation. Conversely, finite owner work is a model assumption, not proof
that real OS allocation or all enabled host effects terminate within a bound.
Actual generated roots, C weak memory, arbitrary ownership chains and full GC/
FFI composition remain unproved here.

An initial sandboxed launch could not bind its localhost checker endpoint and
failed with `PermissionError` before state exploration. Its output directory
`handoff-wait-conditions` is retained. The subsequent check used the same model
and declared limits with permission for a local endpoint; the permission error
is not recorded as a protocol counterexample or a passed run.

## Lean And DSL

The guarded Lean build/check passed with **20 theorem inventories**, standard
axioms only and no `sorryAx`. All **11 deliberately false claims** were rejected.
The two new results distinguish current bucket correctness from mere bounds;
their source premises still require implementation evidence.

Observations below `.cache/runtime-entry-formal/run-je7ux3qb/`:

| Observation | SHA-256 |
| --- | --- |
| `build.json` | `57a40ac4289bacb0acabab5b30928baf608b6d514b6a6726c65321e87699cf86` |
| `axioms.json` | `054eb906e10619071e3040bfe98d33c86729c873b12709f699d6d11277cf8b39` |
| `false-claims.json` | `544948109329f97976a4e596dbab6c79adfa2b5deac5f4d9c3b047ce20cd4a8a` |

No observation timed out or left an active process group. The existing focused
suite passed three tests (3.544 seconds); the unchanged parallel-GC scenario
passed one test (0.327 seconds). These are check times, not runtime speedups.
The existing Scheme component joins the added source premises, reuses its
Session, exposes missing provenance on source withdrawal and restores the same
answers when sources return. All model scopes stay partial, all three native
obligations stay open, and `satisfies=[]`. No production Python inference,
parser, workflow, new endpoint or native acceptance is introduced.

## Scope Correction And Reproduction

The earlier out-of-scope candidate artifacts were moved unchanged into the
isolated cache, not committed as pending runtime patches:

- `.cache/fixtures/shared-metadata-transaction/unadopted-source.lock.json`:
  `85ceb82f7a07b1101c57d60f22808439f73de7923bbe6dc8c90cb89420301dd9`.
- `.cache/fixtures/shared-metadata-transaction/unadopted-cumulative.patch`:
  `7d0f3df9edc0a4801e9b12b7d883683e8937eefe758d2f078e421507c9ae7748`.

They are historical observations of an unqualified excursion, not input sources
or an executable Recipe. No algorithmic failure or native success follows from
their existence. The implementation handoff is the reviewed research contract,
not these artifacts.

```sh
quint typecheck models/gambit/predicate_lock_retry_rooting.qnt
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry-wait.manifest.json --case predicate_lock_retry_rooting --out .cache/runtime-entry-models/handoff-wait-recheck
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json --case predicate_lock_retry_rooting --out .cache/runtime-entry-models/handoff-effects-recheck
.venv/bin/python -m unittest discover -s tests -p test_runtime_entry_formal.py -v
.venv/bin/python -m unittest discover -s tests -p test_parallel_gc_evidence_scenario.py -v
```

Use fresh verifier output paths and retain rejected attempts. Cache observations
do not become reproducible source dependencies or current native acceptance.
