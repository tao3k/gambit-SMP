# Completion Admission: Anchor, Reserve and Helper Source Evidence

Date: 2026-10-20. Static research and downstream Evidence-DSL consistency only;
no compiler/backend implementation, native workload or performance validation.
See [anchor preservation](gvm-anchor-preservation.md),
[allocation/helper contracts](allocation-reserve-helper-contract.md) and
[research queries](zig-research-chains.md).

Research HEAD reread: `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`.
Vendor Gambit HEAD reread: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
No overlay was applied; vendor observations are not current repaired-binary
acceptance. Exact hashes are bound in the registered research view.

| ID | Direct source / inspected scope | Finding and qualification boundary |
| --- | --- | --- |
| AR01 | [_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):488-553,725-827,1072-1102 | Clone/comment sharing, iterative purification and entry-seeded dead-code traversal require explicit external anchor authority |
| AR02 | [_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):1105-1490 | Common-code equality can merge return/simple labels; common-tail extraction creates new frame/label/comment state. No new anchor-preservation guarantee exists |
| AR03 | [_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):1492-1544 | One recorded predecessor can permit jump fusion; runtime external entry is not represented by that count |
| AR04 | [_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):1548-1733,1735-1866 | Ordering starts at ordinary entry, schedules references and renumbers; linearization/frontier analysis follows. DCE roots alone do not close output coverage |
| AR05 | [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):110-183; [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):345-448,1120-1141,2527-2550 | Compiler 4096-word budget, pending reservations and boxing/check sequencing are separate from runtime physical reserve |
| AR06 | [mem.h](../../../vendor/gambit/lib/mem.h):9-79 | Maximum params/args/frame slots, msection fudge and VM overflow reserve have explicit source formulas; formulas alone do not prove contiguous slow-path finish space |
| AR07 | [header](../../../vendor/gambit/include/gambit.h.in):3110-3168,3269-3366,5309-5325,8544-8566 | Representation-dependent body/boxing costs, direct vector/pair allocation macros and heap predicate; no reservation enforcement inferred from unused macro amount |
| AR08 | [mem.c](../../../vendor/gambit/lib/mem.c):486-506,4525-4582,4801-4802,6350-6497 | Free-space approximation excludes global overflow reserve, soft limits exclude fudge, collector consumes/replenishes overflow reserve. Local headroom is a distinct obligation |
| AR09 | [mem.c](../../../vendor/gambit/lib/mem.c):7104-7411,7428-7503,3363-3390 | Heap/stack section helpers change pointers/limits; stack routines can move frames without a direct collector call in their bodies |
| AR10 | [mem.c](../../../vendor/gambit/lib/mem.c):370-386; [header](../../../vendor/gambit/include/gambit.h.in):6147-6283,10904-10905 | Allocation lock selects no-thread/mutex/ticket variants. Blocking/spinning and selected debug/OS behavior are separate from no-GC classification |
| AR11 | [setup.c](../../../vendor/gambit/lib/setup.c):1014-1201 | OP_NOOP service can participate in winning GC/resize collective; processor-zero error can throw after loop; garbage_collect is a collective wrapper |
| AR12 | [setup.c](../../../vendor/gambit/lib/setup.c):170-255 | Interrupt service invokes registered execute_fn callbacks, returns status/interrupt code and refreshes stack-trip state; dynamic callback effects require their own closure |
| AR13 | [setup.c](../../../vendor/gambit/lib/setup.c):839-855,3276-3395; [c_intf.c](../../../vendor/gambit/lib/c_intf.c):6511-6570 | Nonlocal throw, foreign marker matching and known marker-rooting TODO remain explicit shared-runtime constraints |
| AR14 | [MLIR side-effect rationale](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/), Modeling; [LLVM statepoints](https://llvm.org/docs/Statepoints.html), Safepoint Semantics & Verification | Memory-effect machinery is not complete nonlocal-control semantics; relocation requires explicit post-safepoint treatment. Rolling upstream specification observations, not installed-tool or Gambit integration receipts |

The AR14 discussion is an interpretation of primary upstream specifications
read on 2026-10-20. The DSL binds the local reviewed evidence note and URLs;
it does not claim to pin upstream web bytes/version or identify installed LLVM.
The first attempted MLIR interface-specific URL was unavailable; the accessible
official rationale above is the actual supporting source.

## Rechecked Content Identity

| Source | SHA-256 |
| --- | --- |
| vendor/gambit/lib/mem.h | `4cde6fb9ce310d6c769c94c9f2b70b30e06ca025e436064d715a45b41d9c3331` |
| vendor/gambit/lib/mem.c | `317b5262efd7f3a9418328250c163a9cf3fb9a44fbd573b08fde6f4a3cce2882` |
| vendor/gambit/gsc/_gvm.scm | `a1160027e78b7ee75bb6f89094f658cd518d75c1a133f681d1832966a5e611c9` |
| vendor/gambit/gsc/_t-c-1.scm | `cd9030133390377167b2b29ad5f06f3854606e762a8a7cb44d932b62127d6b0a` |
| vendor/gambit/gsc/_t-c-2.scm | `27d9cc50c6331a0e526c09e029f68153b7fb4bf0e8ce62ed75ec1ba9224a52a0` |
| vendor/gambit/lib/setup.c | `047e88c4561f9a95d770732ff13b942620824a1f74727b3f12ed170063239d46` |
| vendor/gambit/include/gambit.h.in | `2bd9579c7124e0e18eec14180735621351d379a17410047b31b4b74fe2af9ac2` |

## Evidence Levels and Still-Open Gates

The new source-audit premises record located transformation obligations,
reserve equations and selected direct helper effects. They have **static-source**
witnesses. Existing Q-anchor (backend transformation), Q-reserve (native-semantic
bound) and Q-helper (helper closure) keep their original stronger evidence
classes and remain open. No evidence class is weakened to count this research
as qualification.

The possible argument-root-window redesign is a separate deferred alternative
with an additional root-input/publication/lifetime requirement. It does not
become an unexplained prerequisite of the selected first cohort. The research
graph distinguishes shared current dependencies from optional future choices.

Remaining source/native obligations: all external anchor producers and consumers;
AP01-AP09 transformation controls; realized allocation cost and slow-edge/local
headroom correspondence; profile/OS/debug/indirect helper closure; collecting
callbacks, nonlocal unwind and moving-root reloads; actual frame/host/GC/runtime
composition. Neither static arithmetic nor an ASCENT fixed point executes G3 or
establishes a runtime allocation bound.

The downstream Scheme rules additionally check the no-handles conditional
reserve equations and the finish-versus-fudge comparison. Their result is
research arithmetic only. It does not change native requirement classes or
assert a reachable overflow. A separate wrong-arithmetic control is required.
