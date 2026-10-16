# Direct Rust DSL Migration 050

This increment implements direct migration, not a Scheme compatibility layer.
The overall migration is incomplete. Public
Rust objects are Module, Declaration, Value, Result and Explanation. The old
EvidenceComponents, EvidenceDeclaration, OwnedValue and EvidenceResult names
are not aliases in the installed Rust wheel.

Both the Python package configuration and ascent-python's Cargo defaults now
select rust-runtime and Rayon. A normal maturin build (without backend override
flags) produced wheel004 in 8.506 seconds under 120; seven installed controls
passed in 0.817 seconds under 15. Thus default packaging no longer silently
selects the old Scheme backend. Alternative explicit Cargo configurations are
separate artifacts, never runtime fallback.

Final local wheel SHA256:
2c5521f2ea5954350028c8db90511003e1ba02561633d29ca9b7d79342fcd228.
Extension SHA256:
9b04f6336240361f26050c4f0809af61c7c5b4ba2d44ab05aeedff023fc671e2.
Independent installed-byte rehash matched 147 source inputs and 454 role
bindings (158 unique files). Local installation provenance is not a Git pin.

Final seal004:
10f97f5460c75375714be526368f0af5a9f810cf16154d85ae7c7c3332dbe1be.
The full matching Graph004 executed 1519 tests, zero skips, complete inventory,
one failure and ten errors; parent exit 2, 182.606 seconds under the original
300-second cap, no timeout, quiescent and no input drift. All 105 sealed review
cases passed in 14.680 seconds under their original 60-second budget. The four
previously setup-blocked cases actually ran. Readback before archival returned
CURRENT with frameworkValidation DENY, not an overall PASS. Subsequent evidence
archival/document updates must not be mistaken for a revalidated current graph.
The normal-default ASP gate passed in 37.222 seconds under 120, zero ignored.

## Actual Implementation

ASCENT owns pattern-rule expansion, scoped macro calls, relational source,
projection, union and join lowering, explicit relation exports, and closed
declaration constructors. They lower into the existing checked Rust graph;
Python does not implement research semantics. Unsupported macro ellipses and
host-language execution remain explicit errors, not alternate backends.

The unchanged real dependency/investigation DSL now links recursive rules,
operator exports and source authority. Its current source rows remain in the
explanation envelope even when a custom declaration supplies metadata.
Reported rows and declaration dependencies do not establish per-row proof,
causal review, retry eligibility or host authorization.

Structured datum constants reuse ASCENT's ObjectGraph and FrozenValue types.
Separate literal graphs receive separate identities; sharing within an owned
pool and cycles are retained. Tables and opaque values are owned observations,
not executable Scheme handles. Result graph transport is independent from
scalar projection, with explicit partial projection and generation checks.
Identity-bearing table/opaque catalog projection remains explicitly unavailable
where it cannot preserve ownership; it does not prevent Rust execution or
native owned graph results. The graph pool controls retain cycles/sharing and
distinguish separate owner-local opaque identities without a Scheme VM.
No generic Python interpreter or new Python producer was added.

The build-only program/rust-execution.ss IR origin remains a bound build input.
It is not a linked Scheme module or an installed runtime SDK dependency. The
installed Rust-only wheel runs with SDK/upstream checkout reads and Scheme
tool execution denied. Maintainer compilation and runtime are separate claims.

## Qualification Boundary

All raw successes and failures are retained under
evidence/library/rust-consumer-050 and the corresponding local graph directories.
The malformed structured-value test datum, failed investigation lowering and
compiler error were retained, then corrected by actual source/test changes.

- Rust definition controls: 16 passed, zero ignored, 17.850 seconds under 120.
- Wheel001: actual build exit 0, 15.396 seconds under 120; installed controls
  seven passed under 15, after preserving the malformed-datum failure.
- Graph001: parent exit 2, 159.637 seconds under 300, no timeout and quiescent;
  1515 tests, three failures, ten errors, zero skips, four setup-blocked cases.
  Input drift was empty. All 105 sealed review cases passed under their original
  60-second budget, but completeTestInventory remained false and validation DENY.
- Graph002: parent exit 2, 160.301 seconds under 300, no timeout and quiescent;
  1515 tests, one failure, eleven errors, zero skips, no input drift, and the
  same four setup-blocked cases. Subsequent direct session migration is not
  retroactively counted in that run.
- Wheel002 includes subsequent graph-identity, partial result and full source
  explanation fixes. Actual build exit 0, 11.052 seconds under 120; seven
  installed controls passed in 0.561 seconds under 15, SDK and Scheme denied.
- Seal002 is 681b1779877621ec526bd97aa1968863b7e8e9dd22724029e00672162b982967,
  345 files. Wheel001/Graph001 do not qualify this new candidate.

## Still Open

General module/call, closure, higher-order operator and full vector/match/for
consumer contracts are not all migrated. Existing compiled-Scheme-module call
sites must be replaced by the actual Rust interfaces, not made to pass using
forged linkedSchemeSources, aliases or fallback. Positive behavioral contracts
must not be replaced by expected-rejection tests.

The four formerly setup-blocked ModuleSessionTests have been directly migrated
to source-bound define-evidence declarations. All four executed and passed in
0.181 seconds under 15 on wheel002, with SDK/Scheme denied. Source replacement,
non-scalar rational graphs, stale-owner retirement and unbound definition
rejection remain behavioral controls. Exact definition UTF-8 bytes are bound
separately from auxiliary observation inputs; hashing an unrelated file cannot
authorize different DSL text. This focused result does not update the older
full graph's coverage claim.

The installed wheel is local; the declared Git dependency remains a different
publication identity. No remote installation, Git publication, complete current
graph, full consumer closure or matched performance claim is established here.
All original time budgets, historical SHAs and failure receipts remain intact.
