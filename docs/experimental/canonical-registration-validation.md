# Canonical Registration Research Validation

The [source contract](canonical-registration-contract.md) supplements the
[existing Stage-One Recipe](stage-one-handoff-recipe.md). These are research
results, not runtime changes, native qualification or measured speedups.

## Inputs And Inspected Controls

| Input | SHA-256 |
| --- | --- |
| Source contract | `9ee56e3beb1d3ec39d953f798261037bc797d24e5c885f0880e709996b35b4e3` |
| Existing metadata QNT with added key projection | `e0c96e8829b4811438ea5341f9f8e808f1e94c592073841003f432b96641ea94` |
| Existing Lean module | `0c9b4594c19b681588a6f6f463ebbb0ca9d1f8d323be274e02247cd6b2a41020` |
| False-claim controls | `c026ab0b583b1f6bbc68231b5f082f3dc315a095f8b97aaa420683d779890b1b` |
| Canonical manifest | `142cef5522e27e1e1e55cb8f02e537eef0d90c3c47ae5179d77a3c36d68e8009` |

All three expected negative controls were inspected:

- Skipping the owned recheck gives a 12-state trace with both contenders having
  observed a miss, two initialized live identities, results 1 and 2, and two
  successful preparations. Independent atomic allocation/insertion is not a
  canonical same-key transaction.
- Treating growth OOM as insertion failure gives an eight-state trace with
  live identity/result 1 and error 7 simultaneously. The public result cannot
  honestly describe that committed insertion as a preparation failure.
- Retracting membership after growth OOM gives an eight-state trace with
  returned identity 2 but an empty live membership and absent binding. Rollback
  of a private precommit prefix is not rollback of a published identity.

The corrected key safety and weak-fair completion check passed over **180
distinct / 270 generated states**, covering both contenders, optional precommit
preparation failure and optional postcommit growth failure. Atomic ownership,
valid key equality, initialization and fair leaf completion remain premises.
It does not model C visibility, real byte allocation/retention, arbitrary
collisions, root enumeration or VM cells. It does not extend uniqueness to every
direct `___new_symkey` caller or claim the source already implements the repair.

The modified metadata source's existing profiles were rechecked: **ten expected
controls**, fixed safety/completion **1,008 distinct / 2,956 generated states**.
The existing importing VM/publication composition was also rechecked: **two
expected controls**, fixed safety/completion **168 distinct / 387 generated
states**. The added key state stays constant in those projections; these checks
preserve their contracts but do not merge every key/GC/VM/FFI interleaving.

| Receipt beneath `.cache/` | SHA-256 |
| --- | --- |
| `runtime-entry-models/canonical-commit-growth/receipt.json` | `be23790736b675fe799c702d943a2007e35b7f5ec2b756ea3f87f1bac7f16c1f` |
| `runtime-entry-models/canonical-existing-metadata/receipt.json` | `0e1d34406236a7e3e3e42b2f2860a95697a3e6dfc678fd1b079c157823e7707b` |
| `runtime-entry-models/canonical-imported-vm-composition/receipt.json` | `9bbb85f610fe80f752c7ba0a9ac34cdb275761fdc0ef98401b3686a524283a01` |

All report stable context, no timeout, native `not-run` and no runtime/release
admission. Existing host-auto scheduling selected 12 processors, paired controls
with six TLC workers each, and 12 workers for positives. These are observations,
not hardcoded machine or model limits. Unchanged wait/replay transitions were
not rerun merely because the Lean module gained separate additive lemmas; their
old receipts retain their original context and are historical, not current
extended-proof qualification.

## Lean And Evidence Relations

The existing guarded Lean build/check passed with **24 theorem inventories**,
standard axioms only and no `sorryAx`. All **14 false controls** were rejected.
The focused research suite passed **3 tests (1.988 s)** and the unchanged
parallel-GC scenario **1 test (0.190 s)**. These times are checker observations,
not native performance measurements. The existing Scheme relations expose
source withdrawal, restore the same answers, and reuse their Session; all six
model scopes remain partial, all three native requirements remain open and
`satisfies=[]`. No production Python inference or new interface is added.

Guarded observations under `.cache/runtime-entry-formal/run-8it12oct/`:

| Observation | SHA-256 |
| --- | --- |
| `build.json` | `7760e48caa6fd73191fe4e0337966a6399e363388b6395db63aa06ee83e5b7c5` |
| `axioms.json` | `2a66303d5b7924b5a2fa6c5a0608a1b75fdb19bd6fa84352ae4e99c21237049f` |
| `false-claims.json` | `7d9994f5be82604685216deeee4bc28d4582363dc62426830f1f2ad511914b6a` |

No observation timed out or left an active process group. Raw observations stay
in cache, not reproducible source dependencies. Use the existing manifests with
fresh output paths to reproduce these finite checks and preserve rejected runs.

## Parent CI And Historical Reflection Repair

At parent `0891fea6c24e9550392b866a8f6b896b4432d8d2`, `patch-contracts` and native
`build` passed. The native `upstream-check` then failed in `tests/error.scm`:
`make test2` reported error 70; the enclosing command exited 2 without timeout.
Its retained test-log digest is
`06d9004a7922f466473fb1f6c9dd60dc75c2f9f9a2b59e3d66ae52bc5a1c1964`.
Other native modules were still running at that inspection. This failed native
result remains open; no causal link to canonical registration is inferred and
no native rerun or runtime repair was attempted by this research thread.
The separate framework job failed before tests with
`stale reflection artifact: docs/high-performance-reliability-stability.md`.
Its process exited 1 after 0.647 seconds, without timeout. Retained log hash:
`49f66ec1e98e401e52ac67b8614c5cdbdefc5951d1908eca7580ab16511fa611`.
This is not an algorithmic/native counterexample or a full-green result.

The Reflection expected digest `d279cc7f7973b72ca71052c50799248fda7c6c750afd82d88681cbf47bb157cc`
matches the original document at Git revision `37f0432` and the already-retained
`docs/callback-context-performance-reliability-stability.md` byte-for-byte.
The current general design document is different. The repaired reference points
to that exact historical source instead of replacing its expected hash or
claiming the current document supports the old result. No historical success,
failure or model receipt is rewritten. An in-memory publication-tree audit of
all **288 Reflection artifact bindings** passed after that path correction.
This removes the observed provenance failure; only a completed remote run can
establish complete CI success.

## Remaining Whole-Package Obligations

The transferable Recipe now states the canonical caller classes, owned current
lookup, pre/postcommit outcomes and same-name/growth fault oracles. Remaining
implementation evidence is still required for the whole enabled wait/effect
census, actual reader/writer visibility, binding-to-current-VM roots, generated
root maps, supported callback/continuation exits and init/retirement composition.
Preserve the C backend and valid FFI/continuations with one repaired version,
effective configuration and full rebuild. This research does not advance or
reset native progress, change a runtime patch, or rerun another lane's bootstrap
and native stresses.
