# Declarative Evidence Recipes

New research executes `evidence-recipe.v2` through `gambit-smp research` and a
physical immutable engine seal. See [Research Kernel](research-kernel.md) for
the active source-preparation, binding and native-rule architecture. The v1
examples below are historical reproductions, not new experiment entry points.

Research-specific experiments belong in `evidence/**/*.recipe.json`, not new
Python commands. The installed `recipes` entry point discovers them without a
feature registry. Recipes are typed capability graphs: input files, capabilities,
operands, artifact dependencies, budgets and exact result inventories. They
cannot contain shell commands, Python snippets, arbitrary executable selections
or custom handlers. A native Evidence entry selects only a source-bound export
from the host-selected compiled Scheme provider. Unknown fields and capabilities
fail closed.

```sh
gambit-smp recipes --list
gambit-smp --historical-reproduction recipes --run recursive-gc-wait-recheck-controls \
  --out .data/recipe-wait-recheck
gambit-smp recipes --read .data/recipe-wait-recheck
```

The host selects Quint/Node (`--quint`, `--node`) or GNU GCC (`--gcc`). The current
sealed `research --run` entry executes the declared capabilities without an extra
native-mode switch. Historical v1 replay still requires `--allow-native`; this
is an execution permission, not a Gambit compiler flag. A recipe cannot select
another executable. Execution uses the shared bounded
process primitive, a recorded controlled environment, immutable fresh output
directories and a whole-run deadline. Child exit, timeout and structured result
admission must all agree. A failed dependency blocks dependent capabilities.

## Capability Contracts

The terminal `evidence.evaluate` accepts either declared Scheme rule documents
(`rules`) or one declared JSON module entry (`module`), never both. The entry
has schema `ascent.evidence-module-entry.v1` and exactly `module`, `constructor`,
`arguments` and `sourceSha256`. The selected module must appear in the sealed
provider's compiled source inventory; its actual source bytes and entry bytes
are checked before execution and rechecked afterward. Constructors must be
actual exports of that module. There is no Python module loader, language
lowerer, handler registry or alternate inference backend.

The `rules` entry retains the complete upstream DSL loader by default. A
Recipe may explicitly set `rulesContract: "inert-relational-subset.v1"` to use
the Library's checked `open-rule-sources` entry. The consumer verifies both the
operation and advertised `ruleTextContract`; missing or mismatched capabilities
are errors, never fallback to another loader. Scheme reads and validates every
declared source before creating the ordinary source session. Full DSL macros,
arbitrary predicates and module definitions are not silently projected into
this subset. In particular, the complete retry policy still uses its original
full DSL path: its compound comparisons are outside the inert contract.
`rulesContract` is forbidden with `module` or `dsl` entries.

The constructor executes normal upstream Scheme Program/Fragment semantics.
`queries` are partitioned into `expected` exact scalar transport controls and
`recordedQueries` native observations. A result that cannot use the scalar
projection still executes and retains its native value graph. Recording such a
result does not admit a protocol claim. `explanations.json` independently retains
native dependencies, scope, provenance and missing-proof gaps. Handles are
process-scoped; parent exit, timeout and teardown observations are recorded by
the shared process contract, not asserted in advance by the worker. Complete
output files and hashes belong to the normal step receipt. Compilation of these
Scheme modules remains exclusively in upstream `build.ss` / `defbuild-script`.

| Capability | Typed Inputs | Admitted Observation |
| --- | --- | --- |
| `quint.parse` | Declared `.qnt` source | Successful IR and compiler-reported source closure |
| `quint.typecheck` | Source and matching parse dependency | Type/effect check only |
| `quint.test` | Source, parse dependency, main, seed, samples, exact test names | Local sampled controls only |
| `native.c-build` | One declared C translation unit, exact local headers, standard, optimization, pthread, object/executable target | Local build only; GCC-reported header closure is bound |
| `native.test` | Executable artifact, unique cases, bounded integer operands, exact stdout | Child exit and exact observations; negative controls remain negative |
| `gambit.materialize` | Declared immutable source lock and overlay | Git-archived source slice, not dirty checkout/cache state |
| `gambit.configure` | Source-tree artifact, explicit C and RTS optimization levels | SMP/multiple-VM configuration only |
| `gambit.object` | Configured-tree artifact | Full configured `mem.c` object, not linking or execution |
| `gambit.seed-core` | Configured-tree artifact | Initial core from pre-generated C; no SCM regeneration claim |
| `gambit.regenerate-module` | Seed-runtime artifact and explicit SCM module | One actual SCM-to-C invocation, not linked regeneration |
| `gambit.source-core` | Seed-runtime artifact | Generated-C removal and source-regenerated core; not full two-pass bootstrap |
| `gambit.bootstrap` | Seed-runtime artifact | Bounded `from-scratch` command observation; no automatic two-pass or runtime admission |
| `gambit.suite` | Matching runtime/identity artifacts, mode, regime, exact file inventory, optional processor/job controls | Existing retry preflight, topology probe, child exit and exact completion markers |

Artifact references are data, such as `{"step":"seed","output":"runtime"}`.
They must point to a declared dependency with the correct output type. Runtime
and identity must come from the same producer. Every mutating build capability
clones its input into its own fresh step directory; earlier trees are never
modified. Exact tree inventories, internal symlinks and executable modes are
bound and rechecked. Source/tool/artifact drift cannot produce a run-level pass.

Native-only recipes do not require Quint or Node. Installed tools, GCC backend
and compiler-reported system headers are recorded; dependency collection occurs
before C compilation and the closure is checked again afterward. This is local
identity evidence, not a hermetic SDK/linker-library distribution guarantee.

```sh
gambit-smp --historical-reproduction recipes --run gnu-stdio-native-control --allow-native \
  --gcc /opt/homebrew/bin/gcc-16 --out .data/recipe-native-stdio
gambit-smp --historical-reproduction recipes --run retirement-native-component-controls --allow-native \
  --gcc /opt/homebrew/bin/gcc-16 --out .data/recipe-native-retirement
```

Suite regimes are explicit: `whole-sequential`, `whole-parallel` and
`atomic-coverage`. All share the step and whole-recipe deadlines. Atomic
coverage also requires `batchBudgetSeconds`, giving each host-sized batch its
own smaller deadline. It remains correctness coverage, not a whole-mode timing
pass. Capacity retains the existing runner-plus-child VM accounting. Shards are
isolated; each must finish its exact selected file count. Known failed routes
still call the existing preflight before a processor probe or test launch;
`DENY` and `REVIEW_REQUIRED` do not authorize execution.

The active v2 suite gate supports [typed retry review](typed-native-retry-review.md).
Native ASCENT, not Python protocol branches, derives causal coverage, transitive
missing premises, original-budget comparisons and conditional investigation
eligibility. The full canonical failure inventory and sealed safety policy are
mandatory. Eligibility is neither execution authorization nor native acceptance.

Parsing uses Quint's public source map, not a Python import regex. Every source
in that map must be an explicitly declared repository input. Resolved Cache
aliases and outside-checkout imports are denied. The test inventory must match
both the parsed main module and actual structured passed/failed/ignored lists.
A zero exit with missing tests is not a pass.

Receipts bind the recipe, all declared source bytes, executor implementation,
Python runtime, explicit Node executable and installed Quint package files,
actual argv/environment, effective budgets, process times, log/result hashes and
each outcome. Source or tool drift yields `STALE`, including when a process exits
zero. `--read` rechecks those identities without rerunning an experiment. These
are local observations, not portable binary distribution qualification or signed
authority against a malicious host.

When investigating a previous failure, provide `--prior RUN_DIRECTORY`. The
executor retains its receipt identity, requires an input/tool delta for another
failed-route attempt and rejects whole-run, matching-step and recorded atomic
batch budget expansion.
Renaming the output directory is not a causal change. This check does not search
all historical outputs or grant retry permission; callers must supply the known
failure observation. There is no autonomous retry loop.

## Reasoning And Authorization

The graph describes available evidence and dependencies. It does not prescribe
an Agent's next action or freeze an investigation order. The Agent chooses an
authorized experiment and interprets its bounded result against source, paper
and native obligations. All recipe receipts keep runtime/release admission and
execution authorization false. Passing sampled controls is not exhaustive
safety, actual enabledness, source refinement, native acceptance or performance.

The stdio and frozen resource-retirement component recipes exercise the same
native family without experiment-specific Python. The latter keeps existing,
naive-destroy negative, deferred-drain and initialization-failure observations;
it is not a POSIX concurrency or current-source refinement test. Research model
recipes continue to use the same graph engine.

`locked-gambit-source-build` describes the historical 029 slice, configured
object, seed and single-module regeneration. `locked-gambit-source-core-suites`
adds source regeneration and both suite modes. These are available routes, not
qualified results: 029 can omit other candidate repairs, and revision drift or
known failure review may deny execution. Neither was rerun as part of this
adapter migration. Do not interrupt or restart an ongoing native acceptance to
replace its receipt format.

Existing in-flight processes are not interrupted. Historical producer commands
require explicit `--historical-reproduction`; they are unavailable inside the
sealed kernel. New experiments use v2 Recipe data, not feature Python commands.
Missing capabilities require a separate stable framework contract and tests,
not an executable script, handler or renamed case dispatch.

## Source Preparation Boundary

The historical activity-log v1 Recipe reuses native compilation and execution,
but consumes source fragments and receipts prepared by the dedicated
`source_unit.py` producer. That producer binds a particular lock, manifest,
patch and fixture, extracts text and constructs a negative variant. Its token
checks do not establish source refinement. Consumer reuse is therefore not
end-to-end producer reuse or a closed framework architecture gate. That route
remains reproducible history. It is not the v2 source producer.

The active v2 activity-log and sync-resource Recipes independently materialize
the same locked source and overlay, project exact reviewed source bytes, bind
their provenance, compile only the bound workspace and query native ASCENT.
Neither consumes the old producer's `.inc` files or receipts. See
[Research Kernel](research-kernel.md) for the separate acceptance boundaries.

New experiments must not add protocol-specific Python functions or CLI cases.
Missing typed preparation capabilities remain unsupported; arbitrary scripts,
command handlers and renamed case dispatch are not substitutes. Python may
orchestrate paths, hashes and processes. QNT and actual C assertions own protocol
judgments, and native ASCENT owns evidence relations.

Architecture acceptance requires multiple distinct research experiments using
one frozen executor implementation hash, with changes only to declarative
Recipe/Evidence, QNT and native research assets. It must cover source preparation,
binding, judgments and entry points, including negative controls, timeout and
parent exit propagation. Historical dedicated producers and failed receipts
remain reproducible history, not the new experiment production interface.
This independent architecture gate cannot qualify the Gambit full-GC chain.

## Stage Watchdogs Versus Research Quotas

New stage-timed Recipes declare `timeoutPolicy` as
`{"mode": "per-stage", "overheadSeconds": 30}` and omit top-level
`budgetSeconds`, `continuationRequest` and `continuationLedger`. Each step
retains its positive finite `budgetSeconds` watchdog. A fresh attempt starts
fresh stage clocks; previous attempt costs are immutable observations, not
deductions. The executor derives an outer supervisor limit from the sum of
stage caps plus the declared orchestration allowance. Its receipt records
that derived bound as `budgetSeconds` and `supervisorWatchdogSeconds`, alongside
the explicit timeout policy. It is not a performance acceptance threshold.
Legacy whole-budget/quota Recipes keep their original semantics and receipts.
Mixed stage-watchdog and cumulative-quota declarations reject.

`--prior` still binds failure identity and requires a material change. Migrating
an interrupted attempt to a differently named stage-timed Recipe additionally
checks the immutable original request/Recipe, identical stage graph and input
closure, unchanged stage caps and a reaped, quiescent prior process group.
The prior receipt is never rewritten and partial native coverage is not
silently resumed or promoted to a complete test pass.

An explicit repository Recipe path passed to `research --run` validates only
that Recipe and its declared closure. Name-based discovery remains available;
an unrelated unfinished Recipe cannot block explicit-path execution. Both
entry forms still require a sealed implementation, exact input binding and
the same native causal review. A watchdog timeout means incomplete execution,
not proof of deadlock; release performance remains a separate gate.

### Completed-Work Inactivity Policy

The current human-approved anti-stall policy is
`{"mode": "progress", "overheadSeconds": 30}`, with the same prohibition on
top-level cumulative quota/continuation declarations. Step `budgetSeconds`
values define inactivity windows rather than total elapsed execution limits.
The parent supervisor derives its inactivity window from the largest step
window plus orchestration allowance, not the sum of historical attempt costs.
Receipts identify this explicitly as `supervisorWatchdogKind: "no-progress"`.

Only the sealed adapters' completed-work events renew the clocks: completed
compiler subprocess phases, completed test files and validated terminal stage
observations. Repeated counters, raw log output, timestamps and heartbeats
cannot renew a clock. A failed but completed test file may advance the clock,
but still fails correctness admission. Quiet individual phases retain their
own inactivity bound; progressing campaigns are not killed solely for total
wall-clock duration. Performance admission remains independent and unchanged.

Every fresh attempt starts fresh watchdogs. Prior receipts, hashes and elapsed
cost remain immutable evidence and are not deducted from a later allowance.
Policy migration still requires exact stage/input binding and a quiescent
prior process group. Partial coverage is never promoted to full-suite success.

