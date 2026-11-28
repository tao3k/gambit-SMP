# Still and Tail Services: Matched Net-Benefit Matrix

Reviewed: 2026-10-20. Theory/design only. See the
[design](still-construction-tail-design.md),
[source/paper ledger](still-construction-tail-evidence.md) and
[trace map](still-construction-tail-traceability.json).
No implementation/native measurement, checked proof, retired path or positive
economic bound is established.

The [InitSpec/SegmentLayout report matrix](init-spec-segment-layout-cost-matrix.md)
expands constructor endpoints, copied-prefix/context next-GC reachability,
allocation spans and exact statistic views. It credits generated modern C before
Zig savings and charges sparse metadata, no-fill refinement and retained native
islands explicitly. Common modernization and Zig-specific value remain separate.

## Fair Alternatives and Necessary Support

B0 is the inspected processor-owned C path. C-full (C-G in the earlier matrix)
is an equally modern C service using generated descriptors, opaque handles,
typed wrappers and mature synchronization/allocation helpers. C-ZT retains that
C runtime with useful Zig toolchain/build support. Z-full implements the same
native heap service in Zig. Bmin is a control, not the ceiling of modernization.
Credit C's existing deferred accounting, aligned allocator, refcounts, root
save/reload, subtype scanning, donor transfer and chunk handling before counting
any replaced support. There is no advantage from comparing Zig to unrefactored C
while denying C-full the same service/descriptor architecture.

| ID | Necessary support after reuse | C-full / C-ZT | Z-full | What can really retire; residual cost |
| --- | --- | --- | --- | --- |
| SCV01 | Activated grants, serialized claim/refund and carried identity [SCR01, SCO01--03, SCA07/08]. | Generated opaque GrantId/state APIs; one existing or modern C heap authority. C-ZT shares it. | Tagged dispositions and error unions can improve local expression; same protected authority and ABA/pins. | Old scalar-only refund authority retires only after all writers route through it. No grant protocol is removed by Zig. |
| SCV02 | Known native block/deallocator and private abort [SC-S10, SCR02, SCO07]. | Reuse aligned allocation; generated constructors/one cleanup helper or explicit goto cleanup. | Explicit allocator and errdefer can remove repeated private cleanup branches; preserve actual aligned-container deallocator. | Only private known-ownership support is avoidable. Postpublication cleanup/refund cannot use scope exit alone. Count adapter/allocator failure semantics as new Zig work. |
| SCV03 | InitSpec, completion endpoints and caller migration [SCI01--04]. | Scheme-generated C builders/caller annotations, qualified legacy islands, shared descriptors. | Scheme-generated Zig builders can express subtype/error cases; C/generated/FFI clients still need endpoints/bridges. | Raw allocator-return means scan-safe assumption can retire. Both pay semantic inventory and GC/effect proof; Zig does not reduce traced-field count. |
| SCV04 | Root/list publication and effect arming [SCO04--06]. | Existing root reload and target-adapter support reused; opaque publication ABI. | Same opaque authority; local typed records cannot root Scheme references automatically. | Duplicate raw list writers retire only with all-caller closure. H->C->G gaps, native ownership and provider/affinity remain in both. |
| SCV05 | Held-cut recount and deferred/batched accounting [SCA01--09]. | Persistent shards, frozen traversal, carry manifest, checked sums; reuse deferred counters where qualified. | Same storage/quota protocol; explicit allocators may simplify image builder only. | Processor-loop/scalar authority retires after migrated shards/grants/statistics. A global perobject lock or permanent metadata log is a new cost, not free safety. |
| SCV06 | Worker-tail layout, parser and resume adapter [STL01--07]. | Generated interval/layout descriptors and checked cursor helpers can replace whole-section assumptions. | Slices/range types can simplify local bounds plumbing; still require header/body residues, parser, fudge/check and borrowed-prefix proofs. | Old prepare/next-section/sharing/statistics routes retire per migrated cohort only after complete replacement. Tail reuse is common architecture value. |
| SCV07 | Pending transfer, cancellation and retirement [STH01--06]. | One enrolled operation/custodian, native user drain and shared delivery/resolution support. | Same custody service; errdefer stops at public/native effect transfer. | Duplicate owner-specific orchestration can retire when one service serves constructors, recount and resume. H/G/C/T semantics and progress are not eliminated. |
| SCV08 | GC/resize/cleanup integration and actual capacity outcomes [SC-S03/S11/S15]. | Credit existing phase, donor, refund and common-result work before replacing PSTATE ownership. | Same semantic work plus C service/coexistence ABI until migration completes. | Fake worker PSTATE and duplicate C/Zig authority must not survive as the target architecture. Retained legacy islands have explicit ongoing costs. |
| SCV09 | LLVM/MLIR root maps and native code [SC-P05]. | Same high-level semantics and runtime contract available to compiler services through C ABI. C-ZT already receives useful Zig tooling. | Zig may host compiler-service orchestration; does not supply root/credit/layout runtime by itself. | Count common LLVM optimization/tool value once in total modernization. Do not count it again as a Zig-exclusive increment. |
| SCV10 | Generator/tool/ABI/upgrade maintenance [SC-P01/P06]. | Mature C compiler/library coverage; checked generated builders/opaque C ABI have their own maintenance. | Zig tool/stdlib changes, target support, C island and LLVM coupling add migration/upgrade work; some local support can shrink. | Any positive increment must exceed these added costs after modern C helper/generator reuse. Source aesthetics are not a numerical lower bound. |

## Quantifiable Boundaries Without Native Claims

Still policy words per known allocation are STILL_BODY+WORDS(bytes). The aligned
allocator additionally requests padding/container-pointer storage; native malloc
metadata and RSS are not derivable from that policy count [SC-S01/S10]. At a
settled recount, actual block words plus unused grants are charged once;
deferred actual words add no second charge. Refund removes only unused demand;
actual reclaim removes actual storage. This is the main correctness benefit,
common to C-full and Z-full, not a throughput result.

For tail i, with the design's qualified q_i,b_i,F_i, the pre-fudge useful upper
bound is max(0,b_i-q_i-F_i), provided the entire placement/check profile is valid.
Per-object padding, extra guards, stack needs and error-delivery reserve reduce
usable capacity further. Sum of these upper bounds does not prove a feasible
matching to contexts or a reduction in physical SectionIds. The example with
17338 pre-fudge words is conditional layout arithmetic; a short tail contributes
zero. Every added split buffer needs its own exclusive reserve. No percentage
memory saving, pause reduction or worker scaling claim follows.

PrivateAtomicInit avoids scan-safe partial publication at the cost of delaying
a final safepoint until the constructor settles. ScanReadyConstruction can permit
earlier collection but adds safe-field initialization, roots, endpoints and
mutation/reload work. Traced/weak-field initialization is at least proportional
to the fields actually made safe; pointer-free bytes need no GC-only zeroing.
Neither language provides a finite pause bound when a native operation can stall.

Let P be simultaneously unresolved grants/constructions/transfers, S persistent
shards and L retained segment descriptors. Required support space is bounded by
their actual admitted sizes and users, not by worker count alone. Describing it
as O(P+S+L) assumes fixed-size perrecord metadata plus separately budgeted variable
root/manifest/layout payload. An indefinitely unknown effect can make P or its
lifetime unbounded. A perobject forever log is not prescribed; compaction/retire
itself needs last-user proof. Charge shared support once across these services,
then charge each caller adapter and semantic proof separately.

## Maintenance Events to Compare

| ID | Matched future change | Shared work and genuinely language-dependent delta |
| --- | --- | --- |
| SCE01 | Add a new still subtype/constructor. | Both update InitSpec, scanner, default/effect/reload/exit rules and caller census. Compare generated C and Zig builder changes, not hand-written C boilerplate against generated Zig. |
| SCE02 | Change GC demand/refund or deferred batch policy. | Both update grant/cut/carry/actual-free invariants and every writer. Count any admitted C helper reuse; Zig exhaustiveness helps local dispatch, not cross-record semantic proof. |
| SCE03 | Add target word width/alignment or allocation-check policy. | Both update object-start/body residue, chunk/guard parser, overrun reserve, native deallocator and all targets. Zig range checks do not prove the new fudge contract. |
| SCE04 | Add nested callback/cancel/constructor failure. | Both update roots, effect ownership, VM participation and all-exit resolution. Local private cleanup may shrink in Zig; published/native/unknown cleanup remains explicit. |
| SCE05 | Change worker/context counts or shutdown. | Both retain unique extents, resume placement, physical borrower drain and derived task/effect dependencies. Service reuse removes repeated scaffolding only when actual old orchestration retires. |
| SCE06 | Upgrade compiler/LLVM/Zig or regenerate bindings. | C-full and C-ZT incur their real compiler/helper/generator costs; Z-full adds only its actual incremental Zig/ABI/provider work. Count shared LLVM upgrade work once, including any layout/source invalidation. |

For each event, inventory owned adapters, generated versus hand-maintained
support, reachable semantic cases, retained old routes, review/qualification
obligations and unresolved costs. Lines of code can be a support inventory,
not a proxy for hours, correctness or economic value. No labor ranges are
fabricated from these design rows.

## Positive-Net Conditions and Refutations

Use the same scope and maintenance horizon H for each alternative. With a
consistent cost unit, total modernization net benefit is avoided B0 burden plus
bounded new capabilities minus migration, recurring support and runtime/resource
costs. Zig increment is **Z-full relative to the best equal-capability C-full or
C-ZT**, after common architecture value cancels. Unknown terms stay unknown;
there is no accepted positive lower bound for either quantity yet.

| ID | Positive condition to establish | Refutation / failure boundary |
| --- | --- | --- |
| SCN01 | Necessary services share one authority/descriptors/delivery/cleanup implementation; actual raw PSTATE/scalar/list/layout routes retire with full caller closure. | If old and new authorities remain duplicated or caller domains stay unqualified, apparent reuse merely adds adapters and maintenance. |
| SCN02 | After C generator/helper reuse, bounded avoided private builder/bounds/error-support work exceeds Zig migration, target/tool/ABI and retained-island work. | If modern C eliminates the same boilerplate, or most work is cross-GC semantics and native effect custody, Zig's positive increment is absent or unproved. |
| SCN03 | Initialization, recount and gate/batch costs fit explicit pause/metadata/resource budgets while preserving the full semantics. | If safe defaults, global contention, no-GC constructors or unknown-effect retention exceed budgets, the total design may regress despite fewer support lines. |
| SCN04 | Actual qualified tail placements reduce new physical placements or other valued allocation work without sacrificing reserve/progress. | Empty/short/borrowed tails, fragmentation or extra perbuffer reserve may yield zero saving. Counting the shared prefix twice or releasing it is not an optimization. |
| SCN05 | LLVM/MLIR modernization benefits remain achievable through the shared contract and independently justify common service changes; Zig adds a separately bounded advantage. | If justification is solely common LLVM tooling or language preference, there is no demonstrated reason to select Zig over the matched C alternatives. |

The immediate architectural value is explicit semantic and storage authority,
independent worker/context placement and a replaceable native service boundary.
It is larger than build/distribution modernization. Whether Zig is the best
implementation language remains an open, falsifiable economic question. All five
full architecture requirements, AG05/AG06 and future native AG07 remain open;
this study neither accepts the theoretical gate nor authorizes native work.
