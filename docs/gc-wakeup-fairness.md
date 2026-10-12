# GC Wakeup Fairness Audit

## Route Review

This closes a previously analytical source/model fairness gap, not a native
failure attribution or performance claim. Candidate source permits repeated
condition returns; the original recursive model consumes one wake allowance
per worker. Its bounded progress ranking must not be exported to unbounded
source wakeups. The expected benefit is preventing false progress admission
and identifying required scheduling assumptions before choosing a C repair.

## Construction And Scope

`gc_wakeup_fairness.qnt` imports the original recursive model and starts with
its unchanged `initSource` or `initCombined`. Next explores copying and the
original helper probe/recheck/count/wait/resume actions. It does not explore
whole-GC publication, recursive discovery or phase completion. The milestone
is the first copied word of either initial root, not complete GC termination.

The bounded control uses the original `spuriousWake`. The explicit unbounded
variant permits arbitrary repeated wakes and does not update `spuriousUsed`.
All 21 other branches of the complete action disjunction are imported unchanged.
Fairness predicates refer to the complete original/variant action disjunction,
not just the focused Next relation. Public IR checks bind this branch structure;
they are not a proof of C wake semantics or general semantic equivalence.

The supplementary public-IR audit in
`evidence/model-results/gc-wakeup-subrelation-ir/` expands the focused helper
disjunction and checks its ten primitive actions are a subset of the complete
22-action variant. The bounded control has exactly the same focused branches
with only the wake action replaced. Missing, duplicate, aliased, recursive or
extra focused branches are rejected. No state or original initializer is
shadowed. This checks structural subrelation inclusion: a negative focused
cycle evaluated against full-action fairness remains a full-relation behavior.
It does not transfer positive results to full Next, which was not explored by
these six checks. The original campaign receipts are preserved unchanged.

## Actual TLC Results

The final-liveness checker exhausts each focused graph, with no state constraint
or dropped temporal property. Six concurrent checks derive capacity from the
host and share it among checker workers. Each keeps a 30-second watchdog.

| Initial Policy | Wake Policy / Fairness | Distinct States | Seconds | Result |
| --- | --- | ---: | ---: | --- |
| Source | Bounded / aggregate | 3,825 | 12.837 | Conditional first-copy property passes |
| Source | Unbounded / aggregate | 1,053 | 12.548 | Temporal loop counterexample |
| Source | Unbounded / aggregate plus copy fairness | 1,053 | 9.893 | Conditional first-copy property passes |
| Combined | Bounded / aggregate | 13,005 | 13.579 | Conditional first-copy property passes |
| Combined | Unbounded / aggregate | 3,483 | 12.970 | Temporal loop counterexample |
| Combined | Unbounded / aggregate plus copy fairness | 3,483 | 10.197 | Conditional first-copy property passes |

The complete six-check campaign took 13.997 seconds; individual durations are
concurrent, not additive wall time. All queues drained in checker exploration;
`focusSafe` passed in both temporal counterexamples. Logs, compiled TLA+/CFG,
model snapshots and decoded loops are archived in
`evidence/model-results/gc-wakeup-fairness/`.

The source-policy loop begins at original Init. Worker 3 probes all four empty
queues, takes the termination mutex, decrements count 4 to 3, registers a wait,
wakes, restores count and returns to the initial state. Root copied-word counts
remain zero. The combined-policy counterexample also performs queue rechecks.
Thus the combined notification/recheck policy does not itself guarantee
per-copier scheduling. This is a legal model schedule, not an observed OS trace.

## What Must Not Be Claimed

Adding `weakFair(copyWord, Set(s))` is a stated scheduling assumption, not a
Gambit source fix. The positive control proves only the focused first-copy
milestone under that assumption. Neither the original bounded rank nor these
controls proves unbounded whole-GC progress, mutex fairness, eventual condition
return, C memory ordering, GC phase composition or native bootstrap acceptance.
The two negative controls remain negative; passing the audit means their
expected failures were actually observed.

The first attempt failed before checking because the framework callback needed
a deadline argument. That harness failure is not a protocol counterexample.
The next diagnostic campaign used focused-action fairness; the final campaign
above strengthens the audit to the full action-disjunction predicate.

Next source work must preserve the combined Q-release/M-signal/M-held-recheck
design while separating (1) lost-notification safety, (2) finite retry progress,
and (3) environmental scheduler/lock/wake assumptions. Actual repeated-return
schedule controls and the same-candidate GNU GC/multi-VM/bootstrap/Gerbil chain
remain required. No runtime or release admission is established here.
