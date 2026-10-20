# D1-H C/Module Refactor: Source and Specification Evidence

Date: 2026-10-20. [Architecture](d1h-c-runtime-refactor.md) /
[independent evidence plan](d1h-edge-admission.md). Static research only; no
implementation, compiler/preprocessor query or performance/native/model run.

Research HEAD reread: `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`.
Vendor Gambit reread: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Retained materialized Gerbil/Gambit reread:
`1cfb032c7a1612637da6205f5f8a15683eba3ba0` /
`ea114fc3d2f120abbe20393c1f9aeafdd3f8c89f`.
Generated/local text hashes below bind configuration content separately.
Baseline observations do not identify the current repaired native runtime.

## Source-to-Decision Ledger

| ID | Direct source scope | Fact established | Refactor decision / evidence limit |
| --- | --- | --- | --- |
| R01 | [gsc/_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):337-393,1854-2020,2180-2260 | Dump consumes/clears c-intf, emits host body/label/OFD macros and primitive/C/global/module initialization products | Extract a complete HostGraph/product, not only procedure instructions; new renderers are proposed work |
| R02 | [header](../../../vendor/gambit/include/gambit.h.in):1638-1693,6802-6858 | Trust has attribute/plain-return alternatives; compiler/setjmp/centralized/multiple-compiler macros select exit regime | New D1-H C emitter must enforce required tail edges explicitly; no inherited plain-return fallback |
| R03 | [header](../../../vendor/gambit/include/gambit.h.in):6890-6976; [setup.c](../../../vendor/gambit/lib/setup.c):5204-5254 | pc=0 exports goto table; local dispatch uses stored labels/host-pointer equality; setup_kernel_handlers binds roles with numeric LBL values | Replace public goto query, pointer identity and manual handler ordinals with per-host points and typed runtime-role bindings; new emitter correctness/cost remains open |
| R04 | [setup.c](../../../vendor/gambit/lib/setup.c):3209-3275,3317-3395 | Exclusive-tail mode omits normal trampoline and call directly enters a host; foreign marker/catcher handles final return | C and native host entries/exits need separate qualification; retain Scheme/C activation distinction |
| R05 | [setup.c](../../../vendor/gambit/lib/setup.c):1480-1845,1925-1963,1993-2095 | Fixup-done is set before version/size checks; alignment/constants/globals/labels/OFD mutate; pc=0 invokes hosts; setup_mod is called while collecting descriptors; dynamic linkfile gets setup marker after setup_modules returns | Explicit validation/materialization/init/failure states replace single-marker inference; this is a baseline observation, not a newly reproduced runtime failure |
| R06 | [gsc/_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):833-905; [_t-c-3.scm](../../../vendor/gambit/gsc/_t-c-3.scm):471-520; [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):1947-2012 | Return kinds, slot order/link, saved-register internal expansion, map chunks and descriptor form have a concrete producer | Keep one semantic FrameSpec and realize it for both emitters; same hash/size is not map completeness |
| R07 | [mem.c](../../../vendor/gambit/lib/mem.c):3906-3968; [header](../../../vendor/gambit/include/gambit.h.in):6550-6608; prior [root-map chain](gvm-shared-runtime-evidence.md) | RA-selected frame scanning differs for internal/normal returns; capture retains frame chain and dynamic environment | Host ABI changes do not replace Scheme frame/root semantics or lifetime; no collector rewrite claimed |
| R08 | [setup.c](../../../vendor/gambit/lib/setup.c):839-851; [c_intf.c](../../../vendor/gambit/lib/c_intf.c):6511-6570; prior [handler evidence K08-K09](d0-d1-cross-backend-evidence.md) | throw_error uses runtime THROW; SFUN markers record invocation/processor and are invalidated; marker creation baseline contains an explicit possible-GC TODO | Preserve and audit actual entry/root behavior. Do not certify the baseline TODO safe or attribute it to a latest repaired candidate |
| R09 | [header](../../../vendor/gambit/include/gambit.h.in):9385-9440,11872-11930; [kernel](../../../vendor/gambit/lib/_kernel.scm):5075-5155,5274-5335 | Positional module struct carries setup/init pointers and semantic descriptor; kernel invokes init_mod separately and has two-stage module initialization | New declarative product must preserve semantic setup/init ordering; exporting one undifferentiated initializer is insufficient |
| R10 | [gsc/_t-cpu.scm](../../../vendor/gambit/gsc/_t-cpu.scm):165-182 | Native bytes/fixup vectors are packaged using cpu.scm through the C backend | Direct native product must retire that C packaging dependency, not only rename its driver |
| R11 | Retained [gambuild-C.unix](../../../../../.data/ci-source-patch-check/src/gambit/bin/gambuild-C.unix):1-52; [config.h](../../../../../.data/ci-source-patch-check/src/gambit/include/config.h):35-56; [configured evidence](darwin-configured-input-evidence.md) | Captured GCC compiler/mode flags include trust/inline/single-host; runtime config leaves lowlevel-exec off; previous ledger records GCC 16.2.0 and target | Useful conditional H1 baseline, not actual attribute selection or installed binary proof. Do not reuse existing macro-tracking gains as a Zig gain |
| R12 | [shared metadata package](../shared-metadata-package.md):Decision/Authority and resource order; [root lifetime](../root-map-lifetime-contract.md); [retained patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):209-250 plus prior K12 scope; [source lock](../../../evidence/research/processor-interrupt-collective-wait/source.lock.json) | Existing publication/lifetime owners; patch explicitly keeps ordinary-label ordinal prefix stable against private polling continuations and distinguishes stack-only checks | Typed runtime-role binding can retire ordinal-prefix dependence; materialization still joins existing owners. No native acceptance or new lock order is inferred |

Source scopes are selected for architecture correspondence, not a complete
primitive/FFI/initializer census. All proposed retirements require their actual
caller/capability closure. The baseline SFUN TODO and early setup-marker order
are retained evidence; this study does not diagnose the other lane's overlay.

## Rechecked Content Identity

| Input | SHA-256 |
| --- | --- |
| Vendor include/gambit.h.in | `2bd9579c7124e0e18eec14180735621351d379a17410047b31b4b74fe2af9ac2` |
| Vendor lib/setup.c | `047e88c4561f9a95d770732ff13b942620824a1f74727b3f12ed170063239d46` |
| Vendor lib/c_intf.c | `40c42c6ece7b40a2ddeb4d3082b093b85795cb9b193d47e429ee686f06eff0ae` |
| Vendor gsc/_t-c-1.scm | `cd9030133390377167b2b29ad5f06f3854606e762a8a7cb44d932b62127d6b0a` |
| Vendor gsc/_t-c-2.scm | `27d9cc50c6331a0e526c09e029f68153b7fb4bf0e8ce62ed75ec1ba9224a52a0` |
| Vendor gsc/_t-c-3.scm | `b8b4e6ef94679e669ba62324ad15ea2d05689fff393451f23dd8e0c5dccaa035` |
| Vendor gsc/_t-cpu.scm | `e762748c9e8a2aa3aa4904532f85634e380f627b3b56be0fb8dd8859c7a388cf` |
| Vendor lib/_kernel.scm | `9afa811a1c15104b953a10d42cd11bddffbfa0b8684b4f8f8191d848fdb6d9ec` |
| Vendor lib/mem.c | `317b5262efd7f3a9418328250c163a9cf3fb9a44fbd573b08fde6f4a3cce2882` |
| Materialized bin/gambuild-C.unix | `58a8f5938c1ae03b25c9af28d103ea41bf8cc87315bc4417109e6ea9af3f9f60` |
| Materialized include/config.h | `8711492af33a2b7e51c6b014e49ed3375cb218121a31270f9f2067b9904ec6b3` |
| Materialized include/gambit.h | `c54139a48c7456b07e772077e5318f4f7dde12ccc392a8ec1d66cbc811fb5c58` |
| Retained cumulative patch named in R12 | `8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d` |

## Primary Toolchain Specifications Read

| Source | Relevant rule | Consequence / limit |
| --- | --- | --- |
| [LLVM LangRef, call and conventions](https://llvm.org/docs/LangRef.html#call-instruction), musttail rules | Caller/callee convention, prototype/ABI attributes and required return-position form constrain tail transfers | LLVM evidence does not prove the GCC half or linked mixed-cycle behavior; no default fastcc/tailcc interop claim |
| [GCC 16.1 Common Attributes](https://gcc.gnu.org/onlinedocs/gcc-16.1.0/gcc/Common-Attributes.html), musttail | Unsupported required tail calls reject; departing automatic storage cannot remain a callee dependency | Captured compiler report is 16.2.0, not this manual's source/binary. Local attribute selection and each final C edge remain unresolved |
| [GCC Labels as Values](https://gcc.gnu.org/onlinedocs/gcc/Labels-as-Values.html) | Label values cannot target another function; inlining/cloning can affect label addresses; static local tables have specific compiler rules | Keep optional computed goto private to C1 host; public PointId/HostId and module setup do not depend on those addresses |

These primary specifications were read on 2026-10-20; rolling documentation is
not installed-tool evidence. Historical paper support for shared frames/bridges
is retained in the [D0/D1 literature ledger](d0-d1-cross-backend-evidence.md).
The new declarative module/lifecycle and Zig-owned product/C-emitter choices
are project architecture decisions, not claims those papers implemented them.

## Evidence Status

Static evidence establishes concrete responsibilities to replace: interleaved
C rendering, trust-fallback exits, setup-time host queries, module-wide backend
flags, early completion markers and C packaging of native code. It also
identifies the runtime semantic obligations to preserve. It does not establish
that a replacement exists. E01-E12, A01-A08 and U01-U10 remain open; no new build,
correctness, ABI, performance or maintenance result is claimed.
