# GVM Shared Runtime: Source and Literature Evidence

Date: 2026-10-20. Static source/document research for the
[contract](gvm-shared-runtime-contract.md) and
[replacement matrix](gvm-native-replacement-matrix.md). No implementation,
compilation, tracing, native/model execution or performance validation.

Research HEAD reread: `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`.
Vendor Gambit HEAD reread: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
The working tree contains concurrent work; HEAD alone does not identify all
documents or the repaired runtime. Baseline reads below are explicitly baseline.

## Direct Source Evidence

| ID | Exact inspected source scope | Observation | Design consequence / limit |
| --- | --- | --- | --- |
| S01 | [gsc/_back.scm](../../../vendor/gambit/gsc/_back.scm):17-145; [gsc/_front.scm](../../../vendor/gambit/gsc/_front.scm):225-250 | Target supplies representation, primitive, argument/result and frame information; frontend uses selected target before normalization | Export target assumptions with GVM. BH's earlier high-level window remains separate |
| S02 | [gsc/_gvmadt.scm](../../../vendor/gambit/gsc/_gvmadt.scm):1-85 | Register/stack/label immediates and table-backed global/closure/object operands; `obj-val` retrieves compiler objects | Decode logical operands and constant graphs before a service boundary; integer operands alone are not a portable format |
| S03 | [gsc/_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):240-261,337-393 | C target registers dump/link/frame/primitive handlers; dump consumes and clears c-intf fields and passes module descriptor to heap emission | New product must account for C interface and module semantics, not only executable procedures |
| S04 | [gsc/_t-cpu.scm](../../../vendor/gambit/gsc/_t-cpu.scm):14-18,64-135,142-190 | Defaults and target setup include XXX/placeholder link handlers; assembled code and fixup vectors are wrapped by C-backend compilation | Existing native seam is useful but incomplete as evidence for a replacement. Defaults are not the selected Darwin ABI |
| S05 | [gsc/_t-cpu-abstract-machine.scm](../../../vendor/gambit/gsc/_t-cpu-abstract-machine.scm):992-1021,1081-1230 | Primitive fallback transfers to C-defined Scheme code; entry/return code emits headers, lowlevel handler fixups and frame maps, including internal saved registers | Runtime calls need Scheme control compatibility. Do not erase descriptors or treat every primitive as a C ABI function |
| S06 | [gsc/_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):379-449,833-915; [gsc/_t-c-3.scm](../../../vendor/gambit/gsc/_t-c-3.scm):471-520; [gsc/_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):1947-2012 | Cache/check emission; return kind, link and live-slot order; map bits/chunks and internal expansion; inline/out-of-line label encoding | New producer must preserve the complete value-to-scanner chain, not just frame size or bitmap storage |
| S07 | [include/gambit.h.in](../../../vendor/gambit/include/gambit.h.in):6550-6610,6802-6860,8060-8135,8769-8784,11740-11862 | Capture stores frame and dynamic environment; saved-slot helpers, configurable host exits/jumps, pstate/VM access and label layout | No fixed universal C/Zig struct, calling convention or RA layout; native `ret` is not Scheme return |
| S08 | [lib/mem.c](../../../vendor/gambit/lib/mem.c):3667-3798,3817-3968,6511-6558,6838-6880 | Captured frames can move from stack to heap; normal/internal RA decoding selects maps; collector scans frames, pstate registers and saved roots | Root producer must match existing scanner and relocated reloads, including mixed/captured frames |
| S09 | [lib/mem.c](../../../vendor/gambit/lib/mem.c):108-166,375-423; [header](../../../vendor/gambit/include/gambit.h.in):2956-2969 | Object headers/subtypes and permanent/still/movable classes; current collector text names MOVABLE0, despite extra generation tags | Exact collector/profile reuse is plausible; broad equivalence to Chez/OCaml generational GC is not established |
| S10 | [lib/setup.c](../../../vendor/gambit/lib/setup.c):1997-2030,3276-3438,3440-3515,3756-3795,4080-4175 | Module setup fixes objects/tables; call/run create stack-marker return boundaries; lowlevel execution and fixups use architecture-specific machinery | Module semantics and C activation lifetime remain; inspected ARM code is 32-bit, not arm64/arm64e qualification |
| S11 | [retained cumulative patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):45-104,229-276,408-514,825-844; [source lock](../../../evidence/research/processor-interrupt-collective-wait/source.lock.json) | Adds stack-only poll distinction, complete-frame constraints and changed internal/normal frame interpretation; locks base and candidate hashes separately | Profile must include overlay semantics. These patch reads do not establish the whole candidate's correctness or the latest native owner's state |
| S12 | [root-map lifetime](../root-map-lifetime-contract.md), [shared metadata package](../shared-metadata-package.md), [C compatibility](../c-backend-compatibility.md) | Existing producer/scanner/storage and repaired-cohort obligations already have owners | Extend those obligations to a new code producer; do not add an independent root registry, loader or old-protocol fallback |

The ordinary native service's ownership/FFI rules remain in
[primitive/FFI coverage](primitive-ffi-coverage.md) and
[runtime modernization](zig-llvm-runtime-modernization.md). That boundary does
not prohibit admitted Scheme backend code from sharing the exact managed
representation. Neither source set grants arbitrary native libraries permission
to retain moving Scheme addresses or enter a VM from an unknown foreign thread.

## Content Identity Rechecked for This Contract

| Input | SHA-256 |
| --- | --- |
| gsc/_gvmadt.scm | `2d999f38d68055db8c0e781ccbedfc5e83dbba8e1df77656565d0a15dd10ee59` |
| gsc/_t-c-2.scm | `27d9cc50c6331a0e526c09e029f68153b7fb4bf0e8ce62ed75ec1ba9224a52a0` |
| gsc/_t-c-3.scm | `b8b4e6ef94679e669ba62324ad15ea2d05689fff393451f23dd8e0c5dccaa035` |
| include/gambit.h.in | `2bd9579c7124e0e18eec14180735621351d379a17410047b31b4b74fe2af9ac2` |
| lib/mem.c | `317b5262efd7f3a9418328250c163a9cf3fb9a44fbd573b08fde6f4a3cce2882` |
| lib/setup.c | `047e88c4561f9a95d770732ff13b942620824a1f74727b3f12ed170063239d46` |
| source.lock.json named in S11 | `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b` |
| cumulative patch named in S11 | `8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d` |

Other directly read compiler-file digests are retained in the prior
[runtime evidence ledger](zig-runtime-modernization-evidence.md). Hashes bind
which text was studied; they do not establish selected configure output,
descriptor completeness, ABI equivalence or runtime acceptance. S11's lock is a
named retained candidate, not a claim that it is the newest concurrent repair.

## Primary Literature and Provider Specifications

| Reference / inspected scope | Evidence used | What remains a project obligation |
| --- | --- | --- |
| [Feeley and Miller, PVM, 1990](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), sections 1-2, retained prior reading | Parameterized cooperation between frontend and target | Specify today's GVM export and runtime profile rather than assume a target-free frontend |
| [Huberdeau and Feeley, Tail Calling Between Code Generated by C and Native Backends, 2018](https://www.schemeworkshop.org/2018/Huberdeau_Feeley.pdf), sections 3.2-3.4 and 4.1 | Mixed control uses bridges; common Scheme stack/frame descriptors support GC and continuations; frequent primitive cross jumps can have costs | Historical layouts/instructions are not today's configured ABI. D0/D1 are proposed profiles, not paper implementation claims. No historical timing is projected |
| [LLVM call instruction](https://llvm.org/docs/LangRef.html#call-instruction), tail/musttail and conventions | Tail hint versus required bounded tail behavior, with verifier/ABI restrictions | Prove complete mixed-backend transfer behavior and target support, including host-exit modes |
| [LLVM statepoints](https://llvm.org/docs/Statepoints.html), relocation invariants and RewriteStatepointsForGC | Managed references require valid post-safepoint values and base/derived handling | Connect any such mechanism to Gambit's actual scanner; it is neither a collector nor automatic Gambit compatibility |
| [MLIR C API](https://mlir.llvm.org/docs/CAPI/), design | Provider isolation must account for upstream API evolution | Maintain project-owned versioned semantic request/product contracts and qualification |

The 2018 direct PDF open failed again; following PDF link 14 in the
[conference program](https://www.schemeworkshop.org/2018/) recovered the full
11-page text. The 1997 portable-C report and 2000 continuation/C work remain
full-text unresolved in the earlier study; no unread algorithm or benchmark is
used here. LLVM/MLIR web documents were inspected on this date, but are rolling
documentation, not an installed provider identity or a supported release pair.

## Explicit Unresolved Register

| ID | Missing evidence | Consequence |
| --- | --- | --- |
| U01 | Complete typed GVM/constant/c-intf export and capability domain | Schema is a design; no producer exists by this work |
| U02 | Configured profile/offsets and matched C/native descriptors | Baseline source layout is not configured Darwin/GCC compatibility |
| U03 | D0 host-return integration for the chosen cohort; D1 bridges and bounded stack proof | Neither dispatch strategy is currently admitted |
| U04 | Full primitive/FFI effect, continuation and callback lowering | No claim of general Scheme/native replacement |
| U05 | Native materialization/fixup/init and interpretation-storage ownership | Removing the C packaging wrapper is not yet correct by construction |
| U06 | Relocation-safe optimized IR through the full pipeline | Explicit root/reload design alone is not generated-code proof |
| U07 | arm64/arm64e entry, pointers, relocation and code-permission qualification | Historical ARM/THUMB2 and x86 source cannot close platform gates |
| U08 | Matched B0/B1/Z1 work, time, memory and maintenance observations | N01-N10 deltas remain unknown; zero current performance claims |

All SR01-SR08 admission gates in the contract remain open. Existing finite-model,
historical patched-source and native receipts keep their original scope; none
is reissued as evidence for the new backend. The design can identify removable
work and its upper boundary without pretending those removals have happened.
