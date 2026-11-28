# SharedRuntimeContract Source and Primary Evidence

Reviewed: 2026-10-20. Research HEAD
`b67da6262a973a0ae898002d5c7f5be2d8b5a90d`; vendor Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Selected working-source digests are bound by the accompanying receipt/map.
Baseline vendor, cumulative repair candidate, proposals and installed artifacts
are distinct. No model, compiler, native or performance execution.

## Source Cards

| ID | Inspected source / anchor | Fact and architectural implication |
| --- | --- | --- |
| RP-S01 | [setup.c](../../../vendor/gambit/lib/setup.c):480-719,1014-1110 | Priority/combining definitions, tree collective using processor_count, synchronized count special case, operation loop and interrupt reset. Replacing membership needs complete operation/request semantics; root registry alone is insufficient. |
| RP-S02 | [setup.c](../../../vendor/gambit/lib/setup.c):880-982,4665-4818; [header](../../../vendor/gambit/include/gambit.h.in):11670-11726 | Resize, worker exit/join and setup/cleanup are coupled to processor storage; processor owns VM/thread/sync fields. Execution context, GC worker and root-carrier separation is new design, not existing APIs. |
| RP-S03 | [mem.c](../../../vendor/gambit/lib/mem.c):674-827,3969-3991,6839-6863 | RC registration/data/refcount are direct operations; scanner marks h->data; inspected baseline call is P0-scoped. Native payload bytes and managed data differ; VM roots need explicit publication/update/last use. No universal fault inferred. |
| RP-S04 | [mem.c](../../../vendor/gambit/lib/mem.c):6511-6540; [header](../../../vendor/gambit/include/gambit.h.in):8059-8086,6580-6608 | Register/saved scanners and save/reload/clear, RA and continuation capture show real root locations and dynamic-environment custody. A token is not relocated data; roots must survive before allocation and be reloaded afterwards. |
| RP-S05 | [setup.c](../../../vendor/gambit/lib/setup.c):3276-3424; [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):1019-1071 | ___call constructs foreign return frame and matches unwind marker; return handler checks processor/origin validity. Native status alone cannot preserve arbitrary foreign control or revive an expired return. |
| RP-S06 | [c_intf.c](../../../vendor/gambit/lib/c_intf.c):6511-6570; [header](../../../vendor/gambit/include/gambit.h.in):10043-10060 | Marker allocation precedes target installation and contains a rooting TODO; marker invalidation and SFUN conversion/unwind are real operations. New entry must root incoming target before marker/conversion allocation. Candidate repairs are credited separately. |
| RP-S07 | [_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):85-149; [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):344-455 | GVM tracks frame liveness/closed variables; C target adds checks/materialization. Retain Scheme completion/FrameSpec authority before physical FR/SP realization; do not demand handles on every SSA value. |
| RP-S08 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):1355-1380,3638-3678 | Dynamic environment binding/restoration and continuation walker have explicit runtime/frame coupling. Native binding restoration is distinct from Scheme continuation/dynamic-wind semantics. |
| RP-S09 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):4505-4524; [prior wait evidence](owned-callback-wait-evidence.md):OW09/OW12 | Existing select wrapper materializes RA/registers and reloads. BW1 remains an admitted alternative to new parked membership; no arbitrary native wait gains GC permission automatically. |
| RP-S10 | [_t-cpu.scm](../../../vendor/gambit/gsc/_t-cpu.scm):162-179; [NJS design](njs-executor-storage-cleanup.md); [full architecture](modernization-system-architecture.md):sections 3/6-7 | Native instruction route still packages through C. Direct product and separated compiler service have old owners and transport/reaper costs; runtime product bind remains independent. |
| RP-S11 | [candidate patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):3160-3234,3439-3465,4352-4395,4470-4505 | Candidate adds per-processor RC scanning/root barrier and successful joined transfer; pending join retains storage and blocks further operations. Retained bytes do not establish next-GC enumeration/no-mutator state; full shared-runtime design addresses structural custody, not an already-qualified patch. |
| RP-S12 | [header](../../../vendor/gambit/include/gambit.h.in):11015-11090; [setup.c](../../../vendor/gambit/lib/setup.c):496-539 | Configured sync families, full-barrier macro, mutex/condition publication are explicit current mechanics. Their existence does not prove new C11/Zig gate/epoch lowering or validate plain races. |

These are bounded seams, not an all-primitive/all-platform census. RT entries
reference S01-S12 as shorthand for RP-S01-RP-S12. Code role claims require their
actual configured paths and rebuilt cohort; no native acceptance is imported.

## Primary Literature and Provider Cards

| ID | Primary reading / scope | Mechanism and limit |
| --- | --- | --- |
| RP-P01 | [Feeley/Miller PVM, 1990](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), frontend/backend discussion | Supports preserving semantic/target negotiation across backend separation. It does not specify SharedRuntimeContract or favor Zig over C. |
| RP-P02 | [Retrofitting Parallelism onto OCaml, ICFP 2020](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), compatibility/collector/C interface discussion | Runtime parallelism, GC and C interface assumptions are co-designed; serial cost and parallel benefit differ. The historical design/results are not current Gambit capabilities or transferable performance numbers. |
| RP-P03 | [LLVM statepoints](https://llvm.org/docs/Statepoints.html), relocation/base-derived and GC Transitions | Spill/maps and explicit relocated SSA uses are reusable. Presented strategy-specific GC-transition lowering is documented as unimplemented/no-op; Gambit entry/park/ack requires explicit integration. Rolling documentation is not a selected LLVM release witness. |
| RP-P04 | [ORCv2](https://llvm.org/docs/ORCv2.html), How to remove code | ResourceTracker/JITDylib lifecycle supplies provider removal mechanics. Scheme continuations, return origins and scanner/map readers still need project last-use evidence before removal. |
| RP-P05 | [MLIR effects/speculation](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/), Modeling / limitations | Effects and speculatability are distinct; nonlocal control is not fully modeled. New runtime-boundary effects and pass legality remain project work. |
| RP-P06 | [Zig 0.15.1](https://ziglang.org/documentation/0.15.1/), errdefer/error handling/C interoperation | Fallible cleanup is useful for ordinary native resource construction. This supplies neither affine token semantics nor cleanup for arbitrary foreign longjmp across Zig frames. |
| RP-P07 | [LLVM atomics guide](https://llvm.org/docs/Atomics.html), introduction/Acquire/Release | Volatile and atomic are orthogonal; release/acquire require matching synchronization. A real publication/drain protocol and pinned target lowering remain necessary. |
| RP-P08 | [OCaml 5.3 C interface](https://ocaml.org/manual/5.3/intfc.html), 22.12.1-2 / 22.5.3 | Thread registration, domain ownership and released native intervals are distinct. Released code cannot touch OCaml data; acquisition/release may run asynchronous callbacks/raise. Use as design lessons, not Gambit API equivalence or current pinned OCaml revision identity. |
| RP-P09 | [SysML 2.0 language](https://www.omg.org/spec/SysML/2.0/Language/PDF), requirement/part/constraint notation; [prior tool ledger](opensysml-modeling-evidence.md) | Parts and constraints can describe proposed before/after obligations. Model truth, transition completeness, weak-memory refinement and native correctness are separate; no tool/solver was run. |

Selected public documentation is rolling except the named versioned Zig/OCaml
pages and publications. Upstream source/library/target cohorts are not pinned or
qualified here. No upstream benchmark is reused as a cost input. Search/find
misses on underscored OCaml identifiers were resolved by the readable domain-lock
section; absence of a text match was not treated as absence of API.

## Derived Decisions and Remaining Evidence

RD/RT/HB/RC, metadata gate, epoch cuts, worker/context separation and the concrete
cost-event ledger are **our design deductions**. Source shows constraints; papers
show mechanisms and pitfalls. The snapshot model cannot derive location-set
coverage, no-mutator facts or full last-use closure from Boolean certificates.
These require explicit refinement, complete source-call coverage and later
independent native evidence. All Q-full requirements remain unresolved.
