# Target Roots and Collector Entry: Matched Cost Matrix

Reviewed: 2026-10-20. Same complete Gambit capabilities in C-full and Z-full.
C-ZT retains the modern C runtime with Zig engineering tooling where useful.
B0 is current code; Bmin is only a bounded control, not the architecture ceiling.
No implementation/native tests, measured effort or positive cost bound.
See the [design](target-root-adapter-design.md) and
[source/primary ledger](target-root-adapter-evidence.md).
These rows refine RTM/RCM/WSM support; do not sum the same support again.

## Necessary Support After Reuse

| ID / support | Modern C-full / C-ZT | Z-full | Actual reuse / retirement condition | Zig-specific marginal boundary |
| --- | --- | --- | --- | --- |
| TCM01 carrier + RC ownership router | Opaque carrier/handle service; native list, tagged word, provenance and destructor routing. | Same C payload/GC ABI; tagged native records can simplify private cases. | Reuse header/list allocation and constrained donor splice [TR-S01/S14]. Retire PSTATE ownership only when all register/ref/data/free/cleanup clients migrate. | Zig does not discover raw legacy users or make refcounts atomic/lifetimes affine. Extra bridge remains if opaque handles cannot replace raw ABI. |
| TCM02 exact manifest + root kinds | Generated C descriptors, compact arrays, canonical writer mapping and leases. | Equivalent descriptor product, explicit allocator and compile-time validation where possible. | Reuse Gambit tagged tracing/descriptor knowledge; no duplicate Scheme semantics. Replace ad hoc target scan callbacks only after full root coverage. | Comptime may remove some private schema plumbing; generated C can do the same. Bound post-generator edits before credit. |
| TCM03 worker context + seed accounting | Extract PSTATE/TLS/heap/queue dependencies; explicit epoch/seed ownership and active accounting. | Same collector algorithm and dependency extraction behind native ABI. | Reuse mark_array/forwarding and current queue barriers/condition variables [TR-S01--03/S09]. Retire retired-PSTATE scanning when independent context is qualified. | Major modernization value is shared. Zig syntax does not eliminate phase/termination proof or queue synchronization. |
| TCM04 complete operation admission | Common public adapters, guarded private bodies, combined request/participant identity and resize child scopes. | Same request/phase/state machine, enum/error unions for internal outcomes. | Reuse current sync priorities, combining and Scheme saved-state paths [TR-S04--07/S11]. Retire bypasses/duplicated admission for bound cohort only. | Fewer local unchecked variants possible; caller census, scheduler obligations and old ABI semantics remain. |
| TCM05 completion -> registry publication | One opaque native completion service with release/acquire or qualified mutex synchronization, G-protected registry/receipt commit. | Same one-sided atomic service or proved native mapping; avoid shared unqualified atomic structs. | Reuse permit/transaction/resolver and I/J/N/D debt support from preceding studies. No extra coordinator per component. | Ordinary errdefer does not resolve postcommit cross-thread custody. New Zig/C ABI/order/tool review is a real cost. |
| TCM06 closing descendants + physical drain | Enrollment/close arbitration, pending transfers, real borrower pins, successor route and all-exit retention. | Same dependency graph and lifetime protocol. | Reuse resource-indexed lifecycle and WaitContext support. Retire unconditional cleanup only when every actual user has a valid final cut. | Zig no-GC does not remove managed-heap retention or unknown-state quarantine. No language-specific progress proof. |
| TCM07 old outcome ABI + exceptional control | Preserve bool overflow/SCM error contracts, rooted pending requests, C exception islands where needed. | Keep narrow C control islands and typed internal results across admitted bridge. | Credit existing W_ALL/R_ALL and return/error funnels [TR-S04--07]. Wrapper retires only if all generated/foreign imports switch. | Extra bridge/control containment can outweigh local builder savings; never count Deferred=false as simplification. |
| TCM08 source/generated/provider evolution | One schema, source census, generated counterpart review, profile/source binding and provider metadata admission. | Same evidence/regeneration plus Zig compiler/std/native ABI updates. | Reuse descriptor generators and LLVM maps/lowering; old C emit/layout routes retire only after equivalent profile acceptance. | LLVM reuse is shared C/Zig value; positive Zig margin requires support actually absent in C-full after generation/mature-library reuse. |

## Maintenance Events and Units

| ID | Change event | Work that remains in both / differential to estimate |
| --- | --- | --- |
| TCE01 | Add RC product, nested payload or root kind. | Audit actual aliases and effects; extend one schema/router/adapter. Generated C and Zig product cases are matched; count added handwritten branches after reuse, not raw lines. |
| TCE02 | Add allocation/resize/module entry. | Update source inventory and ABI/body-admission closure, saved-state/result mapping and request combining. A typed interface still needs the same new caller proof. |
| TCE03 | Change collector queue/phase/work domain. | Reprove seed-active accounting, derived work publication, later-phase terminality and context macros. No root-count-to-speedup shortcut. |
| TCE04 | Change close/cancellation/failure disposition. | Audit every custody cut and physical user; shared resolver/ledger avoids duplicate support. C and Zig both retain unknown/quarantine/progress obligations. |
| TCE05 | Upgrade backend/LLVM/Zig/native tool ABI. | Revalidate descriptors and providers in both; Zig-specific toolchain and C bridge work is charged to Z-full/C-ZT as incurred. No invalidation of semantic Scheme artifacts unless their contract changed. |

Necessary native support may be shared by root transfer, delayed release,
WaitContext and shutdown. Charge a common executor/byte store/transaction/ledger
once per architecture, plus each component's adapters and maintenance exposure.
The former NJS reuse question does not make collector or root semantics a free
consumer of that support. If C-full can reuse the same mature helpers/generator,
the eliminated duplicate support belongs to modernization, not to Zig alone.

## Quantified Boundaries Without Invented Numbers

Let r be distinct actual root cells, a adopted headers, w seed workers, q derived
trace work, b actual borrowers, h pending handoffs and e maintenance events.
These are symbolic units, not measurements or asserted capacity limits.

| Quantity | Conditional accounting | Benefit boundary |
| --- | --- | --- |
| Manifest storage | O(r) cell descriptors plus carrier/transaction identities and actual pins. | Coalescing contiguous cells can reduce descriptors only after extent/writer equivalence. Object-value deduplication is invalid. |
| Seed dispatch | O(r + w) bookkeeping for explicit cell partition plus collector-dependent q. | Each physical cell needs visiting; this replaces discovery ownership rather than removing tracing. Unequal graph work remains [TR-P03]. |
| Transfer mutation | Prepared batch work O(a) for individual relinks, or bounded splice for a proven whole-list move; target publication may swap a prebuilt manifest handle. | No arbitrary list traversal/allocation hidden inside G. Existing donor splice gets full credit. Manifest rebuilding may still cost O(r) during the held cut. |
| Boundary delay | Remaining admitted epoch/resize + final acknowledgement/borrower drain + manifest work + bounded C/G commit + reload. | Finite tail requires every participant/resolver to progress. No pause upper bound from counters, root partitioning or language choice. |
| Retention | Bytes in live carriers + manifests + handoffs + pinned heap/code/provider/facility dependencies. | Unknown state can pin whole VM without finite bound. O(h) records does not imply O(h) retained bytes. |
| Entry wrappers | One authoritative service plus actual ABI adapters and cohort enforcement. | Do not price one runtime allocation per textual hit or treat 58 symbol lines as 58 wrappers. |
| Maintenance | Shared helper cost once + per-adapter work + e source/schema/ABI/proof changes. | Required qualifications are common work, not avoided just because native code is in Zig. |

| ID | Net-benefit condition | Refutation / current status |
| --- | --- | --- |
| TCN01 | Total modernization pays if lower retirement/ownership duplication and safer evolution outweigh new admission, carrier, context, migration and retention costs at equal capabilities. | Keeping old PSTATE scanner/ref/free routes and adding a second registry leaves duplicate responsibility. No full path is retired here; total gate remains unresolved. |
| TCN02 | Zig increment pays if unavoidable post-reuse C helper/edit/review work saved exceeds Zig/C ABI, tooling, migration and residual support costs. | Generated opaque C service has the same number of handwritten semantic cases; or Zig keeps C islands plus wrappers and saves no common helper. No strictly positive lower bound established. |
| TCN03 | Shared support amortizes only when several necessary users actually consume one runtime implementation and adapters stay smaller than removed duplicate support. | Charging existing Scheme/C facilities as nonexistent, counting hypothetical components or counting shared LLVM savings twice invalidates the calculation. Usage and bounded labor remain unresolved. |
| TCN04 | Independent worker/root ownership is valuable if qualified carrier/context separation removes concrete lifecycle coupling while retaining correct roots/GC/continuation behavior. | Reusing retired donor PSTATE, changing Scheme/GC semantics accidentally or retaining whole VMs in unknown state can erase the gain. Native progress and retention bounds unresolved. |
| TCN05 | LLVM leverage reduces provider-specific work behind a stable shared runtime contract, independently of native implementation language. | Assuming LLVM supplies root registry, collector or RC transaction omits necessary work [TR-P02/P04]. Shared value is credible mechanism, not proved economic gain or Zig-exclusive credit. |

For language L, budget K(L) = common reused support + residual handwritten
adapters + migration/retirement + source/semantic/order qualification + tool/ABI
maintenance + runtime pause/retention exposure under stated workloads. Compare
K(C-full), K(C-ZT), K(Z-full) at equal capability, without mixing labor units and
latency/bytes into an unweighted scalar. A positive net lower bound requires
explicit workload/change frequencies, valuation and uncertainty intervals.
No such bound is supplied by this source-only study; AG05 and AG06 stay open.

The next research gap is a concrete collector-context and combined-request
refinement, plus a bounded post-reuse support inventory. Neither a generic
“modern language” claim nor another wrapper earns admission to the architecture.
