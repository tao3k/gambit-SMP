# Candidate 026 Submodule Inputs

The current source correspondence no longer reads the old candidate cache.
Its source is the fixed `vendor/gambit` submodule revision plus
`patches/snapshots/candidate026-audited-source.patch`, bound by
`evidence/runtime-source-026.lock.json`. No second full source tree is versioned.

The overlay restores all five original correspondence inputs: `lib/mem.c`,
`lib/setup.c`, `include/gambit.h.in`, `configure.ac`, and `lib/_thread.scm`.
The last two also differ from the submodule; they must not silently be left at
their upstream bytes. This is not the candidate 027 source lock, and none of
the original candidate 026 file identities is replaced with candidate 027.

Provision the pinned submodule using the existing source provisioner, then run:

```sh
uv run --locked gambit-smp sync-schedule \
  --source-lock evidence/runtime-source-026.lock.json \
  --gcc "$GNU_CC" --out "$LOCAL_BUILD_DIR/sync-schedule"
```

The runner reconstructs source from the committed tree and overlay, verifies
all selected file hashes, and uses a disposable source directory. Receipts bind
the versioned lock, overlay, extraction code and the selected source file hash;
they do not require that disposable directory to exist on another machine.
The correspondence auditor reconstructs the same source rather than reading
the old candidate cache. Cache source roots are rejected as current inputs.

The eight GNU GCC schedule controls were rerun against this source contract.
Receipt `evidence/model-results/sync-retirement-submodule-003.json` preserves
the original function digest and all expected outcomes, including negative
policies. After adding candidate 029's sixth header input to the provisioner,
all eight controls were replayed into `sync-retirement-submodule-005.json`, now
the current correspondence receipt. Earlier receipts remain historical records,
not rewritten passes. See `gc-notification-source-candidate.md` for the actual
header compilation failure that required this additional input.

This closes the source-cache dependency for this correspondence and schedule
runner only. Other historical protocol manifests still refer to cached source
or paper text; they have not all been migrated by this change. A full clean
checkout graph must not be described as reproducible until those required
inputs are closed as well. No Gambit native, bootstrap or Gerbil acceptance
is implied by source reconstruction or mocked schedule controls.
