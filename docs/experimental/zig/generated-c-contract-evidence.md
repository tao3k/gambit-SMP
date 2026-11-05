# Generated C Contract: Source and Primary Evidence

Selected working-source review only; native/compiler/model execution is absent. Exact identities/spans are in the [trace](generated-c-contract-traceability.json). Scheme/C planning and provider operation names in the companion documents are proposed, not already implemented.

| ID | Source anchors / selected observation |
| --- | --- |
| CS01 | [_back.scm](../../../vendor/gambit/gsc/_back.scm#L14), 14–118: target interface owns representation and primitive/call facts; dump consumes procs and C-interface/module information. A real negotiation seam, not the new contract itself. |
| CS02 | [_gvmadt.scm](../../../vendor/gambit/gsc/_gvmadt.scm#L1), 1–53; [_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm#L75), 75–138, 725–762: compact operand representation, explicit frame/live vectors and purification. Reuse Scheme data/analysis; new completion is still required. |
| CS03 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm#L344), 344–448, 3356–3365, 3735–3738: checks/reservations/root materialization intertwined with C emission; disabled SSB and real pair setters. |
| CS04 | [_t-c-2.scm transfer](../../../vendor/gambit/gsc/_t-c-2.scm#L1318), 1318–1420: return/call preparation, frame update and native jump form selection. Ordinary C calls are not a replacement proof for Scheme control. |
| CS05 | [mem.c RC](../../../vendor/gambit/lib/mem.c#L674), 674–829, 3969–3996; [marker](../../../vendor/gambit/lib/c_intf.c#L6511), 6511–6562; [os_dyn](../../../vendor/gambit/lib/os_dyn.c#L637), 637–675, 744–785: actual root/carrier lifecycle, pre-allocation TODO and conditional C-closure target support. |
| CS06 | [c_intf.c release](../../../vendor/gambit/lib/c_intf.c#L1683), 1683–1809; [mem.c sweep/teardown](../../../vendor/gambit/lib/mem.c#L4389), 4389–4455: native wrapper clear/release, nested strings and GC foreign destruction. |
| CS07 | [os_io.c](../../../vendor/gambit/lib/os_io.c#L950), 950–1008, 1468–1558, 1591–1669, 3929–3972, 4142–4160, 4550–4564: actual wait/abort/close and TLS setup/failure/shared destruction; leaves are reuse, opaque authority is migration work. |
| CS08 | [setup.c](../../../vendor/gambit/lib/setup.c#L4773), 4773–4828, 5888–5928, 5950–5978, 4839–4885: real VM setup, native service publication and cleanup users; immutable recipes are not live VM instances. |
| CS09 | [pthread adapters](../../../vendor/gambit/include/gambit.h.in#L10892), 10892–10915: existing native primitives; neither candidate needs a new synchronization library merely to share support. |
| CS10 | [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm#L337), 337–388, 1137–1216: actual C-interface consumption/clearing and module/count/constants/procedure product construction. A new module provider must replace these duties completely for its cohort. |
| CS11 | [_front.scm](../../../vendor/gambit/gsc/_front.scm#L225), 225–250, 3923–3959; [_ptree2.scm](../../../vendor/gambit/gsc/_ptree2.scm#L28), 28–38, 2093–2112, 2171–2182: pre-normalization seam, actual evaluation scheduling, transforms and C-interface registry collapse. HLO export needs typed FFI/order handoff. |
| CS12 | [gsc makefile](../../../vendor/gambit/gsc/makefile.in#L70), 70–80, 217–224: generated C compiler/link products are distribution material. Supports a maintained snapshot bootstrap design, not new reproducibility or ABI evidence. |
| CS13 | [retained patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3160), 3160–3234, 3433–3452, 4362–4385: existing joined-donor still/RC transfer and per-processor mark_rc placement are credited. Patch text is not loaded/native qualification. |

| ID | Primary reference and bounded use |
| --- | --- |
| CP01 | [MLIR C API](https://mlir.llvm.org/docs/CAPI/), Current status/Scope/Ownership: low-level core/pass interface and explicit handle ownership; no API stability guarantee or supplied Scheme dialect/control semantics. Compiler-service adapter dependencies remain project work. |
| CP02 | [LLVM GC integration](https://www.llvm.org/docs/GarbageCollection.html), Goals: compiler hooks do not supply collector, allocation, global-root/type-map registration or the Gambit runtime ABI. |
| CP03 | [LLVM statepoints](https://www.llvm.org/docs/Statepoints.html), relocation sequence and verification: post-safe-point values must follow relocation discipline; a stack map is not full mixed-provider acceptance. |
| CP04 | [MLIR effects rationale](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/), Overview/Modeling: CFG-region scope and incomplete nonlocal-control model. Custom Scheme control and gated transformations remain necessary. |
| CP05 | [Feeley/Miller PVM paper](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), section 2: bidirectional front/back representation/primitive/call negotiation motivates the seam. Its historical benchmarks and runtime details are not current Gambit evidence. |

| ID | Prior design reused / refined |
| --- | --- |
| DR01 | [hostgraph-generation-contract.md](hostgraph-generation-contract.md): Prior HostGraph/FrameSpec/PointId extraction and bounded negotiation; mandatory Zig placement is superseded by this mainline choice |
| DR02 | [runtime-role-entry-contracts.md](runtime-role-entry-contracts.md): Exact selected fifteen-role source-derived contract domain, not a full entry catalogue |
| DR03 | [native-service-support-design.md](native-service-support-design.md): Actual three-service caller/custody/retirement scope and retained native C reuse |
| DR04 | [single-source-native-profile.md](single-source-native-profile.md): Configure/M4 owns policy/probe production; Scheme consumes typed output without a new configure bootstrap dependency |
| DR05 | [zig-high-level-semantics-design.md](zig-high-level-semantics-design.md): Earlier pre-normalization export and structured FFI/evaluation-order requirements, with optional Zig ownership placement superseded |

All claims of generation, native control, collector correctness, retirement and cost benefit remain design conditions. New documentation does not evaluate registered ASCENT relations or create native witnesses. The companion cost matrix preserves the prior low-confidence labor estimate boundary.
