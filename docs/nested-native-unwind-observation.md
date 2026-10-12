# Native Nested Error Delivery And Marker Cleanup

The identified callback-result candidate, with all three SMP/multi-VM flags,
GNU GCC 16 and diagnostic O0 configuration, was used without runtime changes.
The fixture invokes C -> Scheme -> C -> Scheme and optionally migrates the
outer Scheme continuation before entering the inner C-to-Scheme call. The
inner call injects the configured `UNKNOWN_ERR` through the real runtime throw.

| Migration | Error injected | Returned to C | Generated SFUN marker calls |
| --- | --- | --- | --- |
| No | No | 42, no error | 2 made, 2 killed |
| No | Yes | Original nonzero error | 2 made, 0 killed |
| Yes | No | 42, no error | 2 made, 2 killed |
| Yes | Yes | Original nonzero error | 2 made, 0 killed |

All four processes exit 0 with no timeout, empty stderr and quiescent process
groups. `cleanup_checked` returns zero in every case. An uninstrumented fixture
also observes error delivery and cleanup success for the same four controls.
Thus failure to deliver the error is **not** established by this experiment.

`nestedmarker.scm` wraps real creation/invalidation calls in its generated
module with relaxed atomic counters; allocation and execution are not mocked.
These counters observe the generated SFUN call sites, not every call inside
the separately compiled runtime. The counters remain unchanged after cleanup.
Together with the source audit showing tail invalidation and unexpected
`___call` propagation, this establishes bypassed explicit SFUN cleanup. It
does not prove retained heap bytes, stale-marker exploitation, arbitrary
processor retirement safety or correctness of an unimplemented repair.

Available CPU capacity determines shared build jobs and concurrent case
population. The observed host capacity was 12: four concurrent cases used
three processors each, not four independent twelve-processor VMs. Budgets
remain 60 seconds for compilation and 30 seconds per native process. The
uninstrumented compile took 0.650 seconds; instrumented compile took 0.613
seconds. Instrumented observations took 0.729-0.731 seconds. These O0 diagnostic
times are not production performance claims.

Next source decisions must account for normal completion, allocation and
conversion errors, nested marker ownership, nonlocal continuation exit and
worker fatal shutdown. Killing a shared marker twice is not acceptable.
Additional setjmp guards also require measuring hot callback overhead. Full
GC composition, native suites, bootstrap and Gerbil gates remain open.
