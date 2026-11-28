# Experimental Design Research

This directory organizes research by subject rather than filename prefixes.
It is not a runtime qualification or a separate implementation branch.

[Repair and architectural redesign](../repair-and-redesign.md) separates the
current 9/12 repair's robustness/source obligations from mechanism-level
refactoring. A current native pass cannot qualify this architecture, and an
Experimental model pass cannot qualify the current runtime.

The current Stage-One selection and acceptance boundary is
[the integration design](stage-one-integration.md). Earlier audits preserve
their explored alternatives and source limitations; they are not additional
fallback implementations or requirements to keep defective SMP behavior.

- [C-backend assets, matched rebuild and first-stage boundary](c-backend-compatibility.md)
- [Zig research collection, semantic design, evidence and D2 architecture diagrams](zig/README.md)
- [Zig as a future system engineering layer: responsibilities, C integration and compiler services](zig/zig-system-engineering-architecture.md)
- [Concrete native contract: Gambit/Zig ownership, source changes and decoupled MLIR AOT service](zig/zig-native-contract-design.md)
- [Zig architecture sources, papers, reading coverage and transfer limits](zig/zig-system-engineering-sources.md)
- [Narrower Zig/MLIR backend feasibility assessment](zig/zig-mlir-feasibility.md)
- [Whole-package composition, selected small refactor and acceptance](stage-one-integration.md)
- [Whole-package formal/DSL validation and limitations](stage-one-integration-validation.md)
- [One coordinated source-refactor milestone and native checklist](stage-one-implementation-milestone.md)
- [Research-only handoff: wait contracts, derived lookup and composition gaps](stage-one-handoff-recipe.md)
- [Wait/index counterexamples, conditional proof checks and handoff limits](stage-one-handoff-validation.md)
- [Reader resumption: snapshot lifetime, multi-shot semantics and source handoff](reader-resumption-contract.md)
- [Resumption counterexamples, guarded proofs and preserved historical identities](reader-resumption-validation.md)
- [Canonical registration: contending creators, commit outcomes and growth failure](canonical-registration-contract.md)
- [Canonical controls, preserved VM composition and historical Reflection repair](canonical-registration-validation.md)
- [Shared binding, VM cells and collector ownership](vm-cell-ownership-contract.md)
- [VM-cell controls, admission-conditioned progress and source/proof limits](vm-cell-ownership-validation.md)
- [Root-map interpretation: publication, retained consumers and lifetime](root-map-lifetime-contract.md)
- [Root-map controls, preserved FFI projections and outstanding native premises](root-map-lifetime-validation.md)
- [SMP foundations and two implementation horizons](smp-design-foundations.md)
- [Chez and OCaml transfer applicability](transfer-applicability.md)
- [Runtime shared metadata and host entry contracts](runtime-entry-contracts.md)
- [Root registry exclusion, scanner-owned deletion, carrier reuse and current RC Recipe](root-registry-retirement.md)
- [Host root registration, lifetime carriers and epoch-design boundaries](host-root-registration.md)
- [Actual callers, reference mechanisms and refactor decisions](runtime-entry-callers.md)
- [Complete transactions, capture/delivery and failure contracts](metadata-transaction-recipe.md)
- [Transaction/callback model and evidence validation](metadata-transaction-validation.md)
- [Actual wait effects, nested roots and exit feasibility](metadata-wait-roots-exits.md)
- [Wait/root/exit model controls and evidence validation](metadata-wait-roots-validation.md)
- [Stage-One C entries, liveness, lock and reader-publication closure](stage-one-closure-audit.md)
- [Stage-One publication/map controls and validation](stage-one-closure-validation.md)
- [Complete shared-metadata synchronization package and compatibility](shared-metadata-package.md)
- [Resource-composition model and evidence validation](shared-metadata-package-validation.md)
- [Private-prefix and compatibility evidence validation](c-backend-compatibility-validation.md)
- [Caller/reader model extension validation](runtime-entry-callers-validation.md)
- [Runtime entry model and DSL validation](runtime-entry-validation.md)
- [Concurrent generational collector alternatives](concurrent-generational-gc.md)

Executable models remain in the existing model-library locations. Each subject
links its reused assets, missing contracts, source identities and acceptance
limits; generated checker output stays in the configured cache. Historical
receipts retain their original paths and hashes; this move does not rewrite
past evidence or make an old receipt current.
