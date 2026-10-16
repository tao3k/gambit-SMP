# Current Source Saved-Stack Native Result

## Path Review

The current continuation segment patch already has checked finite conservation,
publication-readiness and wake-budget models. Its prepared deep-stack regression
had only been parsed. Actual current-producer execution is therefore new work,
not a retry of an unchanged failed workload. The expected benefit is closing a
native correctness gap; no numerical runtime speedup was predicted.

The existing source workspace and two-pass producer were reused. No Gambit
source changed, no private cleanup export or loader interposition was used,
and no source tree was copied. All three concurrency flags remained enabled.

## Bound Workload

`evidence/research/current-source-full-bootstrap/saved-stack-geometry.json`
binds the candidate `lib/mem.h` hash to `___MSECTION_SIZE = 131072` and declares
the same numeric recursion depth. The corresponding candidate hash is present
in the 22-file source lock, distinct from the upstream base hash. Geometry is
source-derived; it is not a hardcoded processor count or a physical rollover
witness.

The framework passes declared positive numeric fixture parameters without
allowing replacement of host capacity, root, PATH, GAMBOPT or loader controls.
Each executable stage gets a private environment so parameters cannot leak
into later stages. The recipe and geometry are immutable run inputs.

The unchanged public Scheme workload derives its processor population from
available capacity, pins every worker, retains a non-tail recursive stack,
parks all workers across two coordinator-triggered collections, verifies each
retained frame's owner/depth, joins every worker and shrinks the VM to one
processor. This host reported 12 available CPUs.

## Observed Result

The four-stage sealed run `current-source-public-saved-stack` passed:

| Measurement | Seconds |
| --- | ---: |
| Reused source validation | 16.628 |
| Completed producer validation | 14.912 |
| GNU-backed native compilation | 2.993 |
| Native executable | 0.733 |
| ASCENT verdict command | 1.749 |
| Child final validation | 0.674 |
| Complete child recipe | 38.877 |
| Complete outer run | 40.700 |

Native stdout was exactly `CONTINUATION-SAVED-STACK-PUBLIC:PASS` followed by a
newline. Exit was zero, no timeout occurred and the process group was quiescent.
The original 300-second whole and 120-second native-step limits were unchanged.
The stack sampler threshold was not reached. Selected framework regressions
passed 136 tests; this is not a full framework or full runtime suite claim.

Engine identity:
`5ee4ba243d153665cdd617ee707ad7526d68b911e188b04a519eb293646a1405`.
Child receipt SHA-256:
`9e6773c03b9fbbfd3a666193ee2e07d87c1d9ef058b9bce81a7a6ac2adff7476`.
Fixture SHA-256:
`45d872155c605dc76ed9560f8b40b225478b60daa183f9c87d08d040f60bbfb3`.

## Interpreted Successor

The same unchanged fixture subsequently passed through `gambit.suite` in GSI
mode, including the canonical known-failure inventory and actual ASCENT retry
review. The exact selected inventory was one diagnostic file; no known failure
was removed from the inventory. Host capacity remained 12, the runner/probe
initial population was automatically 11, and the fixture explicitly resized
its own cohort to the available capacity. One selected file requires one
nonempty shard; that is not a fixed worker ceiling.

| Measurement | Seconds |
| --- | ---: |
| Actual ASCENT retry review | 2.323 |
| GSI suite process, one file | 0.311 |
| Complete child recipe | 36.846 |
| Complete outer run | 38.811 |

The runner reported `PASSED ALL 1 UNIT TESTS`; all four recipe stages passed,
no timeout occurred, and the outer process group was quiescent. Engine identity:
`1c5286f4c486502d1cb6462665efd604ae66e4a35c71db1345625102c3af511b`.
Child receipt SHA-256:
`9d0835e1c41af48d298d9eb133b69042e655dfd9de56b7fb85c74efa2a8f5856`.

The native wrapper's suite process timing includes the upstream runner and
its GSI child, not only the workload body; it should not be compared directly
to the standalone compiled body's duration as a language speedup.

## Remaining Requirements

Both compiled GSC-backed and interpreted GSI fixture execution have now been
observed. This is not complete GSC inventory, an instrumented frame-rollover witness, GC phase/root
composition, lifecycle fault rollback or full GC/FFI qualification. The finite
models still have explicit source-refinement premises. The earlier registry
latency timeout and interpreted stress timeout remain failed evidence.

The full milestone remains 3/12 with nine open gates. The new diagnostic adds
current-source coverage to the continuation requirement; it does not redefine
that requirement or promote the complete GC/FFI gate to PASS.

The actual sealed review validation subsequently passed 43/43 inference and
resource-plan tests, with zero skips, in 15.408 seconds under its 60-second
domain budget. Twelve observed CPUs and two declared processes per worker
selected six workers automatically. The earlier ordinary-checkout invocation
was rejected by execution-origin checks; setting an engine environment variable
alone was insufficient. That rejection was not waived: the successful run used
the existing `validation_domains.run_domain` isolated sealed-code entrypoint.
