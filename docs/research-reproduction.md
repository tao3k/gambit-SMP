# Reproducing Research Inputs

## Historical Offline Closure

The offline source-input gate passed at source commit
`86e9145b8d3b57c63905145a4d3694fde986e06f`. A fresh clone using
`--no-local --no-hardlinks`, with neither `.data` nor `.venv`, initialized the
fixed submodule from the versioned capsule and passed full source-tree fsck.
The strict committed-input check verified 24 inputs and seven paper pins;
materialization matched all three audited candidate source hashes. All 32
focused source/paper/input tests passed in that clean checkout. The observation
summary is `evidence/research-source-closure.json`; it explicitly does not
archive raw command logs or admit model/native execution.

This closes offline reproduction of this source slice and portable manifest,
not upstream network health, the historical manifest migration backlog,
ASCENT installation, complete toolchain generation or native/runtime gates.
The older failed attempts below remain historical observations. This is a v1
historical result, not qualification of the current v2 provisioner. The original
receipts and source-input commit are not rewritten by the migration below.

## Current Revision Source

The v2 source manifest pins the same canonical upstream URL and full revision,
with SHA256 of the raw Git commit and complete NUL-delimited recursive Git tree
inventory. Existing per-file base/candidate and overlay SHA256 locks remain
unchanged. No `.bundle` is a current Git input. `source-provisioning-history.json`
records the exact historical commit and bundle SHA; the old bundle can still be
read using `git show <historicalCommit>:<historicalBundle>` or reproduced in an
isolated checkout of that commit. Do not copy old receipts into a new run.

The optional `transportRepository` selects an explicitly configured mirror in
the same provisioning manifest. It now selects `https://github.com/tao3k/gambit.git`,
whose `research/pinned-gerbil-gambit` branch publishes the unchanged locked
commit. `.gitmodules` and cache remotes must match that transport URL; the
original `repository` still matches the immutable source lock. Commit, complete
tree, parent and per-file checks are unchanged. Changing transport does not
rebind historical evidence or admit a runtime.

Provisioning fetches the exact revision, never an upstream branch tip. TLS is
not disabled. For offline use, prepare a portable bare Git object cache before
disconnecting, or transfer objects from an already verified local source repo:

```sh
PYTHONPATH=src python3 -m gambit_smp.source_provision \
  --prepare-cache "$SOURCE_CACHE"
# Alternative, without network (the local commit and full tree are verified):
PYTHONPATH=src python3 -m gambit_smp.source_provision \
  --prepare-cache "$SOURCE_CACHE" --from-repository "$PINNED_SOURCE_REPOSITORY"
# In a fresh checkout, with the prepared cache accessible:
PYTHONPATH=src python3 -m gambit_smp.source_provision \
  --offline --cache "$SOURCE_CACHE"
```

Each preparation command requires a fresh destination; choose one alternative,
not both against the same directory. The default cache is ignored
`.cache/source-cache/gambit.git`. Cache paths are transport, not source identities
or committed evidence. Initialization verifies fsck, canonical URL, commit SHA,
complete tree-inventory SHA, commit parents and base-file SHA before admitting a
checkout. Git transports real shallow metadata; the provisioner no longer
manufactures a shallow boundary. A missing offline cache fails without fetching.
No already populated submodule or existing cache is modified. Fully disconnected
reproduction requires the prepared objects; a pin alone cannot supply missing
source bytes. Neither local transfer nor offline initialization establishes
upstream network health, a complete toolchain or runtime correctness.

### Migration Verification

The v2 provisioner passed 36 source-provisioning, materialization and
reproduction tests in 13.220 seconds under the unchanged 15-second budget,
with no skips, timeout or input drift. Raw logs and process receipts are local
at `.data/source-revision-044/tests-002`; they are not versioned raw evidence.

A fresh `--no-local --no-hardlinks` checkout with no bundle working file
initialized the pinned source offline from a verified bare object cache. Full
fsck and reproduction checks for the default, 026 and 029 locks passed; all
processes exited successfully and were reaped. Inputs remained byte-identical.
The step logs are local at `.data/source-revision-044/fresh-001`.
The current edited v2 inputs were explicitly copied into that fresh checkout,
so this is not a strict committed-input qualification or a new runtime receipt.
The canonical upstream network fetch was not qualified by this offline run.

## Source Identity

### Candidate 026

The source correspondence uses `evidence/runtime-source-026.lock.json`, not
the default candidate027 source lock. It binds the same upstream submodule
revision plus `patches/snapshots/candidate026-audited-source.patch`. The five
audited inputs are `configure.ac`, `include/gambit.h.in`, `lib/_thread.scm`,
`lib/mem.c` and `lib/setup.c`. The original 026 setup identity is
`98b39f7204d1086550d2666be67f447f0f83410e941ef7f2cb3adbea3c19391f`;
substituting candidate027's setup file would invalidate this correspondence.

After initializing the fixed submodule in a fresh checkout, independently check
this candidate slice and the committed input bytes:

```sh
PYTHONPATH=src python3 -m gambit_smp.source_provision
PYTHONPATH=src python3 -m gambit_smp.reproduction_check \
  --source-lock evidence/runtime-source-026.lock.json --require-committed
PYTHONPATH=src python3 -m gambit_smp.source_materialize \
  --lock evidence/runtime-source-026.lock.json --out "$SOURCE_OUT"
```

`SOURCE_OUT` must name a fresh output directory. These checks require no ASCENT.
Offline initialization requires a prepared verified object cache; online
initialization fetches the pinned revision. The source-lock check archives the pinned
commit, applies the versioned overlay and verifies all five candidate hashes;
its strict gate rejects uncommitted or modified required input bytes. It is
distinct from the default recursive-model/027 input check. It does not admit
the full configured 026 toolchain, model refinements or native execution.

Historical schedules and failed native attempts retain their original source
and receipt identities. The new source-bound schedule receipt may document a
new replay, but must not overwrite an old receipt or relabel its results. The
eight extracted/mock schedule controls are not full Gambit runtime tests.

The clean-checkout gate passed at source commit
`428275733bcbb5a1a447ae290caa6dd732a5444f`: all 18 source inputs and 14
correspondence inputs matched committed bytes, all five source hashes matched,
and 33 focused tests passed. GNU GCC 16.2.0 replayed the eight diagnostic
schedules from restored source, preserving both direct-destruction negative
outcomes. The 288 previously committed model-result files stayed byte-identical.
The bounded observation is `evidence/source-026-clean-reproduction.json`;
the new schedule logs and extracted source are hashed under
`evidence/model-results/sync-retirement-submodule-clean-004/archive.json`.
This closes this audited slice/correspondence, not all historical model contexts,
the full configured toolchain or the five pending native gates.

Source inputs and cache outputs are different categories. JSON source bindings
use repository-relative paths such as `vendor/gambit/lib/mem.c`, backed by the
fixed Git submodule revision and checked hashes, not a local runtime cache.
Candidate differences remain versioned overlays with their own hashes. A
relative alias resolving into a cache is rejected as a source input too.

Cache directories, downloaded/extracted paper search aids and local campaign
outputs do not have to be reconstructed to reproduce the research inputs.
Their absence must not invalidate a cache-independent source manifest. Test
definitions and required model/source inputs are not caches. Historical logs,
counterexamples and budget failures retain their archived identities; disposable
cache status does not authorize deleting evidence or rewriting an old receipt
as a new portable run.

`vendor/gambit` is a Git submodule fixed to
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. The original Gerbil checkout's
`.gitmodules`, remote and HEAD confirmed that this revision belongs to
`https://git.cons.io/mighty-gerbils/gambit.git`, not `gambit/gambit` on GitHub.
The historical `vyzo/gambit` GitHub mirror did not provide this revision either.
Do not substitute either mirror's latest HEAD for the reviewed source.

The current authorized fork transport is recorded above. Publishing this exact
commit to that fork did not change its original provenance or any source bytes.

An earlier HTTPS initialization attempt failed certificate verification; the
upstream network route is not qualified. TLS verification remains enabled.
Historical v1 offline initialization used the versioned Git source capsule bound
by its original `evidence/runtime-source-provisioning.json`. Its bundle SHA256, locked commit,
canonical submodule URL, omitted parent and intentional shallow boundary are
checked before the complete commit tree is verified with `git fsck --full`.
That bundle was a required v1 source input, not a disposable cache. It is no
longer a current input; see Current Revision Source above.

A bare bundle clone without shallow metadata was rejected: Git omitted the
sender's shallow boundary, leaving a missing-parent fsck failure. The v1 provisioner
restored only the explicitly locked boundary after checking the commit's actual
parent. It does not claim to reproduce upstream history. It refuses to modify
an already populated submodule and does not disable TLS or change global Git
transport settings. Its file-transport override applies to one command only.

```sh
PYTHONPATH=src python3 -m gambit_smp.source_provision
git -C vendor/gambit rev-parse HEAD
PYTHONPATH=src python3 -m gambit_smp.reproduction_check --require-committed
PYTHONPATH=src python3 -m gambit_smp.source_materialize --out .data/source-slices/candidate027
```

These input-only commands use the standard library (Python 3.13 or newer), Git
and Python's tar support; they do not require ASCENT or a native runtime. Current
offline provisioning requires prepared Git objects as described above.
The check rejects cache paths, missing inputs, context hash drift, a wrong
submodule HEAD/URL and, with `--require-committed`, uncommitted or modified input
bytes. A check without that flag validates prepared local inputs only; it must
not be described as a clean Git reproduction. It does not download upstream or
prove network availability. The provisioner checks the indexed gitlink; the
strict input checker additionally requires that gitlink and all input bytes to
be in `HEAD`. A staged source lock is not a committed-input receipt.

The source lock and `patches/snapshots/candidate027-audited-source-slice.patch`
reproduce exactly the audited `lib/mem.c`, `lib/setup.c` and
`include/gambit.h.in` bytes. The materializer archives the pinned commit, not
working-tree files, verifies base hashes, applies the locked snapshot overlay,
and verifies candidate hashes before publishing a fresh output directory.
The observed fresh materialization matched all three existing candidate027
digests. Other files remain upstream: this is not a complete candidate027
toolchain, generated-header/C parity, compiler build or runtime acceptance.

The snapshot overlay preserves historical source for research. It aggregates
prior candidate changes; it is not a production repair patch or evidence that
every included change is correct. All native/release admission flags remain
false.

## Papers And Notes

```sh
PYTHONPATH=src python3 -m gambit_smp.paper_cache --cache .data/paper-replay
PYTHONPATH=src python3 -m gambit_smp.paper_cache \
  --manifest evidence/papers-audit-expansion.json --cache .data/paper-replay
```

PDF extraction additionally needs Poppler's `pdftotext`. OCR is optional and
explicit; see [paper cache](paper-cache.md). Reviewed research records live
under `docs/` as Markdown/Org. Downloaded PDF/extraction files are replaceable
search aids, not the records or required model inputs.

Git holds the PDF URL/hash lock and Markdown analysis. PDFs and full extracted
Markdown remain disposable cache files; they are not rehosted in this repository.
New model manifests should bind the tracked notes, paper lock, source lock and
overlay, not require a pre-existing cache's TXT file. The recursive/wait manifest
now uses these tracked inputs. Existing accepted receipts retain their original
contexts; migrating their inputs must not retrospectively reclassify them as a
new clean-checkout run.

## Migration Boundary

### Fail-Closed Inventory

```sh
PYTHONPATH=src python3 -m gambit_smp.reproduction_check --inventory
PYTHONPATH=src python3 -m gambit_smp.reproduction_check --inventory --require-committed
```

This standard-library audit scans current `evidence/*.json` context manifests,
not archived run receipts. It exits nonzero for cache-dependent, missing,
escaping or hash-mismatched inputs and missing case QNT files. It does not
rewrite historical inputs or promote old receipts. On 2026-10-11 the result was
**1 portable manifest and 31 blocked manifests**. This is a migration backlog,
not a claim that the whole repository is reproducible.

The second command additionally verifies each otherwise portable manifest's
shared paper/source locks, submodule gitlink and all required input bytes against
`HEAD`. Staged or untracked inputs are rejected. `committedInputsVerified` is
reported per manifest; neither this check nor a Git commit proves that the
upstream is reachable. Keep this strict inventory as the publication gate,
separate from the local migration inventory.

The 2026-10-11 strict inventory rejected all 32 manifests: 31 already had
non-portable inputs, and the remaining manifest's source gitlink was staged but
not committed. Nine reproduction-check regression tests passed, including
strict per-manifest checks and rejection of uncommitted inputs. Fresh source
materialization again matched all three candidate hashes. None of these results
admits a clean network checkout or the complete toolchain.

The per-manifest committed-input gate now also checks every audited submodule
base file and each case QNT file. A staged gitlink, a locally available cache or
a passing model run cannot stand in for committed input bytes.

For each blocked manifest, preserve its original receipt identity, reproduce
the exact recorded source revision and overlay, then create a new manifest
binding the source lock, PDF lock and reviewed `docs/*.md` or `docs/*.org`
notes. If an old source hash cannot be restored, leave that manifest blocked;
never substitute the current source and retain the old acceptance status.

The source lock currently restores three audited source files, not every source
file or generated header referenced by older manifests. Several historical
manifests still name `.data/` source trees and extracted `paper.txt` files.
Those remain historical evidence, **not clean-checkout reproducible inputs**.
Do not change their paths or hashes while retaining an accepted receipt. A
migration requires a new manifest identity, restored source bytes, versioned
Markdown/Org notes and a new validation receipt. Existing failed attempts must
also retain their original identities so migration cannot erase a known failure.

New model input bindings use repository-relative paths to versioned notes,
locks, patches and the pinned submodule. `.data/` is only for freshly generated
outputs. This convention alone does not prove all files have been committed:
review and commit the intended inputs before claiming a fresh Git checkout can
reproduce them.

Local verification repeated source materialization into a fresh output directory:
all three candidate digests matched. The paper-input adapter's 13 tests and the
source materializer's 4 tests passed, including cache-note rejection and
fail-closed source/hash drift checks. These focused results do not close the
upstream TLS, historical migration, full toolchain or native acceptance gates.

On 2026-10-11, the cache-independent input check passed for seven paper pins and
the recursive queue/wait manifest. A fresh source materialization again matched
all three candidate digests. Five input-check regression tests passed. The
strict committed-input check correctly returned DENY because the locked
submodule gitlink is not yet in `HEAD`; staging is not publication. These are
input checks, not model, runtime or speedup acceptance.

The full framework currently also declares a local ASCENT dependency at
`.data/ascent-python` in `pyproject.toml`. Until its source/artifact provisioning
is independently pinned, `uv sync --locked` is **not** a standalone clean-checkout
setup command. The standard-library commands above deliberately do not depend
on that local installation. See [ASCENT integration](../integrations/ascent/README.md)
for the separate native binding boundary.

## Model Execution

```sh
uv run --locked gambit-smp verify --manifest evidence/gc-recursive-queue-wait.json \
  --out .data/recursive-wait-new-campaign
```

The source/protocol mismatch and incomplete positive exploration currently block
runtime admission. Do not rerun its unchanged timed-out positive merely to make
this command green. Complete the processor-owned queue/local-scan model first.

Portable model snapshots, raw-log-derived archives and diagnostic timing records
are preserved under `evidence/model-results/`. Archive-only and controls-only
receipts are explicitly non-admitted. See
[Quint execution budget](quint-execution-budget.md) and
[recursive composition](gc-recursive-queue-wait.md).
