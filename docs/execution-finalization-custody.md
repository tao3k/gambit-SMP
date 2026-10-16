# Execution Finalization Custody

The retained registry diagnostic completed native execution in 18.836 seconds,
with exit zero and all 4,002 latency samples. Its terminal ASCENT command also
returned zero in 1.661 seconds. The outer runner was killed after 54.806 seconds
during final evidence validation, before writing its aggregate receipt. These
are distinct clocks: 54.806 is the outer total, not additional native time.
The missing aggregate receipt is a transport failure, not proof of a GC hang.
The earlier 118-second native timeout remains unresolved and retained.

The executor now permits bounded evidence finalization after every declared
stage has a bound terminal observation and all observed children are reaped
and quiescent. Failed stages are retained too; finalization does not require
PASS. A performance breach remains recorded and does not grant performance
admission. Callback errors kill and reap the supervised child before raising.
Stage wall times and final validation times are recorded separately so a new
run can attribute overhead rather than infer it from native command duration.

The current 30-second finalization grace is a bounded transport safeguard,
not a general proof that a live workload has stalled. Live execution still
uses its existing deadlines. Replacing those deadlines with genuine-progress
hang detection requires a separate protocol; CPU activity or heartbeat logs
alone must not authorize unlimited execution. This change does not solve or
reclassify the earlier native timeout.

`models/gambit/execution_finalization_custody.qnt` separates completion,
quiescence, receipt custody and performance admission. Its negative controls
exhibit lost evidence from wall-only killing and false performance admission.
It is an abstract protocol model, not a proof of native GC correctness.
The cumulative native milestone remains 3/12; cache cleanup never resets it.

## Measured Public Topology Diagnostic

The sealed `current-source-public-topology-custody` run passed on the current
locked source, GNU GCC and completed bootstrap. The host reported 12 available
CPUs; the fixture derived its 2--5 VM populations and processor cohorts from
that observation. It exercised both official cleanup paths under registry
interrupts without private exports. It is a diagnostic, not full GC/lifetime
or fault-rollback acceptance.

| Measurement | Seconds |
| --- | ---: |
| Reused source validation stage | 16.256 |
| Completed producer validation stage | 14.269 |
| Native compilation | 1.045 |
| Native execution | 1.218 |
| ASCENT verdict command | 1.722 |
| Child final validation | 0.600 |
| Complete child recipe | 41.404 |
| Complete outer run | 43.230 |

All seven stages passed; the aggregate child receipt was retained and the
outer process group was quiescent. Framework regression coverage was 224
passing tests with no failures in the selected changed-module suites.
The source stage's three commands used only 0.056 seconds in total; producer
validation launched no command. Those two stages therefore account for
30.524 seconds of non-native framework validation/work, not GC execution.
This measures the new diagnostic, not a retroactive timing breakdown of the
old 54.806-second run. The exact source-validation internals still need finer
instrumentation before attributing all of that time to a particular hash pass.

The run uses engine
`e971ac71931ca2f81b85cf5a5e4bfee41e433333df569ab99f7098556fac15bb`.
Its child receipt SHA-256 is
`5462c2bddc109330cb6d987658af5f6038df3f32dc655312eaa4d9e65b52517e`.
The sandbox's initial loopback preflight refusal remains preserved beside the
subsequent permitted run. No historical failure or ledger was rewritten.
