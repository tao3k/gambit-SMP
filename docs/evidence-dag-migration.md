# Evidence DAG migration

## Implemented boundary

The Library's `program/evidence-dag.ss` owns dependency components, recursive
SCCs, atomic multi-head rules, rule normalization, component fingerprints,
source authority checks, certificate selection, lowering and dependency slices.
The Python `ascent_engine.derivations` binding transports these requests and
manages completed result/session references. Consumer `ascent_program.assemble`
passes complete facts, declarations, rules and queries to the Library. It does
not traverse or prune the dependency graph in Python.

The provider preflight requires `evidence-dag`. An older provider is rejected;
there is no Python planner fallback. This is not a claim that every remaining
consumer policy or source-admission check has migrated.

Fresh sealed rule workers now use the same request-local full before/after
seal boundary as retained evaluation owners. Nested API calls consume that
checked identity instead of hashing the entire inventory again. The boundary
still checks all source bytes on exit, including failed evaluations, and rejects
changed identities. Engine artifact validation and runtime ownership remain
independent checks.

## Observed qualification

All receipts below are ignored local artifacts, not Git-persistent admission:

- `.data/evidence-plan-migration-001/scheme-005`: eight actual source GxTest
  contracts, 2.779 seconds within 15 seconds. Earlier harness failures remain.
- `api-027-controls-001`: nine compiled API contracts and nine C ABI contracts,
  zero skips, 2.842 seconds within the shared 15-second budget. These bind the
  exact `ascent-latest-provider-027` snapshot, not later live Trajectory edits.
- Provider preflight and fresh-worker boundary unit contracts: nine tests pass.
  These are transport/boundary controls, not inference or whole-consumer proof.
- `seal-027-001` was a no-op module invocation. Exit zero did not produce a
  manifest and establishes no seal. `seal-027-002` used the actual entry point.

The DAG controls retain negative cases for forged sources, stale identity,
aliases colliding with base sources, undefined relations, extra rule fields,
and boolean values incorrectly offered as integers.

## Loading failure and latest diagnostic

The fixed 027 research rule worker fails with the original effective budget
of 9.677254 seconds. Removing redundant nested framework hashing did not resolve
it. No whole-recipe retry or larger budget is justified by this change alone.

`verdict-generation-audit-001.json` independently checks all 934 generation
paths: seal 027-003 copied them, with matching bytes but different inodes.
Approved seal 027-004 preserves all 934 source inodes and all hashes. Its matched
rule worker still times out (`verdict-linked-recheck-001`). Thus generation
sharing is not a sufficient repair for this failure.

`verdict-stack-002` records real Python stacks at two-second intervals in an
independent trace file. All samples are inside C ABI `open_sources`; the entry
validation and Engine initialization have already completed. The original
stderr-based diagnostic did not survive temporary ABI stream preservation and
is retained as `verdict-stack-001`, not used as a successful trace.

The first OS sample attempt failed and is preserved. The approved official
macOS sample in `verdict-sample-002` succeeded: 832 of 833 main-thread samples
are under `___dynamic_load`/`dyld dlopen`, with 828 at `__fcntl` during segment
mapping. This is a bounded sample, not proof of a unique cause. No SDK signature,
permissions or private loader hooks were changed.

The same fixed Library and exact rule/fact input also time out using the
original API pathname (`verdict-original-api-001`). That observation is not
sealed admission and does not prove that all loading paths have the same cost.

The latest Trajectory diagnostic seal has engine identity
`7dc2d950e777c8c3d1276993395471d81a426d178e2f1b33c5d14e91fcd25ad0`.
`verdict-trajectory-stack-001` checks all 2280 files before and after execution
and independently restats all 947 shared generation inodes. The exact rule and
fact request completes in 7.507301 seconds at the unchanged 9.677254-second
ceiling, exit zero, without timeout, with the process reaped and quiescent.
The answer is `missing: []`; this is not stable cold-loading qualification.
The earlier `verdict-trajectory-recheck-001` through `004` retain diagnostic
harness failures. In particular, `004` failed while writing its final metadata;
its empty process log is not an admitted execution receipt.

An independent, instrumented Library snapshot records expander entry at
0.017474 seconds, exit at 0.444630 seconds, then import expansion entry at
0.444733 seconds with no exit before the original ceiling. This narrows the
loading investigation in that run to upstream import expansion, not a
replacement loader or Python evaluator. Later split-import diagnostics time
out at expander entry, before any individual import. These observations do
not establish one uniquely slow import. Diagnostic instrumentation is not
part of the production Library.

Later read-only file sampling observes progress through this chain: an early
sample has `gerbil/runtime/table~1.o1` open, while the six-second sample has
`std/ffi~2.o1` open. Core import exits before syntax import in that run, but
syntax import does not exit within the original ceiling. This is evidence of
changing loader work, not proof of one permanently locked file. Read-only
verification reports the sampled table artifact's existing embedded signature
as valid; no signatures or system policy are changed.

A diagnostic using the public global-symbol loading flag also times out at
the same original ceiling. That negative control is not installed into the
live loader. Shared generation inodes and global symbol visibility alone have
not closed the general DSL cold-loading gate.

The constructor-phase dependency candidate must preserve the existing include
evaluation order. `program/syntax.ss` validates the imported Fragment once,
using the validator's returned value; its relation and rule access expressions
are then placed in the eventual Program/Fragment construction. Moving these
operations to ordinary functions must not eagerly snapshot both fields at
include entry. Invalid fragments, nested includes, hygienic macros, custom
storage and caller bounds remain part of the semantic qualification. This is
a candidate constraint, not evidence that a phase dependency has been removed.

The latest source GxTest terminal receipt
`rule-sources-current-source-tests-terminal.json` records exit -9 and timeout
after 180.009848 seconds under the original 180-second ceiling. The terminal
record does not itself establish process-group quiescence; the supervision
permission error remains recorded separately. Subsequent read-only process
inspection is not a replacement for a successful complete test receipt. Warm
test-library preparation and the narrow rule-source controls do not cover this
source-regression failure.

A temporary constructor/import dependency candidate still exceeds the original
cold-request ceiling and is not installed. A separate static compilation
candidate may select a fixed, fully recognized core form before execution;
this is not permission to substitute the inert-source contract for general
DSL. Core operator binding, Scheme numeric and short-circuit semantics,
variable scope, declaration and rule order, bounds, composition checks and
source authority must agree with the original macro lowering. Unknown forms
retain the original upstream path. Once a path has been selected, a runtime
exception must not trigger retry through another path. Guards do not gain a
checked descriptor or proof support merely because their syntax is recognized.
Only actual same-input macro-versus-candidate execution can qualify this
optimization; finite models and a narrower accepted grammar cannot replace it.

The instrumented temporary closed-source API receipt has SHA
`20632bac3ea8df7a3790c8352a500bcd1ae652fde880077623891b2d34ce1a36`.
An independent read-only check matches all 135 build source inputs, 129 linked
Scheme sources, 2220 loading resources and both Library/extension binaries.
The first diagnostic request finishes in 1.936258 seconds under the unchanged
9.677254-second ceiling, with exit zero and no timeout. This temporary artifact
still contains diagnostic instrumentation and is not the final sealed Library
candidate. The initial independent checker mistakenly interpreted a relative
binary receipt path from the process directory and failed; the corrected
check resolves it relative to the API receipt, without changing any artifact.
Neither this identity check nor the one request qualifies semantic equivalence,
the full review, matched workload performance or a CURRENT graph.

The same diagnostic artifact also opens the complete suite-review policy with
57 relation descriptors in 1.198907 seconds under the same ceiling. No complete
fact query or 105-test review is established by opening that session. A later
guard-arity correction changes the temporary source: the API receipt expects
closed-source SHA `c87c629d5c8397530101b6b70b4036c0b278e349a54f0678145d7b698cac78b3`,
while the independent subsequent source check reads
`2c75a50384f328da154b2bea16be06e0e69361277415e74dc0ab0c354b78a809`.
The earlier identity match is therefore historical, not CURRENT. A newly built
and bound artifact is required before qualifying the correction. The current
candidate's recognized guard arities and the ordinary upstream path for other
arities must both retain the complete public DSL contract.

`review-trajectory-001` exercises the original complete 105-test inventory.
It remains DENY: 62 pass, 42 error and one reported failure, with 60.612370
seconds elapsed against the original 60-second whole ceiling. Three owners
are incomplete. One owner's first native request exhausts its 8.849746-second
remaining cap; subsequent requests encounter the closed owner. No sources or
failed tests are removed, and the receipt is not reclassified as successful.

The reported subtest failure was a runtime error, not an assertion failure.
The reporting implementation now follows unittest's failureException boundary
and emits each subtest traceback; errors take precedence over failures for a
test containing both. `reporting-contracts-001` covers the complete 17-test
reporting module, exit zero in 0.120713 seconds under the unchanged 15-second
ceiling. It does not qualify the failed review or a new CURRENT graph. The
historical review receipt remains unchanged.

## Explicit rule-source entry

The Library now advertises `open-rule-sources` with the exact contract
`inert-relational-subset.v1`. A Recipe may explicitly select it with
`rulesContract`; absent that selection, rule sources still use the complete
Scheme DSL. Python transports the original source bytes and hashes and does
not parse or lower the subset. Missing operations, incompatible contracts and
unsupported syntax are errors, never a fallback to another execution route.

The complete review policy is outside this subset: it uses comparison and
compound predicates not admitted by that contract. Review therefore remains
on the general DSL. The intermediate `research-engine-rule-sources-001` seal
contains an interim route and is not a whole-review candidate.

The corrected seal `research-engine-rule-sources-002` has engine identity
`66d73b1d05f88fa96d10a2d3dc76e40e60e502b933e81d39be4fd35b326a0dbd`
and API receipt SHA
`7eacb2635b1a5c0a1a27691953a49181503ec7e8075fed7aa63b15d532e1680e`.
It binds 2282 files and all 949 shared generation artifacts. The real recursive
inert-source controls, including withdrawal, generation changes, released
results, source drift and explicit executable-syntax rejection, pass in
1.979512 seconds under the original 15-second ceiling
(`inert-session-controls-002`). This is a narrow entry qualification.

The same-input full-DSL/inert equivalence test times out at the full-DSL entry
under its original 15-second ceiling (`inert-source-equivalence-001`). It does
not establish equivalence. The corrected complete 105-test review also remains
DENY (`review-rule-sources-001`): 60.394327 seconds against the original
60-second ceiling, with every lane stuck at its first test and no completed
owner receipt. Neither failure is retried unchanged or replaced by the narrow
controls. No CURRENT graph or complete cold-loading qualification follows.

## Remaining gates

The final current provider includes independently authorized Trajectory changes.
Its fixed build, package, API, complete source inventory and resource identities
must match before qualification. The new DAG controls above cannot be stitched
into that identity.

The original 105-test sealed review, whole consumer inventory, matched full
workload performance and complete CURRENT graph remain required. The old
105-test run (81 passes, 24 errors) remains DENY. Source-level contracts,
compiled DAG controls and successful sealing do not replace these gates.
