# Registry History And Evidence Binding

## One Shared Contract

`gambit_smp.registry_history.validate` checks a declared ordered registry history.
It is used by the historical registration regression and by the production
Reflection loader. Audit and information-graph generation therefore validate
the same contract; the rule is not confined to one test or one package.

`gambit-evidence-history.v1` declares the registry schema, collection key and
typed identity selector. Historical snapshot descriptors bind immutable file
bytes with SHA-256. Each successor must strictly extend the prior ordered
collection with its explicitly declared additions. The mutable current registry
must retain that history and the declared current additions. Future appended
entries are allowed, but its newly observed hash changes the graph input.

Historical evidence descriptors bind immutable artifact bytes and an explicit
typed selector for the recorded snapshot claim. A historic logical path may
name what was then the current registry; its recorded digest must still match
the declared historical version, never today's mutable registry. Cache aliases,
external paths, duplicate identities, stale artifacts, lost/reordered entries,
unknown snapshots and mismatched historical claims fail closed.

A Reflection reference opts in with a `history` descriptor matching its own
path and expected SHA-256. All history manifest, snapshot, claim and current
registry hashes enter its returned input map and the existing audit/graph input
revalidation. The new lifetime Reflection uses this path. Original historical
registry snapshots, original Reflection and historical projection stay unchanged.

## Authority Boundary

The host-authored, hash-bound manifest supplies the historical anchors and
declared evolution policy. Validation proves consistency with those anchors;
it does not authenticate their author or recover omitted versions. Future
intentional deletion or reordering requires a different explicit evolution
contract, not silent relaxation of this append-only contract.

This mechanism does not create a current runtime producer, authorize execution,
admit a test result or close an open Reflection requirement. Producer-to-review
binding and native SMP/GC/bootstrap/Gerbil correctness remain separate gates.
Framework PASS must never be reported as SMP PASS.

## Verification

`tests.test_registry_history` exercises the positive chain, future append,
historical byte tampering, current deletion/reordering/replacement, rewritten
snapshot identity, wrong additions, duplicate item identity, current-hash
substitution, stale claims, unknown versions/selectors, pinned mutable hashes,
cache/external aliases, duplicate versions, snapshot aliases, schema mismatch
and Reflection integration without requirement closure.

The repository regression retains its concrete anchors, exact three-entry
historical transition, all four required new bundles and unchanged original
Reflection/hash/acceptance assertions. It delegates version-chain mechanics to
the framework instead of reproducing them locally.

The matched native ASCENT API environment passed the 53 focused history,
Reflection, audit and graph tests in 12.898 seconds under a 60-second cap.
An earlier unconfigured invocation could not import `_ascent_cffi` in 13 audit
tests; it was not a successful acceptance and did not justify source changes.
The matching previously qualified provider was selected explicitly for the
successful rerun; no new provider build or fallback engine was introduced.
