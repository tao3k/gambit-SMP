# ABI Loading Regression Boundary

The consumer uses only the explicit C ABI artifact and its sidecar. Legacy
extension imports, API receipt unwrapping and compiled-extension fallback are
not execution paths.

The retained failure `.data/abi-adapter-migration-001` exhausted the original
15-second process budget before either selected regression completed. The
process exited by signal and its process group was quiescent. Its complete
resource hashes were stable; this was not latest-source qualification.

Two causal diagnostic changes narrowed the stage, without increasing the
budget or replacing the loader:

- `.data/abi-loading-stages-002` timed official `FFI.dlopen` and Engine calls.
  Loading took about 0.015 seconds; initialization, describe and shutdown
  finished within 0.745 seconds total.
- `.data/abi-regression-stages-003` timed the original selected regression
  methods. Engine initialization completed at 1.314 seconds. `Engine.evidence`
  began at 1.316 seconds and did not return before the 15-second deadline.
  The first test uses the declarative `define-evidence` constructor, not the
  inert closed-rule entry. Optimizing that other entry is insufficient.

The bounded owned-child stack sampler exited 255 without a report. Its raw
error is retained; no privilege bypass or fabricated stack is used. These
observations locate a boundary, not a unique native root cause or a fix.

The new Library delivery at `closed-evidence-current-package` changes the
declarative constructor implementation and fixed-arity guard construction.
`.data/abi-qualification-004-cold` runs the two original regressions unchanged
through the direct ABI: exit 0, no timeout, quiescent process group, 2.126 seconds
within the original 15-second budget. Full build-source, syntax-resource and
binding hashes have no drift. This closes that selected functional route;
it is not a matched performance comparison or complete consumer qualification.

The seven compiled-module regressions remain unqualified. The unchanged
selection in `.data/abi-qualification-004-seven` terminates at 15.007 seconds
in its first operator test. Diagnostic `.data/abi-module-stages-005` completes
Engine initialization at 1.023 seconds and module-open at 1.048 seconds;
the first exported procedure call does not return before the original deadline.
The remaining six, which the first run never reached, are separately observed
in `.data/abi-qualification-007-remaining-six`: the entry-drift rejection passes,
then the real compiled Evidence constructor times out. This is not a pass for
the remaining inventory. Library export resolution still enters runtime macro
import/expansion and requires a general Library-owned repair.

`.data/abi-sealed-review-005` retains all 105 outcomes: 46 pass, 5 failure,
54 error, parent exit 1 in 37.438 seconds within the original 60-second cap.
Some direct Library calls lacked the sealed ABI boundary; some evaluation-owner
requests timed out. Validation workers now enter the checked sealed boundary
without an ambient library or extension fallback. The subsequent 006 run was
externally interrupted and has no terminal parent/domain receipt. Its retained
queue and observations cannot be promoted to completed validation.

New source archives physically retain all 137 build inputs and bind all 131
linked modules; original ABI receipt bytes and paths remain historical facts.
The generation-link denial during seal 004 is retained. Seal 005 and 006 used
the explicitly approved existing custody operation, not a silent permissions
fallback. None of these seals alone qualifies a full CURRENT graph.

The custom prelinked export registry experiment was withdrawn; it is not a
qualified candidate. The subsequent official-path build resolves module exports
through Gerbil's import and runtime-binding metadata. Its Library SHA is
`3ad2af4571e14c022ec02954908c74b6a3cf34710e002147c00358aa438c3c5a`.
`.data/official-abi-stages-008` still times out at 15.007 seconds, exit -9,
with a quiescent process group and unchanged full provider inputs. Module-open
finishes at 1.108 seconds; the first `relational-op-source` export call never
returns. Therefore adopting the official path alone has not repaired the cold
call. Deeper native stage observation is required before another causal retry.

## Official Binary Loading Contract

The receipt-bound SDK's `gxi` reports revision `1cfb032`. Its actual
`src/gerbil/runtime/loader.ss` accepts a runtime module path as a string,
without the import-symbol colon:

```scheme
(load-module "std/text/pregexp")
```

The official loader selects compiled `.oN` generations before `.scm`, remembers
loaded modules, waits for concurrent loading, and propagates failed loads.
This exact SDK exposes `reload-module!` separately; do not copy an optional
reload argument from a documentation revision with a different signature.
`load-module` does not construct a macro/import context. The official tools'
`import-module` path resolves compiled `.ssi` interfaces and evaluates the
module before resolving public phase-zero runtime exports.

`.data/gerbil-binary-load-module-002` records the actual binary invocation,
binary SHA, SDK HOME, stdout/stderr and process exit: 0.190 seconds within
15 seconds, exit 0, no timeout and quiescent process group. A built-in module
returns `builtin`; two loads of the installed pregexp module return the same
compiled path. This is usage verification, not embedded ASCENT qualification
or a matched speedup. The earlier unavailable json-module probe and incorrect
ambient HOME startup error remain failed observations.

## Official Final Candidate

The non-instrumented official candidate removes the extra `runtime-binding?`
rejection: Gerbil's official gxtest resolves exports and evaluates `binding-id`
directly, including imported/reexported bindings. Public phase-zero export and
callable-procedure checks remain. Approved immutable generation publishing
preserves each checked `.oN` inode; it does not alter signatures or permissions,
and full per-path SHA checks remain mandatory.

Final Library SHA:
`530557e38296b42f884e5ca189f39c1ce961788a933c8b994025e17058c603aa`.
Original sidecar SHA:
`7df6032b131d8bed4b2f42eed88d9a53b39af8149d838c8ce2a338f79a4f2091`.

- `.data/official-abi-seven-final-009`: original seven regression IDs, seven
  PASS, zero skip, parent exit 0, 6.180/15 seconds, quiescent group, complete
  provider/binding/consumer Python input hashes unchanged.
- `.data/official-sealed-review-009`: original 105 IDs and policy, 105 PASS,
  zero skip, parent exit 0, 28.593/60 seconds; every lane is complete, reaped,
  quiescent and its evaluation owner complete.
- `.data/official-full-consumer-009`: exit 1 in 2.234/300 seconds because
  concurrent consumer changes no longer matched the seal. No test admission.
- `.data/official-full-consumer-010`: latest consumer seal
  `525b724425c8f31df57808a121049a62923a1dd4a4b921db1ca6c9810c5ecfbf`;
  its sealed domain has 105 PASS in 22.707/60 seconds. Whole parent exits 1
  in 161.290/300 seconds, no timeout, quiescent, source inputs unchanged.
  Expected inventory is 1284; 1272 tests ran and 1273 outcomes include a
  class-setup error holder. Zero skips does not make that inventory complete.

The complete consumer result has 41 errors: 28 missing `composes` metadata
errors, nine loopback socket permission errors, two absent historical artifact
errors, one source-unit locked-input omission and one protocol progress/check
contract rejection. All raw outputs and inventories remain retained. A current
graph also still requires six exact historical generated-source/binary files;
no substitute candidate, deleted reference or invented original SHA is used.
The seven regressions and sealed-review route are qualified for their recorded
identities, not whole-consumer or current-graph acceptance.

Two full-consumer causes have subsequent partial evidence, not full admission:
approved loopback permissions allow the nine existing TLC orchestration tests
to finish in 0.079/15 seconds; their checker execution is mocked, not the real
history model verification. Exact historical tool bytes now extend the source
unit archive in `input-archive-011.json`: materialization from Git `37f0432`,
source capabilities from existing seal `proof-capacity-013`, and the unchanged
recipes archive. All three match original receipt inputs; original receipt SHA
is unchanged. The dedicated real source audit `.data/official-abi-source-audit-012`
nevertheless times out at 15.022 seconds and records a concurrent test-file
change. Static byte recovery cannot upgrade this failed runtime check.

Qualification remains open for the latest fixed-source Library build/package,
the seven reported regressions, all consumers, sealed review and CURRENT full
graph. Existing artifacts and previously passing checks remain historical.
No old Library, partial check or diagnostic success establishes those gates.

## Equality Candidate And Remaining Source Gap

Stage observation 013 measured 7.600 seconds in the first observation Evidence
constructor. The closed core expression validator lacked `equal?`, so the
whole declaration correctly used the original macro pipeline rather than
silently executing a reduced language. The general Library repair adds the
canonical two-argument Scheme equality primitive, preserving structural values,
calling-shape checks and the original route for unknown/shadowed expressions.
It does not recognize a case, constructor name or expected answer.

Latest Library SHA:
`7bba72f34f72d563f0697f2b3ebb08dd58a59a6555c10fec2f59fcdae0cdb29b`.
Original sidecar SHA:
`aa74384038e993baba17245894805508d95ab1b7d2425eee77d1f037ad798cd8`.
New seal:
`cbcbb196fae81a211f7c82f87844b9418589d95c90024e47cc84a5744418daa7`,
137 build sources, 131 compiled source bindings, 974 checked shared generations.

- `.data/official-abi-source-audit-final-014`: original source audit PASS,
  2.082/15 seconds, no timeout, quiescent, unchanged full input identities.
- `.data/official-abi-seven-final-014`: original seven IDs all PASS,
  5.064/15 seconds, zero skip, unchanged full input identities.
- `.data/official-sealed-review-014`: original 105 IDs all PASS,
  parent 26.347/60 seconds, no timeout and complete quiescent owners.
- `.data/official-full-consumer-014`: all 1301 tests executed, complete
  inventory, zero failure, four errors, zero skip, no input drift; parent
  exit 1, 199.939/300 seconds, no timeout and quiescent. Its own sealed domain
  also qualifies all 105 tests in 23.131/60 seconds.

The four remaining errors share one cause: the current lifecycle view requires
six exact historical generated-source/binary files. Catalog review collection,
Action discovery, lifecycle evaluation and validation collection all reject
their absence. Existing caches, SDK files, retained Git blobs and the original
source tar have no matching bytes; no near-match or rebuilt artifact replaces
the original SHA. Complete current-graph qualification remains blocked until
the original bytes are recovered, or a separately evidenced new current view
is appended while preserving the old immutable observations and DENY history.
There is no completed CURRENT/PASS graph and no overall admission claim.

## Appended Current Source View

The historical state above is retained. The active registry now selects a
separately captured current continuation-source view, rather than replacing
the six unavailable original artifacts. The old view bytes and SHA are
unchanged and its missing references remain DENY. The new view binds 958
readable source/configuration files and all 22 locked candidate files, records
five unavailable prior-seed generated paths, and claims no runtime binaries.

The complete current workflow is now qualified by
`.data/current-lifecycle-graph-017`: all 1332 tests, zero failure/error/skip,
complete inventory and no input drift. Its same-seal 105-test review domain
passes in 26.081/60 seconds; the whole graph exits zero in 236.155/300 seconds.
The actual readback in `.data/current-lifecycle-graph-read-017` is CURRENT with
frameworkValidation PASS and no source/backend/checkout drift, 3.444/15 seconds.
See `lifecycle-view-source-transition.md` for exact identities, all retained
transition failures and the unregistered-parent contract repair. This does not
recover historical bytes, establish current runtime correctness, close cold
performance or authorize execution. No budget was increased.

## Session Reuse And Generation Custody

The earlier graph qualifications are historical, not qualification of the
new Library. The final no-diagnostic package is
`/private/tmp/ascent-session-reuse-package-008/libascent.dylib`, SHA256
`e7d1636dd195461b4218b6c8e17f45f379157936603a232379db069cbe4ee2dc`.
Its official prepared build took 36.848/120 seconds and packaging 1.576/15.
The package retains 1031 append-only compiled generations and copies 1290
other resources, with all 137 build inputs and 2321 resource hashes checked.
This is not a cold build or portable-wheel qualification.

The two Library changes reuse an official parent import context, with fresh
user module namespaces and current exported binding reads, and reuse Actor
relation declarations for the same immutable SourceCut. Each Actor run still
creates a fresh Program. Source updates, cancellation and failed runs clear
the relation cache. They do not memoize inference results or authorize retries.

The failed diagnostic packages copied all compiled generations after a
sandbox EPERM. Official phase observations and a bounded owned-child Darwin
sample found most sampled waiting in `dlopen -> mapSegments -> fcntl`, rather
than business-rule execution or Python hashing. A controlled package retaining
generation inodes completed the real six-case Action/lifecycle regression.
The publisher now rejects EPERM instead of silently degrading custody; real
cross-volume copies remain explicitly recorded. No system signature checks,
loader registry or runtime permissions were bypassed. Diagnostics were removed
before building the final candidate. Local raw phase logs are preserved in
`.data/library-session-reuse-observations-019`; earlier failures are unchanged.

The final six-case regression is
`.data/official-abi-session-reuse-lifecycle-009`: exit zero, 9.562/15 seconds,
no timeout, quiescent process group, all six tests and no input drift.
The prior `-008` regression rejected an actual concurrent `build.py` change;
its STALE result remains a failure, not a waived pass.

Matched fresh-process studies use three alternating pairs with identical
complete input/answer hashes, native withdrawal/restoration and retained
sessions. `.data/session-reuse-matched-lifecycle-005` completes in 11.241/90
seconds; `.data/session-reuse-matched-actor-003` in 14.311/90. Per-process caps
remain 15 seconds. Lifecycle opening is faster in these three pairs, but the
third Actor retained-run pair is slower than baseline. These small local
studies do not establish stable overall Actor speedup or empty OS-cache cold
latency. Lifecycle `-004` overlapped a regression and is correctness-only.

The new complete graph `.data/current-lifecycle-graph-021` is DENY: 1346 tests,
zero skips, one failure and 11 errors; complete inventory and no input drift.
Its parent exits two in 260.781/300 seconds without timeout and with quiescence.
The separate same-seal 105-test review passes in 27.102/60 seconds, but cannot
cover the full failure. Two errors require complete source-unit receipt
bindings; one historical numeric adapter assertion compares old receipt bytes
with a changed implementation. Their original identities must be preserved.

Eight mocked TLC transport checks omitted mocking their endpoint lease; the
unit resource boundary now includes that lease and rejects invalid checker
configuration before acquisition. Ten focused checks pass in 0.076/15 seconds.
The genuine History check needed approved local service access; all safety,
temporal and five decoded counterexample controls pass in 25.723/60 seconds,
with no source drift. These are separate repairs, not a rewritten graph pass.
Fresh full qualification remains required after the source/historical binding
repairs; overall performance and workflow closure are not claimed.

Actor source conformance additionally uses the repository's official
`gxi :gerbil/tools/gxtest -v 5` entry. All 12 cases, including cancellation,
failed-publication refusal, close/drain, replacement and multiple workers,
pass in 4.760/15 seconds with unchanged source hashes. The standalone
`gxtest` attempt reported illegal import while exiting zero; its raw failure
is preserved and is not admitted on the basis of `HARNESS-OK` or exit alone.
