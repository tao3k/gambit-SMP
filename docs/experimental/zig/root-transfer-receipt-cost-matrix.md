# Root Transfer and Scan Retirement: Modern C and Zig Costs

Reviewed: 2026-10-20. Same complete root/RC/facility/cancellation capabilities in
C-full and Z-full; C-ZT retains a modern C runtime and independent Zig tooling.
No implementation, native testing, measured labor/latency or positive net bound.
See the [protocol](root-transfer-receipt-design.md) and
[evidence](root-transfer-receipt-evidence.md). These costs refine RCM/WSM support,
not extra benefits to sum again.

| ID / necessary support | Modern C-full / C-ZT | Z-full | Reuse / possible retirement | Incremental Zig boundary |
| --- | --- | --- | --- | --- |
| RTM01 complete GC/root entry adapter | Reconstruct direct GC, resize, root mutation, host entry and teardown admission. | Same actual caller coverage and native/runtime interface. | Credit existing Scheme write/reload and sync operation machinery; retire bypasses only for a fully migrated cohort. | No Zig-specific removal of source census or safe-point/root completeness proof. |
| RTM02 exclusive boundary and terminal epoch | Shared state machine with final acknowledgements, phase/borrower drain and held boundary. | Same state and sequencing; typed states can help local cases. | Credit current barriers and candidate queue/counter fixes without treating them as complete protocol. | Atomic syntax/types cannot prove full collector phase or raw-host progress. |
| RTM03 exact root manifest / writer law | Existing descriptor generator or opaque C records with canonical cell identity, extent/kind and target adapter. | Same semantics; compile-time products may reduce some representation plumbing. | Reuse Gambit physical map knowledge; a generated C table is a matched alternative. | No-GC native implementation does not remove managed root locations or relocation writes. |
| RTM04 permit / commit / receipt authority | Pre-reserved transaction records, generation validation, list commit and target publication, one resolution authority. | Same state machine and C/GC/OS ABI; enum/error unions may improve local handling. | Reuse constrained donor splice and allocation helpers; replace precommit receipt confusion and unsynchronized direct RC back doors. | No affine transfer enforcement or automatic postcommit ownership. |
| RTM05 failure retention / held VM | Source/target disposition, boundary quarantine, lost-response resolution, no guessed timeout rollback. | Same storage/root/VM/facility pins; lexical cleanup helps only private precommit resources. | Credit C cleanup funnels and previous I/J/N/D ledger. | Accepted/committed cross-thread lifetime cannot be handled by ordinary errdefer. Extra ABI/tool costs retained. |
| RTM06 facility entry / physical user drain | Serving/ClosingTransfers/future route/collector seal/drain/destroy; include queue writers/waiters/signallers and cached pointers. | Same lifecycle and OS/native primitives. | Existing scan locks and queues remain leaves; destructive cleanup becomes a proven-cut consumer. | A Zig allocator or mutex wrapper is not an independent lifetime proof. |
| RTM07 continuing GC / successor route | Keep needed GC available while managed users finish; admit future route or settle whole heap use before retirement. | Same driver/worker/VM/effect support. | Common modernization can replace PSTATE-tied carriers and old scan facilities; no runtime path retired here. | This decoupling is equally available to modern C and cannot be booked as Zig-only LLVM benefit. |
| RTM08 codegen / LLVM adapter | Translate Scheme/GVM or admitted backend metadata into shared root/effect contract; runtime retains collector ownership. | Same translation and provider/native bridging. | LLVM map/poll/relocation artifacts can be reused behind one contract in either design. | Provider registration, failure policy, compatibility and upgrade review remain necessary; generic LLVM benefit is common. |
| RTM09 construction / evolution evidence | One generated transition/manifest contract, reusable rollback funnel and change/source binding checks. | Same generator/trace needs; defer/comptime can reduce unavoidable local builder edits. | Count one common helper once, credit mature C support first. | Positive local saving needs a post-reuse bound; Zig compiler/std/ABI changes are additional work. |

## Maintenance Events

| ID | Change | Shared obligation and possible differential |
| --- | --- | --- |
| RTE01 | Add root-kind or RC-backed product | Exact cell/kind, hidden roots, canonical writer rule, target adapter and future ticket discovery. C generation and Zig comptime both have support/review costs. |
| RTE02 | Add collector/resize/foreign entry | Extend one admission authority and final acknowledgement domain; preserve direct call/exception/owner semantics. Tagged types do not find an omitted native call site. |
| RTE03 | Alter phase/queue completion | Recheck strong/weak/cleanup/resize publication and all queued/active/wait/signaller users. Both languages require the same collector refinement. |
| RTE04 | Replace facility / move teardown earlier | Validate successor route or no-future-heap-use proof, held permits and registry-lock-free drains. A root receipt never replaces these facts. |
| RTE05 | Upgrade backend/LLVM/library/tool | Bind root-map/effect ABI and relocation/resume rules; retain runtime registration and current native-provider qualification. Add Zig-specific tool/bridge work only to Z-full. |

## Symbolic Cost and Pause Boundaries

Let a be adopted allocations, r the canonical actual cells, m the affected
managed acknowledgements, k stable contributor domains, w old workers and u the
actual facility/heap users. These are workload denominators, not measurements.

| Work / storage | Required budget | Limit on the claim |
| --- | --- | --- |
| Preparation | Reserved transaction, manifest and dependency capacity; no successful permit without a bounded mutation plan. | Records can share allocation. Do not price one heap allocation per field/trace unit. |
| Exclusive boundary | Acknowledgement/writer drain + remaining old-epoch work + manifest construction/canonicalization + membership/publication + reload. | May pause all affected VM mutators; not necessarily a process-wide pause. No constant latency or speedup is established. |
| Root plan | Work depends on r, a and existing descriptor representation. Build canonical indices outside G/C/L while safe hold remains. | “Outside the mutex” is not “outside the pause.” No O(root-count) traversal hidden in G. |
| List mutation | Bounded batch plan under C; constant-size prepared manifest publication under G. | Per-header moves and whole-list splices have different work counts; bound the actual batch rather than claim constant work for every plan. |
| Failure retention | Actual r/a metadata and heap/VM/facility pins retained through known resolution. | Quarantine can be unbounded in time under failed actors. Correct custody is not finite drain. |
| Facility replacement | Drain w and all u users plus admit a valid future route/driver, or settle all heap dependence. | Header transfer alone supplies no independent VM, collector or GC-worker completion benefit. |

For a fixed maintenance horizon and identical capability/failure scope:

`ZigIncrement = Cost(C-full, post-reuse support + changes + migration + risk)
              - Cost(Z-full, same scope + its tool/ABI/bridge costs)`.

Common modernization value against the actual baseline is separate. C-ZT can
capture independently useful Zig tooling without runtime language migration.
Do not count one shared support reduction both as creation saving and repeated
per-resource saving.

| ID | Positive condition | Refutation / current status |
| --- | --- | --- |
| RTN01 | Bound remaining private construction/exhaustive-state edits genuinely lower in Zig after C helper/generator reuse. | Existing generated C/funnel may make marginal saving zero. No positive lower bound yet. |
| RTN02 | Shared root/receipt/facility support serves multiple necessary products without duplicating semantic adapters. | Different root kinds, callbacks and native exits retain their own qualification; shared schema is not shared proof of their semantics. |
| RTN03 | Conservative lower saving bound exceeds upper added migration/tool/ABI/retention/review cost. | No such bound is established. If common protocol work dominates and added Zig cost is positive, increment can be nonpositive. |
| RTN04 | Decoupled root carriers and qualified successor facilities actually retire old implicit PSTATE/scanner ownership routes. | Benefit is common to C-full/Z-full. No path is retired by this study and no successor is qualified. |
| RTN05 | LLVM adapter reuse reduces backend-specific support under the shared contract. | LLVM does not issue runtime receipts or collector shutdown proofs. Provider/root registration and upgrade cost still apply to both candidates. |

Proved native-only products may avoid a managed-root transaction, while retaining
actual list/scanner/cleanup fencing; this is a profile-dependent architectural
opportunity in both languages, not a measured or Zig-only pause saving.

The architecture now has a concrete sequencing and failure specification. It
still establishes no positive total or Zig-only net bound; all five full
architecture requirements remain unresolved. No native experiment is authorized
or performed by this study.

The [target-adapter cost refinement](target-root-adapter-cost-matrix.md) expands
RTM01/03/04/06/07 into concrete carrier routing, collector-context extraction,
seed/operation scopes and completion publication. It credits existing C support
and separates shared modernization from Zig-specific support removal; its costs
refine these rows rather than adding another independent support layer.
