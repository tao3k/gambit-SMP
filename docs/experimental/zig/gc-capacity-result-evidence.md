# GC Capacity Results: Source and Primary Evidence

Reviewed: 2026-10-20. Static source/literature correspondence only. No
implementation, Scheme/native compilation, model/engine execution, native test,
checked proof or performance result. See the
[design](gc-capacity-result-design.md),
[matched matrix](gc-capacity-result-cost-matrix.md) and
[trace map](gc-capacity-result-traceability.json).

## Source Ledger

| ID | Bound source / ranges | Observed behavior / inference boundary |
| --- | --- | --- |
| GC-S01 | [Collector local result](../../../vendor/gambit/lib/mem.c#L6938), [policy assignment](../../../vendor/gambit/lib/mem.c#L7035), [post-policy preparation](../../../vendor/gambit/lib/mem.c#L7041). mem.c 6938--7086. | Local overflow starts zero and only P0 assigns resize_heap; each participant returns local state after fudge/accounting/resume preparation. Source does not establish common result delivery. No configured/native failure is reproduced. |
| GC-S02 | [Heap policy and actual section adjustment](../../../vendor/gambit/lib/mem.c#L6301). mem.c 6301--6508. | Policy includes requested still demand as live, permits reserve reduction and recoverable overflow, checks actual section growth and may reach fatal exhaustion. Success retains demand charge. A policy return is not storage allocation, full request completion or safe rollback. |
| GC-S03 | [Still allocation](../../../vendor/gambit/lib/mem.c#L1554), [API initialization obligation](../../../vendor/gambit/lib/mem.c#L1484), [deferred accounting](../../../vendor/gambit/lib/mem.c#L6794), [actual still recount](../../../vendor/gambit/lib/mem.c#L4387). mem.c 1484--1500/1554--1705/6794--6807/4387--4428. | Demand is STILL_BODY + rounded payload words; small allocation can defer charge; larger paths precharge or call GC. Native storage may fail afterward and refund words. Caller must initialize body before another allocation. Recount of actual objects and outstanding future promises must be distinguished in a queued design. |
| GC-S04 | [Operation priorities](../../../vendor/gambit/lib/setup.c#L479), [combining](../../../vendor/gambit/lib/setup.c#L542), [consumption](../../../vendor/gambit/lib/setup.c#L1049), [public wrappers](../../../vendor/gambit/lib/setup.c#L1155). setup.c 479--491/542--705/1012--1115/1155--1201. | GC is additive, resize noncombined; winner/combining conditions consume matching requests. Loop locals do not provide durable exact batch membership, grant identity or terminal shared outcome. |
| GC-S05 | [Resize guard/child](../../../vendor/gambit/lib/setup.c#L870), [membership/setup/join/create](../../../vendor/gambit/lib/setup.c#L918), [startup sync](../../../vendor/gambit/lib/setup.c#L805), [barrier macro](../../../vendor/gambit/lib/setup.h#L63). setup.c 805--838/870--1009; setup.h 63--67. | Child-GC result determines a branch before topology publication. Actor setup, exits, joins and fatal thread creation have distinct effects requiring stage-specific disposition. Candidate post-count join-error handling is recorded separately in GC-S06. Barrier participation alone supplies neither result copying nor action settlement. |
| GC-S06 | [Candidate operation kinds](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L4227), [guard and partial-failure work](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L4385), [resize result](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L4525). Patch 4227--4238/4385--4505/4515--4552. | Existing C adds MAX guard, target hint rollback, corrected cleanup, join custody and leader resize-result broadcast; its join-error path follows the count commit. The shown GC case still assigns gc_pstate's local return. These are separate proof obligations, not evidence of independent-worker closure or adopted native acceptance. |
| GC-S07 | [Resume preparation](../../../vendor/gambit/lib/mem.c#L4525), [continuation move](../../../vendor/gambit/lib/mem.c#L6223), [Scheme GC save/reload](../../../vendor/gambit/lib/_kernel.scm#L2032). mem.c 4525--4571/6223--6259; _kernel.scm 2029--2075. | Percontext stack/heap bounds, relocated frame state and interrupts are installed before use. Public capacity outcome must be tied to valid current resume/error-delivery facts. Nonlocal/foreign control still requires qualified containment. |
| GC-S08 | [Memory constants](../../../vendor/gambit/lib/mem.h#L12), [occupancy charge](../../../vendor/gambit/lib/mem.c#L360), [heap/free macros](../../../vendor/gambit/lib/mem.c#L488), [VM counters](../../../vendor/gambit/include/gambit.h.in#L11478). mem.h 12--79; mem.c 360--370/488--509; gambit.h.in 11478--11540. | M=131072 source words; F depends on frame/subtyped layout; source minimum is two sections per processor. Physical sections, active halves, doubled movable charge, still/deferred quota and reserve have different units/roles. No installed native footprint is inferred. |
| GC-S09 | [Section allocation/sharing](../../../vendor/gambit/lib/mem.c#L3066), [heap sharing/chunk markers](../../../vendor/gambit/lib/mem.c#L3314), [initial assignment](../../../vendor/gambit/lib/mem.c#L3410), [context setup](../../../vendor/gambit/lib/mem.c#L4625), [occupancy reduction](../../../vendor/gambit/lib/mem.c#L6259). mem.c 3066--3175/3314--3464/4625--4719/6259--6300. | Stack/heap can share one section with adjusted ranges/fudge. Current initial assignment and reductions use processor identities. Worker copies, context resume storage and persistent live extents need distinct identities while physical sections are counted once. |
| GC-S10 | [Partial section growth/shrink](../../../vendor/gambit/lib/mem.c#L891), [initial budget](../../../vendor/gambit/lib/mem.c#L4785), [next allocation demand](../../../vendor/gambit/lib/mem.c#L7458). mem.c 891--1058/4785--4862/7458--7510. | adjust_msections can fail expansion partially and reports actual nb_sections. It can free tail sections on contraction. Initial/next-allocation paths demonstrate why occupied storage, allocation rights, headroom and real borrower exclusions all matter. |
| GC-S11 | [Candidate headroom formula](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L2087), [initial budget use](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3037). Patch 2087--2097/3037--3048. | Existing C reserves ceil(normal_reserve/M)+1 extra sections over its context floor. Conditional source algebra gives nominal one-section headroom after reserve if those unused sections actually exist. It is not a general U/W placement or native memory bound. |

Selected source hashes bind seven files: mem.c/mem.h, setup.c/setup.h,
_kernel.scm, gambit.h.in and the candidate patch. This selected ledger is not an
inferred full build-input closure. No compiler preprocessing/regeneration or
external-client reachability proof is claimed.

## Primary References

| ID | Primary source | Narrow support / limit |
| --- | --- | --- |
| GC-P01 | [WG14 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf), §5.1.2.4. | Qualified synchronization establishes visibility between producer writes and consumer reads. This supports the proposed decision/report/outcome chain, not implicit broadcast of a local variable or assumed cross-language atomic layout. |
| GC-P02 | [Herlihy and Wing, Linearizability: A Correctness Condition for Concurrent Objects](https://cs.brown.edu/people/mph/HerlihyW90/p463-herlihy.pdf), §2. | Makes operation histories, pending invocations and observable completion explicit. Motivates separate selection/effect/result cuts and idempotent authority. It does not prove the proposed multi-record runtime or exactly-once allocation/credit implementation. |
| GC-P03 | [Marlow et al., Parallel Generational-Copying Garbage Collection with a Block-Structured Heap](https://simonmar.github.io/bib/papers/parallel-gc.pdf), §§2.1--2.3 and 3.5. | Separates allocation regions, tospace, perworker work and termination. Supports tracking physical blocks and live work distinctly from mutator count. No GHC heap layout, algorithm correctness or speed result transfers to Gambit. |
| GC-P04 | [Retrofitting Parallelism onto OCaml](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), §4.4. | Coordinated stop-the-world entry, copying races and root work are distinct concerns. This motivates explicit stage/worker responsibilities, not a proof of Gambit resize semantics or a migration to OCaml's collector. |
| GC-P05 | [LLVM GC goals/non-goals](https://www.llvm.org/docs/GarbageCollection.html#goals-and-non-goals) and [statepoints](https://www.llvm.org/docs/Statepoints.html#overview-core-concepts). | Compiler maps/relocation support can feed a shared Gambit runtime contract. They do not grant storage quota, coordinate resize or publish native runtime outcomes. Benefit is shared across modern C and Zig. |
| GC-P06 | [Zig lifetime/ownership](https://ziglang.org/documentation/0.15.1/#Lifetime-and-Ownership) and [errdefer](https://ziglang.org/documentation/0.15.1/#errdefer). | Local typed construction and error cleanup may reduce private support. Cross-thread grant custody, actual allocation disposition, GC roots and publication/lifetime protocols remain programmer/runtime obligations. |

## Evidence and Qualification Boundary

The previous study already recorded a preexisting independent research-view
change without adoption. This study starts from a fresh hash baseline matching
the preceding design record's current observation bindings. It does not evaluate,
modify or adopt registered engine/model/native results. Historical records and
unrelated staged/dirty work remain untouched.

GCU01 and candidate observations are selected source facts. Branch divergence,
double-grant, stale epoch, false capacity and tail-sharing examples are logical
countermodels under named violations, not executed failures. Full configured
source/ABI/all-caller closure, native ordering, precise placement, all-exit
allocation/initialization/refund and finite progress remain unresolved.
