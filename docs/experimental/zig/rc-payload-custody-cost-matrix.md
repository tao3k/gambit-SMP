# RC Custody Reconstruction: Modern C and Zig Maintenance Costs

Reviewed: 2026-10-20. Research only. Compare the same full custody, producer,
root, callback and shutdown capabilities in C-full and Z-full; C-ZT keeps the
modern C runtime with independent Zig tool/build choice. No LOC/person-day,
runtime or positive net-cost bound has been measured or established.
Read the [design](rc-payload-custody-design.md) and [source/paper ledger](rc-payload-custody-evidence.md).

The [root receipt and scan-retirement matrix](root-transfer-receipt-cost-matrix.md)
refines RCM04/05/08/09: a protected permit precedes membership mutation, a receipt
follows target-root publication, and facility retirement has a separate user cut.
These are the same underlying support costs, not additional savings to double-count.

## Necessary Support After Existing Reuse

| ID / obligation | Modern C-full / C-ZT | Z-full | Reuse / real retirement candidate | Zig-specific boundary |
| --- | --- | --- | --- | --- |
| RCM01 allocation identity/provenance | Generated or opaque custody records: base/extent/owner/deallocator and nested edges. | Same records; typed fields/slices/unions can express local shape. | Credit existing RC header and native allocation helpers. Independent-from-birth native cohort can retire old RC membership in either language. | No automatic lifetime proof; allocator-family/ABI bridge is additional Z work. |
| RCM02 synchronized RC/list authority | Reconstruct count/data/list/front-door operations with cleanup exclusion; final unlink under gate, free outside after actual users. | Same gate and native semantics, explicit atomic/order policy if selected. | Reuse header/allocator leaves; reconstruct direct RC entry points and keep free outside the short gate. No unsynchronized old back door. | Atomic integers do not solve membership/roots/force-free cleanup. Most work common. |
| RCM03 nested custody | Shared closure traversal/typed resource adapters; borrowed/shared children keep actual custodians. | Same graph/adapter policy; comptime tables may reduce local repetitive fields. | Reuse one TLS destructor's five-field cleanup and string/list funnels; not six independent new services. | Proving native-only closure and callback effects remains; generated C is matched alternative. |
| RCM04 prepare/commit/settle | Reserve target/R/receipts, one no-fail handoff cut, pre/postcommit failure distinction. | Same transaction state machine; errdefer helps private precommit rollback. | Credit joined-donor list splicing and successful-join checks; extend only with actual receiver/source conditions. | Lexical rollback cannot release target-owned custody after accepted commit. No affine transfer enforcement gained. |
| RCM05 managed root transfer | Gambit safepoint/root contributor handoff for actual data cells, scan/relocation writer discipline and VM lifetime. | Same Gambit contract and adapter; native no-GC implementation does not remove Scheme roots. | Preserve existing mark_rc/managed callback behavior until replacement is complete. | No Zig-specific removal of collector proof or root-map coverage; ABI can add work. |
| RCM06 raw alias/borrow closure | Migrate foreign pointer/address exports, TCP accept readers, managed psettings retention and external issuer protocols. | Same actual-user census and leases. | Existing Scheme retention is credited; replace wrapper-only authority only after cohort migration. | Neither language finds arbitrary escaped raw users automatically. Unknown exports block both. |
| RCM07 producer/cursor extraction | SourcePermit and pre-reserved cursor slots; snapshot and derived births counted through disposition. | Same capacity/failure protocol; explicit tagged state can help local handling. | Reuse I/J/N/D ledger and current release-origin adapters rather than invent another scheduler. | One shared service, not one saving per wrapper/registration. Capacity and failure review common. |
| RCM08 owner/worker dependency orchestration | Separate owner-affine/managed/native-only release phases; registry pins replace lock-held waits, counted continuations and effect/affinity profiles. | Same execution graph and profiles, plus C island for nonlocal exits if required. | Reuse qualified close/wait/library leaves; retire opaque delayed cleanup that hides owner/GC waits. | LLVM/Zig syntax supplies no executor progress or library callback proof. |
| RCM09 survivor/retainer shutdown | Actually transfer storage/list sentinels/root/provider users; independent cleanup and stop/join frontier. | Same survivor domain, allocator ownership, notification and outcome reader drain. | Existing receiving pstate is not automatically independent. Retire force-free ownership only for actually adopted cohort. | New Zig allocator is not a retention policy; additional domain support must be costed. |
| RCM10 evidence/change support | Shared generated transition tables, source identities, root/dependency census and negative cases. | Same evidence plus Zig tool/std/ABI evolution, generated representation and provider bridge review. | Source bindings/receipts are common controls; no engine/model/native witnesses added here. | Exhaustive enum handling can help; generated C switches and existing failure funnels reduce the marginal difference. |

## Maintenance Events and Cost Drivers

| ID | Event | Shared work / differential opportunity |
| --- | --- | --- |
| RCE01 | Add one TLS owned field or change string representation | Update nested closure/deallocator and source adopter/destructor/rollback; audit code/provider effects. Both generated C and Zig compile-time tables can derive related field plumbing; generator/support costs counted symmetrically. |
| RCE02 | Add an RC data-bearing callback product | Root ownership, actual data-cell scan/writer coverage, VM/marker/code return users and callback admission. Zig alone cannot remove those obligations. |
| RCE03 | Permit native tasks to outlive another owner domain | Re-evaluate every nested/borrowed/allocator/provider/user edge, target cleanup and source exclusion. Existing donor-splice C support is reusable only under its own join/drain conditions. |
| RCE04 | Move GC or pstate teardown earlier | Rebuild operational wait graph and producer cut, extraction capacity and retained state. Both designs must reject reverse owner/GC dependencies; a correctly pinned dead executor is still a dead executor. |
| RCE05 | Add raw export / another native executor | Define external borrower revocation and same-lane child behavior; synchronize old header APIs or migrate authority. No local type declaration supplies complete external-user closure. |
| RCE06 | Upgrade allocator/library/toolchain | Preserve header/layout/deallocator compatibility, effect/affinity profiles and code/root lifetime; add Zig-specific tool/ABI costs only to Z-full. LLVM provider decoupling is a common architectural benefit available to both. |

These events refine the previous WSM/WSU support ledger, not extra benefits to
sum again. Shared helper creation is counted once; subsequent real edits are
counted per maintenance horizon. Review obligations are not measured labor.

## Concrete Work and Storage Boundaries

| Item | Source-grounded denominator | What remains open |
| --- | --- | --- |
| TLS native allocation set | One context plus k live RC string fields, k in [0,5]; provider-owned objects and active server readers separate. | Actual live k/sharing/provider callbacks and selected library identity are not measured/qualified. One parent move cannot claim the whole saving. |
| String list | One RC list plus its actual live string references; duplicate allocation identities counted once with correct reference obligations. | No generic shallow-copy/release rule for shared children. |
| C closure | One RC code allocation with data root plus converter/code/return/VM users. | Actual code layout, scanner and callback/marker completeness; moving bytes is not a valid general transfer. |
| Handoff | h prepared handoffs each reserve work/custody before publication; adopted allocation set A and edge set E define closure review. | A private record is not necessarily a separate heap allocation; bounded reservation/counter overflow and contention need target-specific limits. |
| Still teardown | Public lists + all private cursors + issued creators/rollback/finalizer/derived permits. | Callback effects can generate further work; finite bound and full source census remain premises. |
| Shutdown | Per-resource outstanding actual users, managed roots, waiters/notifiers, code/provider and retained dependencies. | No finite-time drain guarantee from correct reference arithmetic alone. |

## Conditional Net Benefit

Let K be necessary post-reuse support RCM01--10 and E the actual maintenance
events over one declared horizon. For L in {C-full, Z-full}:

`Cost(L) = Support(L,K) + Migration(L) + RootAndDependencyReview(L)
         + ToolABI(L) + Sum(Change(L,e), e in E) + ResidualRisk(L)`.

Compare identical functionality, custody scope and failure policy. Common GC/
FFI/LLVM modernization benefit is evaluated separately against the current
baseline. C-ZT can already capture independently useful Zig tooling; it does not
pay for runtime language replacement unless that change is selected.

| ID | Positive condition | Refutation / current conclusion |
| --- | --- | --- |
| RCN01 | Bound recurring private precommit cleanup/state support which Zig actually eliminates after C helper/generator reuse. | Existing C funnel or generated table can reduce that difference to zero. No strictly positive lower bound is established. |
| RCN02 | Necessary components share one custody/producer/ledger layer with admitted per-type adapters. | Native-only, managed-root and owner-affine products have distinct root/effect obligations; consolidation cannot erase them or count one helper multiple times. |
| RCN03 | Lower bound on C-minus-Z support/change saving exceeds upper bound on Zig migration/ABI/tool/residual support cost. | No bound excludes a nonpositive result. Nested storage/root/callback work adds common cost and potentially additional ABI cost. |
| RCN04 | Independent-from-birth products remove old forced RC cleanup/list ownership for a real complete cohort. | This architectural saving is available to modern C too. Without complete raw-user/producer migration there is no actual retirement in either candidate. |
| RCN05 | Aggregate modernization value justifies the full reconstruction even before choosing implementation language. | Better custody/dependency boundaries are concrete mechanisms, not measured performance or a Zig-only benefit. Total and incremental theory gates remain open. |

This study exposes necessary work and rules out unsound shortcuts. It establishes
neither positive total net benefit nor positive Zig-specific increment; it
performs zero runtime replacements, worker qualifications or native experiments.
