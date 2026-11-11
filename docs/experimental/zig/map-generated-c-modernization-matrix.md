# Gambit Modernization: Capability and Runtime Tradeoffs

Design-only decision report. This replaces human-day ROI as the criterion for
the current research; historical estimates remain historical planning material.
The question is whether a coherent reconstruction yields valuable system
capabilities while preserving Gambit's strengths. AI coding agents can assist
implementation; source and paper evidence still have to justify the mechanisms.

MV01. OCaml's useful precedent is a requirements-driven runtime reconstruction:
preserve existing sequential meaning and performance, account for pauses, and
make parallel execution/foreign interaction coherent. The parallelism paper
also identifies how exposed C heap access constrains collector changes. Its
two minor-collector alternatives are historical design alternatives, not both
asserted to be today's OCaml runtime. The effect-handler paper uses one-shot
continuations; Gambit's general Scheme continuations must retain repeated
invocation and dynamic-wind behavior. Copying that restriction would remove a
Gambit capability rather than modernize it. [MP02–MP05]

## Capability Matrix

MV02. Targets below are separate axes, not additive scores or predictions. The
evidence column identifies a mechanism and the missing proof, rather than
claiming a completed capability.

| Goal | Current selected Gambit source | Substantive reconstruction / benefit | Evidence and decisive condition | Zig necessity |
| --- | --- | --- | --- | --- |
| Young/mature collection | Full movable tracing/copying, still mark/sweep; existing parallel STW branch | Young evacuation/promotion plus concurrent nonmoving mature collection can avoid repeated mature copying | ME12–ME13: all writers, weak/ephemeron/finalizer phases, promotion/root publication and termination must close | Neither Zig nor modern C supplies the collector algorithm |
| Multicore execution and ownership | Processor/VM mechanisms already exist; do not count multicore as absent | Separate executing context from collector worker and native service ownership; safe resize/park/reentry/shutdown | ME11–ME13: every participant and accepted root/task has a complete owner/phase path | Same contract needed in both |
| General Scheme control | Real capture/return/dynamic-state and active/heap frame scanning exist | One explicit frame/control model across generated C, modern GC and future providers | MC05–MC10, ME07–ME08: repeated resume, error/wind/value semantics and code lifetime retained | Native Zig calls/defer do not provide this |
| FFI as a managed boundary | Existing RC/still/marker/native calls; current couplings and selected gaps are real | Typed root, borrowing, owner, blocking participation and callback contracts; fewer hidden GC assumptions | ME11–ME13: all raw writers/borrowers/callback owners classified; unsupported raw use rejects a profile | C ABI affinity helps either realization, but cannot classify foreign effects |
| Compiler/runtime separation | GVM/target interface already exists; C emitter still creates check/root/control decisions | Complete semantics once in Scheme; separate native layouts/renderers and runtime algorithms | ME03–ME06: remove duplicate semantic inference from converted emitter; complete exceptional/role edges | Scheme plus generated C can realize the seam directly |
| LLVM/MLIR leverage | Mature C route, no admitted direct provider established here | High-level transforms plus independent direct LLVM provider; reuse common semantics/runtime contracts | MC03, MP06–MP07: transformed graph reanalysis; GC relocation, control and module ABI qualified independently | No mandatory Zig bridge; new provider cost exists in either route |
| Modules and reusable products | Stored relocation/setup tables; fixup state has explicit atomicity TODO | Share immutable products, construct owned instances; explicit partial initialization and unload safety | MC11–MC13, ME09–ME11: no captured frame or foreign/task reader survives code retirement | Implementation language does not establish publication or last-use |
| Rooted observability and diagnosis | Descriptor readers and statistics exist in different paths | PointId/FrameSpec/source correspondence for GC, continuation, errors and provider diagnostics | MC06–MC07, ME05–ME08: independent readers agree; metadata footprint and lookup cost counted | Generated C can centralize products; Zig optional tooling only unless additional value is shown |

## Quantities That Answer the Benefit Question

MV03. The map audit gives **23 stored dispatch labels, 22 return descriptors,
9 normal and 13 internal returns, 10 textual polls, 3 textual heap checks, 1
textual generic-call site, 0 textual F64BOX and 0 textual ALLOC_CLO in this
host**. These are static shape counts, not runtime operation counts, completeness
of callbacks, optimization savings or modernization percentages. All 22
descriptors have a source-artifact correspondence in the point inventory; none
has an implemented new-generator witness. A changed layout may legitimately
have different counts. [ME02]

| Benefit question | Conditional quantitative expression / structural target | Limit / refuter |
| --- | --- | --- |
| How much managed allocation does translating map remove? | Ordinary successful one-list map still constructs n output pairs and performs n callback invocations under the unchanged algorithm | Language/backend substitution alone saves **zero mandatory output pairs and zero mandatory callbacks**; callbacks/helper allocations are extra |
| Does a dispatcher make map constant-space? | Existing non-tail algorithm retains O(n) pending Scheme frames/work; native trampoline growth is a separate quantity | A native tail transfer is not a proof that pending results or captured frames disappear |
| How much copy work can a mature generation avoid? | For the same mature payload chunks, moving from k whole-copy events to at most one promotion avoids sum(s*(k−1)) bytes when k≥1 | Payload model excludes scans, roots, barriers, promotion overhead, major work and fragmentation; k=1 gives zero avoided repeated copying |
| When is whole-program GC gain positive? | With baseline GC fraction f, candidate GC fraction-of-old-work q, and extra non-GC cost a normalized to baseline time: candidate ratio = 1−f+f*q+a; gain iff a < f*(1−q) | q, f and a are unknown workload-dependent quantities here; high barrier/root costs can reverse the result |
| How much C frontend work can a direct provider remove? | For a fully converted cohort, generated C host/frontend invocations can go to zero | Replacement IR/pass/object/map work remains; total compilation time is not thereby zero or faster |
| Is semantic sharing real? | One authoritative meaning for each operation; all selected providers consume its completed contract | A second root/check/control inference hidden in the new renderer falsifies the sharing claim |
| Has old work really disappeared? | Zero remaining selected callers of a retired responsibility, plus an admitted replacement and preserved bootstrap/link consumers | Present source retirement count is **zero**; this documentation is not a retired route |
| Is multicore capability new value? | Complete participant/worker/FFI phase closure, with latency/throughput/space effects assessed separately | Source already has SMP; no “single core to multicore” multiplier can be credited wholesale |

No hypothetical parameter values or human-day intervals are inserted to turn
unknowns into a positive numeric result. This is a mechanism-level quantitative
argument and a clear measurement specification, not completed performance proof.

## Added Architectural and Runtime Costs

MV04. Modern C and Zig are compared at equal capability and proof scope. These
are obligations and runtime burdens, not a forecast of agent implementation days.

| Necessary support | Shared or retireable work | Modern generated C must maintain | Zig must maintain / potential extra value |
| --- | --- | --- | --- |
| Scheme semantic completion | Share one analysis/contract; retire old emitter's semantic decisions only after complete caller migration | Graph/feature identities, effects, frames, roots, check/error/resume validation | Same semantics required; a second Zig planner is an added authority unless it replaces a specified one |
| Typed product construction | Generate declarations/maps/transitions from one schema; retain independent readers | Scheme renderer, checked sizes/layouts, C diagnostics, source correspondence and bootstrap | Native compile-time constructs can replace selected scaffolding; emitter and toolchain/ABI support remain |
| RootRegistry | Share ID/status/storage primitives, retain actual root policies | Stable cells, scan epochs, owner/transfer/marker registration and withdrawal | Equivalent policies; defer/allocator typing covers local scope, not cross-thread or captured lifetimes |
| BarrierLog | Share typed store products; retire unclassified direct writes in admitted domain | Reservation, SATB/young remembering, atomic access, slow retry, root reload and epoch drain | Same algorithm; error unions do not prevent races or make capacity unlimited |
| ReleaseCoordinator | Share statuses/metadata/native leaves; preserve device-specific effects | WaitContext, task accept/cancel, partial effects, thread ownership, child debt and shutdown | Local error cleanup can be simpler; nonlocal escape, accepted tasks and native ownership remain explicit |
| Control and module products | Share FrameSpec/PointId; retire old layout/dump authority per cohort | RETN/RETI or fully qualified replacement ABI, setup/initialization states, retained code/readers | Ordinary Zig stack cannot replace multi-shot Scheme control; mixed C islands and ABI qualification also remain |
| New GC policies | Potential repeated-copy/parallel/latency benefits belong to algorithm | Extra remembered/SATB storage, barriers, roots, promotion reserve, major scan and phase synchronization | Same unavoidable costs at equal algorithm; no-GC host language does not remove managed Scheme GC |
| LLVM/MLIR providers | Reuse semantics; retire generated-C frontend only where completely replaced | Dialect/effect/control modeling, relocation, native calls/maps/modules and LLVM upgrades | Same provider obligations; Zig hosting is optional, not itself LLVM optimization leverage |

Retained support is not a failure when it represents real Scheme or OS
requirements. The failure is retaining duplicate semantic authorities while
claiming they were replaced. Generated code volume is not a correctness or
maintenance metric by itself; incompatible products, hidden effects and policy
duplication are the continuing burdens to minimize.

## Decision and Research Gates

MV05. **There is a credible, substantive modernization direction in modern
generated C: reconstruct the managed runtime and compiler/runtime contract,
then admit independent providers. Source evidence does not establish a need
for Zig to obtain those capabilities.** This preference follows direct reuse
and authority placement, not a claim that human implementation labor is cheaper.
Zig can be reconsidered for a named capability or support elimination which
the equal-scope C route cannot supply as well. “AI can rewrite it” applies to
both realizations and cannot select between their architectures.

MV06. Distinguish three decisions:

1. **Research direction:** proceed with the complete runtime/compiler
   reconstruction, because its target mechanisms address identified GC,
   semantic/provider and ownership couplings; do not reduce it to build tools.
2. **Theoretical admission:** requires complete selected semantic/writer/root/
   phase/module coverage, explicit cost terms, and a declared workload/domain
   where benefit survives them. The map case only closes specified local
   arguments; the full-project positive bound remains unresolved.
3. **Operational admission:** later independent native semantic, GC/FFI,
   sequential-performance, pause, parallel-throughput and memory evidence.
   No implementation or experiment is authorized by these documents.

Retain separate acceptance coordinates for correctness, sequential regression,
pause distribution, multicore scaling, peak memory, generated/native compile
work, foreign usability and change isolation. Budgets must be selected for real
workloads; no invented weighted “modernization score” or borrowed OCaml speedup
can substitute for them. Reaching OCaml-caliber modernization means meeting
such a coherent requirements set, not duplicating OCaml's exact control model
or merely changing implementation language.

## Concrete Captured-Frame Work Model

The [captured-map matrix](map-continuation-gc-benefit-matrix.md) refines MV03
with separate baseline copy and candidate promotion counts, possible k_i=0
early-promotion losses, selective minor traversal, active-root/replay costs
and a non-duplicated gross/new-work time ledger. The
[learning/reflection](map-continuation-gc-learning.md) derives questions from
OCaml and then studies Gambit's own lazy, shared and multi-shot frame graph.
No empirical or full-theory gate is promoted by that refinement.
