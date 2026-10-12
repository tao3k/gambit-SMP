# Typed Native Retry Review

Retry review is a conditional investigation gate, not a runtime repair verdict.
The host still authorizes native execution. No model, component test, review
document or ASCENT result can replace complete same-candidate native acceptance.

## Stable Transport And Dynamic Reasoning

`gambit.suite` and `gambit.bootstrap` accept an optional declared `retryReview`
JSON input. Both enforce the same native policy before runtime testing or
`bootclean`/`from-scratch`. Bootstrap additionally requires a matching producer
identity and declared known-failure inventory/rules. Python
checks paths, schemas, RFC 6901 references, actual hashes and exact campaign
identity. It projects typed facts, not protocol decisions. Native ASCENT derives
the required transitive claims, missing premises, budget comparisons, circular
dependencies, causal coverage, denial reasons and conditional retry eligibility.

New failure/source reviews change data, not Python branches or the ASCENT binary.
The native rule reader admits these declarations at execution time. Changing
the safety policy requires a fresh engine seal; changing experiment facts or
protocol rule assets does not require rebuilding the ASCENT implementation.
Unsupported native language/API features belong upstream, without a Python
inference substitute.

## Bound Inputs

A `typed-native-retry-review.v1` document contains `campaign` and `failures`.
The campaign must exactly match the observed candidate receipt hash, canonical
failure inventory hash, review policy hash, mode, regime, full selected
fixture/hash inventory, suite and recipe budgets, optional atomic batch budget
and requested processor/job controls. It also binds the entire runtime tree
(including configuration/build inputs), actual host CPU capacity and resolved
processor/job counts. Execution consumes those reviewed counts instead of
resolving a new topology. A review cannot transfer to another candidate,
selection, topology or budget.

Every reviewed failure binds:

- Its original receipt SHA and an actual `/results/N/accepted` false value in
  the requested mode, or an actual nonzero `/steps/N/exit` for the exact build
  operation. Historical failure bytes are never overwritten.
- Its original nonempty archived raw log and the baseline identity receipt
  that the failure itself names by SHA.
- Its original native budget field, not elapsed time. Whole-mode and atomic
  budgets retain separate regimes; atomic coverage cannot waive a whole run.
- Exact before/after source or selected fixture hashes. Current bytes must be
  physically present in the candidate/workspace. An unchanged input emits no
  change fact.
- Hash-bound causal review evidence and its declared transitive premises.

`budget` has `regime` and `pointer`: whole regimes use
`/wholeSuiteBudgetPerMode`, and atomic coverage uses
`/atomicBatchBudgetPerMode`; `build-step` uses `/wholeBootstrapBudget` and the
original seed identity binding. Budgets must be positive finite seconds with exact
millisecond precision. Missing historical identities, logs or original budget
fields remain unsupported, not reconstructed from a later passing run.
Environment/tool changes currently require a separate typed observation
contract; a source delta must not silently stand in for them.
The native category/change-domain relation enforces this boundary: an environment
failure cannot become eligible from a source-only review.

## Evidence And Native Policy

Each claim reference binds an evidence file SHA and a JSON pointer. A
`typed-causal-review-evidence.v1` file contains claim rows with `claim`, `domain`,
`status`, failed/current receipt hashes, change IDs, premise IDs, hash-bound
references and explicit reasoning. Root obligations are `failure-scope-review`,
`change-relevance-review` and `assumptions-review`. Native rules expand premise
dependencies transitively and reject dependency cycles.

Only evidence in the `causal-review` domain with `reviewed` status satisfies
those obligations. Finite-model or local-control evidence stays in its own
domain. The relevance review must link an actual changed input. Evidence
authorship and the completeness/truth of the reviewed reasoning are trusted
host inputs, not cryptographically authenticated causal proofs. A typed label
is not a source refinement proof; explicit reasoning must be reviewed against
the original failure and actual source before authoring that label.

The policy is `evidence/research/suite-review-rules.ss`, copied into the engine
seal and hash-checked by preflight. Recipes cannot supply a weaker replacement
policy. The canonical `evidence/native-failures.json` is mandatory; an alternate
empty or reduced inventory is rejected. All overlapping known failures retain
their own disposition, including those omitted from a review document.

## Results And Receipts

`retry-preflight.json` records the exact campaign, projected facts, native query
answers, input identities and boundary flags. Native facts/answers/API identities
and actual subprocess logs are also archived in the step directory. Identity
checks run before and after native inference.

- `NOT_REQUIRED`: no selected known failure overlaps.
- `REVIEW_REQUIRED`: a selected failure lacks a completed review.
- `DENY`: supplied review has a denied premise, changed budget/regime, unchanged
  input, uncovered cause, missing dependency or cycle.
- `RETRY_ELIGIBLE`: every selected failure has a complete, hash-bound review
  under the sealed policy and original native budget. This permits only an
  explicitly host-authorized attempt through the same checked suite gate.

`executionAuthorized=false` and `runtimeAdmitted=false` remain explicit in the
review. Each execution entry recomputes the review before probing or launching
tests; it never treats an old review JSON as cached execution permission.
Child exit, timeout, exact completion inventory, source/binary stability and
teardown still decide the new attempt's actual outcome.

The architecture tests use synthetic runtime identities and failure fixtures
with the real sealed ASCENT implementation. They establish transport/inference
and gate behavior, not a Gambit runtime repair or complete native acceptance.
