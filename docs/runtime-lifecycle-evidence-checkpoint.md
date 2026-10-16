# Runtime lifecycle integration checkpoint

The declarative scenario in `evidence/scenarios/runtime-lifecycle` binds one
explicit Gambit candidate with SMP, multiple VMs and multiple threaded VMs all
enabled. It connects initialization, publication, membership, moving roots,
parallel collection, retirement, rollback and destruction to existing QNT
contexts and inferred read-only Action Catalog entries. It is not a composed
source-refinement proof or a native acceptance certificate.

## Preserved qualification results

* `lifecycle-evidence-003`: three real DSL/action consumer tests passed in
  11.553 seconds under the original 15-second process budget.
* `lifecycle-current-graph-004-process`: exit 1, no outer timeout, 294.099 seconds
  under the original 300-second budget. The process group was quiescent.
* That full validation selected 1,076 tests: 957 passed, four failed test IDs,
  115 error outcomes, no successful complete qualification. Five framework
  inputs changed during execution, so the receipt cannot be reused as current.
* Its sealed domain selected 105 tests. Both lanes were killed under the
  unchanged shared 60-second deadline. Incomplete and unexecuted tests remain
  errors; finished individual assertions do not make the domain pass.
* `lifecycle-git-classification-001`: twelve graph tests passed in 1.294 seconds
  under 15 seconds after adding staged-submodule classification. Staged child
  files remain non-durable at parent HEAD; no provenance check was waived.
* `lifecycle-evidence-004`: exit -9, timeout true, 15.149 seconds under 15 seconds.
  Discovery/select had not completed. The earlier successful result is not a
  substitute for this later failure.

The full run also exposed localhost socket permission rejection in the Quint
backend, a missing source lock in a build-profile fixture, stale historical GC
trace assertions and text-session regressions. The current GC trace assertions
now read the newly decoded shared-contract traces with unchanged violation
predicates. Original trace files remain bound as history. Raw model admission
also checks the receipt's complete QNT input closure, including the shared
WorkObligations module; a changed import is denied rather than silently reused.

All listed process artifacts are under `.data`; they are local observations,
not Git-persistent admission. Historical raw model campaigns remain under
`evidence/model-results/gc-parallel-contracts`. No execution budget was raised.

## Still open

## Retained-session successor

The shared framework owner supplied exact SHA identities and froze its inputs
for this diagnostic window. The freeze was explicitly released after the
diagnostic graph completed; it is not an indefinite hold on native repair.

Single-discovery cProfile (`lifecycle-action-profile-001`) observed 5.956 seconds:
3.142 seconds creating two Library sessions, and 1.182 seconds in complete hash
checks. This is diagnostic profiling, not a stable performance benchmark.
Action discovery and read-only view selection now retain their actual Library
owner. `lifecycle-evidence-retained-001` completed four tests in 9.932/15 seconds,
exit 0, no timeout, process group quiescent; the tests assert real session-handle
reuse rather than infer reuse from timing.

Explicit Evidence-program reuse now keys on complete definitions, constructor,
arguments, trust and fact-limit policy, and rebinds the full current source map.
The source-rebinding test checked withdrawal, generation invalidation, current
source provenance and changed-byte rejection. Ordinary calls retain their
original byte checks.

Within a sealed request only, nested API checks can use the manifest identity
already checked by the surrounding `sealed_api_boundary`. That boundary runs
`execution_identity` before and after every request, including exceptional
exits. It checks the entire seal and host-tool closure; there is no cross-request
identity cache, mtime substitution or skipped source inventory. API paths outside
the checked seal are rejected. The boundary resets its context even on failure.

These changes did not close the sealed deadline: both
`lifecycle-sealed-review-retained-001-process` and
`lifecycle-sealed-review-boundary-002-process` ended with exit -9, timeout true,
under their unchanged 60-second outer deadline. The complete 105-test inventory
was not completed. The latest diagnostic seal was
`f57fad4d60808311c9d603e118aef91e628c7f7d5e2b11417d5fb9567105b655`.

`lifecycle-diagnostic-graph-005` rendered the integrated lifecycle graph in
14.624 seconds, exit 2, no timeout, using explicitly rejected historical
validation. Graph SHA:
`21bfd6e19750e5f60ea744378a93c1366ffed0633f4b878da3fd9a38801edecd`.
Actual readback found no changed input/backend/checkout bytes, but status and
framework validation remained STALE and frameworkValidated remained false.
It is a diagnostic graph, not a current qualified complete graph.

The corrected cross-VM progress QNT source and exact local recipe observation
are now view inputs. Their bounded verification does not close the real native
stall. Library maintenance's new producer/API qualification and paired timing
were still in progress during this window; no additional timing workload was
started to compete with them, and the historical Library package was not
presented as the latest qualified producer.

## Direct Library caller reuse diagnosis

The next diagnostic isolated a second path not covered by evaluator retention:
four policy test classes called `engine_api()` directly, constructing a fresh
Engine and lowering the same rules on every query. A real nine-query test under
its original 15-second diagnostic ceiling took 12.637 seconds with cProfile:
nine `open_sources` calls consumed 8.264 seconds and API boundary checks consumed
3.246 seconds. Logs and the complete profile remain in
`.data/lifecycle-review-test-profile-001`. A separate retained evaluator profile
in `.data/lifecycle-sealed-profile-001` completed two exact same-rule requests in
5.933 seconds, with one `open_sources` call (2.859 seconds) and six full seal
checks (2.170 seconds). Profiling overhead and concurrent host activity prevent
these observations from being a stable benchmark or a latest-Library speedup.

The four direct callers now explicitly use `engine_api(retain=True)` and
`query(..., reuse_program=True)`. Their facts, mutations, withdrawals, expected
answers and assertions are unchanged. Ordinary full API/source checks remain;
no new identity cache or budget exemption was added.

The same nine-query test was profiled after the caller change in
`.data/lifecycle-review-test-profile-002`: one session constructor instead of
nine, complete assertions, exit 0, no timeout, clean teardown, 11.088 seconds
under the same 15-second ceiling. Its single cold `open_sources` nevertheless
took 5.994 seconds. Thus session reuse is mechanically observed, but one
before/after profile under concurrent host activity is not a statistically
stable speedup or a matched latest-provider performance qualification.

The complete original 105-test inventory then passed with zero skips under the
same two-worker, 60-second policy. The domain took 57.205 seconds; its enclosing
process took 57.467 seconds, exit 0, timeout false, process group quiescent.
Both lanes had complete identities, owner receipts, clean reaping and teardown.
Artifacts: `.data/lifecycle-sealed-review-direct-reuse-003` and its separate
`-process` directory. Earlier timed-out runs are retained.

This closes that timeout only for the historical fixed seal `f57fad4d...`.
It does not qualify the moving maintenance checkout, a latest provider build,
the full consumer suite, the complete CURRENT graph or the Gambit lifecycle.
Those require new matching identities and fresh acceptance receipts.

## Remaining gates

A matching stable framework seal and complete CURRENT graph are still required.
The fixed-seal sealed-review timeout has the above complete local result;
latest-Library sealed review and the later consumer timeout still require their
own matching qualification. Permission rejection must not be bypassed.
Source changes during validation must remain STALE, not be normalized away.

Real long topology sampling completed only 624 of 1,000 samples for two
concurrent VMs before a stall; three through five VM phases were not reached.
Completed-sample percentiles cannot represent the full experiment's tail.
Matched baseline/candidate measurements, complete native lifecycle acceptance
and source refinement remain open. No overall closure or speedup is claimed.
