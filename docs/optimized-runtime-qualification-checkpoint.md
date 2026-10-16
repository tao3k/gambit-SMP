# Optimized Runtime Qualification Checkpoint

## Decision Before Execution

The complete compiled Grid hit its original 300-second containing deadline.
Three started groups lack observed results, so no failing subphase is asserted.
The previous producer uses O0 C and RTS settings for correctness investigation.
Qualification of compiler optimization is necessary before release admission;
it is not evidence of a GC source fix or unique timeout cause.

This candidate changes only the explicit C and RTS configure levels to O1.
The source lock, QNT controls, native Scheme causal review, seed and full
two-pass bootstrap, all three concurrency switches, machine-derived jobserver
allocation and original 600-second envelope are unchanged. A contract test
compares every recipe step and input against the original bootstrap. No known
timed-out complete Grid was replayed unchanged. Expected end-to-end benefit was
unknown before execution; this is a bounded qualification, not a speed claim.

## Actual Results

| Stage | Observation | Boundary |
| --- | --- | --- |
| Seed core | 19.476 seconds, exit zero, no timeout | Pre-generated sources, not complete bootstrap |
| From scratch | 126.837 seconds, exit zero, no timeout | Both phase1-4 passes observed |
| Whole bootstrap | 227.385 seconds under 600-second cap | Sealed CURRENT/PASS, not release admission |
| Same-producer host topology recipe | 59.339 seconds under 300-second cap | Sealed CURRENT/PASS, not full Grid |
| Topology fixture compilation | 2.479 seconds | Exact existing fixture |
| Topology fixture execution | 1.372 seconds | All feasible 2-5 VM topologies on the 12-CPU capacity |

The earlier O0 bootstrap's whole observation was 263.366 seconds, and its
topology execution was 0.823 seconds. These are not matched repeated runs.
The new bootstrap observation is lower while topology execution is higher;
neither establishes a general speedup or regression. No performance baseline
or acceptance threshold is changed.

Bootstrap recipe: `vm-registry-resize-grace-optimized-bootstrap`.
Topology recipe: `smp-registry-optimized-host-topology-grid`.
Engine: `7388bde3ca43bc36ffbc0599a3ea16b7db2594d2fe6fa3d0bc5170f3a8da688d`.
Bootstrap identity:
`c8ee76e1d373ebfb7c1a7934a95746fc7a5d4f26829f8a5e15c70610a08eb263`.
The verified immutable producer reference is
`evidence/research/vm-registry-reader-lease/optimized-completed-producer.json`.
It does not substitute for the O0 producer in existing complete Grid receipts.

## Remaining Causal Gate

The existing compiler-options/configuration review explicitly requires a lower
dynamic-module C optimization level than the original failed O1 command/image.
This candidate also changes that dynamic level to O1. It cannot inherit the
O0 retry correspondence merely because its bootstrap and topology test pass.
Keep the existing policy and its negative controls; do not silently waive this
gate or promote the candidate into the complete Grid.

Source makefiles distinguish runtime object compilation from generated dynamic
module compilation. A future candidate can investigate these separate costs,
but must bind the actual configured driver, compiler image, build commands,
source identity and complete native inventory. The current observations alone
do not authorize that candidate or prove a full parallel GC/SMP result.
