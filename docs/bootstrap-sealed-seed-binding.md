# Bootstrap Sealed Seed Binding

## Retained Preflight Denial

The initial `sfun-owned-unwind` bootstrap adapter invocation terminated with
exit1 before launching `make`. It attempted to read the legacy seed identity
field `sourceRevision`, which the sealed source-core producer does not emit.
The actual exception was `KeyError: sourceRevision`. The isolated source copy
already existed, but no bootstrap stage had run and no bootstrap receipt was
produced. This is an adapter denial, not a GC or compiler failure.

## Explicit Source Authority

`bootstrap_runtime.py --source-lock` accepts a versioned source lock rather
than inventing a revision. It uses the existing `locked_source` materializer:
the pinned submodule and overlay must reproduce the locked candidate bytes.
Every selected file must also match the seed runtime. A conflicting legacy
revision is rejected. Source lock, overlay and materializer dependency hashes
are retained as seed inputs and checked after the bootstrap command.

The actual preflight for
`evidence/fixtures/sfun-owned-unwind/source.lock.json` passed, binding revision
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` and six dependency inputs. This
establishes the selected source slice, not reproducibility of all configuration
or generated outputs. The seed runtime identity independently binds its source
and artifact inventory.

The corrected two-pass run uses the same seed and GNU compiler, the upstream
`from-scratch` target, host-derived `make` parallelism and the retained600-second
budget. It does not disable SMP or either multiple-VM feature. Its final result
must be recorded separately; a passed preflight is not bootstrap acceptance.

## Regression Boundary

`tests/test_bootstrap_runtime.py` checks missing authority, candidate drift,
revision conflicts and existing generated-source/build-error guards. Its
temporary source-materializer mock tests the adapter contract only. The actual
materializer preflight above is separate evidence. Full native suites, Gerbil
acceptance and production performance remain open.

## Completed Two-Pass Observation

The corrected run completed in276.356seconds, exit0, within600seconds. Both
passes record all four upstream phases, with actual compiler work. The parent
was reaped and its process group quiescent. Original/immutable source and bound
seed inputs remained stable; recursive build-error inventory is empty. The
configuration retains SMP, multiple VMs and multiple threaded VMs with GNU GCC
and O0 diagnostic optimization. All three rebuilt artifact hashes are archived.

Portable receipt, candidate identity, adapter snapshot and redacted log are in
`evidence/source-results/fixtures/sfun-owned-unwind/two-pass-bootstrap`.
`tests/test_sfun_bootstrap_evidence.py` checks these identities and both phase
inventories. This is actual bootstrap completion, not a performance comparison.

Generated-byte parity is not established. Only `lib/_std.c` and `lib/_module.c`
differ from the seed generated sources. The latter contains changed absolute
build-location strings; the former changes encoded table data and remains
unaudited. Neither difference is silently normalized into parity. The rebuilt
candidate needs its own complete native and Gerbil qualification before any
runtime/release or user-facing performance admission.

The subsequent [Unicode scalar audit](bootstrap-unicode-scalar-audit.md)
compares the seed and rebuilt runtime over the complete scalar domain for
selected character operations. It is separate evidence, not a retroactive
generated-byte parity claim or full runtime qualification.
