# Wait, Nested Roots And Exit Validation

## Scope

This records local design checks for the
[source-bound feasibility audit](metadata-wait-roots-exits.md), not a runtime
patch, reproduced deadlock, native qualification or performance improvement.
No runtime C/SCM, TLS, synchronization primitive, production Python framework,
native Recipe, source lock, checkpoint or historical failure was modified by
this review. The cumulative native milestone is not advanced by these checks.

## Checked Identities

| Input | SHA-256 |
| --- | --- |
| `docs/experimental/metadata-wait-roots-exits.md` | `43cafc9de4988db4ca1ff8a6b365e3ac2a613a5496379c0013e66a0cb0b333cd` |
| `models/gambit/predicate_lock_retry_rooting.qnt` | `cdab928adc90a713f8ca4a989a6add02eb3016b4a5f5f8057c6e73f2a85c711b` |
| `models/gambit/ffi_gc_frame_protocol.qnt` | `8aace52f0c8318461a190caf9c2745602b1335bef63b5352090cfff586352e4c` |
| `models/gambit/lean/RuntimeEntryContracts.lean` | `504c54bdfbb5bb034ca131b9d0a6ef772c3df9738ef005b1aa23843b323ffa3b` |
| `models/gambit/lean/controls/RuntimeEntryFalseClaims.lean` | `7daf16b9f678813c9bcdc7980d632730d50838b190ba6d456d92cfd7b66eb8a7` |
| `evidence/scenarios/parallel-gc/runtime-entry.manifest.json` | `7ae81275804aa3adfd3b6ddb3f14834dae35b7dcdb2a6c1d3a4960f9ecd05733` |

The seven inspected overlay files (`gambit.h.in`, `setup.c`, `mem.c`, `mem.h`,
`_thread.scm`, `_kernel.scm`, `c_intf.c`) matched the versioned source lock.
The lock and cumulative patch digests remain those of the preceding audit.
In particular, `mem.h` is an overlay file, not interchangeable with baseline.

## Actual QNT Outcomes

Both extended files passed `quint typecheck` before TLC execution. New
projections used Quint 0.33.0, safety plus explicit weak-fair finite completion.

| Projection | Actual outcome | Limits |
| --- | --- | --- |
| `effectsStep` | Four expected controls; positive protocol passes, 16 distinct states / 20 generated. | Four abstract collective effects; registry self-wait assumes non-reentrant blocking, not Windows Critical Section semantics. No actual GC/resize/error implementation or C weak-memory proof. |
| `nestedStep` | Three expected controls; positive protocol passes, 22 distinct states / 28 generated. | Two logical root owners, up to two relocations and normal/caught-inner-error cleanup. No C root-stack ABI, arbitrary-depth collector proof or multi-shot continuation model. |
| Original FFI projection | Three existing controls plus positive safety pass at the final file hash. | Original RA/publication/reload assumptions remain unchanged. |
| Original predicate/retry projection | Two existing controls plus positive safety/completion pass at the final file hash. | Existing owner/waiter participation abstraction remains separate from the service effect envelope. |

Decoded controls were inspected, not merely counted:

- Registry control reaches phase 2 with resize selected, `registryHeld=true`
  and `blocked=true` after three states. This is an unsafe proposed composition
  under its mutex assumption, not attribution of a native timeout.
- Metadata control enters service still holding metadata protection.
- Nonreturning-exit control finishes with an owned temporary still live;
  return-site cleanup cannot repair it.
- Error control finishes after the error operation but reports zero instead
  of the model's error 7. Error 7 is an abstract distinguishable value, not a
  claimed Gambit native error number.
- Slot-overwrite control loses the outer root during relocation: both recorded
  roots become 12 where the outer identity should have become 8.
- Raw-backup control retains a valid traced outer root 8 but restores local 7
  after one relocation. A valid root does not make every cached copy current.
- Inner-exit control records error 7 with both frames still live, including the
  exited inner owner. Existing outer ownership is not authority to leak it.

All final checks had stable inputs and no timeout. The two new-projection
receipts explicitly retain `runtimeAdmitted=false`, `releaseAdmitted=false`
and native `not-run`. CPU/memory scheduling remained host-auto: this machine
reported 12 CPUs / 32 GiB, yielding two control jobs with six TLC workers each
and twelve positive workers. These observations are not hardcoded runtime
thread counts. No per-check watchdog was enlarged.

## Lean And Scheme Evidence

The guarded existing Lean adapter passed the thirteen declared theorem/axiom
checks and six expected false-claim rejections. The two additions are a
parameterized relocated-list suffix identity and contradiction of a strict
metadata/service/registry rank cycle. They do not assert the collector scans
such frames or that all prospective source lock edges already exist.

The existing Scheme component derives each transfer condition and all declared
premises, now including separate model scopes for service effects and nested
roots. Session reuse preserves answers; withdrawing any new reference source
or audit/model premise exposes missing provenance, and restoration recovers the
answer. Native obligations remain missing and `satisfies` is empty. No Python
applicability inference or duplicate evaluator was added.

Focused runtime-entry tests (three checks) and the unchanged parallel-GC
scenario check passed. This is not a full-repository or native-suite claim.

## Retained Receipts And Reproduction

Raw receipts below are disposable local cache observations, not source authority
or prerequisite files for reproducing the checks:

| Receipt under `.cache/runtime-entry-models/` | SHA-256 |
| --- | --- |
| `service-effects-platform-bound/receipt.json` | `c12d8c6f5569f25a2632047e6e90bf4306a58cbf0f399eab07d7539e5022487e` |
| `nested-root-ownership/receipt.json` | `34839f5fa9214993ec6eaba891b7dbd1336141a01625593f0cd69d7c51e8f932` |
| `nested-roots-original-ffi/receipt.json` | `667adb643395d98124fbf57e3ba16b4cfc054f77e39c35729b00b29ace0d5ef8` |
| `service-effects-original-retry/receipt.json` | `6ad19394a58512ce7997d9102a14a44ff9e4aa76f2fbc05428ece931b2bc09fa` |

Successful guarded Lean observations under `.cache/runtime-entry-formal/run-8drl5712/`:
`build.json` = `44b16955b49488043a264afd63583f00ead4588b865bee97767977c020b10551`,
`axioms.json` = `811204ed3c4b701c4d1244db8423269ee045506e6d0936aeebb62784f3bc3d1e`,
`false-claims.json` = `4b3f431952b3b28176aed025985a9ba287d3b5b0e882083da043bb0203176c5d`.
All exited, timed out neither build nor elaboration, and left their process
groups quiescent. Earlier receipts, including the effect model before its
platform assumption was made explicit, remain historical and are not rewritten.

Reproduce using the existing manifest/driver and fresh configured-cache paths:

```sh
quint typecheck models/gambit/predicate_lock_retry_rooting.qnt
quint typecheck models/gambit/ffi_gc_frame_protocol.qnt
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json --case predicate_lock_retry_rooting --out .cache/runtime-entry-models/service-recheck
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json --case ffi_gc_frame_protocol --out .cache/runtime-entry-models/nested-recheck
.venv/bin/gambit-smp check --case ffi_gc_frame_protocol --out .cache/runtime-entry-models/ffi-original-recheck
.venv/bin/gambit-smp verify --manifest evidence/research/pipe-predicate-sync-participation/retry-rooting.manifest.json --out .cache/runtime-entry-models/retry-original-recheck
.venv/bin/python -m unittest discover -s tests -p test_runtime_entry_formal.py -v
.venv/bin/python -m unittest discover -s tests -p test_parallel_gc_evidence_scenario.py -v
```

## What Is Feasible, What Remains Open

The source audit rules out treating general service as GC-only, fixed saved
slots as nestable roots, or ordinary C lexical cleanup as portable nonlocal
cleanup. The feasible small-refactor candidate is existing Scheme-rooted
preparation/retry/delivery around a bounded C transaction, without resources
spanning service or arbitrary callbacks. This preserves rather than replaces
the C backend, public FFI, existing SFUN admission and continuation return rules.

Still unclosed before implementation: actual generated liveness/frame maps at
the chosen boundary, all live C/startup caller adapters, complete reader/writer
publication and concrete lock acquisition graph, and the necessary private retry
representation without public ABI/error changes. New-global registration remains
conditional because it holds the VM registry and prepares per-VM segments.

Still unclosed before adoption: exact-source forced contention/GC/rehash,
normal/error/continuation callback behavior, original stress, cross-VM isolation
and performance gates. No result here replaces the other lane's native evidence
or requires it to repeat bootstrap for unchanged runtime source.
