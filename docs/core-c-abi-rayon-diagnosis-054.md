# Core C ABI / Rayon Diagnosis 054

## Exact Measurement

Installed wheel SHA256:
`2060ebd88f80529f4a73520af9c37b12f4d8175b0fb7036f44cd9ad641820360`.
Extension SHA256:
`48704c0d3e2ef4b08b1307dd4722afbc36e515fbad742ead7ecff24a7f89defa`.
Raw matched measurement receipt SHA256:
`96cf7bdaddf610b01240523e16c1aeb316cf2157c8967b955224dbdee4907584`.

The 80 observations alternate one/four workers and graph/typed-row formats,
five repetitions per combination. Complete answers and identical DSL/input
digests match. The complete packaged source inventory matches before/after.
The parent exited 0 in 5.008 seconds under the unchanged 90-second cap; SDK and
Scheme executables were denied. These are local workload results, not whole
workflow acceleration or published dependency qualification.

| Workload | Rows | Graph 1 / 4 workers | Typed rows 1 / 4 workers |
| --- | ---: | ---: | ---: |
| Large join output | 4096 | 46.291 / 46.141 ms | 11.832 / 11.860 ms |
| Large join output | 16384 | 189.013 / 192.009 ms | 48.155 / 46.224 ms |
| 1024-bit arithmetic, count output | 4096 | 9.180 / 9.250 ms | 9.043 / 9.074 ms |
| 1024-bit arithmetic, count output | 16384 | 40.050 / 34.738 ms | 40.119 / 34.704 ms |

## Cause And Change

The earlier graph-only measurement separated inference from snapshot, object
graph construction, ABI encoding/decoding and Python projection. For the 16384
row join, inference was approximately 14-15 ms while graph construction,
encoding, decoding and Python projection together exceeded 90 ms. These nested
boundary observations must not be summed blindly with outer totals.

The fix is explicit lossless typed-row transport, not a new inference algorithm.
It removes scalar object-graph inflation; symbol/text types stay distinct and
object values retain complete graph/namespace data for sharing, cycles and opaque
observations. Unknown formats fail rather than fallback. Native fact counting,
source validation, ownership and explanation boundaries remain unchanged.

This improves the large-output workload approximately 3.9-4.2 times. It does not
establish Rayon scaling: four workers improve the large compute workload about
15%, while smaller workloads are flat. Existing kernels schedule rules/delta
tasks, threshold parallel publication and large row decoding. A small task set
and serial admission/index/transport work can limit scaling; worker count alone
does not prove all phases ran in parallel.

## Remaining Acceptance

The fixed Core ABI uses existing Library Core and upstream owned ABI types; it
does not make arbitrary Scheme exports VM-independent or migrate every existing
Python entry automatically. Installed wheel controls, real downstream regressions,
sealed review and the complete current graph remain distinct gates. Historical
policy, linker, sandbox and old-wheel failures are retained, not rewritten.

Further Rayon changes require task-granularity and contention measurements plus
matching complete-answer tests, not speculative removal of budget checks. Full
consumer and publication status must be reported from their own current receipts.

## Complete Consumer Result

The actual full graph run for seal
`c5327b3bb23734d5f231144f75ab9d1538dec08c18542274740dc909512322ef`
terminated with parent exit 2 in 149.192 seconds under the original 300-second
cap, no timeout, process group quiescent. The combined inventory contains 1521
tests, zero skips, two failures and five errors; changedInputs is empty.
The 105-test sealed review domain passed in 15.193 seconds under its original
60-second cap. Overall framework validation remains DENY.

Remaining typed causes: missing component call/inspection interfaces, missing
Engine.dsl owner entry, incomplete source-text lowering, missing actual TLC jar,
and a local wheel installation rather than the declared GitHub dependency.
They must not be solved by aliases, skipped tests, forged publication metadata or
claiming fixed Core ABI controls cover arbitrary module semantics.
