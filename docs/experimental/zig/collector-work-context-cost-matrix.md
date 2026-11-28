# Independent Collector Work: Modern C and Zig Net Benefit

Reviewed: 2026-10-20. Compare equal complete capabilities: modern C-full,
C-ZT (modern C runtime plus useful Zig tooling) and Z-full. B0 is observed code;
Bmin is a control, not a limit on full reconstruction. No implementation, native
test, measured speed/labor or positive aggregate bound. Read the
[design](collector-work-context-design.md) and
[source/paper ledger](collector-work-context-evidence.md).
These rows refine TCM/RTM/RCM support; shared costs are counted once.

## Necessary Support and Retirement

| ID | Necessary support | Modern C-full / C-ZT | Z-full | Actual reuse / retirement and marginal value |
| --- | --- | --- | --- | --- |
| CWM01 | Explicit domains/field extraction | Opaque typed handles plus generated field/schema/access services. | Equivalent native records, explicit allocator, enum/error products. | Reuse Gambit semantics and existing helpers. Retire implicit worker-as-PSTATE dependence only after transitive users migrate. Language syntax does not remove field/alias/effect audit. |
| CWM02 | Copy arenas versus resume/storage ownership | VM extent service, worker cursors, owner-specific stack/buffer binding and single-count occupancy. | Same allocator/layout/GC contract with explicit owners. | Reuse section allocator and tagged copier, while replacing processor-only capacity/accounting reductions. Zig no-GC does not make native arenas or retained heaps free. |
| CWM03 | Request selection/combining ledger | Durable IDs, frozen round, legacy arbitration policy, checked demand sum and one fan-out. | Same identity/arbitration/demand/results; tagged records can reduce local invalid cases. | Current C already merges GC requests. No new benefit is earned for that existing behavior. Retire untracked local sop/result ownership only for qualified imports/callers. |
| CWM04 | Resize/startup/retirement role map | Parent-child scope, before/after membership roles, rooted startup data and result/exit obligations. | Same lifecycle plus qualified C control islands for nonlocal exits. | Credit candidate collective guard/result/startup/join work [CW-S11]. Independent W roster remains new support in both languages. |
| CWM05 | Root/frame task and publication fence | Existing Gambit frame decoder/capture logic behind owner/worker adapter, canonical writer tasks and root-ready ordering. | Same semantic adapters and C/frame ABI until full replacement. | Retire fake/mixed PSTATE and context-only root partitioning after completeness. Zig cannot infer hidden roots or replace frame semantics with ordinary slices. |
| CWM06 | Ready-work queue and termination authority | One T-serialized metadata service with private work permits, phase state, claims and qualified wake support. | Same service/ordering/census. Lexical helpers can reduce bounded local cleanup. | Reuse existing chunk payload/tracing and wait support; old direct enqueue/steal/decrement paths must retire. A simpler proof boundary can add contention; neither C nor Zig owns that gain/cost exclusively. |
| CWM07 | Later phases, effects and result publication | Will/table/sweep owner tasks, authoritative capacity result and percontext resume mapping. | Same phases and foreign-effect admission; typed internal results plus ABI adapter. | Existing vendor local overflow is not proved common outcome. A repaired fan-out needs semantic/native evidence; no false-success simplification. |
| CWM08 | Worker/facility failure and drain | Borrower/notification/task custody, stalled-worker exclusion and unresolved moving-epoch retention. | Same ledger/dependencies; errdefer covers only private preacceptance paths. | Reuse target-transfer/WaitContext shutdown support, count once. A dead worker's private heap work cannot be abandoned by automatic cleanup. |
| CWM09 | Concurrency/build/backend profile | Separate mutator/collector concurrency modes, CAS/lock capabilities, single-worker fast path and root-map provider checks. | Same semantics plus Zig compiler/standard/native ABI qualification. | LLVM metadata/lowering and multicore separation are shared modernization. Retire SINGLE_THREADED_VMS as a collector proxy only when all affected routes migrate. |
| CWM10 | Change proof/support inventory | Generated contracts, source/field checks and bounded maintenance event review. | Same semantic review; comptime may remove unavoidable product/schema duplication. | Compare against generated modern C after existing library reuse. No positive Zig margin follows from counting prospective C boilerplate that its generator already removes. |

## Maintenance Events

| ID | Change | Common work and differential to bound |
| --- | --- | --- |
| CWC01 | Add root kind/context/foreign alias. | Extend one schema and adapter, prove final physical roots/writer ownership and owner reload. Compare handwritten cases after generation in both languages. |
| CWC02 | Alter GC/resize request or outcome. | Audit arbitration/combining, selected RequestIds, parent-child membership, old Boolean/SCM ABI and all consumers. Typed enums do not establish source equivalence. |
| CWC03 | Alter forwarding/captured frames/phase. | Reprove local unpublished-work coverage, ready publication, frame fence and later-phase dependencies. Preserve native memory/control qualifications. |
| CWC04 | Change worker count or allocator policy. | Rebudget copy/resume/retained extents and fudge; partition K/S independently; preserve fixed W during each phase. Runtime pool reuse and C library reuse are credited equally. |
| CWC05 | Change cancellation/startup/close policy. | Audit all participants, borrowers, wake debt, unknown worker and partial relocation custody; shared service is charged once. |
| CWC06 | Upgrade LLVM/native compiler/Zig/OS ABI. | Revalidate map/frame/atomic/wait provider contracts. Charge additional Zig/C bridge/tool exposure to the designs that actually carry it. |

## Quantified Mechanisms and Cost Boundaries

Let u,k,s,w,o,r,q denote contexts, root domains, storage shards, workers, pending
requests, distinct physical root cells and generated trace work. Let b be ready
chunk batches, d actual dependency users and e relevant maintenance events.
These are symbolic workload units, not measured counts or promised bounds.

| Mechanism / quantity | Conditional work / cost | Boundary and disproof case |
| --- | --- | --- |
| Root/worker decoupling | Root discovery covers k/r; tracing uses w independent native contexts. | May use multiple collector workers for one mutator, but does not parallelize every continuation task or guarantee balanced graph work. U=1 with old single-thread CAS removal is invalid. |
| Request work | O(o) represented membership/demand/fan-out bookkeeping for a frozen selection, plus retained arbitration policy cost. | GC combine already exists. Resize child plus queued GC cannot be counted as one eliminated collection without a new subsumption proof. |
| Field support | 34 selected mem declarations classified, plus external helpers/VM fields. | 34 is a correspondence denominator, not 34 removed fields, handwritten modules or proven support savings. Transitive consumers remain open. |
| Work/queue state | O(w+k+s+queued batches) metadata under the proposed representation, plus actual root descriptors and extents. T is crossed per bounded publication/claim/state batch. | A single T may serialize the hot path. No one ledger allocation per object is assumed; payload scans stay outside T. Batch size changes latency and exposure. |
| Storage budget | Distinct live/reserved extents for ContextResumeArea(U), CopyArena(W), retained shards and actual overlap/fudge policy. | Simply replacing 2u initial sections by 2w omits owner stacks; blindly summing both can double-count shared extents. Exact allocator budget unresolved. |
| Runtime pause | T_ack(U,K,P) + T_root(K,W) + T_trace(q,W) + T_weak/effects + T_heap/resume(U). | Independent W may reduce the trace part while adding queue/copy/slack overhead; no overall latency upper bound or speedup established. |
| Retention | Live copied heap + root/extent/worker/queue/transaction/facility dependencies. | O(w) native contexts does not bound bytes retained by a failed moving epoch. Unknown work can pin the VM. |
| Maintenance | One reused service cost + per-root/operation adapters + e source/schema/semantic/native-order changes. | Counting the same executor/wait/ledger in every component inflates costs; attributing their shared retirement only to Zig inflates savings. |

Under the restrictive same-work assumption, if f of baseline pause is genuinely
parallelizable and h(w) is extra normalized overhead, ideal speedup is bounded
by 1 / ((1-f) + f/w + h(w)). No f or h is measured here, and changed allocation,
work ordering or graph work can invalidate that comparison. Root counts alone
do not determine f; source-level architecture has no numeric speed claim.

| ID | Positive condition | Countermodel / current decision |
| --- | --- | --- |
| CWN01 | Total reconstruction pays when retired implicit context/worker/storage coupling and simpler evolution exceed request/root/queue/migration/qualification and retention costs. | Keeping old implicit paths plus a second worker service duplicates authority. No path is actually retired here; AG05 remains unresolved. |
| CWN02 | Zig margin pays when post-reuse unavoidable C builder/helper/review work avoided exceeds Zig tool/ABI/control-island and residual support costs. | Generated opaque C services have the same semantic cases; Zig adds a bridge without retiring support. No positive lower bound; AG06 unresolved. |
| CWN03 | Shared support amortizes over real target-root, request, WaitContext and shutdown clients with one authority/implementation. | Several wrappers delegating to different unretired authorities are not reuse. Required adapters and semantic proofs are retained. |
| CWN04 | Independent workers are valuable when real workloads benefit from W separate from U after root/allocator/termination/owner qualification. | Root/phase serial work, contention, copy buffers or stalled-worker retention dominate. Theory supplies a mechanism, not a workload or native speed result. |
| CWN05 | LLVM leverage reduces repeated provider layout/map/lowering support behind stable Gambit semantic/runtime contracts. | LLVM does not supply this worker/GC/request runtime [CW-P04]. Shared backend leverage is not Zig-only economic evidence. |

Price each capability with explicit units: reusable support and handwritten
change/review effort; tool/ABI migration exposure; runtime latency/space under
workload assumptions. Do not add labor, seconds and bytes as an unweighted scalar.
Both C-full and Z-full must satisfy the same root, phase, request/result and
physical lifetime obligations. The source result gap strengthens the need for a
common runtime contract; it does not by itself select an implementation language.

The [capacity/result cost refinement](gc-capacity-result-cost-matrix.md) expands
CWM02--04/07/08 into actual outcome publication, resize stage roles, still-credit
custody and interval/peak accounting. It credits the source C guard/result/refund/
headroom mechanisms before estimating residual support. These rows refine this
shared support rather than adding another independent cost or benefit layer.
