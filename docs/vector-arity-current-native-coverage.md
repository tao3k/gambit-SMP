# Current Vector Arity Native Coverage

## Scope-Preserving PR Interpreted Campaign

`smp-vector-arity-full-scope-pr-interpreted-campaign` passed 380/380 files
in 66.338993 seconds under the original 300-second whole budget. This includes
the full original 379-file inventory, all seven explicitly declared PR/GSI
regressions, and the unchanged table-iteration GC diagnostic. Inspection returns
PASS/CURRENT, not runtime or source-refinement admission.

Outer receipt SHA-256:
`e34e2462d96a7d3937ea69be9404685757734f14518fd2dca764d14465a4e1d7`.
Child receipt SHA-256:
`49c1db3fe757ace93e06995a14c946d1f2603b5bbe4674b9fb65f433f04dbe5d`.
Engine: `ec5dee3c6e673f2f3a14f802b90a2541ad477f03cdfb154d59a5cbbc643c9e81`.

This closes the declared PR/GSI coverage gate. It does not claim that every
upstream PR protocol, fault injection or compiled regression is qualified.
Earlier narrowed-scope review denials remain retained and are not bypassed.

## Independent Threaded VMs On The Current Producer

`smp-vector-arity-independent-threaded-vm-entry` passed in 42.812101 seconds
whole, 2.384081 seconds executable compilation and 1.071613 seconds execution.
Inspection returns PASS/CURRENT. The original QNT trajectories, positive and
negative controls, 300-second whole budget and 120-second native step remain
unchanged. The recipe changes only the source and completed-producer bindings.

Observed host capacity was 12 CPUs. The fixture derives two five-processor
cohorts from `(available CPUs - 1) / 2`; the framework derives 11 compile
processors. These are observations, not configured constants. The fixture
exercises simultaneous TLS/kernel entry, private roots, forced GC, join/drain
and cleanup. It does not discharge sustained registry lifetime or faults.

Outer receipt SHA-256:
`5a52fc5e6ab90920102677d48ffb6da1095660ada455d8ba2ee95aedad30062f`.
Child receipt SHA-256:
`0e02e3eb70716560f560dbd6040afe530d7216bdfbdc888b30c1981ca44caa33`.
Engine: `68d3a8c39180d8784f6050e719d4cc338fe698b8af8f86bae2343f275e71a05f`.

The producer transfer reports 2243 copy-on-write files, zero byte copies and
197826295 logical bytes. No bootstrap was repeated. Sandbox loopback denial
and an incorrect prior-directory invocation are retained as prelaunch failures;
the admitted run uses the correct prior run directory without changing budgets.

## CPU-Derived Complete Topology Observations

Two current-producer campaigns retain the original 300-second whole and
120-second native step caps and the unchanged registry topology program.
Neither repeats bootstrap. On the observed 12-CPU host, reserving two positions
and requiring at least two processors per owner derives populations 2 through
5; this range is not hardcoded in the runtime. Both campaigns recorded all
4002 owner/cycle samples, including private roots, forced GC, resize, joins,
owned cleanup and concurrent global interrupts.

| Campaign | Whole seconds | Native seconds | Result |
| --- | ---: | ---: | --- |
| `smp-vector-arity-complete-topology-latency` | 52.186211 | 17.541100 | PASS/CURRENT |
| `smp-vector-arity-complete-topology-reviewed-population` | 87.001892 | 20.459751 | PASS/CURRENT |

The second adds QNT population-completeness, processor-retirement and resize
grace controls and requires exact CPU-derived population coverage in the sample
projection. Additional model checks contribute to whole campaign expenditure;
the whole times are not native execution times.

| VMs | Samples per campaign | First P55/P99 ms | Second P55/P99 ms |
| --- | ---: | --- | --- |
| 2 | 1000 | 17.091 / 83.367 | 16.768 / 108.891 |
| 3 | 1002 | 7.301 / 72.777 | 7.399 / 91.602 |
| 4 | 1000 | 4.727 / 19.929 | 7.445 / 83.821 |
| 5 | 1000 | 4.140 / 22.394 | 4.847 / 17.431 |

Tail variation is retained, not called a stable performance improvement. These
bounded programs do not establish every registry ownership/fault path or
unbounded liveness. The registry lifetime gate is not promoted on this evidence
alone.

First outer receipt SHA-256:
`72a96ac0885f870ad893318ddb9d33f6bec541868b9ac403377a83cea60f8187`.
Second outer receipt SHA-256:
`ebb800acae622bb53423c580759fdd7b58b7e23c36c3a3aad7b64107093d197b`.
Second engine:
`11a1a5f4bec9810beb1261ba11ccd7e812fcd241d4d435b167490b6a1632ad45`.

## Pending Join Fault Recovery

The current producer passed the unchanged corrected errno recovery fixture and
all 32 required model/native/ASCENT steps in 89.477214 seconds, without a new
bootstrap. Compilation took 3.067532 seconds and native execution 0.851818
seconds under the original 300/120-second budgets. Inspection is PASS/CURRENT;
this does not close the entire lifecycle fault gate. See
[protocol, retained failures and remaining requirements](current-producer-join-fault-recovery.md).

## Remaining Gates

The combined owner/root sticky-retention successor passed all 46 steps in
117.474838 seconds, with actual terminal group witnesses. Owner execution was
0.591922 seconds and root execution 0.505505 seconds. This closes the bounded
root sticky-error observation previously missing from lifecycle fault evidence,
not the complete fault campaign. See
[root failures, model refinement and current receipt](root-cleanup-sticky-retention.md).

Current acceptance is 3/12 coverage gates, not an engineering-effort estimate.
Complete GSC, PR/GSC, stress/GSI, stress/GSC, registry lifetime, lifecycle faults,
GC/FFI, Gerbil correctness and release performance remain open. Conditional
QNT checks do not prove full source refinement, memory ordering or API reentry.
