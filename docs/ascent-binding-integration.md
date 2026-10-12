# ASCENT Binding Integration

This describes the framework and CFFI boundary, not Gambit GC/bootstrap/Gerbil
native acceptance, a release approval, or a speedup claim.

## Implemented Boundary

The local gerbil-ascent Python dependency now contains `EvidenceReview` over
the existing Scheme-backed `EvidenceChain`, plus a GNU GCC compiled out-of-line
CFFI API adapter. Python transports and validates data; Scheme computes the
relational closure. `Engine()` requires the compiled adapter; `Engine(library)`
explicitly selects the existing ABI loader. There is no silent fallback.

Both backends preserve result-buffer ownership, typed failures, OS-thread
ownership, terminal shutdown and host child exit status. A fork child is rejected
before it can initialize, enter or clean up the inherited VM. Backend switching
is rejected before loading another runtime.

The copied Darwin engine uses an `@rpath` install name instead of the
producer's build-directory path. Platform packaging remains a separate gate.

## Evidence Boundary

The adapter binds research inputs, loaded binding files, and native
extension/library/build identities. Catalog projection is conservative: any
bound catalog change invalidates that snapshot. Source-hash identity is not by
itself proof of runtime/source refinement. Local test output and generated
query receipts are not durable acceptance evidence unless archived in Git with
their inputs and verification procedure.

## Remaining Gates

- A reviewed source-cause admission schema is still needed. The current Gambit
  adapter deliberately does not turn model passes or proposal text into `Cause`.
- Suite preflight now catches overlapping directory/whole-suite failures. Other
  direct launchers, including bootstrap, still require admission integration.
- Current bindings are local edits; the uv editable dependency is not an immutable
  published source pin. No commit, push or release was performed by this change.
- Portable wheels require transitive OpenSSL/SQLite/zlib dependency auditing,
  license and deployment-tag checks, and clean Linux/macOS qualification.
- The Gambit candidate's three-flag GC, full bootstrap and real Gerbil acceptance
  remain separate pending obligations. Nothing here substitutes for those gates.

Commands and API details: [local integration](../integrations/ascent/README.md).
