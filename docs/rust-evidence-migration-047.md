# Rust Evidence Migration 047

Status: implementation in progress, not full consumer admission.

## Implemented Library Surface

ASCENT's Rust Library now reads `define-evidence` definitions directly, selects
an explicit constructor, resolves immutable reusable Fragment bindings, and
validates explicit `sources` and `outputs`. Relations, recursion, stratified
negation, guard expressions, bounds, aggregates and lattice declarations lower
to the existing Rust relational engine. Python performs value transport, not
language parsing or inference. Cyclic/missing includes, ambiguous constructors,
undeclared bindings and executable unsupported definitions fail explicitly.

The three complete catalog/review/history declarations and their four reusable
rule assets are copied byte-for-byte into Library conformance fixtures. They
compile and execute in Rust. A real review-rule test checks rejection without
premises, reuse of matching source identity, and withdrawal after source change.
Unary integer subtraction was a real catalog lowering gap and is repaired in
the shared Rust operator implementation with magnitude work charged.

`Engine::open_evidence_sources` creates the initial checked transaction inside
the Library. Subsequent source replacements retain atomic validation and scope
revocation. PyO3 releases the GIL before acquiring execution-owner locks.
Foreign/released source-value leases cannot cross owner authority. Execution
results and independent provenance owners retain existing generation semantics.

The explicit `rust-runtime` Cargo feature excludes `ascent-scheme`; combining it
with `scheme-runtime` is a compilation error, never automatic selection.
The existing default feature policy has NOT been silently changed, and the
consumer dependency pin has NOT been relabeled as this uncommitted candidate.

## Matching Local Wheel

- Provider base HEAD: `e6884b83c7b141ec66e2095252e4fb9e17da9869`, with an
  uncommitted Rust Evidence overlay. No remote release or exact-head CI claim.
- Build: `/private/tmp/ascent-evidence-rust-wheel-047-007`.
- Wheel SHA256: `3a9f7ad8758f2175e543f941dcb51708d24aaab5cd75bc50dff7cd9a4ff8a463`.
- Installed extension SHA256:
  `c97ec560464034a7b6d2922bb1a5c149b147b0a32b8ebe7b68567c030ca5d655`.
- Build actual exit 0, no timeout, 4.064946542 seconds / original 120-second cap.
- Final installed conformance actual exit 0, no timeout, 0.514537667 seconds /
  original 15-second cap; three tests, no skips. All three complete declarations,
  history insertion/withdrawal, foreign-reference rejection, explanation
  ownership and generation invalidation execute through the installed wheel.
- The restrictive sandbox denies the SDK, provider checkout and compiler
  execution. The extension links libSystem/libiconv, with no undefined Gambit
  setup/call/state or bridge runtime-init symbols.
- Rust Library package: 54 tests / zero skips, actual exit 0,
  27.973475416 seconds / original 120-second cap. Two existing development tests
  use Scheme reference oracles; this is separate from Rust-only wheel execution.
- PyO3 ASP gate: actual exit 0, 21.392262750 seconds / original 120-second cap.
  Initial policy failures were repaired in code, not waived or downgraded.

Raw command observations, including failed builds/tests and earlier candidate
identities, are retained in `evidence/library/rust-evidence-047/`. Earlier wheels
are not the matching final candidate. No performance-speedup claim is made.

## Still Open

This is NOT complete `define-evidence` language or full Agentic AI migration.
Parameterized constructors, ordinary functions/macros, relational operator
export bridges, custom explanation definitions and independently scoped
component linkage still need general Rust contracts. Unsupported syntax errors
do not mean those semantics have been migrated.

The consumer still expects the complete installed source inventory through
`ascent.build.runtime_identity`, declared component construction, lossless
program projection/slicing, and computational evidence storage APIs. The new
wheel does not yet provide their full Rust-only contract. Do not remove or fake
those source checks, supply SDK paths, or copy old Scheme receipts to proceed.

The full current graph attempt with wheel 004 exited 1 in 3.260857541 seconds /
original 300-second cap at `ascent.build` import, before framework validation.
The missing inventory capability is unchanged in wheel 007, so that known failed
graph route was not retried. There is no CURRENT/PASS full graph for this overlay.
Full consumer regression and complete source-bound wheel qualification remain
independent gates; Library and installed conformance results do not replace them.

The actual complete downstream unittest discovery against wheel 007 terminated
with exit 1, no timeout, in 52.278602541 seconds / 120-second cap: **1365 tests,
3 failures, 234 errors, 40 skips**. SDK/provider/compiler access was denied. This
is an audit failure, not a full qualified regression: unavailable Quint and
explicitly skipped optional lanes are not counted as passes. The original raw
observation is `ascent-evidence-rust-047-consumers007.json` in the archive above.
Do not retry this unchanged inventory merely to obtain a different outcome.
