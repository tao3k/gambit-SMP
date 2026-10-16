# VM Topology Latency Monitor

## Scope And Method

The existing `gambit.executable-test` framework capability now accepts an optional
typed `latency` contract. `latency_observation.py` validates a bounded regular
JSONL file, the observed CPU capacity, unique owner/round identifiers, exact
planned population coverage, positive monotonic durations and sample-count
floors before producing descriptive nearest-rank percentiles. Missing, duplicate,
out-of-range or censored samples cannot qualify a population. Source/executable
and raw sample hashes are retained in the sealed step receipt. Neither percentile
observation nor a passing fixture admits the complete runtime or release.

`registry_topology_latency.scm` measures each VM's complete repeated cycle:
grow, pinned processor work with forced-GC root checks, joins and shrink to P0.
It is not gxi startup, package build/test, standalone GC latency or a same-input
speedup measurement. The sample ends before telemetry-file locking/writing;
subsequent cycles still experience telemetry contention. Samples share a process,
CPU scheduling and GC environment; they are correlated, not independent trials
or confidence intervals. There are no invented P55/P99 performance limits yet.

Available CPUs determine every feasible VM population, reserving one root and
one interrupt driver slot and at least two processors per VM. Each population
collects at least 1,000 complete cycle samples across owners, with no shortened
correctness assertions. On the observed 12-CPU host this means:

| Concurrent VMs | Processor Allocation | Rounds Per VM | Planned Samples |
| --- | --- | --- | --- |
| 2 | 5 + 5 | 500 | 1,000 |
| 3 | 4 + 3 + 3 | 334 | 1,002 |
| 4 | 3 + 3 + 2 + 2 | 250 | 1,000 |
| 5 | 2 + 2 + 2 + 2 + 2 | 200 | 1,000 |

The native file is flushed after every completed cycle. A timeout therefore
retains completed raw trajectories plus the original process timeout/exit
receipt; the unfinished tail is not silently removed from percentile admission.
This is monitoring, not a synthetic progress heartbeat. Whole/step budgets
remain 300/120 seconds.

## Current Candidate Result

`smp-global-cleanup-topology-latency` on the explicitly selected global-cleanup
producer was DENY: compilation 2.467 seconds, native execution timed out after
116.642 seconds; whole framework time 191.276 seconds. The parent was reaped
and process group quiescent. The 2-VM population retained 624 of 1,000 planned
samples: owner 1 completed rounds 0-361, owner 2 completed rounds 0-261. Populations
3-5 were not reached. All full-population P55/P99 results are therefore unknown,
not zero or extrapolated from the surviving fast samples.

The raw file hash is
`337e0c2dca36eb84d2d2afae74918d4662d38e1e6bd2b655d64e6734f889d961`;
its sealed run is
`.data/fixtures/vm-global-cleanup-preflight/topology-latency-run`.
No candidate source repair or performance admission follows from this failure.
The qualified resize-grace producer is selected as a same-input control in
`bazel-profile-topology-latency-control.recipe.json`; its result must be recorded
before classifying this as successor-only regression or inherited instability.
There is no matched Linux comparison or claimed speedup.

The same-input qualified resize-grace control also was DENY, within the original
budget: whole 208.007 seconds, native compilation 2.508 seconds, execution timeout
116.766 seconds. It retained 361/1,000 planned 2-VM samples (owner 1: rounds 0-41;
owner 2: rounds 0-318); populations 3-5 were not reached. Its immutable run is
`.data/fixtures/vm-registry-reader-lease/topology-latency-control-run`.
Both parents were reaped and process groups quiescent. This contradicts a claim
that only the new pending-join/precommit code can stall this campaign. It does
not prove the two stalls share one root cause or establish a speed comparison
under uncontrolled scheduling. Neither run admits full-population P55/P99.

| Producer | 2-VM Completed/Planned | 3-5 VM Samples | Full-Population P55/P99 |
| --- | --- | --- | --- |
| Explicit global-cleanup successor | 624/1,000 | Not reached | Unknown; DENY |
| Qualified resize-grace control | 361/1,000 | Not reached | Unknown; DENY |

The next source/model audit must address repeated grow/GC/shrink/join protocol
interaction, retaining both stall observations. The earlier bounded topology
pass is not evidence of long-run stability; surviving completed cycle timings
must not be relabeled as the distribution of all planned cycles.

## Model And Correctness Boundaries

`latency_population_admission.qnt` checks the admission protocol, not the GC
implementation or quantile arithmetic. A survivor-only publication control
violates the invariant; the complete policy requires every planned trajectory,
stable binding and no failed run. Four complete/partial/timeout/drift trajectories
and bounded safety/negative verification passed through the existing QNT/ASCENT
framework in 35.868 seconds. Unit tests separately check percentile arithmetic,
identity boundaries, incomplete/duplicate data and native-capability integration.

The same successor's complete interpreted regression was DENY, with 378/379
files passing and `prim_port.scm` failing a behavior comparison. Its diagnostic
helper refers to unbound `##failed-check` instead of the available
`##failed-test`; this hides the compared values but does not make the underlying
comparison pass. The ASCENT verdict also timed out. Both failures are retained.
Root failure recovery, repeated topology stability, full compiled inventory,
GC/FFI and Gerbil/performance acceptance remain open. The acceptance count is
still 2/12 for the qualified baseline, not for this failing successor.
