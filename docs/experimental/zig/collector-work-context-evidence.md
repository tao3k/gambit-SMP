# Collector Context: Source and Primary Evidence

Reviewed: 2026-10-20. Static source/paper research, not implementation or native
qualification. No Scheme/native compiler, model/solver/engine or native test ran.
Read the [design](collector-work-context-design.md),
[34-field correspondence](collector-work-context-fields.json),
[cost matrix](collector-work-context-cost-matrix.md) and
[trace map](collector-work-context-traceability.json).

## Source Ledger

| ID | Bound source / ranges | Observation and inference boundary |
| --- | --- | --- |
| CW-S01 | [Tags](../../../vendor/gambit/lib/setup.c#L479), [tree selection](../../../vendor/gambit/lib/setup.c#L542), [operation loop](../../../vendor/gambit/lib/setup.c#L1049), [sync record](../../../vendor/gambit/include/gambit.h.in#L11599). setup.c 479--730/1012--1151; gambit.h.in 11597--11606. | Priorities and opcode combining, tree-selected winner, matching-request consumption, repeated rounds and NOOP participation are explicit. Resize is noncombined; GC sums arg0. No durable RequestId/role map is already supplied. |
| CW-S02 | [PSTATE mem members](../../../vendor/gambit/include/gambit.h.in#L11340), [VM fields](../../../vendor/gambit/include/gambit.h.in#L11478), [access macros](../../../vendor/gambit/lib/mem.c#L278), [section allocation](../../../vendor/gambit/lib/mem.c#L3066), [stack/heap setup](../../../vendor/gambit/lib/mem.c#L3410). gambit.h.in 11340--11449/11478--11565; mem.c 278--386/3066--3240/3314--3465/4615--4635. | All 34 selected struct members are classified. Perprocessor allocation, section sharing, copy queues and accounting are mixed. Setup uses processor_count for initial sections/counters and processor 0's tospace offset on new context setup. Moving the struct wholesale cannot separate ownership. |
| CW-S03 | [Chunk publication](../../../vendor/gambit/lib/mem.c#L3256), [forwarding](../../../vendor/gambit/lib/mem.c#L3490), [scan local/queue](../../../vendor/gambit/lib/mem.c#L4250). mem.c 3256--3313/3490--3670/4250--4384. | Copying has alignment, CAS, tospace allocation and chunk publication dependencies. Partial local chunks can contain unscanned work outside the ready queue. SINGLE_THREADED_VMS removes key synchronization. A new T protocol must intercept actual publication/claim paths. |
| CW-S04 | [Captured continuation](../../../vendor/gambit/lib/mem.c#L3672), [stack root traversal](../../../vendor/gambit/lib/mem.c#L3898), [RC scan](../../../vendor/gambit/lib/mem.c#L3969), [globals](../../../vendor/gambit/lib/mem.c#L6590), [strong root order](../../../vendor/gambit/lib/mem.c#L6813). mem.c 3672--3989/6570--6668/6813--6870. | Frame root traversal/capture rewrites stack links and copies frames under existing exclusion. Global partition and leader-only VM/symkey/RC root roles are tied to processors in vendor code. Independent worker assignments must cover physical root domains without duplicating mutable frame writers. |
| CW-S05 | [Termination](../../../vendor/gambit/lib/mem.c#L6669), [initial count](../../../vendor/gambit/lib/mem.c#L3454). mem.c 6669--6771/3454--3463. | Worker count and victim enumeration use processor_count; local work, steal, active decrement, condvar wait/reactivation are connected. All fields are not automatically C11 atomics. Queue empty alone does not prove no future publication. |
| CW-S06 | [Context resume](../../../vendor/gambit/lib/mem.c#L4525), [continuation movement](../../../vendor/gambit/lib/mem.c#L6223), [saved GVM state](../../../vendor/gambit/include/gambit.h.in#L11610), [Scheme save/reload](../../../vendor/gambit/lib/_kernel.scm#L2032). mem.c 4525--4610/6223--6259; gambit.h.in 11610--11665; _kernel.scm 2029--2075. | Resume installs percontext fp/hp/limits and interrupts; continuation move uses owner stack allocation. Root maps and saved registers must remain associated with the mutator, while tracing allocation belongs to the worker. |
| CW-S07 | [Still setup](../../../vendor/gambit/lib/mem.c#L4210), [sweep/release](../../../vendor/gambit/lib/mem.c#L4387), [wills](../../../vendor/gambit/lib/mem.c#L5032), [table cleanup](../../../vendor/gambit/lib/mem.c#L5364), [occupancy](../../../vendor/gambit/lib/mem.c#L6259). mem.c 4210--4249/4387--4465/5032--5115/5364--5408/6259--6350/683--829. | Persistent still/RC/will custody, phase work and accounting differ. Still reset changes links/marks; sweep can call foreign release. Occupancy sums processors and minimum section budget depends on target_processor_count. New worker arenas and retained shards need new reductions/capacity accounting. |
| CW-S08 | [Startup](../../../vendor/gambit/lib/setup.c#L805), [resize](../../../vendor/gambit/lib/setup.c#L870), [public wrappers](../../../vendor/gambit/lib/setup.c#L1155). setup.c 740--1009/1155--1201/4831--4885. | New processor enters NOOP sync before thunk; resize may collect before topology update, then create/join/exit actors. Shutdown resize is another participant path. Source does not encode a separate independent W roster. |
| CW-S09 | [PSTATE macro alternatives](../../../vendor/gambit/include/gambit.h.in#L8731), [single-thread locks](../../../vendor/gambit/lib/mem.c#L373), [single-thread CAS alternative](../../../vendor/gambit/lib/mem.c#L3560). gambit.h.in 8731--8757; mem.c 373--386/3555--3608. | Implicit versus explicit PSTATE and single-thread build branches are actual dependencies. Mutator cardinality alone cannot qualify a multiworker collector. |
| CW-S10 | [GC full entry/result](../../../vendor/gambit/lib/mem.c#L6938), [heap policy](../../../vendor/gambit/lib/mem.c#L6301), [adjust hook](../../../vendor/gambit/lib/mem.c#L4500). mem.c 6938--7086/6301--6360/4500--4524; setup.c 1024--1031/897--914. | overflow is local, initialized zero; only processor 0 assigns resize_heap result before each local return. Dispatch uses that local result and resize tests it. This source slice has no common GC result publication. It establishes a design gap to resolve, not a reproduced target failure. Custom allocation/heap hooks also require effect review. |
| CW-S11 | [Candidate queue/root fence](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3385), [resize guard/result](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L4385), [startup participation](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L4549). Patch 3385--3465/4385--4425/4515--4650. | Candidate modern C adds protected queue recheck, perprocessor RC scan, a root-phase fence, collective resize guard/result and startup/join accounting. Credit these mechanisms; the shown GC dispatch still assigns gc_pstate's local result. No whole-candidate transitive proof or native outcome is adopted. |

The [field inventory](collector-work-context-fields.json) records source line,
exact declaration, proposed domain and design row for each of the 34 members.
It does not infer field offsets, active macro branches or complete users. Four
source files plus the selected candidate patch are bound by the trace ledger.
The prior caller inventory remains a source-reference alarm; this study does
not regenerate it or claim new dynamic call tracing.

## Primary Literature

| ID | Primary source | Narrow support and limits |
| --- | --- | --- |
| CW-P01 | [Marlow, Harris, James and Peyton Jones, Parallel Generational-Copying Garbage Collection with a Block-Structured Heap](https://simonmar.github.io/bib/papers/parallel-gc.pdf), §§3.1--3.5. | Discusses copying races, local allocation/work and global termination when workers might still export work despite an empty shared pending set. This motivates explicit worker activity/production accounting. The proposed T protocol is our conditional design, not a copied verified algorithm. No GHC measurements transfer to Gambit. |
| CW-P02 | [Dijkstra and Scholten, Termination detection for diffusing computations](https://www.cs.utexas.edu/~EWD/transcriptions/EWD06xx/EWD684.html). | Tracks outstanding signalling obligations in a finite computation with bounded production. Supports distinguishing local idleness from global quiescence and safety from eventual completion. We do not claim to implement their cornet algorithm or obtain its theorem by naming counters. |
| CW-P03 | [Retrofitting Parallelism onto OCaml](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), §§4.4.1--4.4.3 and 5.1. | Separates coordinated stop-the-world entry, parallel promotion and root distribution; equal root counts need not balance reachable work. Terminating domains require runtime lifecycle treatment. This is a modernization comparison, not a Gambit root/GC proof or a claim of equivalent collector designs. |
| CW-P04 | [LLVM statepoints](https://www.llvm.org/docs/Statepoints.html#overview-core-concepts) and [GC goals/non-goals](https://www.llvm.org/docs/GarbageCollection.html#goals-and-non-goals). | Admitted compiler relocation/root metadata is useful behind a common runtime contract. LLVM does not provide this collector, root registry, worker membership or runtime result/facility lifecycle. |
| CW-P05 | [WG14 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf), §5.1.2.4. | Qualified synchronization can order queue payload, claims and resumed reads. Volatile field names and unrelated atomic counters do not alone supply the required cross-thread visibility or global predicate. This is a language-model reference, not qualification of the configured C/Zig ABI. |
| CW-P06 | [Zig ownership](https://ziglang.org/documentation/0.15.1/#Lifetime-and-Ownership) and [errdefer](https://ziglang.org/documentation/0.15.1/#errdefer). | Local explicit ownership/error cleanup can aid builders; the programmer still owns pointer lifetime. Cross-thread producer permits, moving roots, phase closure and accepted-work recovery remain runtime support in either language. |

## Provenance and Non-adoption

The preceding design-artifact record binds the old research view digest. At this
study's start, `evidence/scenarios/zig-native/research.view.json` already had a
different working-file digest. This concurrent change is preserved and recorded
as preexisting input drift; it is neither evaluated nor adopted as evidence for
this study. Engine declarations, views and independent native outputs are not
modified here. Historical design records remain immutable. Selected source
hashes, current checkout identity and this study's baseline are recorded
separately from those unrelated results.

All five full-runtime/provider/retirement/total-cost/Zig-increment questions
remain unresolved. Literature analogies and the explicit representation invariant
are conditional argument premises, not new registered witnesses or theory-gate
acceptance.
