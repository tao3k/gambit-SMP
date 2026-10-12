# SFUN Exception Configurations And Diagnostic Cost

## Actual Header Controls

The exact candidate generated header was compiled with GNU GCC and GNU G++,
using O2 and Wclobbered. Three wrapper families each exercise normal return,
mocked allocation failure, nonlocal body error and an error-handler call that
throws again. Both exception configurations pass all twelve controls without
warnings, timeout or live process groups. Allocation failure makes/kills zero
markers. Other paths make/kill one. The setjmp unit also checks that the outer
catcher is restored after every case.

These are actual macros with mocked allocation, marker invalidation and Scheme
call functions. They are not real OOM, complete parameter conversion ownership,
Linux or full C++ runtime qualification. The previously archived real-runtime
22 controls and optimized 14 controls retain their separate evidence boundary.

`sfun_catcher_error_families.qnt` imports the existing cleanup transition model
and expands initialization to all four outcomes for all three families. This
is transition reuse, not a copy of the model or C++ source-refinement theorem.

## Matched Cost Is Not Admitted

Parent and candidate runtimes use the same source revision and cumulative
patches except the six SFUN header macro lines. Both are diagnostic O0 runtimes;
the wrapper/harness code is O2. The harness validates every return and marker
count, times only the repeated calls and reports process elapsed time separately.
Both sides use the same atomic instrumentation. This is not a Gerbil build/test
benchmark or an uninstrumented production latency claim.

Two ABBA blocks run each of the three kinds in CPU-capacity-bounded parallel
processes. A short pilot uses 100,000 calls per case. The longer observation
uses 3,200,000 calls per case, within the unchanged thirty-second process budget.
All 48 observations complete their exact useful-work and marker inventories.

| Long ABBA Block | VOID Candidate/Parent | SCMOBJ Candidate/Parent | Converted Integer Candidate/Parent |
| --- | --- | --- | --- |
| First | +7.60% | +10.65% | +1.89% |
| Second | -24.47% | -29.96% | -11.94% |

The direction and magnitude disagree across blocks. The short pilot has
multiple increases near 10-13%, but lasts only about 13-20 milliseconds per
case. Neither observation proves an unchanged hot-call cost. Preserve both;
the performance decision is **INCONCLUSIVE**, not PASS or a speedup claim.
No native performance threshold is relaxed and the candidate is not promoted.

Further work should isolate the macro delta in a shared-runtime comparison,
then evaluate actual production/Gerbil performance. Correct cleanup alone does
not close the simultaneous high-performance/reliability/stability requirement.
