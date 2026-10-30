# Semantic Completion and Runtime Roles: Evidence Ledger

Date: 2026-10-20. Static source inspection; no backend implementation or native /
performance validation. [Operations](semantic-completion-operations.md),
[role contracts](runtime-role-entry-contracts.md),
[ASCENT research view](zig-research-chains.md).

Research HEAD `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`;
vendor Gambit HEAD `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
The DSL view binds the exact source hashes independently. Source observations
do not identify the current repaired overlay or establish its native status.

| ID | Source and inspected one-based scope | Established fact / extraction constraint |
| --- | --- | --- |
| SC01 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):575-645,725-820,1318-1398; [_front.scm](../../../vendor/gambit/gsc/_front.scm):2900-2998 | Incoming/exit frame selection, arity plan, return-register alias handling and poll masking belong before textual C emission |
| SC02 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):345-419,1120-1141 | Heap/flo/cache/SSB debts; Some(0) check semantics; combined checks false; ordered end-of-block checks |
| SC03 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):424-448,2527-2550 | Live/closed-dependent dirty cache materialization; F64BOX itself reserves flonum heap space |
| SC04 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):379-408,825-905; [header](../../../vendor/gambit/include/gambit.h.in):8495-8566 | Fresh private return-internal label, caller extent and mandatory saved roots; poll/heap macros pass label in temp1; zero requested check is not no-check |
| SC05 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):224-336; [mem.c](../../../vendor/gambit/lib/mem.c):7236-7278 | R03/R04 build complete internal extension before collecting services; stack-limit frame migration explicitly relies on that top-frame shape |
| SC06 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):123-237 | CFUN wrapper saves arguments/RA, uses arity+1 all-live return descriptor/link=arity and separate inline/OOL rendering |
| SC07 | [header](../../../vendor/gambit/include/gambit.h.in):10040-10061,10326-10374; [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):150-218; [c_intf.c](../../../vendor/gambit/lib/c_intf.c):6511-6570 | SFUN/CFUN payloads and error/unwind paths differ; marker construction contains an explicit potential-GC rooting TODO; no safety inference from scratch storage |
| SC08 | [header](../../../vendor/gambit/include/gambit.h.in):8110-8138,8172-8193; [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):342-496 | Invalid call, raw global cell, wrong arity and GET handler payloads; nonproc-global symbol search disabled under #if 0 |
| SC09 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):502-598 | Rest handler cannot collect with partial args; completes a parameter vector before Scheme heap-check helper; na=-1 processed entry |
| SC10 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):604-731 | Keyword defaults, reverse-position assignment, error ordering, local key array and final parameter reshape |
| SC11 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):737-976 | DSSSL and key/rest flags, optional strict rejection, rest construction and complete-vector slow path |
| SC12 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):2866-2895; [header](../../../vendor/gambit/include/gambit.h.in):8568-8573; [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):982-1015,1861-1920 | Force creates a private RETI point, undetermined-promise role entry, saved-state prologue and reentrant Scheme thunk algorithm; result resumes through temp2 |
| SC13 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):1019-1071; [setup.c](../../../vendor/gambit/lib/setup.c):3276-3395; [c_intf.c](../../../vendor/gambit/lib/c_intf.c):6511-6570 | Two-slot marker frame intentionally matches handler shape; processor/validity checks and matching nonlocal catcher precede frame removal |
| SC14 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):1075-1275; [header](../../../vendor/gambit/include/gambit.h.in):6570-6606,9218-9230 | Break pointer/tag, stack/heap RETN/RETI decode, copy/link rewrites and no-break-chain tail invariant |
| SC15 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):1281-1346; [header](../../../vendor/gambit/include/gambit.h.in):6570-6586,7113-7114,7159-7160,7207-7208 | Internal-return marker saves result, pops actual RA/all GVM registers and undoes CFS alignment; private descriptor is distinct from marker label |
| SC16 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):1355-1380,3638-3724; [setup.c](../../../vendor/gambit/lib/setup.c):5248-5251 | Dynamic-env post-thunk anchor and restoration; continuation walker compares that return and reads saved denv at normalized fp[-2] |
| SC17 | [header](../../../vendor/gambit/include/gambit.h.in):6570-6606,9220-9318; [mem.c](../../../vendor/gambit/lib/mem.c):3817-3845,3910-3975,6511-6540 | RA store/fetch break distinction, RETI size/map/link decoding, separate continuation/register/saved-root consumers; root completeness not implied by frame byte equality |
| SC18 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):365-377,508-512; [retained patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):46-106,209-280,390-435,802-854 | SSB TODOs remain open; patch distinguishes stack-only/complete frames, protects old ordinal prefix, snapshots/resets stack_check_only and changes wrong-processor C-return result/arity payload |
| SC19 | [mem.c](../../../vendor/gambit/lib/mem.c):7428-7514; [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):1964-2048 | Heap-section helper returns collection request; check-heap and rest-param-check-heap implement different complete-frame/raise/retry/resume paths |
| SC20 | [view loader](../../../src/gambit_smp/evidence_views.py):49-122; [clue exchange](../../../src/gambit_smp/trajectory_exploration.py):151-181,298-455; [DSL example](../../../evidence/scenarios/parallel-gc/design.ss) | Existing reference hashing, Scheme component/ASCENT evaluation and Clue projection can carry research dependencies without a new Python inference engine |

Per-role source construction identifies concrete anchors; it is not a compiler
dump of generated point IDs. Synthetic `(0)` calls are operands of ##c-code and
evaluate before its body. The new producer must replace that technique with
explicit anchor declarations and preserve external reachability through passes.
Runtime-role signature extraction is therefore source-derived design, while
exact transformed anchor/physical descriptor qualification remains open.

The [machine-readable view](../../../evidence/scenarios/zig-native/research.view.json)
records source facts, proposals, role/operation coverage, feasibility requirements,
retirement dependencies and benefit measures as separate entities. A missing
source reference fails exact loading; missing declared premises remain visible
in inference. Source hash agreement confirms identity, not truth of the manually
reviewed correspondence or a correctness proof of allocation reserve bounds.
