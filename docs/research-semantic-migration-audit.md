# Research Semantic Migration Audit

## Observed Gaps

This records the audit and the implemented migration. Whole-consumer and current
graph qualification remain separate gates.

The former `protocol_source_audit.check_schedule` enumerated four policies and
eight schedules, calling `sync_retirement_source.expected` in Python. The current
path no longer imports that oracle. Versioned observation declarations and
`evidence/dsl/observation-contract.ss` own completeness, duplication, missing
fields and outcome correspondence. Python transports exact fields and receipt
pointers. Model coverage and allowed research statuses similarly moved to
`source-review-contract.ss` and `protocol-source-requirements.json`.

`research_actions._execute_action` returns a proposal for `design-experiment`.
Its separate-kernel-review marker correctly preserves the authorization boundary,
but does not constitute a completed discover/select/execute/evidence loop.

The existing `source-schedule-revalidation` v2 Recipe already demonstrates the
generic execution route: materialize, project, bind, build, exact controls, and
Scheme Evidence evaluation. Its source-derived mock boundary must be preserved.

## Actual Action Execution

`evidence/research/observation-contract/actions.json` declares two v2 Recipes:
source-bound synchronization schedules and VM activity-log resource controls.
Both use the same generic contract and exact prior-step JSON pointers; neither
adds a mechanism-specific Python capability. `evidence.evaluate` accepts the
typed observation binding, checks its complete Recipe input membership, and
archives its sources through the existing evaluation path. A terminal DSL query
also preserves the complete step, source binding and control linkage inventory.

Both were executed through actual `discover`, authorized `select`, sealed kernel
and `observe` calls, not direct test mocks. With seal
`00d60b1ae9fe5b245b398914da4b62fd2b66df31c91c9d5949754be0a9dcd1fb`,
the schedule parent exited zero in 20.183/90 seconds, and the VM-log parent in
16.696/90 seconds. The terminal budget stayed 10 seconds. Both readbacks were
CURRENT/PASS. This qualifies these source-derived component observations, not
SMP runtime correctness, source refinement or release admission.

Original attempts with seal `d2ce16af69a15f770bf26ca0ce1f291f8ec5103ca48a1a3190aa0012e557edd7`
timed out in the terminal 10-second step and remain DENY. Its 927 compiled
generations actually used copy fallback. A formally approved sealing operation
created a new seal with 927 linked canonical generations; no source bytes,
permissions, generation names, signatures or loaders were modified. Runtime
profiling located the old stall in first `open-evidence`, before query execution.
No statistical speedup or universal portability conclusion follows from this.

Raw local receipts are retained under `.data/observation-dsl-migration-001` and
`.data/research-actions`. They are not Git-persistent admission. The original
serial 15-second audit timeout, first contract assertion failure and no-op module
entry attempt remain preserved. The migrated 11-test audit passed within the same
whole 15-second budget using the existing process batch supervisor; a six-test
contract suite exercised both inventories and withdrawal/restoration.

## Ownership Contract

- Versioned Recipe data declares inputs, exact inventories and execution budgets.
- C/SCM research assets implement observed runtime mechanisms; QNT models state
  transitions and explicit assumptions, not runtime admission.
- Declarative Scheme Evidence owns relations, hypothesis comparisons, research
  obligations and evidence-supported conclusions.
- Python validates schema, path/SHA/pointer identity, permissions, reservations,
  deadlines and process termination. It must not compute mechanism-specific
  expected outcomes or introduce a producer for each research question.
- The action interface requests existing capabilities. Inferred availability is
  not host authorization, and every executing step rechecks its state identity.

A fixed capability registry is not itself a defect: a capability should describe
a reusable operation, not a candidate, case, package or expected research answer.
Moving special-case Python into Scheme branches does not satisfy this contract.

## Direct Migration Acceptance

Migrate the current schedule oracle without altering historical receipts. Bind
the complete existing eight-control inventory to versioned declarations and
Scheme rules, then compare all answers against the frozen historical observations.
Keep missing-control, duplicate, changed source, wrong outcome and failed-process
negative controls. The historical oracle may remain as receipt-bound archive
bytes; it must not execute as the new admission path.

Qualify at least a second distinct mechanism without Python implementation edits.
Then exercise discover/select/observe through the sealed kernel with stale state,
permission refusal, unchanged failed route and interrupted execution controls.
Only matching full consumer and current graph results can establish integration.
No timeout increase, omitted input, old PASS substitution or silent fallback is
permitted. Full consumer, sealed-review and current graph acceptance remain open.

## Complete Qualification Attempts

`fullgraph-001` retained all 1192 declared tests. The ordinary inventory ran
1087 tests successfully in 245.049 seconds. The separate 105-test sealed review
domain did not complete under its original 60-second, two-worker contract:
72 finished observations passed, two were unfinished and 31 were unclaimed.
The domain reports all 105 as errors because its terminal inventory and teardown
were incomplete. Aggregate validation is DENY with zero skips, zero ordinary
failures and no changed inputs. The outer graph process exhausted its original
300-second budget (300.003961 seconds, exit -9, process group quiescent). No
complete CURRENT graph was produced.

`review-auto-001` is a new scheduling experiment, not a retry waiver. Its bound
test source explicitly selects the existing resource-aware `auto` policy while
retaining all 105 tests, all byte checks and the original 60-second deadline.
Observed capacity and selected workers were both 12. Each lane claimed one test
but none completed; all lanes timed out, and the terminal domain remained DENY
in 60.709190 seconds. There was no evaluation-owner request archive, so these
observations do not establish an inference or loader root cause. More workers
are not an established fix. Preserve this complete failed inventory alongside
the two-worker result; do not rerun either unchanged experiment or promote the
two successful component mechanisms to complete consumer acceptance.

## Measured Cold Entry And Exit

The original two-worker and later auto-worker failures remain immutable. Two
diagnostic runs use Python call/return tracing and an eight-second traceback
snapshot, not private Scheme loader hooks or an admission retry. Their complete
logs live in `exit-phases-001` and `exit-phases-002`. Instrumentation itself
changed request timing; neither run qualifies its test population.

The second diagnostic shows most workers waiting for cold source construction,
one inside the official `open_sources` dispatch, and other snapshots inside full
resource hashing. Visible retained-session close calls take milliseconds;
visible official runtime shutdown calls take approximately 0.40 and 0.59
seconds. These samples do not prove that all exit failures have one cause.

The first construction permit omitted Library import and runtime initialization.
Seal 006 attempted to cover the first official API context through its first
DSL request. Its complete 105-test run remained DENY: a caller can wait on a
sealed child inside that context, so retaining the permit across `yield` creates
a cross-process wait cycle. The failed candidate and entire inventory remain.
The replacement scopes the permit to official C ABI import and initialization/
describe, never the caller body or child request. Independent source construction
is no longer serialized across processes. Its
same-process/thread reentry does not grant a child the parent's permit. Warm
retained calls remain ungated. The original deadline includes permit waiting;
the per-owner exit wait remains one second. Completed owner finalization uses
the same permit; incomplete requests never wait on a permit their child might
hold. Parent reaping and the complete terminal source-byte check remain
mandatory. No source validity is inferred from an identity-cache hit.

`review-admission-001` and `002` remain DENY despite finishing in 57.390 and
54.191 seconds: forced owner exits prevent complete admission. New seal 005's
`review-admission-003` also remains DENY: all workers exhausted the original
60-second deadline, without a completed request inventory. Seal 007 contains
the corrected cold-entry boundary; its actual review and complete graph results
must be checked separately. None of these observations establishes a stable
speedup, full consumer acceptance or Gambit runtime correctness.

The complete seal 011 review (`review-admission-008`) finished in 52.739791
seconds under the original 60-second budget: 84 passed and 21 errored, with no
skips. It remains DENY. One lane's first request took 8.033092 seconds; the next
request in the same original ten-second test context had only 0.482527 seconds
left. The resulting closed-owner errors are not independent Library failures.
Seal 010's initial-owner indentation error is preserved separately; its shorter
run is not performance evidence. The retained-session module also exhausted its
original 15-second budget after nine completed tests.

Seal 012 removes the surrounding API-entry permit from full per-path hashing.
Actual C ABI import and runtime initialization remain guarded; full initial and
terminal byte validation remain mandatory. The focused lock controls verify
that hashing and caller execution do not retain the initialization permit.
Its new complete review must be evaluated independently, not combined with seal
011. Seal capture 013 transposed timeout and elapsed fields in its caller; the
original receipt is retained with an explicit correction document, not silently
rewritten. No complete current graph or stable matched speedup is established.

Seal 012's complete `review-admission-009` finished in 56.766178 seconds:
81 passed and 24 errored, zero skips, still DENY. Five owners completed and one
did not. Its first request took 7.770208 seconds, leaving only 0.563827 seconds
for the next subtest request within the original ten-second context. Moving
hashing out of the permit is therefore not sufficient and establishes no
matched speedup. Do not repeat this unchanged campaign or run a complete graph
as though its sealed-review prerequisite passed. Library source changes from
other owners require a separately matched producer identity; API018 results
remain observations of the fixed old artifact, not qualification of new code.
