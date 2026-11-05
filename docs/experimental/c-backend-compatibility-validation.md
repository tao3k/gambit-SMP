# C Backend Compatibility Validation

This records local checks of the [compatibility review](c-backend-compatibility.md).
No runtime implementation, native bootstrap, stress test or other-lane
checkpoint was changed or executed. Earlier receipts remain tied to their
original digests; passing source/finite-model checks does not admit a runtime.

## Bound Inputs And Source Findings

| Input | SHA-256 |
| --- | --- |
| `docs/experimental/c-backend-compatibility.md` | `42e96c60366c0250daeaa8e153dea13930648abc3d2f5aa055f058054fd4d86e` |
| `models/gambit/runtime_metadata_allocation.qnt` | `0cf0ea4e994871ef122e2b075f0461ebd3ebbec7f1c7ca07e0d8631c61b2814f` |
| `evidence/scenarios/parallel-gc/runtime-entry.manifest.json` | `e9880efc24c4f8e305382f0965a1257d818a94b06929b2268e6e699028ce0497` |
| `models/gambit/lean/RuntimeEntryContracts.lean` (unchanged) | `2b530d4829f4c2f22d9cd2ddac26eb5625ef13c17df58b07f8d480eb202b8f8f` |

The read-only overlay configure/header/setup digests matched the existing lock.
Pinned Gambit README/manual and OCaml startup source hashes were added to the
existing context and source relations. No cache source path is an authority.

The source audit establishes distinct compatibility premises, not reproduced
native faults: ordinary nested FFI is documented; registry-owned release
callbacks have a different effect context; module version/size checks cannot
certify old inline publication semantics; partial memory setup and initialized
guards need explicit prefix ownership; effective capability macros and OS
primitive return types are not interchangeable. OCaml explicitly rejects
post-shutdown startup, so its startup counter is not a restart guarantee.

## QNT Controls And Positive Checks

Typechecking passed. The existing verifier accepted **ten expected negative
controls** and positive safety/weak-fair completion across **1,008 distinct
states, 2,956 generated**. The eight previous reservation/reader/publication/
resource controls remain at the current digest. Two added traces were inspected:

- Leaked private prefix: six states pass P/M and first-table setup, fail the
  second table, then discard ownership on retry without releasing the completed
  prefix; the retained `leaked=true` witness violates `privatePrefixReleased`.
- Destroy before initialization: three states fail the first guard, reach empty
  ownership, then attempt unconditional destruction; `invalidDestroy=true`
  violates `initializedOnlyDestroyed`.

Positive setup chooses failure at any of the four prefix cutpoints or no
failure. Partial entered-memory ownership is unwound before guards, only owned
resources are released, and a single private retry occurs before publication.
This is a finite projection of the new guard/memory unit. It does not cover
the existing OS/interrupt/V prefix, OS exception semantics, original-error
propagation, late module mutation, complete runtime shutdown/restart or C weak
memory. Those remain explicit source/native obligations, not implicit passes.

Receipt: `.cache/runtime-entry-models/private-prefix-compatibility/receipt.json`,
SHA-256 `fad32a8f78981c7c749816636fba667be3717f1b5a9b8883bed2df2b51922fa4`.
It has stable context/source, no check timeouts, native `not-run`, and both
runtime/release admission false. The unchanged host-auto scheduler selected two
control jobs and six TLC workers each, twelve for the serial positive check on
this host. The 37.336-second formal campaign is not a runtime benchmark or a
fixed CPU/VM configuration. Budgets were not widened.

## Existing Lean And Scheme Evidence

Unchanged guarded Lean checks passed: sixteen theorem inventories, no `sorryAx`,
standard axioms only; all nine deliberately false claims were rejected. The
interval/order/owned-exit lemmas remain conditional. No additional arithmetic
lemma was invented to claim complete C-backend or callback compatibility.

Observations under `.cache/runtime-entry-formal/run-z5454zjy/`:

| Observation | SHA-256 |
| --- | --- |
| `build.json` | `8cc43f8a83f469f50243035cd2a425ee3c53d895ce5ef05c369dadcea606db51` |
| `axioms.json` | `32f7f27ef889721f99dd785e172dc86c613366e53e638e2f106aae2e4e4c2700` |
| `false-claims.json` | `f66aaa330999a1b8893020cb02b631a9e57fe9314e1a36fb20f9d887fa17af26` |

Every guarded observation left a quiescent process group, without timeout.
Existing focused tests passed: three runtime-entry checks in 1.708 seconds and
one unchanged parallel-GC scenario check in 0.341 seconds. Local check durations
are not native acceptance/performance results.

The existing Scheme component consumes the added preservation, callback, inline
ABI, prefix and effective-profile premises. Session reuse is unchanged; each
new source is withdrawn to expose missing premise provenance, then restored to
recover the original answer. Native obligations remain missing, model scopes
remain partial, and `satisfies=[]`. Python edits only add these source identities
to the existing focused provenance test; no production parser, inference engine,
workflow or new interface was added.

## Reproduction

```sh
quint typecheck models/gambit/runtime_metadata_allocation.qnt
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json --case runtime_metadata_allocation --out .cache/runtime-entry-models/private-prefix-recheck
.venv/bin/python -m unittest discover -s tests -p test_runtime_entry_formal.py -v
.venv/bin/python -m unittest discover -s tests -p test_parallel_gc_evidence_scenario.py -v
```

Use fresh verifier output paths. Cache output is not the source dependency or a
native milestone certificate.
