# History Journal And Analysis Publication

The consumer receives Evidence definitions through Python/C ABI. The Library
owns expansion and inference; no downstream Scheme import or compile is needed.
`evidence/dsl/history.ss` declares the history relations and publication rules.

## Separate Transactions

`append_observation(root, lineage, inputs, results, backend)` commits a complete
content-addressed observation and a distinct raw event before any analysis.
Repeated answers have the same observation identity; each received event keeps
its full backend metadata. Unknown identity, exit, timeout and budget fields are
not invented. Recording alone never makes a conclusion reusable or authorized.
`bound_inputs` names actual caller-root files and exact hashes. `record` binds
all supplied source inputs by default and rechecks them before inference and
publication. A raw `append_observation` without those bindings remains reported
input data; its analysis explicitly lists reported-only inputs, not source proof.

`analyze_observation(root, observation, limits=...)` appends an immutable request,
then loads the current definitions and checks the complete Library artifact
inventory. ASCENT derives insertion, withdrawal and retention over full prior
and current rows, source inputs and backend bindings. It separately derives
publication eligibility from actual completion, checked sources/backend, and
the expected parent. This second query withdraws comparison source rows rather
than redundantly recomputing their delta; the full first comparison is retained
in the analysis receipt. It does not replace or truncate observation inputs.

Publication is one short SQLite transaction: append the successful analysis,
compare both head observation and head analysis generation, and update both.
Publication also checks the immutable lineage definition captured by the request.
Comparing only observation identity is insufficient when the same observation
is republished. Native inference never holds the SQLite publication lock.
There is no automatic conflict retry or execution-deadline reset.

An exception retains the request, observation, raw event and available analysis
metadata, and leaves the published head unchanged. A killed process leaves a
request without a terminal result; readback calls that attempt pending, not a
fabricated timeout or successful analysis. Recovery explicitly starts a fresh
current analysis, preserving the original interrupted request.

`read_journal(root, lineage)` checks identities and returns all observations,
events, requests, results and pending attempts. It never loads disk results as
current native passes. These APIs are journal transport, not a Python reasoner.

## Stable Lineage

`lineage(workflow, task=..., branch=..., selection=..., policy=...)` binds a
caller-owned logical workflow. Failure inventories, source revisions and
backend versions are observation data, not implicit partition keys. Database
roots isolate workspaces. The default `workspace` branch label is explicitly
not Git branch detection; shared databases require explicit caller labels.

`run_review(..., history_lineage=...)` accepts that label. Its default is stable
across growth of the full failure inventory. On first use only, a matching old
inventory-keyed head can seed an explicit immutable lineage parent. A missing
old partition is not guessed. Existing observation bodies and old heads are
never renamed or rewritten. `fork_lineage` explicitly binds a parent observation
and rejects a different parent for an existing lineage.
Forks bind the exact published parent analysis generation as well as its observation;
republishing that same parent observation cannot silently change the fork's basis.

## Evidence Boundaries

`models/library/HistoryJournal.qnt` models append/prepare/complete/fail/publish,
versioned CAS, inventory changes and immutable forks. It has separate negative
controls for loss of observations, failed or early publication, observation-only
CAS and inventory-derived lineage. Safety and conditional progress use finite
identities, not production record limits. Progress assumes fair completion,
failure and conflict handling; it does not prove arbitrary native callbacks
terminate, process availability, disk durability after hardware failure, or
source-refinement. `tests/test_history_protocol.py` uses the shared Quint/TLC
backend rather than a Python transition simulator. These framework model checks
do not establish research receipt admission or runtime correctness.

Real consumer tests cover actual finite native rejection, full-input growth,
withdrawal, independent publication premises, legacy identity preservation,
versioned publication races and process exit before analysis. Full validation
binds the QNT files individually. Execution budgets and historical failures
remain unchanged; focused checks do not substitute for a complete current graph.
