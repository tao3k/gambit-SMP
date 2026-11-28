# Modern Generated C: Cost Scope and Responsibility Matrix

The current [modernization matrix](map-generated-c-modernization-matrix.md)
supersedes human-day estimates as the research decision criterion. The numbers
below are preserved historical planning estimates, not the reason to select
modern C or reject Zig. Judge the architecture by new runtime/compiler
capabilities, actual retired responsibilities, semantic guarantees and ongoing
runtime/space/upgrade costs.

Design-only cost refinement. This does not establish measured labor, speedup or positive project ROI. The baseline is the [25-task service WBS](native-service-support-costs.md), whose source-informed author ranges remain low-confidence planning estimates. The present design chooses a realization and allocates existing scope; it does not add those estimates to themselves.

GC01. The six shared modern-C work packages are funded once for all three services. This design makes their products explicit:

| Prior WBS | Concrete common product/work | C workdays already priced | Reuse / non-duplication |
| --- | --- | --- | --- |
| S01 | Contract/operation/owner/caller inventory for selected service cohort | 8–16 | One implementation; domain-specific policies remain |
| S02 | Scheme schema, typed C records/statuses and descriptor rendering | 8–16 | One implementation; domain-specific policies remain |
| S03 | Native allocation, checked sizing, local cleanup and distinct storage adapters | 5–10 | One implementation; domain-specific policies remain |
| S04 | Qualified native access/synchronization and status adapters | 4–8 | One implementation; domain-specific policies remain |
| S05 | Service build/bootstrap/product integration | 3–6 | One implementation; domain-specific policies remain |
| S06 | Independent reader hooks, IDs, diagnostics and source/product correspondence | 6–12 | One implementation; domain-specific policies remain |

GC02. Service policy/adapter/qualification work is in the corresponding service subtotal, not hidden in the shared generator budget:

| Scope | Previous C planning range, workdays | Contract/generator responsibility | Native C responsibility still required |
| --- | --- | --- | --- |
| Shared support | 34–68 | Schema/projection, checked products, descriptor/manifest and support hooks | Native primitive adapters and independent qualification framework |
| RootRegistry | 36–72 | Root/carrier/transfer operation shapes, root descriptors and typed adapters | Stable storage, owner/scan/reader epochs, transfer, marker and teardown enforcement |
| BarrierLog | 46–92 | Store/root/init/weak/CAS/bulk variants, explicit preparation/commit operations | Bounded reservation, memory ordering, visibility, epoch handoff/drain/reset |
| ReleaseCoordinator | 56–112 | Attempt/task/outcome shapes and owner/effect/custody recipes | Actual wait/wake, accept/cancel, native staged effects, nested storage and shutdown |
| **Known service scope** | **172–344** | **No extra generator subtotal added** | **Still not a whole-runtime modernization budget** |

GC03. The present architecture extends beyond those three services. The following are newly explicit program work scopes, not new zero-cost promises or bounded labor estimates:

| ID | Additional work outside previous service subtotal | Source / why it is separate | Current cost status |
| --- | --- | --- | --- |
| XC01 | Full GVM semantic completion, frame/control and required runtime-role extraction | CS02–CS04; prior HostGraph/15-role scope. B04 prices selected store-client migration, not every call/frame/check/control path | Unestimated additional scope; no finite upper bound established |
| XC02 | Whole-cohort C host/module/role binding renderer and bootstrap migration | CS08/CS10/CS12. S02/S05 price service products/builds, not complete targ-dump replacement | Unestimated additional scope |
| XC03 | Early high-level Scheme export, ordered binding/effect/FFI handoff and transformed-result importer/validation | CS11 and DR05. GVM-to-native service products cannot reconstruct lost lexical/foreign structure; transformed graphs need fresh completion | Optional provider scope, unestimated |
| XC04 | Scheme MLIR dialect, custom control/effect semantics, pass/verifier and compiler-service adapter | CP01/CP04. C API does not supply those semantics; choose one transport if needed | Optional provider scope, unestimated |
| XC05 | Direct LLVM maps/relocation, mixed-call/control and module acceptance | CP02/CP03 plus CS08. Existing C frame protocol does not automatically qualify LLVM native frames | Optional provider scope, unestimated |
| XC06 | Unknown raw native/foreign callers, new target callback support and proof failures | CS05–CS08; earlier retained patch is credited, not relabeled as full closure | Explicit unknown tails in each selected route |

The mainline program cost is `172–344 service workdays + actual selected additional scopes`. Do not label 172–344 as the cost of the entire generator/backend/collector reconstruction. Shared semantic work may benefit multiple providers, but cancels only when scope and realization are actually the same. A full Zig alternative would also need its emitter/ABI/native migration and independent program costs; this update does not expand the prior 4–56-day scoped difference into a whole-runtime conclusion.

GC04. Quantitative reporting and refutation remain separate:

| Benefit or cost axis | Concrete quantity / condition | Present evidence boundary |
| --- | --- | --- |
| Shared support maintenance | One authoritative schema and one shared support implementation for the three selected clients | Architecture decision; no claim that three existing separate libraries have already collapsed |
| Old semantic authority retirement | Zero remaining selected callers of old C-scanner check/root/role inference before deleting that responsibility | Caller and semantic/native acceptance still required; currently zero paths retired |
| C renderer replacement | Old targ-dump route no longer used for a completely converted cohort; a new C renderer still invokes a native C frontend | No build-time saving follows from renderer replacement alone |
| Direct LLVM provider | Zero generated C host/frontend invocations for its fully converted code cohort | Adds IR/pass/object/map acceptance work; no measured compile/runtime ratio |
| GC workload benefit | The earlier sum(s*(k-1)) conditional payload-copy result belongs to the selected collector in either native realization | Not a generator or language-exclusive speedup |
| Native correctness and safety | Complete roots/writers/control/owner/custody and matching producer/reader interpretation | Generated types, state tables and digests do not prove the global properties |
| Full lifecycle economics | Value of admitted capabilities and actually retired maintenance exceeds all funded service/program/migration/upgrade costs | No positive full-project lower bound established |

GC05. Retire duplicate semantic responsibilities, keep useful C leaf algorithms, and preserve independent oracles. C-G is the mainline choice because it can directly reuse current C producers/native APIs while funding the missing contracts. It is not a claim that old code is already modern or that language migration is inherently impossible. Sources justify work and reuse; all labor numbers above retain the previous human-estimate boundary.
