# Runtime Modernization: Source and Literature Evidence

Date: 2026-10-20. [Architecture](zig-llvm-runtime-modernization.md) and
[18-row benefit ledger](zig-modernization-benefit-ledger.md). Static reads only;
no implementation, native/model test or performance validation.

Research HEAD: `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`.
Vendor Gambit HEAD: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Vendor Chez HEAD: `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`.
Both vendor identities were reread. Baseline code, cumulative runtime repair
source lock and historical scoped receipts are different evidence objects.

## Repository Evidence

| ID | Source read and exact scope | Architectural relevance |
| --- | --- | --- |
| G1 | Gambit lib/mem.c:108-166,375-423,3270-3305,3410-3465,3555-3605,6661-6755; include/gambit.h.in:2956-2969,8769-8784 | Movable/still/permanent representation, generation tags, msection copying, publication, forwarding CAS, worker/steal/termination machinery and configuration-dependent VM access |
| G2 | Gambit lib/c_intf.c:1624-1668,1679-1705,5154-5192; header:10040-10059 | RC native conversions, foreign release/ownership and generated Scheme-callback markers/control |
| G3 | Gambit lib/_kernel.scm:4500-4524; include/gambit.h.in:6580-6587,6802-6803 | Existing RA/root writeback and reload boundary; not evidence it is absent or safe to delete |
| G4 | Existing GC/FFI current-graph status, frame protocol, shared-runtime VM entry audit, owned-retirement contract and parallel-GC comparison | Scoped positive/negative evidence and remaining semantic, memory-order, lifecycle and native gates |
| C1 | Chez c/thread.c:150-205; c/types.h:363-409; c/gc.c:3164-3225; models/chez/source.json | Activation/deactivation and sweeper completion, retained code/root duties; model/source refinement remains explicitly false in the source manifest |
| E1 | Existing native contract, high-level export/pass design, primitive coverage and migration matrices | Concrete producer/backend/FFI seams; 1588-name census and 32/12 design denominators are prior source inventories, not new runtime results |
| G5 | Gambit gsc/_back.scm:17-145; _front.scm:225-250; _t-c-1.scm:240-261; _t-cpu.scm:142-180; _t-cpu-abstract-machine.scm:992-1021 | Parameterized target contract, native-code/C packaging and explicit primitive dispatch seams; not native backend admission |

Local source links:
[Gambit collector](../../../vendor/gambit/lib/mem.c),
[Gambit header](../../../vendor/gambit/include/gambit.h.in),
[C interface](../../../vendor/gambit/lib/c_intf.c),
[kernel wrapper](../../../vendor/gambit/lib/_kernel.scm),
[Chez thread](../../../vendor/chez/c/thread.c),
[Chez types](../../../vendor/chez/c/types.h),
[Chez collector](../../../vendor/chez/c/gc.c),
[Chez source manifest](../../../models/chez/source.json),
[parallel-GC comparison](../../parallel-gc-design-comparison.md),
[frame boundary](../../ffi-gc-frame-protocol.md),
[scoped GC/FFI status](../../gc-ffi-current-graph-status.md),
[VM entry audit](../../shared-runtime-vm-entry-audit-20261015.md),
[owned retirement](../../vm-owned-retirement-contract.md),
[candidate lock](../../../evidence/research/processor-interrupt-collective-wait/source.lock.json).

The candidate lock was read to preserve baseline/candidate identity. It is not
applied, rebuilt or promoted here. Earlier successful workloads, finite models
and compiler failures remain scoped to their original source/flags/receipts;
this document does not reissue current runtime acceptance from those records.

## Rechecked Source Digests

| Source | SHA-256 |
| --- | --- |
| Gambit include/gambit.h.in | `2bd9579c7124e0e18eec14180735621351d379a17410047b31b4b74fe2af9ac2` |
| Gambit lib/c_intf.c | `40c42c6ece7b40a2ddeb4d3082b093b85795cb9b193d47e429ee686f06eff0ae` |
| Gambit lib/mem.c | `317b5262efd7f3a9418328250c163a9cf3fb9a44fbd573b08fde6f4a3cce2882` |
| Chez c/gc.c | `6d937386a3aa466cf908fb2990047aba006c01662f28866e328b5a9f15e15fc9` |
| Chez c/thread.c | `6081cd912e5903e19cba808fbe646a846ad49459bab73e79b4d67d6ff59c1c72` |
| Chez c/types.h | `5870d3cd0a6ffd670c4b0c406ec17719480bfac49380bb0e5da996860b1ab407` |
| Gambit gsc/_back.scm | `fe9021d1e7f88c46a869d0701d4dc960346b7383e21857102ef2150b448ecf3b` |
| Gambit gsc/_front.scm | `e05dd9b2370da0e1a7baa3c8b7ea1d212fc3efe23e0e90e8fce3db69119c63de` |
| Gambit gsc/_t-c-1.scm | `cd9030133390377167b2b29ad5f06f3854606e762a8a7cb44d932b62127d6b0a` |
| Gambit gsc/_t-cpu.scm | `e762748c9e8a2aa3aa4904532f85634e380f627b3b56be0fb8dd8859c7a388cf` |
| Gambit gsc/_t-cpu-abstract-machine.scm | `7beaa1c36bb456e2fa56dbfda64ea2a61c5e2d57045bd24099a796773872f3c8` |

## Primary Literature and Toolchain References

| Reference and inspected scope | Transfer / limit |
| --- | --- |
| [Feeley/Miller PVM, LFP 1990](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), abstract/sections 1-2 | Bidirectional target contract, not an isolated emitter; historical PVM is not current SMP specification |
| [Huberdeau/Feeley, SFPW 2018](https://www.schemeworkshop.org/2018/Huberdeau_Feeley.pdf), sections 1-3.3 | Same-runtime native/C interoperability; historical design, not current ABI or arm64e support |
| [Retrofitting Parallelism onto OCaml, ICFP 2020](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), sections 1 and 4 | C API/collector coupling, sequential compatibility and latency constraints. No external benchmark number is projected onto Gambit; historical designs are not all the final OCaml 5 collector |
| [OCaml 5.4 parallelism](https://ocaml.org/manual/5.4/parallelism.html), section 3; [C interface](https://ocaml.org/manual/5.4/intfc.html), section 12 | Domain-local allocation/collection and runtime-access/foreign-thread contracts; not Gambit API definitions |
| [OCaml 5 design review](https://github.com/ocaml-multicore/docs/blob/main/ocaml_5_design.md), WG2 | Historical domain-membership and blocking-participation design; no adoption-duration estimate |
| [LLVM GC](https://llvm.org/docs/GarbageCollection.html), integration boundaries; [statepoints](https://llvm.org/docs/Statepoints.html), relocation contract | Compiler mechanisms must be connected to the actual runtime; not a replacement collector or proof of SMP behavior |
| [MLIR pass infrastructure](https://mlir.llvm.org/docs/PassManagement/), analyses/pipelines; [bufferization](https://mlir.llvm.org/docs/Bufferization/), overview | Reusable mechanisms behind domain-specific legality; tensor bufferization does not solve Scheme regions |
| [LLVM LTO](https://llvm.org/docs/LinkTimeOptimization.html), design | Potential interprocedural optimization requires supported LLVM IR objects/toolchain; not automatic for existing GNU GCC objects |
| [MLIR C API](https://mlir.llvm.org/docs/CAPI/), design | No current stability guarantee; isolate provider ABI rather than freezing upstream C headers |
| [Zig 0.16 documentation](https://ziglang.org/documentation/0.16.0/), C ABI/translation; [release notes](https://ziglang.org/download/0.16.0/release-notes.html), C translation and future direction | Target/flags matter, translation/backend dependencies evolve. Zig is not a promise that LLVM/Clang/LLD/PAC share one stable release contract |

The author's corrected paper URL was recovered after an initial guessed PDF URL
failed. No secondary benchmark or “ten years” duration was used as a planning
estimate. Modernization role assignments, R0-R2, F0-F5 and Q01-Q18 are proposed
project architecture, not claims made by those sources. The remaining gaps are
the selected Gambit collector profile, complete FFI site/effect denominator,
runtime-component source refinement and all incremental benefit/cost baselines.

The 2018 primary author-host URL was access-blocked. Following the conference
program's PDF link recovered the 11-page paper from the conference site; the
[backend redesign](gambit-centered-backend-redesign.md) uses the read text, not
search snippets. The 1997 portable-C report and 2000 continuation/C paper remain
full-text unresolved after author-host attempts. No algorithmic detail or old
performance number from those unread works is promoted. G5 local links:
[target interface](../../../vendor/gambit/gsc/_back.scm),
[C backend](../../../vendor/gambit/gsc/_t-c-1.scm),
[CPU backend packaging](../../../vendor/gambit/gsc/_t-cpu.scm),
[native primitive path](../../../vendor/gambit/gsc/_t-cpu-abstract-machine.scm).
