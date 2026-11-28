# Allocation Bounds and Scheme-to-Zig: Evidence Ledger

Reviewed: 2026-10-20. Static selected-source/primary-literature research only.
Read the [bound/metadata design](allocation-check-bound-design.md),
[backend position](scheme-to-zig-architecture.md),
[report matrix](allocation-check-bound-cost-matrix.md),
[conditional cases](allocation-check-bound-cases.json) and
[trace map](allocation-check-bound-traceability.json).
No implementation, native test, compiler/model/engine/solver/prover execution,
checked proof, configured-profile qualification or measured gain is adopted.

## Source Ledger

| ID | Source anchors / selected spans | Observation and limit |
| --- | --- | --- |
| AB-S01 | [Target interface](../../../vendor/gambit/gsc/_back.scm#L197), [selection](../../../vendor/gambit/gsc/_back.scm#L388), [GVM frames](../../../vendor/gambit/gsc/_gvm.scm#L78). _back.scm 197--235/388--432; _gvm.scm 78--105. | Target dump/primitive/frame/register/jump interfaces and GVM live/closed/slot/register state establish a real backend seam. They do not implement a Zig backend or complete late C-target semantics. |
| AB-S02 | [Frontend target dump](../../../vendor/gambit/gsc/_front.scm#L415), [C target setup](../../../vendor/gambit/gsc/_t-c-1.scm#L228), [C dumper](../../../vendor/gambit/gsc/_t-c-1.scm#L337). _front.scm 415--451; _t-c-1.scm 228--270/337--382. | Frontend passes procedures/output/c-intf/module data to selected target.dump. C dumper consumes C declarations/procedures/inits/objects and scans procedures before final product. New Zig emission must replace these responsibilities, not rename C output. |
| AB-S03 | [Reserve/check](../../../vendor/gambit/gsc/_t-c-2.scm#L344), [frame update](../../../vendor/gambit/gsc/_t-c-2.scm#L424), [end-block checks](../../../vendor/gambit/gsc/_t-c-2.scm#L1120). _t-c-2.scm 344--448/1120--1142. | Current operation enters debt before check; frame update may box live values before predicate; check resets counters. End-block checks depend on actual debt and preserve zero-valued check requests. Counter reset is not deletion of pending emitted work or a native capacity receipt. |
| AB-S04 | [Portable sizes](../../../vendor/gambit/gsc/_t-c-1.scm#L108), [primitive allocation](../../../vendor/gambit/gsc/_t-c-2.scm#L2607), [vector/small emitter](../../../vendor/gambit/gsc/_t-c-2.scm#L2728). _t-c-1.scm 108--200; _t-c-2.scm 2607--2635/2728--2873. | Portable header allowance and minimum-word arithmetic yield planned pair/flonum costs of four words. Vector reserves/checks before operand materialization/BEGIN/ADD/END/GET. Specialized small alloc reserves conservatively; no universal maximum literal/closure batch follows from small-array threshold. |
| AB-S05 | [Operand boxing](../../../vendor/gambit/gsc/_t-c-2.scm#L2367), [float storage/cache](../../../vendor/gambit/gsc/_t-c-2.scm#L2450), [F64 representation](../../../vendor/gambit/include/gambit.h.in#L3260). _t-c-2.scm 2367--2384/2450--2487/2524--2575; gambit.h.in 3260--3371. | Dirty operand access can materialize a boxed value; write-if-dirty marks the entry clean after emitting F64BOX and adding debt. NAN immediate, self-tagged conditional and allocated branches differ. Actual events/versions and effect order matter more than cache capacity or equal floating payloads. |
| AB-S06 | [Body/handle offsets](../../../vendor/gambit/include/gambit.h.in#L3102), [cursor/alignment/allocation](../../../vendor/gambit/include/gambit.h.in#L3133), [pair macros](../../../vendor/gambit/include/gambit.h.in#L5316), [heap predicate](../../../vendor/gambit/include/gambit.h.in#L8542). gambit.h.in 3102--3168/5316--5326/5365--5384/8542--8565. | Ordinary no-handles pair uses three actual words. Cursor advance, alignment and body stores are separate events. CHECK_HEAP tests strict hp>limit; inspected m is unused. Conditional object sizes are not installed target facts. |
| AB-S07 | [Dynamic allocation macro](../../../vendor/gambit/lib/_kernel.scm#L44), [vector fill caller](../../../vendor/gambit/lib/_kernel.scm#L2419). _kernel.scm 44--115/2419--2451. | Small branch requires calculated words<=255; extra 32-bit alignment allowance bounds its advance. Large branch uses still allocator and may collect before returning uninitialized body. Vector saves/restores fill then initializes it. This supports a selected single-object extent bound, not a whole-caller no-GC certificate. |
| AB-S08 | [Weak-table producer](../../../vendor/gambit/lib/_system.scm#L1366), [bignum producer](../../../vendor/gambit/lib/_num.scm#L7893). _system.scm 1366--1441; _num.scm 7893--8047. | Small branch tentatively advances hp before predicate, then either rolls it back on the fast edge or reaches slow servicing before body initialization. False predicate and post-resume body have different bounds/assurances. Temporary pointer validity cannot be inferred from absence of a body write. |
| AB-S09 | [Heap slow helper](../../../vendor/gambit/lib/mem.c#L7428), [limits](../../../vendor/gambit/lib/mem.c#L4525), [Scheme check](../../../vendor/gambit/lib/_kernel.scm#L1954), [handler frame](../../../vendor/gambit/lib/_kernel.scm#L301). mem.c 7428--7505/4525--4571; _kernel.scm 1954--1992/301--341. | heap_limit can change section/limits; true requests GC. Scheme caller saves/reloads and separately invokes GC. Handler builds an internal return frame and pushes registers. A successful helper return or Zig error union does not independently certify current root/heap placement. |
| AB-S10 | [Still API and allocation](../../../vendor/gambit/lib/mem.c#L1487), [GC phases/resume](../../../vendor/gambit/lib/mem.c#L6938), [allocation constants](../../../vendor/gambit/lib/mem.h#L12). mem.c 1487--1500/1554--1739/6938--7086; mem.h 12--79. | Still allocation may collect/precharge then fail native allocation; caller initializes body. GC runs later phases and prepares resume capacity. 4096, F and normal reserve have separate roles. Native/root/credit outcomes retain the previous study's unresolved publication conditions. |
| AB-S11 | [Rest/key finish before collection](../../../vendor/gambit/lib/_kernel.scm#L908). _kernel.scm 908--976; mem.h 60--78. | After need_to_gc, helper finishes remaining cons cells and packages np fields into a heap vector before jumping to rest-param-check-heap. The finish branch has its own contiguous work and complete-frame obligation. Arithmetic with independent source maxima is not a reachable-state/overflow witness. |
| AB-S12 | [Saved root macros](../../../vendor/gambit/include/gambit.h.in#L8059), [register/saved scanning](../../../vendor/gambit/lib/mem.c#L6511), [scan work](../../../vendor/gambit/lib/mem.c#L4250). gambit.h.in 8059--8086; mem.c 6511--6538/4250--4386. | Roots are actual runtime cells, and new copy work has concrete chunk grammar. Native Zig locals/static metadata are not automatic root locations or actual completed object extents. Full root domains remain governed by previous studies. |
| AB-S13 | [Host exits/dispatch](../../../vendor/gambit/include/gambit.h.in#L6810), [trampoline](../../../vendor/gambit/lib/setup.c#L3214), [C call/unwind](../../../vendor/gambit/lib/setup.c#L3290). gambit.h.in 6810--6850/6888--6978; setup.c 3214--3290/3290--3380/3426--3448. | Existing variants use proper-tail/native exits, computed labels or switch dispatch and a C trampoline/unwind protocol. They support analyzing explicit alternative realizations, not universal Zig tail compatibility or safe C longjmp through Zig frames. |
| AB-S14 | [Pre-normalization source](../../../vendor/gambit/gsc/_front.scm#L225), [normalization schedule](../../../vendor/gambit/gsc/_ptree2.scm#L28), [closure allocation](../../../vendor/gambit/gsc/_t-c-2.scm#L1010). _front.scm 225--252; _ptree2.scm 28--38; _t-c-2.scm 1010--1042. | High-order semantic export can precede normalization/lambda lifting; low-level emission already chooses allocation/control details. Closure groups reserve a sum, not automatically one <=255-word object. The proposed high-level MLIR and Zig-source routes have different export/lowering purposes. |

The trace binds exact selected working-file hashes. These are selected syntax/
branch/dataflow observations, not preprocessing, target ABI, whole-CFG/helper/
foreign caller closure or configured Darwin native acceptance. The previous
immutable artifact record and all unrelated staged/dirty files are preserved.

## Primary References

| ID | Reference | Narrow support / excluded inference |
| --- | --- | --- |
| AB-P01 | [Feeley and Miller, A Parallel Virtual Machine for Efficient Scheme Compilation](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), §2. | PVM transports semantic and target information bidirectionally. Supports a new backend with explicit object/frame/primitive obligations; does not already define Zig output, today's runtime ABI or a migration benefit. |
| AB-P02 | [Zig call modifiers](https://ziglang.org/documentation/0.15.1/#call), [labeled switch](https://ziglang.org/documentation/0.15.1/#Labeled-switch), [C translation limitations](https://ziglang.org/documentation/0.15.1/#Translation-failures), [C import](https://ziglang.org/documentation/0.15.1/#cImport). | always_tail requests guaranteed tail optimization or compilation failure; explicit dispatch is expressible. C translation excludes some goto/macro constructs and import has real parsing/configuration costs. These facts motivate qualified profiles and a genuine emitter, not an automatic backend or cost-free compatibility. |
| AB-P03 | [Compiling with Continuations and LLVM](https://arxiv.org/html/1805.08842v2), §§3.2--3.5. | Tail calls, collector interfaces and first-class control need deliberate lowering/calling conventions. Chunk/trampoline and custom conventions carry tradeoffs. Manticore's runtime/JWA/measurements are not Gambit or standard Zig capabilities. |
| AB-P04 | [LLVM statepoints](https://www.llvm.org/docs/Statepoints.html#overview-core-concepts). | Root maps, relocated uses and managed/unmanaged transitions require compiler/runtime agreement. Does not provide InitSpec, span bounds, actual sparse completion or Gambit continuation semantics automatically. Explicit-root Zig profile and native-stack-map provider profile are different obligations. |
| AB-P05 | [MLIR rationale](https://mlir.llvm.org/docs/Rationale/Rationale/), [MLIR C API](https://mlir.llvm.org/docs/CAPI/). | Progressive lowering preserves useful high-level semantics. C API is low-level and currently offers no stability guarantee; dialect/pass semantics and provider lifecycle remain engineering work. Zig source emission and isolated MLIR service can share contracts without serializing through each other. |
| AB-P06 | [WG14 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf), §§5.1.2.4, 6.5.6. | Synchronization must order publication. Formed C pointer arithmetic has same-allocation/one-past requirements even before dereference. This supports separate address and write footprints; it is not a proof that an existing tentative probe fails on any actual runtime input. |
| AB-P07 | [Retrofitting Parallelism onto OCaml](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), §§1.3, 4.4, and [OCaml C interface](https://ocaml.org/manual/5.3/intfc.html), §§4.4--5.2. | Collector/safepoint/FFI assumptions and initialization/root rules must evolve together. Supports treating modernization as protocol/algorithm work, not importing OCaml barriers/collector/performance into Gambit. |

Reference URL identities are actual evidence editions, not architecture generation
names. No benchmark, RSS/pause percentage or maintenance-hour figure is adopted.

## Evidence Boundary

The selected case equations are handwritten conditional arithmetic. The JSON
case list is documentation, not a running analyzer/model or emitted certificate.
Whole-program B, layout/root/helper/target closure, typed product equivalence,
native profile/control behavior and economic positivity remain unresolved.
Zig is recommended as a substantive backend/system-service candidate; that
recommendation is not an executed feasibility/performance result.

Three registered research views changed after this study's entry baseline.
The trace/artifact record distinguishes these during-study observations from
preexisting drift and binds both entry and observed hashes without evaluating
or adopting their producer/native/model results. Selected source hashes and
document authority remain separate; this study does not overwrite those views.
