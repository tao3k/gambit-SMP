# Full Modernization: Source and Primary Evidence

Reviewed: 2026-10-20. Research HEAD b67da6262a973a0ae898002d5c7f5be2d8b5a90d;
Gambit HEAD 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882. Registered hashes bind
actual working-copy files. Source facts, existing candidate repairs, architecture
proposals, upstream mechanisms and native admission are separate. No implementation,
compiler/native/model test, engine evaluation or performance experiment.

## 1. Gambit Seams and Prior Design Constraints

| ID | Direct source / prior contract | Evidence and design consequence |
| --- | --- | --- |
| MS01 | [_back.scm](../../../vendor/gambit/gsc/_back.scm):17-145; [_front.scm](../../../vendor/gambit/gsc/_front.scm):225-250; [_ptree2.scm](../../../vendor/gambit/gsc/_ptree2.scm):28-35 | Target negotiation and pre-normalization tree/context exist; six normalization steps transform important semantics. High export must preserve target/declaration meaning and precede information-losing storage/control choices. No public export API implemented. |
| MS02 | [_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):85-149; [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):344-455; [completion design](semantic-completion-operations.md):OP01-OP24 | GVM carries frames/closed/live state; C target creates checks/private resumes/materialization late. Scheme completion must issue missing root/control/effect semantics before physical realization; raw GVM is insufficient. |
| MS03 | [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):337-346,1182-1207,1934-2017; [_t-c-3.scm](../../../vendor/gambit/gsc/_t-c-3.scm):471-520 | Interface clearing, gambit.h inclusion, procedure/module/constant emission and frame encoding are concrete work to replace. Removing selected C route does not remove its object/setup/root obligations. |
| MS04 | [_t-cpu.scm](../../../vendor/gambit/gsc/_t-cpu.scm):162-179; [_gsclib.scm](../../../vendor/gambit/gsc/_gsclib.scm):498-593 | Native instruction generation still packages through C; build parameters travel through string fields. Direct native products and one typed native request have named old owners, not hypothetical duplicated services. |
| MS05 | [_ptree2.scm](../../../vendor/gambit/gsc/_ptree2.scm):2093-2112,2171-2182,2902-2955,3144-3222; [high semantics](zig-high-level-semantics-design.md):section 2 | FFI information must be captured before reset/emission; conversion/control ordering cannot be recovered solely from a C signature. High hook and typed foreign side product are independent required producers. |
| MS06 | [setup.c](../../../vendor/gambit/lib/setup.c):3276-3424,5213-5254; [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):1019-1071; [shared runtime](gvm-shared-runtime-contract.md):sections 3-5 | Scheme frames, configured host/trampoline returns, marker/processor checks and handwritten role ordinals are actual seams. Native ret/status alone cannot preserve continuation/foreign-return semantics. |
| MS07 | [header](../../../vendor/gambit/include/gambit.h.in):8059-8086,8622-8784,11309-11315; [mem.c](../../../vendor/gambit/lib/mem.c):674-827,3969-3986,6511-6538,6839-6863 | Fixed saved roots, per-processor RC, configured selector and actual scan domain constrain current ABI. A VM-owned retained/context root domain is a new architectural candidate, not already supplied by an opaque handle or Zig allocator. |
| MS08 | [candidate patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):3160-3234,3439-3460,4390-4501; [RC study](rc-marker-minimal-contract.md):sections 1-3 | Existing per-processor scan and successful RC/still transfer are credited; pending-join storage retention and actual next-GC enumeration differ. Full root-carrier redesign may replace processor-coupled lifetime assumptions; no reproduced native fault inferred. |
| MS09 | [runtime contract](runtime-root-participation-contract.md):sections 2-6; [owned wait](owned-callback-participating-wait-contract.md):section 6 | V/E/R/S/P and current BW1 publication/abort/service are distinct assets. New parked/detached contexts need request/member/root/reentry protocol, not lock release or count decrement. |
| MS10 | [layout/provider boundary](native-layout-provider-design.md):LD1-LD4,NP01-NP12; [replacement plan](hostgraph-retirement-plan.md):H01-H10; [benefit ledger](zig-modernization-benefit-ledger.md):Q01-Q18 | Existing project work already separates semantic/physical/object/provider duties, source retirement and total costs. This full study makes them primary together; local Bmin economics is a control, not a prerequisite choosing saved0 for the full cohort. |

Reads are selected bounded seams, not a complete application/primitive/foreign
or installed-profile census. The exact native product, managed cohort and target
ABI still need source correspondence. No existing historical model/native result
is recomposed into SharedRuntimeContract acceptance. The full design can change an
internal ABI with cohort rebuilding; doing so needs explicit cost and interfaces.

## 2. Papers and Official Provider Mechanisms

These are upstream reading identities, not pinned source-byte snapshots or an
installed compatible toolchain. Rolling MLIR documentation includes facilities
that may be absent from a chosen release. Capability/version selection must be
explicit. None of the papers selects Zig over the same modern C architecture.

| ID | Primary evidence / inspected scope | Supported mechanism and limit |
| --- | --- | --- |
| MP01 | [Feeley/Miller PVM paper](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), section 2 and frontend/backend interface discussion | Bidirectional semantic/target negotiation supports separating Scheme meaning from target realization. It is not the new root/control ABI or evidence that existing C emission must remain forever. |
| MP02 | [MLIR paper, 2020](https://arxiv.org/abs/2002.11054), abstract; [MLIR rationale](https://mlir.llvm.org/docs/Rationale/Rationale/), motivation/progressive lowering | Reusable multi-level compiler infrastructure can preserve useful abstraction and delegate common machinery. Domain semantics and transformations still need implementation and lawful lowering. Abstract/rationale read; full-paper HTML fetch failed, no benchmark transferred. |
| MP03 | [MLIR Side Effects & Speculation](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/), categorization/modeling/limitations | Memory effects and speculatability are explicit; documented framework does not fully model nonlocal control and resource hierarchy is not fine alias analysis. Gambit needs additional control/GC/capture legality, not Pure annotations on Scheme calls. |
| MP04 | [MLIR C API](https://mlir.llvm.org/docs/CAPI/), scope/ownership/stability; [Interfaces.h](https://mlir.llvm.org/doxygen/mlir-c_2Interfaces_8h_source.html):268-288 | Low-level C handles/ownership and external memory-effect fallback callbacks can be used by C/Zig. Callback effect instances have specified temporary lifetimes. This is concrete interoperation leverage, not all dialect/pass implementation or a stable version-independent API. |
| MP05 | [LLVM Statepoints](https://llvm.org/docs/Statepoints.html), overview/relocation sequence/base-derived pointers | Safepoints identify updateable references and explicit relocated values; stackmaps can describe machine spills. Gambit collector registration, Scheme continuation/frame interpretation and code/map lifetime must be integrated; FR and SP are distinct adapters. |
| MP06 | [Clang ThinLTO](https://clang.llvm.org/docs/ThinLTO.html), introduction/incremental/cache | Cross-module analysis and incremental backend caching are upstream facilities, available to qualifying C/Clang and new native routes. Imports/semantic invalidation and actual target/linker support remain project obligations; no installed Darwin flag or speedup claimed. |
| MP07 | [LLVM source-level debugging](https://llvm.org/docs/SourceLevelDebugging.html), design/debug-information model | Frontend-supplied debug descriptions can flow through LLVM. Scheme source variables, suspended continuations, GC maps and root meaning still require explicit mapping; a machine debug format is not a Scheme continuation decoder. |
| MP08 | [Compiling with Continuations and LLVM, 2018](https://arxiv.org/html/1805.08842v2), sections 2-3 | PML separates normalized lambda/CPS/closure/CFG, integrates tail transfer, root/GC checks and preemption with LLVM. Heap continuations and historical custom conventions/API limits are not current Gambit/LLVM guarantees or portable performance forecasts. |
| MP09 | [Elsman, GC Safety for Region-Based Type-Polymorphic Programs, PLDI 2023](https://elsman.com/mlkit/pdf/gcsafe-pldi23.pdf), introduction/section 2 | A logically unused captured pointer can remain collector-visible after its region is freed. This motivates traced-edge/capture/effect lifetime checks for hybrid regions; its type system/results do not prove safety for Gambit control/FFI. |
| MP10 | [Retrofitting Parallelism onto OCaml, ICFP 2020](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), sections 1.2-1.4,4.4 | C interface assumptions and collector choices interact; serial semantics/cost/pause and parallel goals are separate. Modernization is protocol/algorithm co-design, not a language rename or imported benchmark gain. |
| MP11 | [ORCv2](https://llvm.org/docs/ORCv2.html), resource trackers/code removal | Upstream symbol/code resource machinery supports an optional JIT provider. ResourceTracker removal does not establish no live Scheme continuation, native return, map reader or GC user; quiescence remains runtime-owned. |
| MP12 | [Zig 0.15.1 reference](https://ziglang.org/documentation/0.15.1/), C interoperation, tagged products, fallible propagation, allocator/lifetime; [modern C controls](zig-vs-modern-c-evidence.md):P01-P04 | Zig supplies private native construction/resource-expression mechanisms. C can use generated/opaque APIs, existing libraries and selected compiler checks. Lifetime, GC/member/control and economic superiority are not language guarantees. |

The first llvm.org ThinLTO URL failed; the Clang page above succeeded. The first
SideEffects URL omitted Rationale and failed; the corrected official page above
succeeded. Failures are retained as reading limits, not silently turned into
new provider/target qualification. No upstream example/test command was run.

## 3. What Is Inferred and What Remains Open

SharedRuntimeContract, VmRootDomain, separate AOT compiler worker/runtime SDK,
CT0-CT6, SO01-SO08, MA01-MA09, LM01-LM14,
FD01-FD09 and AG01-AG07 are project architecture/decision units. Sources expose
current work and constraints; provider references establish reusable mechanisms,
not a complete compiler/runtime solution. All physical layout, nonlocal-control,
root/update/participant/weak-memory, region/capture and capability coverage remain
explicit theory gates. Actual old-path deletion and justified total/marginal cost
bounds remain open. Future native acceptance is separate from source/cost theory.

The exact modernity objective is a coherent shared-runtime compiler/system
boundary, with substantial attributable stage/support retirement and/or valuable
admitted capability. LLVM reuse can make that investment worthwhile; Zig adoption
additionally requires its disjoint incremental argument against C-full. Neither
minimalism nor ambition alone decides it. No new engine/native/cost witness is
issued by this document.
