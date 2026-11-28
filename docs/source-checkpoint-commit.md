# Source checkpoints and native qualification

`gambit_smp.revision_submission.commit_source_checkpoint` saves an explicitly
selected source snapshot at the user's request. It is a source-control
transaction, separate from `RevisionSubmission`'s qualified integration path.
It advances neither an architecture result nor the SMP family ledger.

Each invocation requires the exact request path and SHA-256 in the selected
work item's `sourceCheckpointRequests` registration. The registration derives
from an explicit user source-checkpoint request, never from an observation or
an agent's preference to skip native gates. It is bound throughout publication;
there is no wildcard or force grant. Remove a scoped grant after publication.

The request is `revision-source-checkpoint-request.v1`: one exact repository
and predecessor, a source scope and ledger, explicit byte-hashed files or
Git links, original JSON observation references, a commit message and the nine
existing audit fields. Snapshot files can come from retained task evidence;
ongoing working files do not have to be replaced with historical versions.
The stored observations retain their original epochs. They are not relabelled
as execution of the resulting Git tree, a clean build or a new native producer.

The Python owner uses a private index, writes the selected blobs unchanged and
advances the branch with Git's compare-and-swap reference update. A concurrent
HEAD update refuses publication. Sources and observations must match their
recorded hashes. Neither the real index nor working files are written. A child
checkpoint can be selected as an exact Git link in a separate parent checkpoint.
No push, source generation, compiler invocation or build/test hook is performed.

The receipt is `revision-source-checkpoint.v1`, with `complete=false`,
`qualificationKind=source-checkpoint`, `progressDelta=0` and
`runtimeAdmitted=false`. The native submission constructor explicitly rejects
this receipt kind even if a caller changes its `complete` flag. There is no
force/ignore-admission option. Qualified native publication continues through
the existing SysML/ASCENT gates and complete source/native delivery contract.

Invoke the Python API through the existing workspace supervisor and stable task.
The caller supplies source-selection data and an existing Python entry using
this API; it must not bypass a registered work item's execution boundary.
Task records and private indexes belong under `.cache/tasks/TASK/`.

The regression owner is `tests/contracts/source_checkpoint/test_submission.py`.
Its real Git fixtures cover selection versus unrelated staging and newer work,
source/observation drift, stale predecessors, target escape, Git links,
concurrent ref updates and refusal to promote a checkpoint to native evidence.
