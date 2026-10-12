# ASCENT Utilization Audit

Audit date: 2026-10-11. This is a local source and native-interface audit,
not an exact-head CI result or a Gambit acceptance receipt.

## Findings

Priorities below rank integration and assurance work, not newly demonstrated
runtime vulnerabilities. None of these findings permits weakening retry gates.

### F1: Agent evidence is not native derivation support (P1)

`src/gambit_smp/review_graph.py:110-140` builds useful claim, receipt and
input edges. `derivedBy="ASCENT:Reusable"` identifies an output relation; it
does not identify the actual ground rule application or its parent facts.
Neither this exporter nor `ascent_review.py` consumes `ComputationalEvidence`.

The unchanged, loaded native library already supports this separate interface.
The audit obtained four ancestor-closed support nodes for `path(0,2)`, with
rule labels, parent IDs, source identity/generation/digest and candidate digest.
Changing source bytes made the old handle return `unknown`.

The gap is between an available bounded support capability and the Agent's
actual context. A stable observation interface should expose a requested
conclusion and its supported ancestors, not reconstruct a proof in Python.
Do not relabel current graph edges as proof nodes. This positive graph probe
does not establish generic provenance for negation, aggregation, or the retry
policy; unsupported proof fragments must remain explicitly unsupported.

### F2: Current review views do not consume typed retry outcomes (P1)

The active sealed suite/bootstrap path evaluates
`evidence/research/suite-review-rules.ss` and archives `typed-suite-retry-review.v2`.
It can derive conditional `RETRY_ELIGIBLE` while keeping execution authority and
runtime admission false. In contrast, `ascent_review.py:66-78` projects a
historical/proposal view, leaves `Cause` empty, and uses the separate provider
`EvidenceReview` policy. `review_brief.py:71-78` correctly leaves native gates
open, but has no intake for a checked modern campaign/result receipt.

That provider policy is still authored by the Python function
`python/src/ascent_engine/review.py:52-94`, not a dynamic inert rule asset.
Scheme executes the resulting program, so this is not a Python evaluator;
however, changing that policy still changes Python implementation identity.
Migrating its rule authoring to the admitted declarative surface is distinct
from adding new protocol-specific Python cases.

Consequently, a model-scoped graph cannot yet explain a current typed retry
review or connect its actual subsequent result to the same campaign. This is
an information integration gap, not evidence that conservative DENY is unsafe.
The historical review and launch gate must remain distinct domains. A generic,
identity-checked receipt observation contract should connect them without
converting eligibility into runtime acceptance or turning history into permission.

### F3: Reviewed causal premises are supplied, not discovered (P1)

`native_review.py:158-184` checks schemas, hashes, references, explicit reasoning
and named premise/change lists. Native rules expand those lists transitively,
reject cycles and missing evidence, and bind the original failure and budget.
They cannot discover an omitted semantic premise or decide whether a reviewed
explanation actually captures caller lifetime, synchronization or GC behavior.

The three root reviews are necessary but not a generic source-refinement proof.
Completeness and truth remain explicit host/reviewer assumptions. Improve
coverage with a separately reviewed, versioned requirement inventory tied to
the actual protocol/source obligations, and test deliberately omitted obligations.
Keep evidence authentication outside finite relational inference. Missing
acceptance evidence limits conclusions; it must not prohibit already authorized
investigation or causal-change testing.

### F4: Reuse is measured inside one call, not across investigation rounds (P2)

`ascent_program.py:118-144` opens and closes a new `EvidenceChain` on every
evaluation, then immediately repeats that query. Two identical adapter calls
each opened two native sessions, although each reported two repeated reused
components. Sharing an `Engine` object does not retain those closed chains.

A direct retained-chain control queried `path` and then `usable`: the second
query had zero fresh and two reused components. The capability exists, but the
production wrapper does not expose that lifetime. `reasoning_history.py:37-90`
persists observations and computes deltas in ASCENT; it explicitly does not
restore native sessions or reuse persisted verdicts.

A stable source/rule-generation owner could retain a chain for distinct real
queries. Its lifetime, publication, invalidation and teardown need executable
contracts. Do not advertise immediate duplicate-query counts as measured saved
Agent work or saved native tests.

### F5: Invalidation is safe but coarse; updates are not fully qualified here (P2)

The selected provider's `EvidenceChain.replace` clears all component
certificates and result references. Its component key includes the entire source
identity. In the audit, changing an unused source left answers unchanged but
made both components fresh again. Removing an edge withdrew old answers and
rejected the old result reference. An invalid typed replacement preserved the
previous completed source and answer.

These observations support conservative safety, not minimal invalidation or
arbitrary transactional recovery. Failure during a later native solve,
multi-source publication, rule changes and concurrent readers require separate
tests. The existing Scheme retained operator/transaction APIs are candidates
for a general upstream interface; do not replace them with consumer-side replay.

### F6: The inert rule reader exposes less than the provider (P2)

The loaded ABI advertises checked `compute` and `reduce` operators. The inert
reader accepts relational atoms, stratified negation and closed `<`/`even?`
conditions, but rejects `aggregate` syntax. The audit retained that real
rejection. Provider source also has checked integer min/max lattices and
retained source operators; those are not available through this current reader.

Do not implement equivalent inference or feature-specific rule builders in
Python. When an actual research query needs one of these operations, add a
bounded inert declaration to the upstream language/API and qualify it across
independent mechanisms. Do not add lattices or parallelism merely to increase
a feature count. No C ABI lattice or parallel-evaluation qualification was
established by this audit.

### F7: Local identity sealing is not provider release qualification (P1)

The research seal freezes provider Python modules, selected API/library and
consumer implementation. The provider still has modified/untracked binding and
interface files, and the editable dependency is not an immutable published
release. Host transitive dylibs and the complete toolchain are not hermetic.

The current native probes are reproducible local observations, not clean
checkout, portable-wheel, exact-head producer CI, or cross-platform acceptance.
Publish/pin and qualify the provider independently before asserting those
distribution properties. A passing consumer cannot qualify producer source.

## Evaluation Matrix

There is no meaningful single "ASCENT utilization percentage". Correctness and
authority gates cannot be averaged away by good speed or coverage numbers.
Report each criterion as established in a named scope, partial, open,
unsupported, or not measured. Proposed conditions below are not completed work.

| Dimension | Acceptance criterion | Current audit boundary |
| --- | --- | --- |
| Semantic ownership | All relational verdicts come from admitted native rules; new experiments change assets, not consumer/provider Python | Dynamic catalog/retry policy established; provider `review.py:52-94` still constructs a separate policy in Python; no fallback |
| Expressiveness | Each needed operation is exposed as a typed, inert, bounded native capability with explicit failure on unsupported forms | Joins, recursion, negation and integer comparisons exercised; inert aggregation/lattice surface incomplete |
| Answer correctness | Frozen independent expected rows plus mutation/negative tests for recursion, typing, negation, budgets and updates; real final process exit | Eight focused native probes passed; not arbitrary-program or C ABI refinement |
| Traceability | Each important conclusion resolves to a scoped evidence reference and, when supported, native rule/parent ancestors; source and hypothetical facts stay distinct | Source-bound positive support demonstrated; not integrated into Agent graph; generic negative provenance open |
| Premise completeness | Applicable requirements have an independently reviewed inventory; missing, cyclic, stale and omitted prerequisites cannot become established | Declared closure is enforced; semantic inventory completeness remains trusted |
| Temporal correctness | Append/replace/withdraw/rule-change traces reject stale handles and never publish incomplete or failed prospective results | Withdrawal/type-invalid replacement passed; broader transactional/concurrent trace matrix not run |
| Incremental work | Distinct real queries reuse valid components; matched cold/warm/update controls measure native work and resource use | Direct cross-query reuse demonstrated; wrapper lifetime and minimum-change invalidation incomplete |
| Failure feedback | Same-campaign failure/log/input/budget identities enter native reasoning; review and actual execution outcomes remain separate; no unchanged retry or budget expansion | Typed suite/bootstrap gate implemented; Agent observation intake incomplete; environment/tool change domains unsupported |
| Operational reliability | Bounded memory/session/input behavior, actual timeout/exit/teardown, thread/fork ownership and absent-provider rejection are qualified | Selected bounds described; observed 16 successful opens/16 closes and real child final exit; no stress/leak or cross-platform claim |
| Agent usefulness | Matched tasks improve correct evidence-backed answers/actions without prescribing Next Action; measured tool/latency/token cost includes extraction and invalidation | No matched Agent experiment in this audit; repeated component counts are not Agent efficacy |
| Reproducibility | Exact provider/consumer/rule/input/API identities; raw logs and full inventories; clean checkout and producer CI separately qualified | Selected immutable local seal; dirty source/local-only receipts; release and host hermeticity open |
| Engineering outcome | One actual candidate closes GNU GCC three-flag GC, multi-VM lifecycle, full bootstrap, Gerbil build/full tests before performance | Open; this audit does not launch, waive or substitute for that campaign |

## What "Maximum" Should Mean

The objective is maximum *verified benefit within the intended evidence scope*,
not moving every task into Datalog. ASCENT should own finite closure, relational
joins, declared prerequisite propagation, scoped conflict/rejection reasoning,
and supported computational explanations. It does not infer authoritative
source truth from a digest or prove unbounded source fairness by finite success.

Python should own stable transport, filesystem/hash validation and bounded
process observation. C/QNT/source contracts own their actual domain assertions.
The host owns authorization and evidence authentication. An Agent retains the
choice of investigation based on facts, alternatives and explicit gaps.

There are three different updates:

1. Fact changes use a checked source transaction/generation and invalidate
   affected references; they do not rebuild the implementation.
2. Rule/requirement changes are inert, versioned program inputs with native
   admission and fresh rule identity. A safety-policy change requires a fresh
   seal. It does not require a feature-specific Python handler.
3. New language/API capabilities require a separately qualified upstream
   implementation change. This must not happen for each ordinary experiment.

Evidence/Agent support intake and a single explainable campaign observation
contract have higher semantic value than an early performance optimization.
Retained investigation sessions can then be evaluated with matched controls.
These are engineering priorities, not a forced Agent action sequence or a
requirement to fill every gap before doing authorized research.

For an Agent evaluation, hold model, task corpus, source/rule generation,
available tools and budgets fixed. Compare raw evidence, current relation-only
context, and scoped native support. Include withheld premises, source/rule
changes and stale results. Measure final answer/action correctness, verifiable
citations, obsolete-evidence use, actual redundant queries, latency and total
cost. Ground conclusions in observable answers/tool receipts, not inferred
private reasoning. Retain negative results; report paired variation rather
than a speedup inferred from one successful run.

## Native Receipts And Reproduction

Audited consumer checkout: `.data/gambit-SMP`, branch `main`, HEAD
`0bd78e43514759990174a4294a0f32406cfa7b56`, with concurrent dirty work preserved.
Provider source inspection: `gerbil-ascent`, HEAD
`d0753a12f17c7d9d26ddff3a97bf79d4ce612a3f`, with dirty working-tree changes.
The binary observation is bound to the seal, not inferred from either HEAD.

Selected engine: `.data/research-engine-006`, ID
`ea9f9140b51d18da366035e84b9aa6e18cc64090ce89b1a644bdd916711da97f`.
Native library SHA-256:
`7304321dfd54ca89c072b11031f4664df4f12e7e398daceb1f4cac2d592d409f`.

Local `.data/ascent-utilization-audit-001/receipt.json` is DENY: the audit
observer incorrectly assumed all native responses were dictionaries. Its
raw traceback remains archived; this was not a native semantic rejection.
No claim of a complete source snapshot for that failed attempt is made.

Only the observer's result-shape handling changed for attempt 002. The same
engine and original 45-second budget were retained. Attempt 002 recorded eight
tests, no failures/errors/skips, child exit 0 after teardown, no timeout,
0.2462 seconds, and unchanged observed inputs/seal. The local receipt binds
argv/environment, PID, times, before/after hashes, raw stdout/stderr, an actual
test-source snapshot and native observations. No performance claim follows.

```sh
# A fresh output directory is mandatory; an existing receipt is immutable.
# The audit runner selects the unchanged seal and executes the saved test snapshot.
.venv/bin/python3 -I -B .data/ascent-utilization-audit-002/run.py
```

That exact directory is already completed and its runner refuses overwriting.
Reproduce in a fresh attempt directory with the same bound runner/test snapshot;
do not replay an unchanged failed native route or broaden the budget.
The separately retained typed-retry validation receipt contains synthetic
runtime fixtures, not same-candidate Gambit acceptance; it was inspected, not
rerun here. No full Agent-context validation or competing native campaign was
started by this audit.

These `.data` artifacts are local diagnostics. They are not committed durable
evidence or model/native admission facts. The machine-readable audit index is
`evidence/research/ascent-utilization/audit.json`; it explicitly keeps
`overallQualified=false` and records local references without importing passes.

## Primary Reference Boundary

The original Rust Ascent paper describes index generation, semi-naive fixed
point evaluation and lattice extensions:
[Sahebolamri, Gilray and Micinski, CC 2022](https://s-arash.github.io/ascent/cc22main-p95-seamless-deductive-inference-via-macros.pdf).
The Rust project's [current README](https://github.com/s-arash/ascent) documents
stratified negation/aggregation, lattices, parallel evaluation and BYODS.
These motivate capability questions; they do not establish those properties
for this Scheme implementation, compiled C ABI, or current Gambit consumer.
Semi-naive work inside a fixed point is not cross-revision incremental reuse.
