# Recursive GC Ranking Obligations

## Pre-Code Review

The path follows the existing queue/discovery safety model, not a new native
repair route. Initial inclusion and all 22 original transition branches have
passed the archived candidate safety checks. Full explicit-state composition
previously exhausted its unchanged 90-second budget; rerunning that exploration
without changing the proof strategy would add no evidence.

This ranking path has not previously been checked. It is worth checking because
safety does not prove completion, and the original `progress` requirement also
needs enabledness and a source/fairness refinement. Expected benefit is a smaller
symbolic proof decomposition, not measured runtime acceleration. No GNU GCC,
Darwin or native speedup claim follows from this model work.

## Measure

The proof layer imports the exact protocol and safety candidate; it does not
guard, weaken or replace an original action. Three ghost variables record the
pre-transition primary component, all worker components and whether a real
transition has happened. Their exact assignments are checked against the
manifest, including capture of the actual pre-state. Replacing a captured
measure with zero or leaving `advanced=false` is rejected; neither can be used
to obtain a vacuous ranking pass.

The primary component counts object discovery, copied words, publication,
eager/tail completion, used spurious-wake budgets and termination publication.
Completed unexported/retired regions normalize publication progress to five.
Its proposed bound is 201. The shifted worker-phase sum is in [0,132], so a
weight of 256 makes a primary increment dominate every secondary decrease.
The resulting proposed measure bound is [0,51588]. These are finite-model
arithmetic constants, not machine thread counts or native watchdog settings.

Worker phases depend on the first currently nonempty queue in the original
probe order [2,0,3,1]. A probe beyond a newly nonempty already-visited queue is
ordered before recheck/retry; a probe still approaching a nonempty queue is
ordered after retry and before claim. `found=true` recheck without remaining
queued work gets separate phase credit. This handles retry/reset transitions
without assuming that each worker mode follows one fixed linear sequence.

The initial generator imposes the current candidate invariant. Safety
preservation is revalidated from the exact archived 22-branch receipt, model
hashes and original checker-log attestations; it is not recomputed for every
rank query. The separate target checks the measure bound and a
strict measure increase for each transition whose successor is nonterminal.
Terminal successors may bypass strict increase; they still satisfy safety and
the measure bound. `finished` remains the original terminal stutter. Proving all
such checks would rule out an infinite sequence of nonterminal model steps,
but does not rule out deadlock, establish native scheduling fairness or prove
the original 1000-probe loop refinement.

## Failures And Scope

The native Quint `enabled(step)` expression typechecks but Apalache 0.62.1
rejects it as an unsupported `ENABLED` expression in a zero-step symbolic query.
See `evidence/model-results/quint-symbolic-enabledness-unsupported/`. This is a
backend limitation, not a protocol counterexample; TLC support is a separate
boundary. Do not repeat this symbolic query unchanged on the large model.

The first rank campaign failed before solving because its combined query step
did not assign the new proof-only history variables. The full `rankAll`
disjunction now updates that history for every original branch. The failure is
preserved in `gc-ranking-history-assignment-deny/`, not counted as a rank
counterexample. Bounds, original actions and per-query budgets were unchanged.

The first completed rank-bound query passed in 19.388 seconds, but the
`countOrRetry` and `finishProbe` one-step queries both reached their unchanged
90-second budgets. They are inconclusive, not counterexamples or passes; the
remaining branches were not run. The archive is `gc-ranking-fold-budget-deny/`.
The revised candidate uses explicit sums over the same four finite model roles
and separates rank obligations from the already-recorded safety obligations.
It does not shrink state domains, omit original branches, relax budgets or
discard the safety dependency.

The scalar revised query still reached the hard budget for both branches; its
archive is `gc-ranking-scalar-budget-deny/`. Logs localize the unresolved solver
work to the combined before/after sum inequality after the bounds had passed.
The following candidate instead checks a compositional lexicographic rule:
either the primary strictly increases, or it stays equal and every worker
component is nondecreasing with at least one strict increase. With both
secondary sums in [0,132], this stronger rule implies strict growth of the
original weight-256 integer measure. No original action or deadline is changed.

The four highest-risk administrative checks then passed (20.913, 21.497,
21.942 and 20.031 seconds). Their archive is
`gc-ranking-administrative-components/`. This filtered result covers only
`countOrRetry`, `finishProbe`, `probeRecheckQueue` and `resume`; the other 18
original branches and component-bound implication require the full matrix.
`rank_composition.qnt` separately checks the arithmetic composition rule and an
insufficient-weight negative control; a passing fragment alone cannot admit GC.

The complete compositional matrix then passed 24 obligations: candidate-domain
rank bound (18.598 seconds), every original transition (18.178-22.636 seconds)
and component bounds (17.282 seconds). Aggregate checker work was 504.431
seconds, not elapsed wall time: transition queries ran in host-auto pairs.
The archive `gc-ranking-all-components/` contains exact model snapshots, public
IR, raw-log attestations and the revalidated safety dependency. This is recorded
as a separate ranking observation, not as temporal/native `model_checked`.

The independent arithmetic composition query passed in 5.201 seconds; reducing
the weight to one produced the required counterexample in 4.635 seconds. The
archive is `quint-rank-composition/`. Together with candidate-domain component
bounds and the original-branch matrix, this supplies the finite ranking
argument; it does not establish enabledness or justify a new native runtime.
The catalog records the matrix and arithmetic control separately and retains
all runtime/release/temporal admission flags as false.

Metric-value fixtures check only arithmetic examples, including queue order and
retry/reset credit. They are not transition preservation, reachability, native
or temporal proofs. All campaign admission flags remain false until the entire
proof/source/native chain is actually established.

## Reproduction

### Actual Initial-State Bridge

`gc_rank_actual_initial.qnt` uses both original `initial(policy, "none")`
starts, not the arbitrary candidate-state generator. A length-zero Apalache
check of candidate inclusion, component bounds and initial rank passed in
19.402 seconds. The deliberately impossible predecessor-history control
produced a counterexample in 17.717 seconds. The positive initializer and all
three protocol dependencies are byte-bound to the archived positive query;
adding the control did not change them.

The first wrapper omitted direct imports and failed with `QNT404` in 0.656
seconds. This was a parse denial, not a protocol counterexample. All three
attempts, source snapshots and logs are under
`evidence/model-results/gc-rank-initial-bridge/`. No transition matrix was
rerun, no timeout increased, and every runtime/release/temporal admission flag
remains false. The bridge closes actual-start rank inclusion only; generator
coverage, action semantics and source fairness remain separate obligations.

The new negative-control launch initially encountered a sandbox loopback bind
denial before the checker started. The authorized local-endpoint retry above
produced the actual solver result; the endpoint denial is not a model failure.

See [the design decision](gc-design-decision.md) for the minimal protocol repair
and the unselected generation/ownership redesign hypothesis.

```sh
quint test --backend typescript tests/fixtures/gc_rank_values.qnt
PYTHONPATH=src python3 -m gambit_smp.induction_matrix \
  --manifest evidence/gc-ranking-matrix.json --out .data/ranking-new
```

Use a fresh output directory. The framework binds all three model snapshots,
source/paper context, public IR, checker version and proof adapter. Host CPU and
memory select concurrency. Each obligation keeps the 90-second hard limit;
any failed batch stops subsequent branches. A filtered `--step` campaign remains
partial, even if each selected query passes.
