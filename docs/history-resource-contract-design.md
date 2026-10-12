# History Retention And Native Operation Resources

Status: default cardinality and request-byte policy implemented and qualified on
the final 046-005 native build. See `caller-owned-capacity-qualification.md` for
matched build, consumer, production and identity evidence.
The human authorized a new general contract, then explicitly required infinite
default fact counts and optional caller limits. This supersedes the old default
4096 policy; it does not change any historical receipt or watchdog budget.

## Correct Boundary

Persistent history must not have a fixed lifetime record-count limit. Optimization
creates additional observations, and keeping them is part of the product.
Explicit user retention/deletion policy is distinct from inference capacity.

The SQLite implementation has no row-count retention cap.
`reasoning_history.record` reads the head observation and the current observation,
not all preceding observations. The refusal at 4096 is therefore not a history
record limit: the historical `evidence/native/history.ss` fixed input occurrences
at4096 and derived/output counts at32768. The new constructor uses the Library's
unlimited defaults. Backend identity
leaves are source facts in that comparison and are counted individually.

This operation limit currently has a persistence side effect: record writes the
observation and advances its head only after native comparison succeeds. A
comparison-budget failure therefore prevents a valid new observation from being
recorded. That coupling is unsuitable for a growing optimization history.

## Three Independent Contracts

1. Durable observation retention: append complete identity-bound observations;
   no fixed lifetime count. Storage exhaustion or corruption is an explicit
   persistence failure, never silently omitted history.
2. Query semantics: the caller names an exact scope/range/snapshot and native
   Scheme owns the comparison, joins, negation, aggregates and withdrawal.
   A pairwise query is not an all-history query. Any projection or selection must
   be declared by the query, not introduced to evade a resource limit.
3. Operation resources: the host may explicitly budget one execution's time,
   resident memory and optional input/derived/output counts. These bound work,
   not how much history may exist. A generic Library contract must not require
   every caller to accept a permanent 4096-fact semantic cutoff.

No default unlimited-history claim implies unlimited RAM, infinite execution or
guaranteed completion. Fact count is an optional workload guard, not an accurate
memory metric: a small number of large native values can cost more than many
small tuples. Resource exhaustion is a typed incomplete operation, not evidence
that a conclusion is false, impossible or unauthorized.

## General Native Policy Design

The new policy distinguishes optional cardinality guards from execution resource
budgets. Native Program, ordinary `ascent` and operator compilation default to
`+inf.0` for input/derived/output counts. This is actual infinity, not a large
integer substituted for4096. Python transports optional `FactLimits(input=...,
derived=..., output=...)`; `None` fields have no caller ceiling. Native Scheme
validates and applies ceilings; they cannot loosen explicit finite DSL bounds.
Existing finite policies retain their negative controls. No history-specific
branch belongs in Python or the Library; the consumer supplies ordinary DSL.

Finite count enforcement covers source occurrence admission, replacement and
derived/materialized facts. Unlimited counts do not imply all-phase time or
resident-memory budgets: the current `program/evaluate.ss` run deadline does not
cover arbitrary user callbacks or all input admission. Those are separate
resource contracts, not a reason to impose an undeclared finite fact default.
The human separately authorized request-byte defaults to become unlimited,
with optional Python `Engine(max_request_bytes=...)`. Allocation-overflow,
UTF-8/NUL checks, DSL structure, symbol codecs and handle-lifecycle safeguards
remain distinct; their existence must not be concealed under an
all-resources-unlimited claim.

The same operation budget applies across all its phases. Failure returns the
original cause, phase, actual usage, policy identity, complete input inventory
and completion boundary. No phase/session partition resets a whole-operation
budget. Counts remain observable even when not an admission guard. Results and
explanations have independent ownership and explicit incomplete/gap metadata.
Trusted arbitrary Scheme callbacks still require host isolation and a final
process watchdog: cooperative native checks cannot promise to preempt arbitrary
user code. A watchdog alone does not qualify native operation-resource coverage.

Persistent observation identity and native analysis identity must be separate:
an observation can be recorded-only while its comparison is missing or incomplete.
An analysis head advances only after its own complete identity-bound native run.
Recording a new observation must not forge a completed delta or replace a prior
analysis head. Python may manage durable transactions and transport, never derive
deltas, dependencies, decisions or proofs.

## Source Review

| Observation | Exact Current Source | Consequence |
| --- | --- | --- |
| SQLite stores observations without a record-count cap | `src/gambit_smp/reasoning_history.py:50` | History retention is not4096 |
| Previous head plus current snapshot supply the comparison | `src/gambit_smp/reasoning_history.py:52` | Lifetime growth and per-query working set differ |
| Observation/head writes occur after native query | `src/gambit_smp/reasoning_history.py:81` | Failed analysis currently suppresses durable recording |
| New consumer constructor uses unlimited defaults | `evidence/native/history.ss:28` | Finite policy is supplied explicitly through Python |
| Input occurrence and output counts checked together | provider `program/initialization.ss:40` | Merely disabling one guard does not remove the other |
| Evaluator accepts positive integers or native infinity | provider `program/evaluate.ss:124` | A real native contract change, not a larger finite cap |
| Run deadline applies after engine construction | provider `program/evaluate.ss:328` | All-phase resource coverage needs implementation and testing |

## Required Qualification

- Growing durable history with repeated native analysis and exact previous heads.
- Complete datasets exceeding4096 under a newly declared policy, not old receipts.
- Explicit finite-policy boundary failures remain negative controls.
- Native joins/recursion and negation/aggregation/lattice are separate mechanisms.
- Source withdrawal, identity drift and rejected update atomicity remain correct.
- Admission/run/extraction resource failures retain facts and recorded-only history,
  do not advance analysis heads, and leave no live child/owner after teardown.
- Concurrent writers, durable storage failure and corrupted identity fail clearly.
- Python-only consumers contain no Scheme imports/packages/compile workflow.
- All raw failures, original caps and policy identities remain immutable; no
  deletion, folded input identities, Python inference or hidden partition budgets.

The original API045 complete-input count5746 and its4096 rejection remain valid
historical observations. They do not impose a permanent size limit on History.
The final 046-005 production observation now qualifies the new native policy;
the earlier design review and DSL regressions alone did not. Separate persistence/analysis transactions remain an independent
design, not an implemented feature of the fact-count change.
