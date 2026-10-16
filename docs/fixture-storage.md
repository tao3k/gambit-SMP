# Disposable Source Storage

Versioned submodule revisions, overlays and source locks are authoritative.
Generated source is not evidence authority and must not accumulate per attempt.

The framework materializer and artifact transfer share a file-locked limit of
two source trees under `.data/fixtures`: one accepted baseline and one current
candidate. A third tree is rejected, not automatically admitted by a new name.
This does not impose a limit on small model receipts or failure logs.

Use `make clean` in an existing inactive workspace for compatible rebuilds.
Source changes still require lock validation and fresh qualification; cached
objects never establish correctness or a cold-build result. Expired source may
be removed using `python -m gambit_smp.fixture_storage`, first without `--apply`
to inspect the plan, then with explicit retained paths and `--apply`.

Cleanup rejects active open files, working directories and executable mappings,
and refuses Git checkouts. It copies JSON receipts and log/Markdown/output
evidence outside the cleanup root before removing reproducible source/build
trees. A per-tree deletion receipt records partial completion after interruption.
Historical receipts remain historical; removal does not turn failures into
passes or qualify changed source.
