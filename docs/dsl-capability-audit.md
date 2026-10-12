# Evidence DSL Capability Audit

This is a source audit and implementation ledger, not a whole-consumer PASS.
The starting Library identity is the frozen scope058 source. Any changed
Library prelude needs a new build and matching consumer qualification.

## Why Usage Was Narrow

Two concrete boundaries constrained downstream use. The checked consumer
`modules()` entry called exports only from compiled provider modules, while
scenario-defined components entered through `SourceQueryOwner` as table
sessions. Ordinary constructors, operators, closures and multi-value results
existed below that adapter but had no source-bound general scenario owner.
Separately, `program/higher-order.ss` was built but not imported by the
Evidence prelude. Import-free definitions could not name that public API.

The changes provide a `definitions()` owner over the same complete source
inventory and re-export the existing higher-order API inside the Library.
Python still transports bytes, identities, arguments and references; Scheme
owns linking, macro expansion, descriptors, inference and update semantics.

## Capability Map

| Capability | Authoritative upstream surface | Actual Evidence use / boundary |
| --- | --- | --- |
| Ordinary definitions and hygienic macros | `interface/evidence-module.ss`, `evidence/interface.ss` | Independently scoped dependency macro and business constructors; downstream scaffolding stays forbidden |
| Module composition | Library component resolver and `program/syntax.ss` include | Catalog/review/history compose declaration and rule parts; complete inventory bound, selected scopes expanded |
| Recursion, negation, aggregates, lattice | `program/syntax.ss`, `program/aggregators.ss`, Program constructors | Investigation applies recursive dependencies, missing-premise negation, count aggregates and max lattice to real receipt inventory |
| First-class operators and transformers | `program/operator.ss`, `operator-session.ss` | Actual contract edges become a union/join/project/fix transformer; retained closure survives replacement and withdrawal |
| Finite higher-order types | `program/higher-order.ss` | Relation and arrow domains, typed function/application/fix and compiler; now available to scenario definitions without an import |
| Positive insertion plans | `program/operator-change.ss` | Existing Library contract; not arbitrary withdrawal. Do not relabel insertion-only deltas as general incremental maintenance |
| Complete source transactions | `program/session.ss`, `scheme-admission.ss` | Catalog/review/history retained sessions and operator replacement; failure must preserve completed publication |
| Arbitrary results and closures | `interface/engine-api.ss`, `interface/value-graph.ss` | General owner transports opaque references and multi-values; no finite/scalar projection prerequisite |
| Explanations and source support | Evidence explanation callback, native result/explanation owners | Separate ownership, full source rows and explicit proof gaps; observations do not become causal review or authorization |
| Actor scheduling / cancellation | `program/actor-session.ss`, `actor-round.ss` | Real contract edges use an owned Actor closure at 1/2/4 workers, replacement/withdrawal/restoration and explicit close; an ABI owner close does not close arbitrary Scheme-owned resources |

## What Is Not A Gap To Paper Over

The generic value path does not remove contracts from checked relational
operators. Their scalar domains admit exact integers, booleans, symbols and
characters, not arbitrary mutable Scheme objects. The dependency scenario
maps exact catalog string labels to Scheme symbols inside Scheme. Finite
typed domains and normalization limits are explicit compiler contracts, not
a substitute for the default-unlimited source fact policy.

`assemble()` requires a lossless finite projection because it creates a
finite proof packet. `evaluate()` and the new `definitions()` path do not
inherit that requirement. The sealed `evidence.evaluate` terminal selects
typed query observations; it is not a general-purpose arbitrary-code runner.
Its recorded value graph and explanation gaps must not admit unsupported
protocol claims. General trusted execution remains a distinct Library path.

Current component loading reads and binds all assets but expands only the
selected native closure. It does not implement lazy file IO, cross-owner value
sharing, source hot reload, or automatic expander-memory reclamation.

## Runtime And Scheduling Boundaries

An already-loaded `Module.evidence(constructor, *arguments)` invokes the native
constructor without loading or expanding definitions again. Each returned
SourceSession independently owns its Program, input policy and explanation.
Closing the definition owner prevents further construction but does not discard
already-created sessions. Failed construction does not create a new DSL scope.

Scheme Actors are distinct from Python executor threads. Actor Session admits
pure positive canonical Set programs; Actor Round independently checks provider,
field-callback and lattice eligibility. The complete investigation includes
negation, aggregates and lattice, so it must not be silently switched wholesale
to this narrower execution contract. Its positive dependency subgraph can use
the existing public Actor API through import-free definitions and opaque closures.

The current C ABI runtime and Python Engine bind to their initializing OS thread.
The ordinary C ABI SourceSession constructor still opens a retained non-Actor
Session. Having Scheme Actors does not authorize entering the same runtime from
arbitrary Python threads or prove that green threads use multiple CPU cores.
No new multi-core speed claim is made without a matching VM/configuration test.
Actor Session does not implement the ordinary Session's `.run-timeout` entry.
Replacing that C ABI backend requires an explicit deadline/cancellation/drain
contract; selecting an Actor closure through the general value path does not
pretend that contract has already been implemented.

Standard-library ThreadPoolExecutor supervises independent test processes under
one shared wall-clock deadline. Queue time consumes that deadline; each child
keeps its original ceiling, final exit, both streams and process-group teardown.
An unstarted queued job has no invented exit or PID. AnyIO is not a dependency.

## Models And Qualification

Existing Quint contracts cover scoped ownership, release/foreign references,
Evidence lifecycle, source transactions, complete publication and change-plan
ownership (`NativeDslOwnership`, `NativeEvidenceLifecycle`,
`SessionTransaction`, `NativeSessionPublication`, `ChangePlan`). Their finite
state abstractions do not execute the DSL compiler or prove arbitrary user
macros/callbacks correct. Public-native tests and actual complete consumer
scenarios remain independent gates; a model PASS cannot replace them.

Required executable qualification: a new matching Library build, complete
API/ABI regression, exact real inventory operator/recursive-rule/typed-closure
comparison, repeated owner use, withdrawal/restoration, released references,
source/artifact drift rejection, original execution budgets, matched
performance input inventory, and a fresh complete current graph. Previous
scope058 graph results became STALE on registry drift and are historical only.
