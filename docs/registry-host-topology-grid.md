# Host-Derived Threaded VM Topology Grid

## Scope

Two VMs are not two processors. The earlier campaign used two five-processor
VMs on the observed twelve-CPU host, reserving a root and interrupt driver.
Sixteen cycles exercised growth, pinned processor execution, owner-tagged roots
across forced GC, worker joins, shrink to P0 and owned VM cleanup. A bounded run
does not enumerate arbitrary scheduler interleavings or prove full parallel GC.

The successor `registry_topology_grid.scm` consumes the existing framework's
`GAMBIT_SMP_AVAILABLE_CPUS`; there is no twelve-CPU constant. After reserving two
execution positions, it visits every feasible VM count from two through half
the remaining capacity. Quotient/remainder allocation uses the remaining
capacity without exceeding it. Every VM has at least two processors and must
fit the producer's compiled processor limit. Cohort size is thread-local;
membership uses counters rather than a fixed two-element array or bit mask.

Every topology preserves the original assertions and performs at least sixteen
cycles, increasing this minimum to observed CPU capacity on larger hosts. The
original whole 300-second and executable 120-second deadlines remain unchanged.
These are execution-capacity allocations, not a claim of physical core affinity,
continuous full CPU utilization, exhaustive schedules or scaling performance.

## Observed Native Result

The same resize-grace GNU producer, with all three concurrency switches, passed:

| VMs | Processor Allocation | Root + Interrupt Driver |
| --- | --- | --- |
| 2 | 5 + 5 | 2 |
| 3 | 4 + 3 + 3 | 2 |
| 4 | 3 + 3 + 2 + 2 | 2 |
| 5 | 2 + 2 + 2 + 2 + 2 | 2 |

Whole recipe: 56.038 seconds. Native compilation: 2.619 seconds. Execution:
0.823 seconds, exit zero, no timeout, parent reaped and process group quiescent.
Sealed readback: CURRENT/PASS. The fixture emitted the exact success marker only
after all selected topologies completed and each observed global interrupts.
The bound source and deterministic topology selection establish these counts;
the executable does not emit per-topology timing or utilization telemetry.

Identity bindings:

- Program SHA-256: `078e34ef259dbcb66343ce19219a2b16b67f64aa2a55e0e17c25d6e3db36f35d`.
- Recipe SHA-256: `9a57caa5135111a767cca7eaa55ba4880fc537b143eab9be6d32e3957a6155aa`.
- Whole receipt SHA-256: `61f15c2deec2500304437c2f810e20c10d51bb3c40445ccdacd15dfe3af53e21`.
- Candidate identity SHA-256: `5de0edf649f2cf8dc1032389bfc71f23c785c9397bc5488fce3d2680521a743e`.

Reproduce via the existing framework and exact completed producer reference:

```sh
gambit-smp research --run smp-registry-host-topology-grid --engine ENGINE --out FRESH_RUN
gambit-smp research --read FRESH_RUN
```

The versioned recipe retains its source lock, existing QNT controls and immutable
producer handoff. A fresh checkout must reproduce that producer first; local
artifacts are not source authority. There is no new Python native runner.

## Remaining Milestone And Rejected Framework Experiment

This result remains `same-producer-standalone-fixture-only`, with
`runtimeAdmitted=false` and `nativeGcPassed=false`. Complete gsi/gsc inventories,
PR/stress coverage, lifecycle faults, GC/FFI, source refinement and Gerbil gates
remain mandatory. The local two-processor QNT model is not an unbounded proof
over these VM counts.

Separately, full framework validation passed all 910 ordinary tests. Its sealed
94-test native review domain exceeded the unchanged 60-second containing cap;
87 finished observations passed, but these were not a terminal domain admission.
An explicit twelve-owner experiment failed internal request deadlines in
38.914 seconds. That failed observation is retained; automatic maximal owner
concurrency was not enabled in the default review tests. Native VM topology
coverage and framework review-owner concurrency are different measurements.
