# Source, Evidence And Local Execution Storage

JSON is a representation, not a retention class. A successful process, a SHA
field, an ASCENT answer or a filename containing `evidence` does not automatically
make its output a Git asset. Failed results may be important durable evidence;
successful debug logs may be disposable.

| Class | Location | Retention and authority |
| --- | --- | --- |
| Source and research definitions | `src/`, `models/`, `library/`, `patches/`, Evidence DSL, Recipes and locks | Version in Git; exact source and policy remain bound inputs |
| Selected research evidence | `evidence/` and reviewed notes in `docs/` | Explicitly publish typed observations, failure identities, source/fixture/receipt digests, actual outcomes, budgets and evidence limits; review before commit |
| Execution output | `.cache/` or an explicit external local artifact directory | Logs, traces, generated graphs, test output, request/response bodies, wheel/build products and intermediate inventories stay out of Git |
| Local operational state | `.cache/reasoning`, `.cache/research-actions`, `.cache/research/budget-ledgers` | Pending requests, journal heads and budget reservations are not disposable logs; migrate explicitly, never reset them |
| Historical active workspace custody | Existing ignored `.data/fixtures` stores | Old references remain exact; active leases/quarantine stay with their original workspaces and are not silently moved |

## Framework Behavior

- The cache root is exactly `git rev-parse --show-toplevel` plus `.cache/`, not
  the current working directory or a caller-selected source subdirectory. Nested
  repositories and Git worktrees own separate caches. A missing Git repository
  or a cache symlink escaping that root is an error, not a fallback to `cwd`.
- Recipe execution no longer automatically writes every intermediate tree inventory
  into `evidence/research/workspace-states`. New observations go to
  `.cache/research/workspace-states`, retain their exact hashes and still undergo
  source/binary identity checks. Missing cached state yields UNKNOWN/unavailable,
  not an invented successful runtime or automatic reconstruction.
- ASCENT context, review, validation and query output paths, process batches,
  research execution and engine seals reject Git source destinations before work
  starts. Use `.cache/ascent/<run>` for new local runs. New in-repository `.data/`
  and `.ci/` output paths are rejected. Explicit external temporary directories
  remain supported for isolated host/test use; defaults never depend on `cwd`.
- Runtime-only argparse adapters share the same path type. Historical producers,
  source provisioning, downloaded PR audits, compiler/model controls and suite
  coverage do not get separate output-directory exceptions. Explicit publication
  commands below retain source/Evidence destinations by their distinct contracts.
- CI seals, build/test runs, artifact downloads and raw uploads use `.cache/ci`
  and `.cache/fixtures`. New fixture references include `.cache/fixtures` explicitly;
  old reference names still select their original `.data/fixtures` store without
  changing a recorded path or SHA. No old run is relabeled as a new run.
- Paper PDFs, extracted full text and search aids default to `.cache/papers`.
  Fixed URL/hash pins and reviewed notes stay in Git. An explicit old local cache
  may still be selected; it is not a source alias or a replacement for a pin.
- `evidence --refresh` is an explicit, reviewed materialization of the deterministic
  catalog snapshot, not a log dump. `research --export-producer` explicitly publishes
  a typed producer reference. These publication operations are distinct from
  runtime `--out`; neither provides admission or permission by itself.
- `.cache/` is ignored. A normal commit must not force-add raw output to bypass
  that boundary. A local output need not be reproducible or retained indefinitely.
  If a claim needs audit evidence, publish the selected typed facts and provenance
  first. Do not claim raw logs are archived when they are only local or deleted.

## Existing Evidence And Cleanup

The audit found 92 versioned workspace-state inventories (30,439,189 bytes).
The 54 automatic records under `evidence/research/workspace-states` alone occupied
17,378,270 bytes. Those 54 payloads are removed from the current Git tree; their
exact bytes are cached under `.cache/history/git/<sha256>/record.json`. Git keeps
the explicit `evidence/storage-history.json` index: original path, original SHA-256,
fixed original commit and Git blob identity. The reader checks commit membership
and the payload digest; it may rematerialize only these explicitly indexed old
records from local Git objects. A corrupt cache is rejected rather than hidden.
This is historical metadata lookup, not a source-path alias, runtime restoration,
new execution or admission. Old receipts and their reference SHAs are unchanged.
The same explicit index preserves the original continuation-accounting source
used by a historical model fixture as data only; it is never imported/executed.
CI fetches full Git history so pinned historical objects are available without
network fallback during record lookup. A shallow clone missing them fails closed.
The other source-state declarations are explicitly selected research inputs and
are not removed merely because their schema or filename resembles a cache.

Existing local SQLite observations and Action handles are also not Git evidence.
They contain operational history, including pending work and retry protection;
being ignored does not make deleting them safe during an active campaign. This
change relocates new access to `.cache/` without resetting them. When an old
database exists but no new one exists, access fails until explicit migration.
Migration takes a non-waiting SQLite writer reservation, uses SQLite backup,
checks integrity/schema/row counts and refuses overwrite. Originals remain intact;
old processes must not be assumed to have stopped merely because backup finished.
A separately selected observation can be published as typed Evidence with its
real provenance and limits. Original budget ledgers remain bound by old references;
a fresh cache directory cannot reset their expenditure or reservations.

## Write-Path Audit

The audit separates runtime-only adapter arguments from publication paths:

| Writer family | Result location / boundary |
| --- | --- |
| ASCENT catalog/review/context/validation | Shared runtime-output guard; `.cache/ascent` is the documented run location |
| Recipe/sealed worker/evaluation requests, answers, explanations and logs | Inside the guarded run directory; intermediate custody snapshots in `.cache/research/workspace-states` |
| Model, compiler, source-unit and suite adapters | Shared runtime argument; no direct `evidence/` execution output |
| Upstream PR download/audit, papers and source Git transport | Guarded cache arguments; `.cache/papers` and `.cache/source-cache` defaults; pins stay in Git |
| Engine/runtime export and cross-job reuse | Cache artifacts, original byte/identity checks, no fresh execution budget |
| SQLite journal, Action reservation, continuation ledger | Stateful local stores; not a generated Evidence publication |
| `publish-protocol`, `publish-progress`, `publish-source-observation` | Explicit publication of selected source/model observations; raw payload/log directories remain ignored |
| `crash`, identity/source-delta export, upstream triage export, `evidence --refresh`, `research --export-producer` | Explicit selected portable evidence/source projection, not an execution log destination |

No publication is deemed valid because it landed under `evidence/`. Its original
schema, provenance and semantic checks still apply. No claim of raw-log durability
or reproducible execution is inferred from the Git archive index.

Deleting an unused debug log does not require reconstructing its run. Conversely,
do not delete the only failure record used by retry review, an active lease or
quarantine record, or a referenced publication payload and then claim its evidence
is still available. Historical-source recovery and active baseline/candidate
custody are separate from cache retention.

## Scope Of This Repair

These are downstream framework storage boundaries, not a change to ASCENT's
inference semantics, native execution, time budgets or upstream wheel packaging.
Existing historical producers and caller-written files still need audit before
any bulk relocation. No entire `.data/` tree or published Evidence set is cleaned
automatically. Local storage controls are not whole-framework/native acceptance.
