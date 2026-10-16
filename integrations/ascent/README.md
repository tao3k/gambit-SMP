# Local ASCENT Evidence Review

## Rust Runtime Direction (2026-10-15)

The active execution-runtime migration is now to Rust, not a Rust scheduler
around a Scheme VM. Provider selection is explicit and compile-time gated;
there is no automatic Scheme fallback. The corresponding bridge decision and
real wheel qualification are documented in gerbil-scheme-rust at
`docs/rust-runtime-transition.md`.

The installed Scheme binary's shared-runtime test created two live VMs, each
with processor 0 and one processor, but both entry-selection readbacks failed.
That failure remains preserved; neither the old private-image probe nor a
single-VM loader result closes it. Gambit was not edited or rebuilt.

The new ASCENT Rust qualification wheel runs real recursive relational rules,
source withdrawal and independent concurrent Rust sessions without a Scheme
runtime. It does not yet support this consumer's complete `define-evidence`
catalog/review/history/module interface. Consequently the existing consumer
dependency and its receipts are not relabeled as migrated or current. The
Scheme/CFFI instructions below describe the existing/historical integration,
not a requirement to ship an SDK with the new Rust runtime.

## Python-Only Evidence DSL

ASCENT is a Library for Agentic AI. Downstream code imports Python and submits
its own scenario definitions with `Engine.dsl` or `Engine.evidence`; it has no
Scheme `import`, `module`, `export`, `gerbil.pkg` or compile workflow. The Library
supplies the upstream native environment and hygienic scope internally. Python
only binds exact source bytes, transports arguments/results and manages owners.
Trusted host execution must be explicitly authorized; it is not a sandbox.

`load_evidence_catalog` binds ordered DSL assets and a constructor for
`SourceQueryOwner`. Actual catalog, review and history paths now use
`evidence/dsl/catalog.ss`, `review.ss` and `history.ss`. Those policies belong
to this consumer, not fixed Library build tasks. Native results and independent
explanations remain available when finite scalar/proof projection is unsupported.
The real investigation scenario is in
`evidence/scenarios/investigation/README.md`.

History uses caller-owned capacity: fact counts and request bytes default to
unlimited, with optional Python `FactLimits` and `max_request_bytes` ceilings.
Complete source/backend bindings remain mandatory. Historical finite-limit
failures are preserved, not rewritten as new-policy successes. Scope, handle
and execution-time protections remain independent. See
`docs/caller-owned-capacity-qualification.md` for the capacity qualification.

## Bundled Modules

The bundled-module Agentic AI entry is `gambit_smp.ascent_program.modules`, wrapping
the provider's `Engine.module` owner. It accepts actual exported native Scheme
procedures and retains their returned objects across calls; there is no Catalog,
Fragment-only or finite-proof projection requirement. Use `module.call` for
constructors/operators/sessions and `Value.apply` for native closures.
`Module`, `Value`, `Result` and `Explanation` name their ownership roles;
there is no separate native namespace. `module=` on a call composes exports from another compiled module within the
same object ownership scope. Complete provider resources and compiled source
identities are checked before and after that scope. Source or artifact drift
rejects reuse; it does not select another backend.

The historical pure rule-document and compiled-module entries remain separately
identified. Their old receipts do not qualify the new import-free consumer path.
Fragment remains an upstream composition unit, not the only executable entry.
Build ownership and authority boundaries are unchanged.

The public provider now also supports ordinary compiled Scheme Evidence modules
through `Engine.open_module`, not only Fragment or inert rule-text entry points.
Constructors, hygienic macros, reusable relations, whole Programs, aggregators,
lattices, relational operators and incremental sessions retain upstream semantics.
Compilation remains in the provider's `build.ss` / `defbuild-script`; Python only
packages the ABI, calls it and manages ownership/lifecycle.

`gambit_smp.ascent_program.load_module_catalog` binds a native constructor entry
to explicit host source inputs and the producer's compiled-module inventory.
Non-scalar results use native value graphs, preserving shared/cyclic objects and
opaque references. Native explanations retain dependencies, source scope and
explicit gaps independently of executable semantics. A missing finite projection
or proof is not a restriction on authorized native investigation.

See [Native Evidence Module Terminal Qualification](../../docs/native-evidence-module-terminal-qualification.md)
for the newly completed, source-matched build, actual SDK-hidden loading controls,
full engine regression and remaining research admission boundaries. The sealed
Recipe terminal also accepts a typed, compiled-source-bound module entry; both
source-derived mechanisms passed through that entry on one seal. Native result
and explanation observations remain distinct from Gambit full-native acceptance.

## Existing Review Integration

The root uv project now consumes the real `ascent_engine` CFFI binding from the
selected local ASCENT checkout. This integration project only adds native build
dependencies. Audit, Evidence queries, review and suite retry preflight all use
ASCENT by default. The Python Datalog engine has been removed from source,
tests and both lockfiles; there is no fallback backend.

From the research repository, set `ASCENT_REPOSITORY` to the desired checkout
and `LOCAL_BUILD_DIR` to an ignored local output directory:

```sh
mkdir -p "$LOCAL_BUILD_DIR"
ln -s "$ASCENT_REPOSITORY/python" "$LOCAL_BUILD_DIR/ascent-python"
export ASCENT_ENGINE_LIBRARY="$ASCENT_REPOSITORY/.gerbil/lib/libascent.dylib"
```

Use the corresponding built `.so` on Linux. The library is required; a missing
engine must fail, not switch to a Python semantic substitute. The local binding
must include `ascent_engine.review`. Its initial implementation is a local,
uncommitted change, not yet an immutable published dependency. The uv lock pins
third-party dependencies; it does not pin editable source. Review receipts bind
the actual Python module bytes and selected shared library separately.

Build and select the compiler-checked CFFI API extension:

```sh
uv run --project integrations/ascent --group native --locked \
  python -m ascent_engine.api_build --library "$ASCENT_ENGINE_LIBRARY" \
  --header "$ASCENT_REPOSITORY/bindings/c/ascent.h" \
  --out "$LOCAL_BUILD_DIR/ascent-api" --cc "$GNU_CC"
export PYTHONPATH="$LOCAL_BUILD_DIR/ascent-api"
uv run --locked gambit-smp ascent-review \
  --out "$LOCAL_BUILD_DIR/ascent-review-api/receipt.json"
```

This verifies the extension and copied library against their build receipt.
It does not qualify a portable wheel; host transitive dynamic libraries remain
an explicit distribution obligation. See the provider's `python/NATIVE.md`.

The command validates the existing evidence catalog and QNT receipts before
projecting facts. It does not run TLC again or start any failed native route.
Use `--failure ID` to select a known failure; `--proposal PATH` accepts the
existing retry proposal schema and checks actual binary/fixture identities.
No proposal means a historical, unchanged-route review, not an observation of
the current candidate's behavior.

## Four Views

| Relation | Meaning |
| --- | --- |
| `KnownFailure` | Relevant candidate/failure/report links, not root-cause attribution |
| `Established` | Qualified finite-model claim or hash-checked recorded audit observation |
| `Reusable` | Receipt still bound to the supplied input snapshot |
| `Missing` | Required claim missing after transitive prerequisite expansion |

`Need`, `ReceiptPath`, `Unusable`, `CausalEvidence` and `Denial` expose the
derivation dependencies and rejection reasons. Repeated queries reuse completed
Scheme components. Source replacement withdraws prior references and evidence.
The Gambit projection currently binds reuse to the entire validated catalog;
invalidation is deliberately conservative, not a claim of minimal recomputation.

Finite-model facts remain explicitly named `finite-model:*`. Audit claims remain
`recorded-observation:*`, with their original claim, source links, limitation and
next step retained in `recordedObservations`; a recorded report is not a local
reproduction or a proven causal diagnosis. Open native
obligations remain missing premises even when the model check passed. A checked
bounded model is not a source refinement proof or a native acceptance result.
Source-cause admission is intentionally not synthesized from model passes or a
proposal's prose: the adapter leaves causal links pending. A future causal
review must bind the changed source, failure scope, assumptions and reviewed
evidence before it can populate that relation.

## Permission Boundary

The API emits only `DENY` or `REVIEW_REQUIRED`, never `ALLOW`, and always sets
`executionAuthorized=false`. CLI exit 2 means denied, exit 3 means review is
required; neither is an execution permit. Authentication of facts, completeness
of input and premise sets, and execution permission remain host responsibilities.
No claim of protection against bypassing the runner or malicious host facts is
made. The existing suite preflight remains the enforced launch gate. Directory
and whole-suite failures now require review when their scope overlaps a selection;
that does not mean every file in the scope caused the original aggregate failure.
Bootstrap and other direct launchers still need their own admission integration.

## Full Research Audit Through ASCENT

The main audit uses the installed native ASCENT rule-source API for all
its requested queries, not only the separate EvidenceReview projection:

```sh
PYTHONPATH="$LOCAL_BUILD_DIR/ascent-api" uv run --project integrations/ascent --locked \
  gambit-smp audit --check --out "$LOCAL_BUILD_DIR/ascent-full-audit"
```

Use the directory of the selected, receipt-bound CFFI API build in `PYTHONPATH`.
ASCENT is mandatory for suite preflight as well as audit; unavailable
or mismatched artifacts stop before native tests. No native failure route is
launched by these audit commands.
`evidence/catalog.ss` and `evidence/research-rules.ss` are the rule sources of
truth: inert, typed ASCENT declarations with native `<--`, `not` and checked
`if` clauses. They contain no imports. `Engine.read_rules` sends their text to
the installed engine, which reads and admits the supported declarative subset.
Consumers need Python and the installed native API, not `gxi`, Scheme compilation
or a Python rule parser. JSON remains only the C ABI transport, not rule authoring.
Python selects declared query dependencies and checks paths, hashes and fact
types; Scheme performs semantic admission and inference. Unsupported source
forms fail closed. Historical receipts keep their original `.dl` identities.

The receipt records API extension/library/build and binding implementation
identities, query path identity and completed-component reuse. A changed binary
or a text hypothesis still cannot grant execution. Framework equivalence is not
GC/bootstrap/Gerbil acceptance. Broader Scheme capabilities missing from the
public binding must be implemented upstream in that binding, not recreated in
this repository.

## Validation Commands

Run the framework and binding suites against the selected ASCENT checkout and
the receipt-bound native API build. Store local run outputs outside versioned
documentation; only committed evidence can support a durable acceptance claim.

`evidence`, `audit`, `ascent-review` and suite preflight use the same
identity-checked API loader. Individual queries release sessions, not the
process runtime: Gambit shutdown is terminal, and the binding's exit handler
owns final teardown. Loaded Python/native identities must remain unchanged
within a process. Neither query failures nor missing APIs select another engine.

The shared history module stores immutable, content-addressed observations and
transactional per-scope heads in a local SQLite database. ASCENT derives
added, removed and retained conclusions and changed input identities. Historical
rows are available for comparison, not injected as current passes. Current
source receipts are checked again; runtime/release admission remains false.
Across process restarts this is persisted evidence and reasoning continuity, not
deserialization of native retained sessions. Native result reuse remains scoped
to the loaded process. No pickle, cached permission or unverified certificate
import is used. This boundary must not be described as minimal recomputation.

The public binding losslessly maps symbols through collision-checked SHA-256
tokens for equality joins, including long row/path identities. This respects the native scalar bound without
increasing a budget or dropping evidence. Receipts decode the native delta back
to the original rows. SQLite rows and checksums do not defend against a malicious
host rewriting both; they are not an authority signature.

Evidence's integer comparison uses explicitly declared integer columns and the
native checked `<` operator. There is no Python schema inference or relational
fallback. No package or PR number is special.

The selected ASCENT source includes local binding changes not yet published as
an immutable release. Root and integration lockfiles bind the same editable
provider; receipts additionally bind its actual bytes. Clean GitHub CI needs
that source published and a matching platform API built/provisioned before this
migration can be remotely accepted. Do not report the old Python-only workflow
as working or skip native tests to obtain a green badge.

```sh
uv run --project integrations/ascent --locked python -m unittest discover \
  -s "$LOCAL_BUILD_DIR/ascent-python/engine_tests" -p test_review.py -v
uv run --locked python -m unittest discover -s tests -p test_ascent_review.py -v
uv run --locked python -m unittest discover -s tests -p test_retry_gate.py -v
```

The binding tests require the actual shared library. They exercise stale source,
unbound receipts, dependency cycles, missing transitive premises, text-only
causes, unchanged failures and propagation of engine errors. These are review
framework checks, not Gambit GC/bootstrap/Gerbil native acceptance.

### Model task brief

Run the review with the same receipt-bound native API selection used above:

```sh
gambit-smp ascent-review --model gc_queue_wait_composition \
  --out "$LOCAL_BUILD_DIR/gc-queue-task-brief.json"
```

The `taskBrief` field lists required finite claims, reusable and
invalidated receipts, their input paths, inherited obligations, recorded failed
routes, and open engineering gates. The accompanying `history` field compares
current conclusions with the prior observation; it never imports old passes as
current facts. Exit 2 is expected while historical routes or task premises are
denied.

Each modern receipt binds its recorded input identities. When the current
protocol exporter has rechecked saved logs, source context, model hashes and
result completeness, the brief records `revalidated-output`: old verifier
module identities are listed under `supersededVerifierInputs` and replaced by
the current verifier identities. Runtime source, model, paper and receipt
identities remain bound to the original evidence. A legacy model summary with
no archived raw logs is `unverified`, even if its `accepted` field is true.
An optional raw-log attestation manifest lists the published receipt identity
and every archived raw log's repository-relative path and SHA-256. The manifest,
snapshots and logs must be committed together before citing them as durable
evidence:

```json
{"schema":"gambit-model-raw-log-attestations.v1","receipts":[
  {"model":"MODEL","receipt":"evidence/model-results/MODEL.json",
   "receiptSha256":"SHA256",
   "modelSnapshot":{"path":"evidence/model-logs/MODEL.qnt","sha256":"SHA256"},
   "logs":[
     {"name":"MODEL-fixed.log","path":"evidence/model-logs/MODEL-fixed.log",
      "sha256":"SHA256"}]}]}
```

The framework checks full log coverage, Quint version, the archived QNT snapshot
against the receipt and current model, and the model identity,
negative counterexamples, successful queue exhaustion and the current verifier.
Only then does a legacy receipt become `raw-log-revalidated` without rerunning
Quint. Missing or mismatched logs remain open evidence, not a green model.
`ClaimDepends` records model composition requirements; `ReceiptDepends` is used
only for an actual receipt reference, not inferred from a conceptual model
link. A finite composition receipt can therefore coexist with open source,
GC/lifecycle, bootstrap and Gerbil acceptance gates.

The brief counts relevant reusable receipts and recorded failed routes.
`actualRerunsAvoidedMeasured=false` until an execution preflight records an
actual denied retry; a query count or historical DENY is not a saved runtime.

A generated task brief is a local query result, not a versioned acceptance
receipt. Model reuse does not close the source, native, bootstrap or Gerbil
gates.

### Agent Evidence Context

Generate a new context bundle after validating the Python pipeline:

```sh
gambit-smp agent-context --model gc_queue_wait_composition --profile full \
  --out "$LOCAL_BUILD_DIR/agent-context"
gambit-smp agent-context --read "$LOCAL_BUILD_DIR/agent-context"
```

The `full` profile discovers the complete Python test inventory. The default
`evidence-review` profile covers catalog export, native ASCENT inference,
receipt/log revalidation, history, retry decisions and Agent output. Neither
profile runs the Gambit native acceptance campaign. A parent process records
the test worker's real exit after ASCENT teardown, alongside every test outcome,
source/test identities, dependency environment and raw logs. Missing tests,
skips, failures, input drift or unsuccessful teardown keep validation open.

The bundle contains `context.json`, an Agent-readable `context.md`, the complete
`graph.json`, a focused `graph.mmd` overview and the original `review.json`.
The graph connects model/report/paper Catalog entries by file and JSON pointer
to evidence receipts, individual checks, archived logs and counterexamples,
current input hashes, source references, failed routes and open obligations.
Catalog coverage and report dependency paths come from ASCENT queries in the
same native session as evidence review. Declared claim requirements and actual
receipt dependencies have separate edge types. Model facts, recorded source
observations and framework tests retain their distinct verification domains.

The partial induction Catalog adds recorded-only observations with exact JSON
pointers, archived model snapshots, per-check logs and separate raw/portable
digests. Missing recorded IR is an explicit gap. These nodes do not emit
`Passed`, `model_checked` or `supports-in-snapshot`; a partial preservation
result cannot establish generator coverage, temporal progress or native repair.

Every file records whether its bytes are committed, modified, staged, untracked
or ignored. Source references without a unique context file remain explicitly
unbound or ambiguous. The graph also identifies the actual loaded native API,
library, build receipt and binding implementation. This is a local working
context; commit its supporting artifacts together before citing it as durable
repository evidence.

Use `--validation <receipt.json>` to reuse an unchanged test receipt instead of
running those tests again. The reader rechecks artifact hashes, current inputs,
checkout and backend identity. A stale receipt never becomes current through
history or graph rendering. `frameworkValidated=true` names the Python evidence
pipeline only; execution authorization and native runtime admission remain false.
The CLI prints the paths and status that an Agent must read before choosing its
next source change or test route. An Agent that is never given this bundle has
no automatic knowledge of these results.
