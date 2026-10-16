# Source Review Historical Binding

## Observed Failure

The complete graph's source-review tests rejected the existing source-unit
receipt because its original `recipes.py` digest differed from the current
reconstruction input. The original source lock, overlay and reviewed Gambit
source identities still matched. Updating the old receipt to the new tool hash
would fabricate an execution input; replacing it with the current vector-arity
candidate would change the reviewed source. Neither is permitted.

## Existing Framework Contract

`protocol_source_audit` now accepts an optional `sourceUnitInputArchive`
descriptor through the existing `historical_inputs.bindings` contract. The
descriptor pins the unchanged receipt and restores exact bytes of its original
input. Current reconstruction inputs remain separately bound under their
original paths; archived producer inputs are bound under their archive paths.
An archive cannot replace the currently reviewed source lock or overlay.
Context source hashes, source-unit status, all eight schedule observations,
compiler success and native-admission restrictions remain checked.

The restored file is
`evidence/source-results/fixtures/sync-retirement-source-history/recipes.py`.
Its SHA-256 is
`28aa3e3d60e538205fcfe9909992a73e81db70e134b04cea773ff7f0c23fa012`, exactly
the original receipt input. It is archival evidence, not an imported runtime
module or alternative executor. The old source-unit receipt retains SHA-256
`a36b50b1fb050e643f77463236db0da720c49fa9445c0ae5e2269c3927c0a560`.
No private source path or cache directory is required to consume this archive.

## Actual Verification And Boundaries

The real locked correspondence test passes without accessing numbered cache
sources. The full source-audit default/managed-engine agreement test passes
against the actual ASCENT provider. New regression controls reject altered
archive bytes and historical substitution of the current source lock, and
verify that current tool and historical tool hashes remain distinct without
changing the original receipt. The Bazel profile test uses a complete producer
context rather than bypassing the duplicate-build gate.

This restores source-review provenance for its original bounded schedules.
It does not prove current candidate source refinement, current runtime
correctness, whole-graph acceptance or SMP release performance. The 105-review
failure and other native gates remain independently required.

## Human Test Boundary

The constructor failure fixture using `RTLD_NEXT` and
`___cleanup_owned_vmstate` is not authorized for execution. It must not be
replaced by another injection mechanism to bypass that decision. Only official
loader/FFI paths are admitted for further native work. Its four constructor
failure branches remain native coverage gaps; finite model or source-schedule
observations do not close them.
