# Recursive GC Action Feasibility

## Review Before Execution

Safety preservation and bounded ranking do not rule out a nonterminal state
with no executable action. This is the next obligation on the existing proof
path, not a new native repair route. Native `ENABLED` is already known to be
unsupported by Apalache 0.62.1; repeating that query or the unchanged timed-out
explicit-state campaign would not add evidence. Expected benefit is proof
completion and actionable model counterexamples, not measured runtime speedup.

## Necessary Guard Projection

`guard_projection.py` reads the public parser IR for the unchanged 22 original
branches. Every `oneOf(D)` becomes an existential over that exact domain,
including empty domains and dependent choices. It erases exactly one whole-state
assignment per branch. Local values used only by that RHS may be dropped.
Remaining guard predicates and their local dependencies are unchanged; helper
calls are checked to reject action or recursive dependencies. No successor
filter, hand-written guard or selected branch list is used.

Quint's installed official IR formatter emits the diagnostic module, which is
parsed again. The adapter compares every guard and the whole coverage expression
with the original projection. Parser identities are ignored, expression and
binder structure are not. These checks are a narrow syntactic audit, not a
formally verified compiler transformation.

The necessary coverage query passed in **34.824 seconds** and a terminal-only
negative control produced a counterexample in **25.973 seconds**. Raw log hashes,
all three model snapshots and both public IR files are archived in
`evidence/model-results/gc-necessary-guard-coverage/`. A preceding local-endpoint
permission failure is separately archived in `gc-necessary-guard-localhost-deny/`;
no solver result was produced in that attempt.

This only establishes necessary guard coverage over the candidate generator.
Erasing partial RHS expressions can admit an otherwise undefined action. The
receipt explicitly keeps `enablednessProved`, `rhsDefinednessProved`, temporal,
source, native and release admission false. The terminal-only control is not a
substitute for missing-key, bounds, empty-choice or assignment-conflict controls.

## Conservative Defined Transition

`expression_definedness.py` builds a stronger predicate from the same original
IR. It retains guards and existential domains and checks original local values,
guard expressions and assigned RHS expressions. Map `get` and `set` require key
membership; list `nth` requires a nonnegative index below the list length.
Conditionals validate the selected branch only; collection helpers require
body-definedness for every domain member, a deliberately conservative rule.
Helper substitution renames binders to avoid capturing caller arguments.
Unknown operations, recursion and unsupported dynamic map construction fail
closed. Multiple or non-state assignments are rejected rather than erased.

The rule can be stronger than actual lazy evaluation: unused partial local
values are still required to be defined. Failure therefore is not automatically
an original-action deadlock. Passing this conservative query still needs the
kernel's semantic controls, typed record-frame/assignment review and an explicit
correspondence argument before it can be called an enabledness theorem.

The conservative coverage query passed in **31.226 seconds**; its terminal-only
control produced a counterexample in **22.745 seconds**. The archive is
`evidence/model-results/gc-defined-transition-coverage/`. All 22 original
branches, the exact generated expressions and the Cartesian generator contract
were checked; the generator auditor still reports solver coverage unproved.
This does not retroactively change the earlier guard-only result or its flags.

The independent semantic-control campaign completed in **34.652 seconds**:
one expected `QNT202` conflict rejection, two positive symbolic queries and
five expected predicate counterexamples. It demonstrates why guard-only coverage
is insufficient: the invalid map action's guard-only predicate proves, while
its defined-transition predicate has a counterexample. Empty choices remain
empty; they are not erased. The archive is `gc-definedness-semantic-controls/`.

The first control fixture placed an unused conflicting assignment in the main
module, so whole-module typechecking rejected it before solving; the preserved
attempt is `gc-definedness-controls-module-type-deny/`. The second attempt hit an
Apalache conversion failure for an unconstrained empty-set literal, archived in
`gc-definedness-controls-untyped-empty-deny/`. The final fixture expresses that
same empty integer domain as `Set(0).exclude(Set(0))`, without adding choices,
and isolates the intentionally ill-typed conflict module. No budget was widened
or actual protocol action changed.

Original-action TypeScript evaluation independently completed in **1.236 seconds**.
The valid map action reached State 1; missing-key get/set returned `QNT507`, and
out-of-range list access returned `QNT510`. These four actual evaluations are
archived in `gc-original-evaluation-controls/`, separately from symbolic predicate
counterexamples. They validate the tested primitives, not general kernel
soundness, source SMP behavior or native GC tests.

## Evidence Pipeline Boundary

The subsequent full framework validation ran **390 tests**, with zero failures,
errors or skips, in **13.631 seconds**; its input-drift list was empty at
completion. The following graph export failed while `reasoning_history.record`
asked the native ASCENT engine to open the history delta program:
`ASCENT engine status -1: {"error":"scheme request rejected"}`.
No new graph/context bundle was produced. Do not reuse an older graph as this
campaign's successful export or call the full pipeline green. This note records
the observed run, not current admission; further input edits require fresh
validation. The 14 catalog observations remain partial and non-admitted.

## Remaining Source Gates

See [source and fairness obligations](gc-recursive-progress-source-obligations.md).
The combined M-held notification/recheck protocol is not implemented by the
reviewed C source. The finite once-per-worker spurious-wake budget and the
first-occurrence steal loop are not unbounded source fairness proofs. None of
the action feasibility checks admits a new configured binary, bootstrap or
Gerbil test result.

## Reproduction

```sh
PYTHONPATH=src python3 -m unittest discover -s tests -p test_guard_projection.py
PYTHONPATH=src python3 -m unittest discover -s tests -p test_expression_definedness.py
PYTHONPATH=src python3 -m gambit_smp.guard_projection --out .data/necessary-guards-new
PYTHONPATH=src python3 -m gambit_smp.guard_projection --sufficient --out .data/defined-transitions-new
GAMBIT_SMP_INDUCTION_OUT=.data/definedness-controls-new PYTHONPATH=src \
  python3 -m unittest discover -s tests -p integration_quint_induction.py -k test_definedness_semantic_controls
GAMBIT_SMP_INDUCTION_OUT=.data/original-evaluation-new PYTHONPATH=src \
  python3 -m unittest discover -s tests -p integration_quint_induction.py -k test_definedness_original_evaluation
```

Use fresh output directories, Quint 0.33.0 with its official IR formatter, Node
and Apalache 0.62.1. Each symbolic query retains the 90-second hard budget. Any
unexpected failure stops the remaining campaign. Inputs remain uncommitted until
the strict research-input publication gate has passed; archived files do not
by themselves prove clean-checkout reproducibility.
