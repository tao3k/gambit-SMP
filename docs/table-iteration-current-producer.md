# Current Producer GC Iteration Qualification

## Closed Counterexample

The existing framework recipe
`smp-vector-arity-table-iteration-reviewed-counterexample` is CURRENT/PASS.
It binds the old single-file omission/duplicate failure to the existing typed
snapshot repair in the current immutable producer; no runtime source patch
was added for this qualification.

| Observation | Result |
| --- | --- |
| Whole recipe | PASS, 48.252/300 seconds |
| QNT snapshot specification | PASS |
| QNT old traversal negative control | Expected counterexample, PASS |
| QNT wrong source-tag negative control | Expected counterexample, PASS |
| ASCENT source/assumption/budget review | PASS |
| Unchanged original interpreted fixture | 1/1 PASS, 0.055908 seconds |
| Native deadline | Original 20 seconds, not widened |
| Teardown | Parent reaped, process group quiescent |

The fixture digest remains
`57f8cea541700c6f22b281961f9d360976fc5167c50e376e4217127175d1f997`.
Its read-only callback still forces GC and asserts exactly one visit per
rooted logical key. The old failure remains in `native-failures.json`, receipt
`29bfd9c9bdebef504a6ec45a689f540a587ebad21ed3b16d39d448f3d995f381`.
The failed schema preflight is retained separately, not counted as a runtime
failure or silently overwritten.

## Reproducible Binding

Use `vector-arity-table-iteration-reviewed.recipe.json`, its typed review
intent and causal evidence in `evidence/research/smp-threaded-vm-native-grid`.
The source lock pins vendor revision
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus the consolidated patch.
All three concurrency flags remain enabled with GNU GCC. The single completed
bootstrap producer is reused; its transfer reports 2243 filesystem clones,
zero byte copies and no hardlinks.

The portable native stdout is retained in
`evidence/model-results/table-iteration-current-producer/native.stdout`, digest
`0093580b26cf2ac88b6e0e851141c64c00ab6b56ab656369184b29a77cdfa1c2`.
It contains no personal absolute path or cache reference. The authoritative
local outer receipt digest is
`eb10ca9e3dd35a2464d47d7c1a8f1a8dcf4e857aca76694619aecfbc8b8295d4`;
the native step receipt digest is
`0f497bbd92541378b06a1ae6069407958ccd2cae8f1a7002ab47b71edbcc0eec`.
The portable transcript and this reviewed summary do not replace the full
sealed receipt or allow deleting its dependency chain.

## Remaining Boundaries

This closes the current-producer interpreted counterexample for
`018-gc-table-iteration`; the historical DENY is retained. The finite model
assumes atomic typed capture after allocation and rooted keys. It is not a
source-refinement proof or full weak-table/concurrent-mutation/GC-FFI result.
No performance ratio against the old failing execution is admitted.

The milestone remains 2/12. Complete gsc, complete PR gsi/gsc, stress gsi/gsc,
registry lifetime, lifecycle faults, full GC/FFI, Gerbil correctness and release
performance remain open. Compiled qualification of this diagnostic also remains
open and cannot be inferred from the interpreted result.
