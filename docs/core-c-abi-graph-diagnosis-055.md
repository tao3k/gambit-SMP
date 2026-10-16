# Graph Naming And Rayon Diagnosis 055

## Direct Namespace Migration

Current Library lowering is `rust/ascent/src/source/graphs.rs`, `mod graphs`,
and `super::graphs`. Generated identifiers use `__ascent_graph_*`. Diagnostics
and the consumer's source inventory assertion also name Graph. There is no
`plans` module, forwarding alias or retained old symbol prefix in current Rust
execution sources. Historical wheel/source receipts are not rewritten.

The final wheel is 055-003, SHA256
`a63b2a4660baf3ffcc5ce1f822ca24d6158297d68cd6dc2bdfa993df1583a568`;
installed extension SHA256 is
`939a0201615bc4be8e7c9c19d34cd706c7a6b76c476e31ddbe047a683b372597`.
Its actual build exited 0 in 17.805/120 seconds. Current Core tests passed
2 unit/policy plus 68 integration cases; installed SDK-denied controls passed
8 cases. These are separate from complete consumer validation.

## Rejected Parallel Guard Experiment

The existing scheduler distributes rule/pivot tasks and 256-row join batches.
Publication requires more than one nonempty relation and at least 512 pending
rows before parallel dispatch. Large result decoding starts at 8192 rows.
Initial source/index preparation and lower-stratum completion barriers remain
serial boundaries. Guard evaluation was serial.

An experimental parallel guard used the existing predicate algorithm and
shared exact Budget, without relaxed accounting or changed answers. Three
alternating installed baseline/candidate pairs, with full input/DSL/answer
digests and before/after complete source inventories, rejected it:

| Pair | Baseline 4-worker compute | Experimental 4-worker compute |
| --- | ---: | ---: |
| 0 | 31.365 ms | 41.260 ms |
| 1 | 32.975 ms | 41.571 ms |
| 2 | 32.184 ms | 43.086 ms |

Workload: 16384 1024-bit integer inputs, count output, explicit typed-row format.
The complete paired batch exited 0 in 25.670/90 seconds and matched all answers.
The change was withdrawn, not accepted as an optimization. The final 055-003
pairing exited 0 in 24.728/90 seconds; corresponding medians are baseline
33.874/32.793/33.076 ms and final candidate 33.644/34.609/34.222 ms. No stable
overall acceleration is established. The earlier approximately fourfold large
output conversion result remains a different, explicitly scoped observation.

Independent sampling of the rejected candidate used a 3-second/1-ms sample,
separate from speed measurements. It observed allocation/free, owned ABI encode
and decode, Python big-integer conversion, value comparison and Budget::work.
Budget::work appeared in 39 collapsed top-of-stack samples. This is not a causal
percentage or proof that budget contention dominates. Worker condition-variable
wait samples include normal parked workers and must not be reported as deadlock
or mutex contention. Source audit confirms shared atomic exact-work accounting
and per-relation pending locks; neither was removed to obtain a faster result.
The initial sampling attempt missed the child PID and produced no stack evidence.

## Formal Tool Repair

The formal test no longer defaults to an upstream checkout cache. It accepts
`QUINT_TLC_JAR` or the consumer's explicit local fixed-version tool cache.
The standalone TLC 1.7.2 attempt was retained: it could not find Apalache.tla.
The restored [official Apalache 0.62.1 distribution](https://github.com/apalache-mc/apalache/releases/tag/v0.62.1)
has archive SHA256
`93fef2f381d30465eff906a2d6afa3358cb2c9adf6a8aad3bec0ded4f45432bb`;
extracted jar SHA256 is
`880c0b2b72354816f12e9a9755829f2907071e9a181ffea1937954c23d54739d`.
Actual positive safety/liveness and five decoded negative controls passed in
24.431/60 seconds. These finite-model results are not source/runtime correctness.

## Complete Current Boundary

Final seal:
`71e8d31c3a8acdc2d8d04345e71ae8e27a169fa0670d1563647001085862ae35`.
Full graph 055-003 terminated with parent exit 2 in 165.381/300 seconds, no
timeout. Complete inventory: 1521 tests, zero skips, one failure and five errors,
changedInputs empty. Sealed review's 105 tests passed in 15.553/60 seconds.
The actual read observed CURRENT with frameworkValidation DENY.

Remaining errors are unsupported component export/call semantics, missing
Engine.dsl entry and full match/for lowering. These require actual VM-independent
algorithm exports, not restoring Scheme VM-backed adapters, generic closure
producers, a second interpreter or fake result projection. The remaining failure
is local-wheel installation versus the declared published Git revision; direct
URL metadata and historical SHA values were not forged. Early tests can error
before later assertions run, so zero skips is not complete semantic coverage.

Local raw receipts, full stdout/stderr, stack sample and complete test inventory
are retained under evidence/library/core-c-abi-055. This is not Git publication,
full consumer PASS or performance closure.
