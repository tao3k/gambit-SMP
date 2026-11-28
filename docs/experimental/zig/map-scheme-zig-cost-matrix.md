# Map Modernization: Actual Baseline and Complete Candidate Costs

Reviewed: 2026-10-20. Theory/design report only. No implementation, compiler or
native test, timing claim, measured labor estimate or positive economic bound.
Read the [path](map-scheme-zig-design.md),
[evidence](map-scheme-zig-evidence.md) and
[conditional arguments](map-scheme-zig-arguments.md).

## Modern C Is a Candidate, Not the Present

MC01. The inspected Gambit already implements closures, generic Scheme calls,
continuations, GC maps and a trampoline. The selected modernization gap is the
coupling of semantic control/root decisions, physical layout and C construction,
with opaque native/control/module assumptions [MP-S04–12]. We must not erase
those existing capabilities, nor describe hypothetical typed C services as
already available.

The alternatives all start from the same current checkout:

| Candidate | What must actually be built | What is not assumed free |
| --- | --- | --- |
| B0 with selected repairs | Keep current backend/runtime and fund needed fixes | Ongoing legacy duplication, tool/macro costs and delayed capability value |
| C-G | Scheme semantic completion; modern typed C product/service generator, runtime/control and module reconstruction; useful LLVM provider | Generator development, validators, platform/library integration, full migration and future maintenance |
| C-ZT | C-G plus only the useful Zig tools/services chosen | Both C modernization and added tool/interop/upgrade cost |
| Zig | Same required language/runtime capabilities, realized directly through generated Zig hosts and selected Zig native services | Zig emitter/planner/control integration, retained native islands, target/tool upgrades and complete qualification |

A modern-C implementation is **not a prerequisite stage** before Zig. Compare
complete alternative delivery paths, including delivery delay and opportunity
cost under an explicit valuation. Calling a benefit common means both designs
can deliver it; it does not mean its implementation cost is identical or zero.

## Required Service: Call/Frame Product Construction

MC02. Choose one service that map really requires: a common producer of
call/return/continuation-frame products. Its clients are the one-list proc
application, recursive return/cons, multi-list cars/cdrs/apply, optional force,
error services and ordinary/internal GC/poll resumes [MP-S04/S07/S08]. These
are necessary consumers of a shared contract, not seven independently required
libraries or a reason to create a unique wrapper per label.

Proposed input is a Scheme-completed CallSpec and FrameSpec: callee class and
ProcRef, argument/value protocol, continuation and dynamic-state obligations,
semantic homes/live roots, explicit effects/checks, normal/control successors
and target profile. Output is a validated transfer/restore recipe, physical
frame/map bytes, point/relocation records and renderer operands. Service
execution itself must not invent a safepoint or run user Scheme. Runtime
activations and captured state are different objects from these immutable
compile-time recipes.

| ID / necessary support | Modern C-G after reasonable reuse | Zig after reasonable reuse | Saving that could actually occur / remaining cost |
| --- | --- | --- | --- |
| MC03 Recipe representation and variants | Generate structs, enums, tagged unions/accessors and declarations from the Scheme schema | Use typed records/unions and comptime construction from the same schema | Zig may avoid a separate C-specific helper generator; C-G may already generate these in Scheme, leaving little residual saving. Schema meaning remains common. |
| MC04 Range/layout/map validation | Generated checks plus checked integer arithmetic and an independent decoder | Generated/comptime checks plus checked integer arithmetic and an independent decoder | Fewer handwritten field/variant synchronization points are possible; neither eliminates decoder, actual-root oracle or target-dependent overflow checks. |
| MC05 Worklists, bytes and interning | Reuse mature storage libraries or existing Scheme facilities; maintain domain wrappers | Reuse Zig storage/allocator facilities; maintain domain wrappers | Avoid only genuinely bespoke residual buffer/growth/error plumbing. Source identity, relocation ownership and frame validity still need project code. |
| MC06 Builder cleanup and local failure | Structured C cleanup/goto or generated cleanup tables, explicit ownership | defer/errdefer/error propagation for ordinary local returns | Can remove repeated local exit bookkeeping if substantial after C reuse. Cannot implement Scheme dynamic-wind, multi-shot capture, async drain or cross-language longjmp cleanup. |
| MC07 Generic transfer/root writeback | One admitted ABI lowering with SELF/arity/return and root homes | The same admitted ABI lowering with explicit dispatcher dispositions | Does not remove an existing per-callback C FFI wrapper: current map already uses generic Scheme dispatch. Both need call/root/control logic. |
| MC08 Capture/restore and code lifetime | Reuse/migrate Gambit runtime frame copying, dynamic transfer and scanner users | Same runtime algorithms/contracts through admitted imports | No Zig-specific elimination of captured-frame storage, collector, dynamic-wind or code-user pinning is established. Native defer is not their replacement. |
| MC09 Renderer/provider adapters | Typed C and optional LLVM adapter, common module product and independent readers | Zig emitter and optional LLVM adapter, same module product/readers | Real C host macro emission can retire on Zig-selected routes; new syntax/frontend/native and provider-adapter work replaces it. |

## Benefit and Cost Report Matrix

| ID / target | Present source behavior / gap | Gain versus current Gambit | Incremental Zig condition versus fully costed modern C | Present assessment |
| --- | --- | --- | --- | --- |
| MC10 Higher-order calls | Generic jump exists with explicit return setup [MP-S04/S07/S09] | Make call/effect/root protocols independent of C strings | Cheaper recipe construction/validation and maintenance after reuse | Architectural candidate; no eliminated per-call FFI overhead established |
| MC11 Closures | User environment identity plus internal lambda lifting [MP-S06/S09] | Explicit closed-value and mutable-cell contracts across native providers | Cheaper physical construction/integration; not rediscovering capture analysis in Zig | No demonstrated per-iteration closure removal |
| MC12 Non-tail continuation | Callback and recursive tail result each have pending work [MP-S01/S04] | Decodable frames and bounded native dispatcher depth | Lower full service cost, including dispatcher/restore/regression costs | O(n) pending Scheme work remains in this design |
| MC13 Multi-shot/dynamic control | Captured stack/heap frames and wind/unwind [MP-S10/S11] | Explicit replay, root, frame/code lifetime and external-control boundaries | Real reduction in surrounding support outweighs extra Zig/native-control integration | Core semantic algorithms remain necessary in both |
| MC14 GC and allocation | Multiple safe points, movable roots and helper allocations [MP-S07/S11] | Complete root publication/reload and actual span contracts | Less residual builder/metadata maintenance with the same complete GC protocol | Isolated cons B=3 does not bound callback or map |
| MC15 Full module product | map belongs to _std; old setup and C interfaces remain [MP-S12] | One binding/point/init owner replaces implicit C discovery | Cheaper planner/loader/support realization plus real caller retirement | Not achieved by translating one function |
| MC16 Generated native pipeline | Existing target.dump consumes C interface [MP-S05/S12] | Converted hosts can bypass old C emission/macro compilation | Full Zig generation/native cost below best C/LLVM route at equal capability | No build/startup/runtime speed ratio established |
| MC17 LLVM/high-level optimization | Primitive expansion and lifting precede C rendering [MP-S05] | Earlier closure/effect/control export, selective lawful transformations | Cheaper provider integration beyond shared LLVM capability | LLVM value available to C as well; unknown proc is not automatically pure |
| MC18 Shared service economy | Call/frame products reused at actual semantic clients | One implementation instead of per-path support duplication | Positive residual saving after MC03–09, per-consumer adapters and upgrades | No proven crossover consumer count or accepted net bound |

![Complete alternatives from today's Gambit](map-modernization-economics.svg)
[D2 source](map-modernization-economics.d2).

## Three Ledgers and Positive Conditions

MC19. Fix capability domain K, maintenance horizon T, source identity and valued
outcomes before comparison. Keep correctness/runtime admission separate from
economics. Define engineering burdens in commensurable units, with build time,
latency, memory and reliability as separate constraints or explicit valuations:

```text
Net_C_from_B0 = valued C modernization outcomes - full C reconstruction/lifecycle cost
Net_Z_from_B0 = valued Zig modernization outcomes - full Zig reconstruction/lifecycle cost
Delta_Z_vs_C = Net_Z_from_B0 - Net_C_from_B0
```

Each full cost includes contract work, necessary support implementation,
migration, independent verification, transition duplication, native islands,
target/library/compiler upgrades, continued legacy obligations and delivery
delay. The C generator is in the C ledger; the Zig emitter/tool integration is
in the Zig ledger. Only truly identical common effort may cancel. Differences
in the cost of realizing shared architecture are part of the language decision,
not excluded merely because the architecture is shared.

MC20. At equivalent admitted outcomes, a useful decomposition is:
`Delta = (C initial reconstruction - Zig initial reconstruction)
+ (C residual maintenance - Zig residual maintenance)
- Zig-specific extra obligations relative to C`.
Use each cost exactly once: if tool/ABI/bridge cost is already in Zig initial or
maintenance totals, do not subtract it again. Positive theoretical selection
needs a justified conservative bound `lower(Delta) > 0`, plus positive total net
for the selected modernization route. Missing bounds are unresolved, not zero.
If outcomes differ, show a tradeoff instead of silently changing K or inflating
an equal-capability claim.

MC21. For k necessary consumers, fixed support cost is paid once, plus k actual
adapter/change obligations. Zig could amortize a lower-cost common builder/
storage/cleanup implementation; C-G could amortize a Scheme generator and mature
libraries. Counts of map's labels or possible future clients are not support
cost estimates. Repeated runtime invocations are not repeated maintenance
implementations. No k threshold follows without bounded fixed and per-user
costs. Baseline retention and opportunity cost must also be recorded; comparison
must not indefinitely assume that staying with today's path is free.

## Maintenance Events and Structural Retirement

| ID / event | Work remaining in both designs | Candidate-specific difference to account for |
| --- | --- | --- |
| ME01 Add a call/value/control variant | Scheme meaning, effects, frame/live homes, independent normal/escape checks | C generator/variant consumers versus Zig unions/comptime/emitter changes; exhaustiveness is not semantic completeness |
| ME02 Change closure/frame representation | Layout/GC/capture/restore/SELF and all reader compatibility | Generated C packers versus Zig packers; both retain target and independent-decoder obligations |
| ME03 Add a safe point/helper | Materialization, actual bound, root publication and reentry/exception edges | Remaining hand-coded emission and error plumbing after respective reuse |
| ME04 Upgrade compiler/LLVM/platform | Provider contract, target ABI, object/module maps and bootstrap users | C tool/library/generator maintenance versus Zig frontend/emission/interop plus retained C cost |
| ME05 Rework capture/VM shutdown | Actual continuation/code/callback users, owner and drain semantics | Native lifetimes/bridge integration may differ; no defer-based shortcut |
| ME06 Delete legacy support | Complete caller census and qualification, preserve historical receipts | Actual disappeared old work versus new permanent support in the chosen route |

| ID / order | Replacement and deletion obligation | Eligible retirement / retained responsibility |
| --- | --- | --- |
| MR01 | Close public map features, mutable policy, helper, error and unknown-call domain | Retire downstream inference of those semantics; Scheme authority remains |
| MR02 after MR01 | Complete CallSpec/FrameSpec and roots/control successors | Retire C-scanner-only call/check/resume/boxing semantics; preserve language protocol |
| MR03 after MR02 | Common layout/product service with independent decoder | Retire separate private frame/label packing authority; keep GC/capture readers |
| MR04 after MR03 | Whole-cohort dispatch, generic closure entry, Scheme return and native-control islands | Retire selected old transfer macros; no ordinary Zig callback replacement or old ABI mixture |
| MR05 after MR03/04 | Complete _std/module/native-interface product and init/lifetime closure | Retire selected old C host/module generation; no duplicated map supplier |
| MR06 after MR01–05 | All kernel/FFI/bootstrap/captured-code users rebuilt and independently admitted | Remove zero-caller legacy branches; no global deletion or retired-path claim from this design alone |

MC22. **Net can favor Zig before any modern-C implementation exists.** Evidence
would be a complete necessary-support design showing lower bounded realization
and lifetime maintenance cost after fair reuse, matched capabilities and actual
retirement dependencies. It is not necessary to build both candidates now.
The opposite result can favor C, and unbounded estimates keep selection open.
Neither “modern C could do it” nor “Zig has modern features” settles the decision.

## Full Runtime Scope

The [complete native-layer candidate](zig-native-layer-reconstruction.md) also
includes collector, VM, OS and FFI implementation migration. Charge that wider
surface in the lifecycle ledger; neither C friendliness nor a lower-cost small
planner establishes positive net for the entire runtime.
