# Modular Evidence Loading

Status: component linking implemented; whole-consumer qualification remains open.
The component loader transports separate definitions to independent native scopes.
The older collection loader still concatenates its explicitly supplied definitions.
A Catalog indexes Evidence;
it is neither its storage format nor proof that a query has complete support.

## Boundaries

- Downstream supplies scenario definitions and data through Python/C ABI. It
  does not supply Scheme import/module/export or a compilation workflow.
- Small manifests reference independently versioned definition, fact and policy
  assets by exact source bytes and digest. They do not embed the entire inventory.
- The Library's Scheme implementation resolves component dependencies, creates
  hygienic scopes, binds exports and composes native inference components.
  Python transports the manifest and bytes; it does not resolve rule semantics.
- Immutable receipts, logs and observations retain their original identities.
  A Catalog is a rebuildable query index over these records, not their replacement.

## Loading And Reuse

An explicit query or component request selects a native dependency closure.
Every selected input and artifact remains individually hash-bound; an aggregate
digest is an index key, not a replacement for the full source inventory. Complete
Library/backend identity checks remain separate from selecting Evidence data.
Unselected Evidence is not silently admitted as support.

Each loaded component has an owner, source generation and dependency identity.
Identical applicable components may be reused within their supported lifetime.
Source replacement or withdrawal invalidates dependent results and explanations
according to upstream semantics, including negation, aggregates and lattices.
Independent modules cannot exchange foreign owner references implicitly.

Queries distinguish not-loaded support, absent premises and stale support.
Partial loading cannot establish a complete-proof claim. These limitations do
not revoke host authorization to investigate or execute trusted Scheme code.
Results and explanations remain independently owned, including non-scalar,
shared, cyclic and opaque values.

`definitions(bound_assets)` opens an ordinary owned DSL/component scope, not a
Catalog table. The binding helpers accept an optional constructor; only the
table-query path requires one. Call any exported scenario procedure through
the resulting owner, retain its opaque value/closure references, and apply
them within that owner. Complete definition and implementation identities are
checked before and after its lifetime, also on exceptional exits. Explicitly
passing an existing Engine permits runtime reuse without crossing owners.

The Library owner also provides `module.evidence(constructor, *arguments,
limits=...)` to construct independent sessions from these already-loaded
definitions. Native constructors and limits are evaluated anew, while loading
and macro expansion are reused. This does not share mutable Session state,
reset scope accounting or skip the consumer's complete source checks.

The real dependency scenario returns a closure over an upstream retained
operator session. Its union/join/project/fixed-point transformer derives
transitive contract dependencies from the complete catalog inventory. Replacing
its inputs supports withdrawal and restoration; the independent recursive
Evidence rules check the complete answers. Finite typed relation/arrow/function
and fixed-point constructors are now part of the Library's internal Evidence
prelude, not downstream imports. Their finite scalar/domain/normalization
contracts are retained; this is not arbitrary higher-order proof admission.

## Qualification

The contract requires real C ABI scenarios for dependency loading, same-named
definitions in separate hygienic scopes, repeated queries without re-expansion,
source withdrawal and restoration, shared dependencies, independent owners,
source/artifact drift, and complete teardown. JSON declares cases and immutable
expected observations; Scheme implements the scenario and semantic assertions.
The shared Python runner handles invocation, identity, deadlines and receipts.
Python-specific ownership and OS-process controls remain boundary tests.

Matched performance runs must use identical facts, definitions, queries and
required source closures. Loading less required evidence is not an optimization.
Existing execution-time limits and all failure records remain unchanged. Default
fact/request capacity stays unlimited; optional limits belong to the caller.

DSL scope admissions also default to unlimited. An explicit
`Engine(max_source_scopes=64)` ceiling applies to the shared Library runtime's
cumulative admissions, including failed expansions. Independent Engine wrappers
do not reset that count or change another wrapper's policy. The complete
selected component closure is checked before any of its definitions expand.
Closing an owner releases ABI references, not the global expander's bindings;
unlimited admission does not establish bounded memory or automatic reclamation.

## Current Gaps

The component manifest and typed terminal bind the full individual source
inventory. Scheme selects and links the requested dependency closure. The real
catalog/review/history entries now compose declaration and business-rule assets
with upstream `include`; see `evidence/scenarios/catalog-review-history/README.md`.
Artificial left/right hygiene fixtures live in `tests/fixtures/components`.

All inventory bytes are still read and transported; selective native expansion
does not provide lazy file IO or a modular fact-storage index. Source-definition
hot reload and cross-owner reuse are not newly qualified by this change. The
complete current graph, matching regression receipts and same-input performance
comparison remain required. Partial tests do not establish whole-consumer closure.
