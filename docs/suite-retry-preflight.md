# Failed Route Execution Gate

## Scope And Decision

`native_suite.py` now calls the shared `retry_gate.py` before its processor
probe or any suite process. The gate uses the existing research Datalog rules
and preserved native-failure receipts; it does not execute a candidate.
It compares each concrete selected failed file/mode against actual interpreter,
compiler, GNU build-driver/helper and tested fixture bytes, plus the budget.

The original toolchain directory binds executable identities. The isolated
test snapshot binds the actually tested fixture, including test-only patches.
The research adapter's strict path containment is unchanged. Comparing a
symlinked runtime view directly failed that containment check in integration
attempt 001; this was an adapter error, not native evidence. Attempt 002 and
the source-digest-bound attempt 003 reject the unchanged route before execution.

- `DENY` exits 2: unchanged failed inputs, expanded budgets, missing hypotheses
  or unbound identities do not start the candidate.
- `REVIEW_REQUIRED` exits 3: changed inputs with a causal hypothesis still do
  not grant execution. There is no bypass or automatic review approval.
- `NOT_REQUIRED` means no comparable denied file/mode was selected. It is not
  a native pass; all existing identity, topology and completion gates still run.

An optional `--retry-hypotheses` JSON object maps failure IDs to `cause` and
`expectedObservation` strings. It explains a proposed change; it cannot admit
an unchanged route or waive the budget. A reviewed-repair resumption mechanism
remains to be implemented before changed failed routes can execute here.

This first integration covers concrete failed suite files/modes. Directory,
whole-suite, bootstrap and compiler-phase-only denials remain separate
obligations. Selected concrete failures whose old format cannot be compared
require review rather than silent execution. Extra fixtures absent from the
original source also require review; their unsupported comparison is explicit.
Do not interpret this as universal coverage of every runner or report.

## Actual No-Execution Check

Runtime026's original `03-number/_num.scm`, compiled mode, unchanged 300-second
atomic budget is rejected as unchanged tested inputs (and missing causal
hypothesis). There is no processor-probe or compiler-run log, and the suite
receipt records `runtimeExecuted: false`. This is an execution-gate negative
control, not another attempt to compile the known failing file.

The source-bound gate receipt and comparison are archived as
`evidence/model-results/suite-retry-preflight-026-bound-deny.json` and
`suite-retry-preflight-026-bound-details.json`. Earlier attempt 002 receipts
remain separately archived; raw attempt 001 exception context remains local.
No Gambit runtime code was changed.

Seven focused gate tests exercise unchanged routes, changed-artifact review,
budget expansion, unbound binaries, mode isolation, actual patched-fixture
comparison and path escape rejection. A separate native-suite integration
test asserts that DENY never calls the runtime probe or suite executor.

Full query inputs are bound at observation time. During a permitted campaign,
only execution-relevant registry/rules, route artifacts and adapter sources
are retained as additional stability inputs; unrelated paper/model inventory
updates do not impose per-batch rehashing of the entire research corpus.
