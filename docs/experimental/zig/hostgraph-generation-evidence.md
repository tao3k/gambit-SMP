# HostGraph Generation: Source Evidence and Unresolved Qualification

Date: 2026-10-20. Static source/configuration research only. See the
[generation contract](hostgraph-generation-contract.md) and
[C replacement order](hostgraph-retirement-plan.md). No implementation, compiler
query, preprocessing, tracing, model/native execution or performance validation.

Research HEAD: `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`.
Vendor Gambit: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Hashes below bind source content separately from Git revisions. The retained
patch is historical source evidence; it is not identified as the current
repaired native runtime or proof of its acceptance.

## Source-to-Contract Ledger

Line scopes are one-based in the inspected text; linked files and SHA-256 bind
the claims if later edits move lines. HG rows establish existing responsibilities
and constraints. HostGraph, FrameLayout and named-role protocols are proposed.

| ID | Direct source scope | Source fact | Design consequence / limit |
| --- | --- | --- | --- |
| HG01 | [gsc/_back.scm](../../../vendor/gambit/gsc/_back.scm):17-145,207-208; [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):199-312 | Target interface supplies dump, representation/primitive data, frame constraints, result and entry/jump location information | Target negotiation remains before GVM; Zig is not handed a target-free frame graph. Extract a common immutable profile, not duplicate target authority |
| HG02 | [gsc/_front.scm](../../../vendor/gambit/gsc/_front.scm):225-250,757-960,1258-1388,2899-2998 | Frontend normalizes/compiles, creates procedure/entry/frame contexts; entry-context uses target label-info; seal-bb may split polling edges and copies instruction comments | Semantic export follows GVM completion; profile influences location assignment; role authority cannot simply live in copied comments |
| HG03 | [gsc/_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):85-149 | Frames contain size, slots, registers, closed vars and live vars; closure-env liveness also depends on closed variables; frame comparison considers live locations/ret-var | Keep closure/liveness meaning in Scheme; logical slot/register assignment cannot be replaced by LLVM liveness or a simple Zig membership check |
| HG04 | [gsc/_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):300-338,390-480,494-553 | Mutable block-label allocation; instruction kinds include entry/return/task labels and jumps with separate ret/nbargs/poll/safe fields; cloning rewrites labels but reuses comments | Explicit transfer kind and AnchorId/PointId lineage needed; no semantic identity from allocator integers or shared comment objects |
| HG05 | [gsc/_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):725-827,1072-1139,1730-1818 | Purification performs cascade/dead/common/useless jump passes and ordering; dead reachability begins at entry; code-list conversion computes backward slots-needed/coherence | Add role-root/transform preservation before purification and explicit stack-frontier obligation after it; needed slots and live roots are different analyses |
| HG06 | [gsc/_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):26-115,273-300,575-645 | Procedure scan builds code/label/debug/resource queues, then allocates value and goto label numbers; label categories distinguish normal/task/internal returns | Freeze semantic identities before C label assignment. GVM labels, runtime ordinals, local gotos and debug order are distinct namespaces |
| HG07 | [gsc/_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):344-455 | Heap/floating-state budgets and checks are accumulated; check emission creates a fresh target return-internal label; frame update materializes dirty cached values based on frame/closure liveness | Raw GVM lacks some points/root obligations currently created by C backend. Extract semantic checks/materialization before Zig; preserve allocation needed for materialization |
| HG08 | [gsc/_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):825-905 | Return construction reverses/extends slots, requires ret-var position, distinguishes internal expansion; all saved GVM registers and protocol return slot are marked live for internal frames | Scheme declares semantic and mandatory protocol roots; Zig packs a declared recipe. Missing RA rejects; no root elision based only on frontend dead-value or LLVM analysis |
| HG09 | [gsc/_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):115-224,934-945,1318-1392 | C-procedure scanner has conversion/control setup; primitive inline generators are Scheme callbacks; jumps prepare R0/return state, checks/frame adjustment and specialized target forms | Extract call/return/foreign semantics from C spellings. Codegen callback serialization or arbitrary raw host-control C forwarding is not the proposed boundary |
| HG10 | [gsc/_t-c-3.scm](../../../vendor/gambit/gsc/_t-c-3.scm):471-535; [header](../../../vendor/gambit/include/gambit.h.in):9220-9318; [mem.c](../../../vendor/gambit/lib/mem.c):3817-3845,3909-3968 | Map builder uses ordered-slot predicate; packer chunks/alignment/internal expansion and descriptor limits are concrete; scanner uses RA-kind-specific frame size/link/maps, starts frame fields at 1 and consumes link+1 | Separate root obligations from profile packing and coordinate conversion. Preserve normal/internal scanner meaning; a descriptor hash/round-trip alone cannot prove complete roots |
| HG11 | [kernel](../../../vendor/gambit/lib/_kernel.scm):140-228; [setup.c](../../../vendor/gambit/lib/setup.c):5213-5254 | Kernel handler container must never be called; embedded C and dummy Scheme calls construct handler/return positions; setup assigns 14 fields from it plus dynamic-env-bind-return from another container | 15 assignments in this function; role anchor is a specific region/resume, not a procedure-entry name. Exact per-role incoming/descriptor contracts require further extraction, not inferred from field names |
| HG12 | [retained cumulative patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):46-106,210-258; [source lock](../../../evidence/research/processor-interrupt-collective-wait/source.lock.json) | Patch distinguishes stack-only checks/complete frames and keeps ordinary value labels before private polling labels while remapping debug order | Evidence of real ordinal/check coupling. New roles can remove that dependency after all consumers migrate; unrelated frame/masking fixes must survive. No new patch run or deletion qualification |

The [D1-H source ledger](d1h-refactor-evidence.md) supplies the adjacent module
and host ABI evidence: R01 rendering/init, R02/R04 exits, R03 host queries,
R05 fixup/ownership, R07 capture/scanning, R08 foreign errors/markers,
R09 initialization stages, R10 native-through-C packaging, R11 retained
Darwin/GCC configuration and R12 metadata lifetime. This study refines those
boundaries; it does not rerun or upgrade their native evidence status.

## Rechecked Source Content

| File | SHA-256 |
| --- | --- |
| gsc/_back.scm | `fe9021d1e7f88c46a869d0701d4dc960346b7383e21857102ef2150b448ecf3b` |
| gsc/_front.scm | `e05dd9b2370da0e1a7baa3c8b7ea1d212fc3efe23e0e90e8fce3db69119c63de` |
| gsc/_gvm.scm | `a1160027e78b7ee75bb6f89094f658cd518d75c1a133f681d1832966a5e611c9` |
| gsc/_gvmadt.scm | `2d999f38d68055db8c0e781ccbedfc5e83dbba8e1df77656565d0a15dd10ee59` |
| gsc/_t-c-1.scm | `cd9030133390377167b2b29ad5f06f3854606e762a8a7cb44d932b62127d6b0a` |
| gsc/_t-c-2.scm | `27d9cc50c6331a0e526c09e029f68153b7fb4bf0e8ce62ed75ec1ba9224a52a0` |
| gsc/_t-c-3.scm | `b8b4e6ef94679e669ba62324ad15ea2d05689fff393451f23dd8e0c5dccaa035` |
| lib/setup.c | `047e88c4561f9a95d770732ff13b942620824a1f74727b3f12ed170063239d46` |
| lib/_kernel.scm | `9afa811a1c15104b953a10d42cd11bddffbfa0b8684b4f8f8191d848fdb6d9ec` |
| lib/mem.c | `317b5262efd7f3a9418328250c163a9cf3fb9a44fbd573b08fde6f4a3cce2882` |
| include/gambit.h.in | `2bd9579c7124e0e18eec14180735621351d379a17410047b31b4b74fe2af9ac2` |
| Retained cumulative patch, HG12 | `8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d` |

`_gvmadt.scm` is bound as adjacent representation context; no new claim above
depends on treating its type declarations as an implemented export schema.

## Primary Infrastructure Evidence and Its Boundary

Official [MLIR Interfaces](https://mlir.llvm.org/docs/Interfaces/) explains
operation/dialect interfaces for exposing behavior to reusable infrastructure.
It supports explicit semantic interfaces; it does not supply Gambit continuation,
GC root or runtime-role laws. Official
[MLIR Pass Management](https://mlir.llvm.org/docs/PassManagement/) describes
analysis preservation/invalidation. It supports making dependencies explicit;
it does not validate the proposed HostGraph freeze/amendment protocol. Read on
2026-10-20; rolling web specifications are not local installed-tool evidence.

The earlier [paper-driven backend study](gambit-centered-backend-redesign.md)
and [shared-runtime literature ledger](gvm-shared-runtime-evidence.md) remain
the paper context for separating language semantics from native engineering.
Neither a paper nor upstream MLIR implemented the project-specific types here.
The concrete ownership decisions above are derived from the inspected Gambit
producer/decoder chain and are explicitly proposed refactors.

## Unresolved Register

| ID | What static research can settle | Evidence still needed; status |
| --- | --- | --- |
| HG-U01 | Current sources intertwine C emission and semantic point/frame creation | Complete selected-domain primitive, C-proc and embedded runtime-control census; extraction coverage unresolved |
| HG-U02 | 15 named assignments and their old containers/ordinals are visible; follow-up [entry contracts](runtime-role-entry-contracts.md) now locate bodies/producers, payloads and frame obligations | Explicit compiler anchor insertion, transformed identities and exact realized descriptors still unresolved; source-derived signatures are not native ABI qualification |
| HG-U03 | Existing cloning/comment/reachability behavior requires explicit preservation | All optimization passes preserve/export anchors, including merge/inline and externally reachable code; unresolved |
| HG-U04 | Current frame producer and scanner equations can be statically aligned | Independent root completeness and realized normal/task/internal capture/resume correctness; unresolved |
| HG-U05 | Semantic completion must precede physical planning | Full resource negotiation rules and finite amendment behavior for each provider; unresolved |
| HG-U06 | One common plan can define both C1/N1 products | Actual C/LLVM exits, linked mixed cycles, module/FFI setup, GC and lifetime receipts; E/A/SR gates remain unresolved |
| HG-U07 | Real deletion targets and structural work counters are specified | Zero old callers/fallbacks across the rebuilt cohort and measured net engineering/performance costs; unresolved |

No unresolved row is converted to pass by diagrams, matching schema names,
source hashes or agreement between two consumers of the same generator.
