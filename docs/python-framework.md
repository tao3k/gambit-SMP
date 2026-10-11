# Python Verification Framework

## Project And Commands

This is an installable `uv` project, not a directory of directly executed
scripts. Production modules live in `src/gambit_smp`, tests in `tests`, and
`pyproject.toml` owns dependencies and the `gambit-smp` console entry point.
`uv.lock` pins dependency artifacts; `.python-version` selects Python 3.13.

```sh
uv sync --locked
uv run --locked python -m unittest discover -s tests
uv run --locked gambit-smp --help
uv run --locked gambit-smp source-unit --help
uv run --locked gambit-smp evidence --validate
```

CI executes these same locked checks. Add reusable behavior to package modules
and tests, not a new standalone script. The CLI dispatches to existing adapters;
it does not change their timeouts, source identities or acceptance boundaries.
Case-specific protocol assertions remain in the corresponding adapter/fixture.

Quint, Java, GNU GCC, Git and native Gambit build trees are external tools, not
Python dependencies. A wheel installation needs a research checkout selected
with `gambit-smp --root PATH COMMAND`; models, papers and evidence are not bundled
into the wheel. Source-bound verification uses the editable checkout installed
by `uv sync`; building a wheel is not validation of native adapters. Local
generated outputs stay under ignored `.data`, the managed
environment under `.venv`. `uv cache clean` manages uv's dependency cache; it does
not delete research evidence or candidate build trees.

### Evidence Across The Layout Migration

Historical receipts and their recorded `tools/model` paths/hashes are immutable.
No alias silently substitutes the new package for the old source. Receipts that
require current verifier bytes must fail closed after migration; models whose
admission binds only unchanged model/context bytes retain that narrower scope.
Do not rerun failed native routes solely to refresh a framework path.

Temporary unit fixtures may map old paths to package paths and bind their copied
inputs, explicitly as validator tests, never as published runtime evidence.
`evidence/relations.json` is a derived current index and can be regenerated after
review; it is not an immutable native receipt. Older checkpoint counts below
describe their original runs, not the current package verification.

The portable `evidence --validate` command queries available inputs without
rewriting a saved index; missing local source context remains pending. The
separate `--check` mode still rejects any stale saved index. Validator unit
tests use temporary synthetic context to test receipt admission, not an
unchecked assumption that a local candidate cache exists. Actual candidate C
extraction and fault injection remain explicit `source-unit` operations.

### Migration Validation

On 2026-10-11, a clean copy excluding `.data`, `.venv`, Git metadata and build
outputs passed all **205 framework tests in 22.101 seconds** with locked uv
dependencies. The first clean run exposed three local-cache dependencies in
tests and a Git-working-directory dependency in delta inspection. The unit
fixtures are now self-contained, and numstat inspection does not inherit a
surrounding Git checkout. No native test was skipped or promoted.

The same clean copy passed `evidence --validate`; nine source-context-dependent
protocol checks and one historical progress check correctly remained pending.
The local source-filled checkout is a different evidence context. Wheel/sdist
construction and offline lock validation also passed. These checks establish
framework packaging and portability, not GC, bootstrap or Gerbil acceptance.

The source-filled checkout also passed **205 tests in 31.543 seconds**. The new
installed CLI reran the unchanged successful source-schedule adapter with GNU
GCC, observing all eight expected schedules. Its new package input hashes are
recorded in `evidence/model-results/sync-retirement-source-schedule-uv-001.json`;
the correspondence manifest selects that new receipt, leaving both historical
003 receipts untouched. This extracted-source/mock schedule check is not a
native runtime rerun and does not admit GC or bootstrap.

## Shared Model Backend

The post-migration decoder also supports homogeneous string sets. Empty sets
infer an element type from the trace without erasing a type already observed;
integer-to-empty-to-string transitions, mixed sets and decoded duplicates are
rejected. This is shared value handling, not a VM-model exception. Re-parsing
the original `vm-mem-setup-model-001` log recovered its seven-state negative
trace without running TLC again. The current model has since changed, so this
recovery belongs only to the frozen original model, not a new campaign pass.

`quint_backend.py` is a library, not another case runner. `check_gambit.py`,
`verify_protocols.py` and `model_progress.py` now use one backend for command
construction, isolated converter endpoints, bounded execution, strict negative
trace decoding, state counts and explicit temporal admission. Case adapters
retain only their input preparation, required checks and evidence schema.
Protocol extensions belong in QNT and manifests; do not copy this backend into
a new per-issue script. Native and source-unit adapters still use `framework.py`
and must not inherit model-only acceptance as native success.

The strict value decoder accepts strings and compact integer intervals in
addition to its existing value types. It never evaluates trace text or expands
a large interval into a large allocation. A protocol campaign may reparse a
same-model negative-control log after a decoder improvement, but must recheck
version, source stability, initializer, context, exit status and timeout.
Recovery records the original receipt/log hashes and `recoveredCounterexampleParse`;
the original failed receipt is not edited. Internal checker errors and timeouts
cannot be recovered into expected counterexamples.

Validator unit fixtures are temporary and explicitly distinct from live receipts.
Changing a verifier invalidates live receipts that bind its old bytes; unit tests
must test that rejection, not rewrite production evidence or force expensive
reruns just to satisfy a fixture. Test categories remain separate: backend and
parser unit tests, admission/mutation tests, real bounded-model checks,
source-unit observations and native campaigns. Only the last class can satisfy
the real-runtime gates, and only within its actual coverage.

The shared-backend checkpoint passes **196 tests in 24.544 seconds**. Its actual
tree-retirement campaign reuses both previous negative traces and executes only
the previously unrun positive check. This is backend/model verification, not
GC, bootstrap or Gerbil acceptance.

## Ownership

| Layer | Responsibility |
| --- | --- |
| `framework.py` | Bounded execution, process-group timeout termination, child identity, hashing, isolated fixture snapshots, clean GNU GCC selection |
| `quint_backend.py`, `tlc_values.py` | Shared model-check execution, verdict interpretation and typed counterexamples; no package or issue-specific paths |
| `check_gambit.py` | QNT counterexample/positive admission, source-bound native interpretation and compilation |
| `source_unit.py`, `ffi_source_unit.py` | Exact C extraction, representation guards, controlled faults and protocol-specific assertions |
| `runtime_identity.py`, `crash_evidence.py` | Source/artifact identity and child-bound crash evidence |
| `evidence_index.py` | Deterministic Datalog facts and explicit coverage gaps |
| `debug_runtime.py` | Bounded same-process observations, isolated DWARF and hidden debugger-error rejection |
| `native_suite.py` | Generic isolated upstream test snapshots, exact mode/count admission and optional reference fixtures |
| `compiler_cost.py` | One unchanged original fixture split into compile/execute phases under one diagnostic budget; no suite admission |
| `bootstrap_runtime.py` | Isolated upstream two-pass source bootstrap, GNU compiler/source binding and recursive-error rejection |

Adapters must not implement another subprocess timeout loop or import a model
checker merely to obtain hashing/execution helpers. Adding a protocol means
adding its fixture, assertions and case metadata, not another candidate runner.
Receipt schemas remain adapter-specific: bounded-model success, mocked source
success and actual native success are different evidence classes.

## Isolation And Failure

Native fixtures are snapshotted into the fresh run output before interpretation
and compilation. Generated C/object files therefore stay outside the tracked
fixture directory. Snapshot overwrite and source drift fail closed.

Timeouts preserve the child's failed status and kill its process group; no
heartbeat or budget expansion changes a failure into a pass. GNU GCC version
inspection and compilation use the same environment without inherited
`SDKROOT`, `LIBRARY_PATH` or `CPATH` overrides.

Native processor capacity is detected from the host, bounded by affinity where
supported. The upstream-suite adapter reserves one processor for each runner
and selects child populations within the remaining capacity, in sequential
and parallel modes. Explicit plans exceeding that Scheme-VM bound are denied.
One-CPU hosts necessarily time-share runner and child. External GCC processes
are outside this bound. Receipts distinguish automatic selection from explicit
controls; neither changes the finite processor bounds of a QNT model.

Model-bound test patches can target an extra upstream fixture copied into the
isolated snapshot. Original and derived fixture hashes are recorded separately;
source, patch and proof drift fail admission. This does not rewrite the cached
upstream source or permit replacing original assertions.

## Local Validation

The paper-guided composition checkpoint passes 128 framework tests. Integer
sets in TLC traces have a strict tagged representation, distinct from tuples;
changing cardinality preserves the declared type, while malformed/duplicate
members remain rejected. Datalog now validates paper references, acyclic model
contracts and designated model receipts against current model bytes and exact
required checks. Receipt admission, native fixture availability and release
admission remain separate. No runtime patch is added at this checkpoint.

The 2026-10-11 framework change passed 70 unit tests, the unchanged extracted
`mark_array` four-control source unit, Datalog coverage checks and whitespace
checks. The source-unit output is
`.data/mark-array-source-unit-framework-001/receipt.json`.

This is framework validation, not proof of an SMP runtime repair. Native
reproduction, complete threaded bootstrap and Gerbil acceptance remain open.
The source-unit duplicate-visit control still demonstrates a forwarded
destination under an injected schedule; native reachability remains unproved.

The subsequent queue/post-copy work passes 85 framework unit tests and the
current Datalog input checks. Same-process repeated debugger observations keep
one PID rather than silently launching a second sample. Optimization-preserving
DWARF and O1 diagnostic builds are distinct evidence classes. Debugger Python
assertions remain failures even when LLDB returns zero.

The suite adapter copies upstream tests/support files and adds optional
reference fixtures only to that isolated snapshot. It runs each requested mode
separately, requires the exact completed-file count and exit zero, and checks
candidate identity again before campaign PASS. A successful first mode remains
RUNNING while another mode is outstanding. Whole-suite budgets are explicitly
recorded, not misrepresented as per-file or MCP performance gates. The processor
environment probe must observe the automatically selected VM population.

Parallel upstream runners use one processor each and preserve the independently
selected child population in `GAMBOPT`. Automatic capacity reserves one driver
processor per shard as well as the child population. On the observed 12-CPU
host this selects three shards of three child processors, not twelve shards of
twelve processors. Receipts name the capacity scope: external GCC processes
are not included. A one-CPU host necessarily time-shares driver and child.
The generic processor-population fixture checks the actual interpreted and
compiled test child and fails on a mismatch. Additional fixtures are immutable
snapshot inputs in every shard, with digest checks at completion.

The residual-repair checkpoint passes 122 framework tests. This remains
framework evidence, not complete native bootstrap or release admission.
Generated C build drivers and present reuse helpers are independently hashed;
their configured compiler must match the selected GNU GCC. Receipts record
reuse activation and reject driver/helper drift at completion. Older receipts
do not gain this stronger binding retroactively.

The bootstrap adapter copies the admitted runtime before invoking upstream
`from-scratch`; it does not replace the accepted runtime. The seed compiler,
configured GNU GCC and host-selected job count are recorded. Generated C may
change, but handwritten source drift rejects the result. Recursive make errors
also reject an otherwise zero exit status because upstream phase loops can mask
earlier failures. Bootstrap success is a new candidate identity, not complete
native, Gerbil or release admission.

After adding masked-recursive-error rejection, 88 framework unit tests pass.
The earlier interpreter campaign and two-pass bootstrap remained DENY; their
timeout receipts do not become passes through framework validation. The later
runtime023 complete interpreter campaign passes 379/379 files; bootstrap023
still fails its unchanged 600-second budget.

## Atomic Correctness Coverage

`native_suite.py --parallel --atomic-coverage` partitions the complete selected
file set into bounded batches of at most the host-selected worker count, each
worker receiving exactly one file. Each batch uses the independently checked
parallel runners. Every selected file must appear exactly once, with exit zero,
the exact completion marker, no failed assertions and stable inputs. The first
denied batch stops the campaign; source or runtime drift prevents the next launch.
The initial implementation partitioned into twice the worker count of groups;
with 379 files this still aggregated 21/22 files per worker. Its denial remains
recorded. The corrected one-file-per-worker rule changes coverage granularity,
not the per-batch bound or the rejected whole-suite timing gate.
Adapter source hashes are now receipt inputs as well as runtime, fixture, proof
and GNU build-driver identities. Older receipts are not retroactively bound.

The distinct `gambit-upstream-atomic-coverage.v1` schema ends in `COVERAGE-PASS`,
not whole-mode `PASS`. It records each batch budget, total diagnostic elapsed
time and `performanceAdmitted: false`; splitting does not convert a previous
whole-suite timeout into a timed-suite success. Runtime023 calibration completes
three compiled files in 29.073 seconds, with all three batches within the
unchanged 60-second batch bound. Full compiled coverage remains a separate gate.
The first full compiled runtime023 batch is denied in 301.229 seconds: one
21-file shard completes, two exceed their batch budget, and the retained log
contains a vector-increment type assertion plus a UDP permission failure.
These are three different failure categories, not a whole-suite pass or a
single diagnosed GC defect. Remaining batches are not launched.

Compiler-only repair admission requires observed GNU object compilation, a
new compiler hash, an unchanged interpreter hash and identical ordered runtime
object-member hashes. Darwin's regenerated archive symbol index and container
headers are not object code; actual rebuilt binaries must still link. It does
not pretend a compiler delta rebuilt all runtime artifacts. The exact expander
patch and forced generated `_prims.c` regeneration remain separately bound.

The suite adapter supports explicit processor and minimum-heap diagnostic
controls, recorded separately from its host-auto defaults. Local failure facts
distinguish assertion, signal, environment and budget; a bound counterexample
model is not upstream attribution or release admission. The non-Git bootstrap
stamp exception requires the exact upstream message and a newline-only stamp;
it never exempts unrelated headers or changes the previous timeout denial.

## Source Candidate 019

The bootstrap adapter also supports an isolated `core` source candidate with
an exact patch and reusable model receipt. The GC traversal candidate validates
its lexical source binding, removes copied `_system.c` to force regeneration,
and records a new artifact/source identity. This narrower core success is not
called a two-pass bootstrap. Current admission additionally rejects unchanged
seed artifacts in patched rebuilds.

Ninety-two framework unit tests pass. The new test-patch round-trip check binds
the original upstream file and tested supplementary fixture by SHA-256.
Twelve related native files pass both modes on actual source candidate 019;
the separate original prim-port file remains budget-denied. Neither result
admits a whole-suite or release claim.

## Resource User Model Checkpoint

After adding `sync_resource_users`, full framework discovery passes 145 tests
in 9.475 seconds. The new trace regression checks all five independent fault
controls, their model digests and the published-but-still-locked sender state.
It does not execute Gambit or claim native correctness. The full discovery
includes the separate research-audit tests without changing that adapter.

The refreshed Datalog export and query checks pass. Eight designated model
receipts are admitted, with zero missing model receipts in the contract
closure. The same query retains 18 report/model gaps, 38 models without native
adapters and 13 open source-overlap reviews. These are incomplete acceptance
obligations, not omissions to hide behind framework green. Raw query results
are recorded in `.data/sync-resource-users-index-001/receipt.json`.

## Failed-Route Entry Gate Checkpoint

Full discovery after the retry-entry integration passes 159 tests in 19.777
seconds, including concurrently added research-model adapter regressions.
The actual source-bound runtime026 preflight exits 2 without a processor probe
or suite execution. Its receipt includes adapter source hashes and a digest of
the detailed Datalog comparison. See `suite-retry-preflight.md` for unsupported
route scopes and the still-open reviewed-repair resumption mechanism. Neither
framework green nor this no-execution control constitutes SMP acceptance.

## Explicit Progress Evidence Checkpoint

The current full framework discovery passes 172 tests in 19.846 seconds.
The first discovery in this step had three evidence-export errors caused by
macOS temporary-root aliases; resolving the exporter root fixes them without
changing the original QNT model or its input hashes. Independent regressions
reject stale source context, omitted controls, changed/rehashed snapshots,
nonboolean acceptance and safety-only logs presented as temporal evidence.

The main Datalog export now records four checked protocol extensions and one
explicit progress obligation/check, with zero pending checks in those two
lanes. Eight designated safety-model receipts remain a separate lane. This
does not close the 18 report/model gaps, 38 missing native adapters or 13 source
overlap reviews. The query receipt is
`.data/explicit-progress-index-001/receipt.json`. See `model-progress.md` for
the actual temporal boundary and unchanged-source verification overlay.

## Continuation Publication Checkpoint

The new publication-policy model has an admitted stale-frontier control and
a six-state positive graph. GNU GCC executes the extracted unchanged chunk
publication block with three mocked frontier combinations and observes the
expected stale committed-pointer behavior. It does not exercise native GC.
Full discovery passes 183 tests in 26.271 seconds at this checkpoint.

Datalog records nine designated model admissions and two diagnostic source-unit
observations, independently of the four temporal protocol extensions and the
explicit unchanged-model progress check. Native, bootstrap and source-refinement
gaps remain open. See `continuation-chunk-publication.md`; no measured speedup
or runtime repair is admitted from this source-unit observation.
