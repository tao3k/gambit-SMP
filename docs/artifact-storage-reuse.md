# Artifact Storage Reuse

## Existing Admission Contract

`gambit.completed-runtime` is the reusable producer interface, not a second
build harness. It requires a completed PASS, exit zero, no timeout, reaped
parent and quiescent process group, exact source ancestry, two bootstrap
passes, all concurrency flags, GNU compiler identity and unchanged artifacts.
Failed or interrupted jobs cannot be reused as completed producers. The
consumer records original producer expenditure; reuse does not reset budgets
or qualify a cold build. New source bytes require a new producer.

## Storage Isolation

Completed-runtime, configured-source, review-fixture and suite-shard transfers
all call `artifact_storage.transfer_tree`; they do not create new producers.
On Darwin it attempts filesystem `clonefile` for each regular file: a distinct
inode with copy-on-write storage. Unsupported filesystems or cross-device
transfers fall back to a byte copy and report it. Permission and destination
errors remain errors. Symlinks retain their existing representation. No
hardlinks are used because consumer compilation can mutate files.

The existing before/after source and artifact hash checks remain mandatory.
`storageTransfer` reports actual clone/copy counts and explicitly makes no
native-acceptance or cold-build claim. `logicalBytes` is transported file size,
not physical APFS disk allocation. Destinations must be new or explicitly
empty runtime-view directories. Populated destinations, destination symlinks
and overlapping source/destination trees are rejected before copying; old
build output cannot silently be merged into a new observation. Tests cover real transfer, independent
consumer writes, symlinks, cross-device fallback and failure propagation.

## Reuse Versus Rebuild

Before `gambit.configure` clones, runs autoconf or configures a seed, the framework
checks registered completed-bootstrap references under `evidence/research`.
Matching source-lock and GNU GCC hashes plus identical configure arguments
require `gambit.completed-runtime`: duplicate bootstrap is denied with a
`buildReuseDecisions` receipt pointing at the producer. Registered evidence is
revalidated, not trusted as a cache index; drift fails closed instead of
silently rebuilding. Distinct configuration or compiler identities do not
match. The search consumes the existing deadline, not a separate budget.

The same guard remains at bootstrap as a second check. Materialization first
looks for a completed producer with the exact source-lock digest. It revalidates
the receipts and complete source-tree identity before and after an isolated
transfer, recording `REUSE_MATERIALIZED_SOURCE`. This skips repeated Git archives,
extraction and patch application; it does not borrow compiler outputs or admit
native correctness. Compiler/configuration matching remains a separate guard.
Registered source drift fails closed instead of silently generating another
tree. A first materialization removes its temporary archive after extraction.
The decision records its stage.
It does not automatically rewrite recipes or treat cache availability
as native admission. Explicit cold-build benchmarking needs a separately
reviewed contract; there is no untyped force-rebuild bypass in this guard.

Same-source native consumers must use the completed producer interface when
a matching producer is registered. New source or compiler bytes
require a new producer; an interrupted build is not a completed cache hit.
Mutable build phases retain isolated trees, using copy-on-write where possible.
No shared writable hardlinks or borrowed mutable producer directories are
allowed. Clean/cold-build qualification still performs its declared rebuild;
storage reuse does not remove that obligation. Copy fallback is visible in
receipts, not reported as a cache hit or performance improvement.

## Cleanup Boundary And Remaining Work

The package benchmark framework already has reviewed cleanup plans, digest
approval, exclusive leases, terminal-run checks and toolchain protection in
`tools/bench/gerbil_bench/cleanup.py` of the parent repository. Do not introduce
a competing recursive-delete path in the SMP framework.

Research fixture reclamation is not yet wired to that planner. It must protect
active runs, sealed producer references, accepted baselines and historical
evidence dependencies before selecting disposable working copies. There is
currently no claim that all research garbage is automatically reclaimed or
that a global disk quota is enforced. That dependency-aware integration
remains an explicit framework requirement. No cache directories were deleted
in this change.
