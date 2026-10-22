# Target Root Adapter: Source and Primary Evidence

Reviewed: 2026-10-20. Static source correspondence and primary literature only.
No native/compiler/model/solver/engine execution, regenerated-C parity claim or
performance result. The [design](target-root-adapter-design.md) derives proposed
contracts; the [inventory](target-root-caller-inventory.json) preserves exact
query scope, matching text and source hashes. Selected ranges and file hashes
are also bound by the [trace map](target-root-adapter-traceability.json).

## Source Ledger

| ID | Source evidence | Observed fact / permitted inference |
| --- | --- | --- |
| TR-S01 | [Header/layout](../../../vendor/gambit/include/gambit.h.in#L11309), [PSTATE membership](../../../vendor/gambit/lib/mem.c#L306), [RC lifecycle](../../../vendor/gambit/lib/mem.c#L673), [data access](../../../vendor/gambit/lib/mem.c#L783), [mark_rc](../../../vendor/gambit/lib/mem.c#L3969), [mark_array](../../../vendor/gambit/lib/mem.c#L3490). Ranges gambit.h.in 11309--11315/11409--11416 and mem.c 300--310/673--829/3969--3989/3490--3652. | Header lists/refcounts/data writes and unconditional cleanup are coupled to existing storage. mark_rc caches next and marks the actual data cell; mark_array rewrites relocated cells and uses collector allocation state. New carrier routing and one discovery/writer law are required. |
| TR-S02 | [Chunk publication](../../../vendor/gambit/lib/mem.c#L3256), [worker setup](../../../vendor/gambit/lib/mem.c#L3425), [work/termination](../../../vendor/gambit/lib/mem.c#L6669). Ranges 3225--3314, 3425--3463, 6669--6771. | Queue publication has ordered barriers, locking and signalling. Active/idle worker accounting must cover root seed production as well as derived work. New independent workers cannot be inferred from an address-list adapter. |
| TR-S03 | [Strong roots](../../../vendor/gambit/lib/mem.c#L6813), [later phases](../../../vendor/gambit/lib/mem.c#L6880), [full entry](../../../vendor/gambit/lib/mem.c#L6938). Ranges 6813--6936, 6938--7086. | Vendor strong phase scans RC inside processor-0 branch then other processor roots before reachability work; weak/will/continuation/cleanup/heap phases remain distinct. Strong idle is not terminal epoch. |
| TR-S04 | [_kernel allocation](../../../vendor/gambit/lib/_kernel.scm#L44), [stack](../../../vendor/gambit/lib/_kernel.scm#L255), [sync interrupt](../../../vendor/gambit/lib/_kernel.scm#L1420), [rest/GC](../../../vendor/gambit/lib/_kernel.scm#L1950), [explicit GC](../../../vendor/gambit/lib/_kernel.scm#L2032), [resize](../../../vendor/gambit/lib/_kernel.scm#L2353). Ranges 44--74, 255--290, 1420--1450, 1950--2005, 2029--2075, 2350--2365, 3140--3160. | Actual allocation, GC/retry/will and resize wrappers preserve particular saved state and results. Saved _kernel.c direct-symbol lines are retained in the inventory (5917/6271/10968/12383/16752/16944/16993); no regenerated equivalence is claimed. |
| TR-S05 | [Weak-table allocation](../../../vendor/gambit/lib/_system.scm#L1374), [bignum allocation](../../../vendor/gambit/lib/_num.scm#L7910), generated [_system.c](../../../vendor/gambit/lib/_system.c#L10995) and [_num.c](../../../vendor/gambit/lib/_num.c#L82824). Ranges 1374--1428, 7910--7962, 10985--11010, 82814--82839. | Both small allocation paths directly call garbage_collect with W_ALL/R_ALL; large allocation paths call alloc_scmobj. These were omitted from the preceding selected caller slice and are now explicit closure obligations. |
| TR-S06 | [Still allocation](../../../vendor/gambit/lib/mem.c#L1637), [private declaration](../../../vendor/gambit/lib/mem.h#L111). Ranges 1637--1666, 105--118. | Native still allocation can enter public GC. Private pstate body is declared as a C function; a search of known Scheme sites cannot rule out other callers. |
| TR-S07 | [Operation tags](../../../vendor/gambit/lib/setup.c#L479), [resize body](../../../vendor/gambit/lib/setup.c#L870), [dispatch](../../../vendor/gambit/lib/setup.c#L1012), [public entries](../../../vendor/gambit/lib/setup.c#L1155). Ranges 479--491, 870--914, 1012--1201. | Resize can call gc_pstate directly. Sync dispatch invokes both bodies. Public GC returns overflow as Boolean; resize returns Scheme result. GC operation has additive combining. New Deferred/Rejected outcomes cannot silently become old false-success. |
| TR-S08 | [Shutdown](../../../vendor/gambit/lib/setup.c#L4831), [VM teardown](../../../vendor/gambit/lib/mem.c#L4928), [pstate cleanup](../../../vendor/gambit/lib/mem.c#L4736). Ranges 4831--4885, 4928--4971, 4736--4750. | Shutdown shrinks VM before processor/VM cleanup; scan synchronization is destroyed in cleanup. New target carriers and issued transactions need explicit heap/facility lifetimes across these paths. |
| TR-S09 | [PSTATE macro alternatives](../../../vendor/gambit/include/gambit.h.in#L8731). Range 8731--8757. | PSTATE can be obtained implicitly or passed under different macro profiles. CollectorWorkContext extraction requires configuration-aware treatment; no arbitrary Zig-thread mark_array API exists here. |
| TR-S10 | [Thread resize branch](../../../vendor/gambit/lib/_thread.scm#L3146), [other branch](../../../vendor/gambit/lib/_thread.scm#L6880), [universal stub](../../../vendor/gambit/lib/_univlib.scm#L834). Ranges 3146--3165, 6880--6898, 829--838. | Managed resize calls and nonnative stub have different roles. The two textual branches are not assumed simultaneously active for Darwin. Generated _thread.c matches here are symbol metadata. |
| TR-S11 | [Processor error participation](../../../vendor/gambit/lib/setup.c#L740), [shared operations](../../../vendor/gambit/lib/setup.c#L1204), [barrier macro](../../../vendor/gambit/lib/setup.h#L63). Ranges 740--838, 1204--1271, 58--67; combining mechanics 542--626. | Error forwarding, processor setup and GC/resize share sync loops; fdset/actlog also use rendezvous. Blocking all participation behind a new request seal would alter progress. Empty single-thread barrier is not a root ticket. |
| TR-S12 | [Late binding](../../../vendor/gambit/include/gambit.h.in#L8557), [slots](../../../vendor/gambit/include/gambit.h.in#L13309), [imports](../../../vendor/gambit/include/gambit.h.in#L14785), [slot setup](../../../vendor/gambit/lib/setup.c#L5963). Ranges 8557--8604, 13309--13319, 14785--14800, 5960--5970. | ___EXT can dispatch via GSTATE pointers; direct and indirect ABI routes need one runtime authority. Externally generated/loaded modules remain an open cohort obligation, not an extra matched call count. |
| TR-S13 | [Weak-table tests](../../../vendor/gambit/lib/srfi/124/test/test.scm#L89), [GC example](../../../vendor/gambit/examples/Xlib-simple/bounce.scm#L320), [memory test](../../../vendor/gambit/tests/mem.scm#L40), [mixed test](../../../vendor/gambit/tests/mix.scm#L649). Ranges 80--125, 315--323, 34--43, 644--652. | Real managed clients call ##gc. Source inspection only; none was run. Generated gsi/gsc/link symbol tables in the inventory establish names, not another private collector route. |
| TR-S14 | [Candidate donor transfer](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3160), [worker correction](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3385). Ranges 3160--3234, 3385--3452, 4360--4385, 4482--4505. | Existing modern C work provides constrained donor list transfer, queue rechecks/perprocessor RC scan and joined-donor callers. Credit this support; it does not already publish an independent target manifest/receipt or prove complete root/worker closure. No native result is adopted. |

## Primary Literature and Language Boundary

| ID | Primary reference | Narrow evidence / inference boundary |
| --- | --- | --- |
| TR-P01 | [WG14 C draft N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf), §§5.1.2.4, 7.17.3. | Release/acquire on the same atomic with the required reads-from relation provides synchronization and orders prior writes. This supports the proposed completion edge; it does not prove list consistency, physical custody, cross-language ABI or source exclusion. The draft is a memory-model reference, not evidence of the current Gambit build's C language mode. |
| TR-P02 | [LLVM statepoints](https://www.llvm.org/docs/Statepoints.html#overview-core-concepts). | Relocation requires correct managed pointer handling and resumed values. Compiler metadata must be admitted into a runtime root scheme; it does not repair hidden C copies or issue a root-transfer receipt. |
| TR-P03 | [Retrofitting Parallelism onto OCaml](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), §§4.4.1--4.4.3 and 5.1. | The paper separates stop-the-world coordination, promotion and root-work sharing; equal roots need not mean equal reachable graph work. Terminated-domain structures can require adoption. These are design comparisons, not a Gambit collector algorithm or performance prediction. |
| TR-P04 | [LLVM GC support](https://www.llvm.org/docs/GarbageCollection.html#goals-and-non-goals). | LLVM supplies compiler support; the runtime still owns collector and registration/lifecycle integration. Reusing maps/lowering across C and Zig is shared modernization value. |
| TR-P05 | [Zig lifetime/ownership](https://ziglang.org/documentation/0.15.1/#Lifetime-and-Ownership) and [errdefer](https://ziglang.org/documentation/0.15.1/#errdefer). | Explicit ownership and lexical error cleanup help local builders. They do not establish shared carrier lifetime, commit cancellation, release/acquire ABI or shutdown progress. Exact language/tool identity remains an upgrade dependency. |

## Evidence Boundary and Open Questions

The lexical inventory deliberately retains noncalls and generated counterparts.
The native query has 58 matched lines in 11 files; the three groups together bind
23 files. Each matched path/line/text is recorded. Its completeness is over the
specified source/file/symbol domain, not all dynamic clients or all allocation
routes. Generated-C matches were inspected as retained artifacts; no compiler
was invoked to establish Scheme/C parity or active Darwin preprocessor branches.

The previous root-transfer study remains valid as a conditional cut, but its
selected kernel/still/resize references were not an exhaustive caller closure.
TR-S05 and TR-S12 make two specific missing families visible. Source inventory
and internal guards complement each other: the former exposes obligations; the
latter must make future entry bypass impossible in the admitted runtime.

Pending proofs include exact participant/combined-request refinement, all ABI
imports, private-body enforcement, data/ref/free routing, target cell manifest
completeness, independent worker context extraction, strong/later phase drain,
all-exit commit disposition and C/Zig ordering. No full requirement or theory
net-benefit gate is closed by this evidence ledger.
