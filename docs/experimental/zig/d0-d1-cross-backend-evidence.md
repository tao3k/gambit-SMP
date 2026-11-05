# D0/D1: Darwin Configuration, Control and Frame Evidence

Date: 2026-10-20. [Protocol design](d0-d1-cross-backend-protocol.md).
Read-only source, generated configuration and primary specification research.
No compiler/preprocessor query, build, tracing, model/native test or performance
validation was performed. All D0/D1 profiles are proposed and unqualified.

## Identity and Observation Boundary

Research HEAD: `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`.
Vendor Gambit: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Retained materialized Gerbil: `1cfb032c7a1612637da6205f5f8a15683eba3ba0`;
its Gambit tree: `ea114fc3d2f120abbe20393c1f9aeafdd3f8c89f`.
All four HEADs were reread; generated/local contents are bound separately below.
No claim that the materialized tree, vendor baseline, retained repaired candidate
or installed activation are the same cohort. No concurrent staged edits were
changed or restaged by this study.

## Source Ledger

| ID | Directly inspected scope | Fact established | Limit / consequence |
| --- | --- | --- | --- |
| K01 | Materialized [gambuild-C.unix](../../../../../.data/ci-source-patch-check/src/gambit/bin/gambuild-C.unix):1-55; [config.log](../../../../../.data/ci-source-patch-check/src/gambit/config.log):1-20,78-88; [config.status](../../../../../.data/ci-source-patch-check/src/gambit/config.status):426,1006-1029,1125 | Recorded native aarch64 Darwin/GCC compiler, flags and mode definitions, trust-C-TCO and single-host configuration | Retained configured text, not current toolchain bytes, actual argv for all requests or binary behavior |
| K02 | Materialized [include/config.h](../../../../../.data/ci-source-patch-check/src/gambit/include/config.h):1-65; [lib/makefile](../../../../../.data/ci-source-patch-check/src/gambit/lib/makefile):15-78; [header](../../../../../.data/ci-source-patch-check/src/gambit/include/gambit.h):18-19,1230-1270,1555-1693 | Runtime build uses HAVE_CONFIG_H; config header enables trust/inline/single-host, leaves lowlevel-exec undefined; ordinary C selects setjmp | Runtime configuration and application definitions are separate ingress paths. No preprocessed TU or runtime archive was inspected |
| K03 | Materialized [configure.ac](../../../../../.data/ci-source-patch-check/src/gambit/configure.ac):535-580; [lib/_kernel.c](../../../../../.data/ci-source-patch-check/src/gambit/lib/_kernel.c):1154-1157 and bounded policy-macro search | lowlevel-exec and trust are independent options; retained kernel C has LBLCOUNT 1461 and includes gambit.h, with no centralized/multiple-C-compiler/trust policy overrides found in that file search | This one generated source is not a census of all request/source overrides or proof of which object is installed |
| K04 | Vendor [header](../../../vendor/gambit/include/gambit.h.in):1555-1693,6802-6860; same materialized header policy region | Trust defines PROPER_TAIL_CALL via musttail attribute if available, else plain return-call; centralized/setjmp/multiple-compiler decisions select host exits | Boolean H0/H1/H2 table is source-derived. Actual local attribute selection and tail machine code remain unresolved |
| K05 | Vendor [setup.c](../../../vendor/gambit/lib/setup.c):3209-3438 | Trampoline exists only outside exclusive-tail regime; unrolled loop dispatches label hosts; call/run create foreign-entry frame/marker; H1 directly calls the host | D0 cannot assume an existing dispatcher in an H1 runtime; ordinary host return is distinct from final Scheme-to-C unwind |
| K06 | Vendor [header](../../../vendor/gambit/include/gambit.h.in):1368-1435,6802-7015,8099-8135,8170-8195,11772-11870 | Label-values and computed-goto policies, local/external transfers, SELF/arity errors and host/entry/descriptor fields | Local C goto addresses are not native function entry ABI; new native hosts need pc decoding and exact configured layout |
| K07 | Vendor [gsc/_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):833-915; [_t-c-3.scm](../../../vendor/gambit/gsc/_t-c-3.scm):471-520; [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):1947-2012; [header](../../../vendor/gambit/include/gambit.h.in):9220-9328 | Live-slot order, normal/task/internal return kinds, internal saved-register expansion, map chunks and descriptor decoding | Native descriptor producer is new work; copied frame sizes or bit constants alone are insufficient |
| K08 | Vendor [lib/_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):220-300,980-1095,1310-1348; [header](../../../vendor/gambit/include/gambit.h.in):6550-6750,9980-10010 | Stack/internal handlers save registers/RA and restore internal resume state; capture/graft retain dynamic state; return-to-C uses processor/marker checks and throw | Transfer writeback is not automatically a collecting prologue. Preserve supported nested foreign-entry/nonlocal control and overlay changes |
| K09 | Vendor [lib/mem.c](../../../vendor/gambit/lib/mem.c):3667-3798,3817-3968,6511-6555 | Captured stack frames can relocate; RA selects normal/internal maps; register/saved arrays are scanned | Only actual mapped/rooted locations survive collection; prior native SSA and interior pointers require reload/recomputation |
| K10 | Vendor [setup.c](../../../vendor/gambit/lib/setup.c):1532-1628,1740-1845; [header](../../../vendor/gambit/include/gambit.h.in):3107-3128,8197-8358 | Setup checks sizes/version, aligns/copies labels, queries C goto tables via pc=0 when module flag requests it, installs descriptor/entry fixups; lowlevel mode changes representations | Initial native-only flag-clear module design avoids goto query, but complete native materialization remains unimplemented. Module-wide mixed-host setup needs separate design |
| K11 | Vendor [gsc/_t-cpu-abstract-machine.scm](../../../vendor/gambit/gsc/_t-cpu-abstract-machine.scm):1081-1230; [setup.c](../../../vendor/gambit/lib/setup.c):3440-3515,3756-3795,3980-4058 | Existing CPU producer emits lowlevel handler/point/descriptor fixups; bridge code is architecture-specific, with ARM THUMB2/32-bit conventions | Not a reusable arm64 bridge; D1-H deliberately avoids dependence on enabling lowlevel-exec |
| K12 | [Retained cumulative patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):45-104,428-518,795-844; [source lock](../../../evidence/research/processor-interrupt-collective-wait/source.lock.json); [root lifetime](../root-map-lifetime-contract.md), [C compatibility](../c-backend-compatibility.md) | Stack-only check/resume distinction, complete-frame constraints, RA tag diagnostic; existing interpretation-lifetime and repaired-cohort owners | Diagnostic tag validity is not pointer lifetime or full root correctness. Retained patch is not asserted to be latest owner candidate or native acceptance |

The protocol's initial scope deliberately excludes private register ABI and
new hot-unload/foreign-thread capabilities. C/native general Scheme transfers,
ordinary foreign calls and blocking/callback adapters remain separate effect
classes; X01-X12 are design cases, not executed controls.

## Rechecked Content Digests

| Input | SHA-256 |
| --- | --- |
| Materialized bin/gambuild-C.unix | `58a8f5938c1ae03b25c9af28d103ea41bf8cc87315bc4417109e6ea9af3f9f60` |
| Materialized config.status | `3ec142dbeeecad9aee1bab1e0517b30390bf0c640ec8d1cbd11632b0307eee83` |
| Materialized config.log | `932f438230719dce418fdce97ec5a5f94f0b702fb30cb70ed402a1a42c31db2c` |
| Materialized include/gambit.h | `c54139a48c7456b07e772077e5318f4f7dde12ccc392a8ec1d66cbc811fb5c58` |
| Materialized include/config.h | `8711492af33a2b7e51c6b014e49ed3375cb218121a31270f9f2067b9904ec6b3` |
| Materialized lib/makefile | `e70d078a7b3818a90bb94c49ef81c0781ca0c756b90890924abe03f57a410312` |
| Vendor include/gambit.h.in | `2bd9579c7124e0e18eec14180735621351d379a17410047b31b4b74fe2af9ac2` |
| Vendor lib/setup.c | `047e88c4561f9a95d770732ff13b942620824a1f74727b3f12ed170063239d46` |
| Vendor lib/_kernel.scm | `9afa811a1c15104b953a10d42cd11bddffbfa0b8684b4f8f8191d848fdb6d9ec` |

The [shared runtime evidence](gvm-shared-runtime-evidence.md) retains map-source,
collector, candidate-lock and cumulative-patch digests; this study rereads the
selected source/hunks and does not apply that patch. The existing
[configured-input ledger](darwin-configured-input-evidence.md) retains complete
flag strings and historical receipt distinctions. No old measured number is
used as a new bridge-performance estimate.

## Primary Paper and Toolchain Evidence

| Reference / inspected scope | Supported fact | Qualification limit |
| --- | --- | --- |
| [Huberdeau/Feeley 2018](https://www.schemeworkshop.org/2018/Huberdeau_Feeley.pdf), sections 2.3-3.4 | C/native state placement needs bridges; shared Scheme frames/descriptors support mixed continuations; direct native control references required layout changes | Historical x86/32-bit ARM design, not current Apple ABI or proof of D1-H. Recovered full text through conference program PDF link |
| [LLVM LangRef](https://llvm.org/docs/LangRef.html#call-instruction), calling conventions and call tail rules | Dynamic caller/callee conventions must agree; musttail has required form and constraints; tail hint alone does not suffice | Uniform C-ABI host design still needs exact target/provider and C-side evidence |
| [GCC 16.1 Common Attributes](https://gcc.gnu.org/onlinedocs/gcc-16.1.0/gcc/Common-Attributes.html), musttail | Required tail call is rejected if unavailable; departing automatic storage cannot remain a callee dependency | Nearest read public versioned manual is 16.1, while retained compiler report says 16.2.0; no claim of exact source/binary correspondence or actual attribute selection |

Primary documents were read on 2026-10-20. No local compiler feature probe or
preprocessing was run to close version/attribute gaps. Apple ARM64 documentation
was located, but its directly opened page exposed only the JavaScript shell;
no register-level bridge contract is inferred from that incomplete page.

## What Static Evidence Closes and Leaves Open

| ID | Static conclusion | Still unresolved |
| --- | --- | --- |
| DU01 | Retained defaults conditionally select H1; ordinary trampoline is excluded in that branch | All actual request/source overrides, runtime/archive identity and realized macro selection |
| DU02 | D0 needs a coherent H0 cohort, not only a new host function | Rebuilt C/runtime/library equivalence and native host product admission |
| DU03 | Uniform C host ABI avoids a required private-register/lowlevel representation switch in the proposed D1-H | Exact ABI/attributes, every GCC and LLVM tail edge, target lowering and nonlocal-control behavior |
| DU04 | Current normal/internal descriptor producer/consumer and return-to-C marker paths are identifiable | Complete native maps, all continuation/FFI cases, collector-safe optimized code |
| DU05 | Flag-clear native-only module can avoid the C goto-label query by source condition | Full materialization/fixup/debug identity, error/init behavior, concurrent owner and code/map lifetime |
| DU06 | Existing ARM bridge is not arm64/arm64e evidence; D1-R entails two-way state conversion and potential layout changes | Private register set, OS stack/ABI preservation, code permissions and pointer authentication |
| DU07 | Required work and future edge cases can be enumerated | All native, performance and maintenance deltas; all SR01-SR08 admission remains open |

These are deliberately bounded conclusions. The design does not turn trust in
a C compiler, a valid return tag, successful linking, a finite model or a
historical patched run into current mixed-backend acceptance.
