# Full Modernization: LLVM Leverage, Retirement and Cost Matrix

Reviewed: 2026-10-20. [Architecture](modernization-system-architecture.md),
[source/primary evidence](modernization-system-evidence.md). Theory/design only;
no implementation, native/compiler/model tests or measured benefits.

## 1. Attribution Before Aggregation

Bmin is the RC/marker repair control. C-full and Z-full have the same full
runtime, semantic, provider, target and service capabilities. C-ZT adds the same
independently selected Zig tool to C-full. Current GCC, possible Clang, repaired
candidate and installed SDK profiles remain separate identities. Clang-generated
C can already use LLVM optimization/LTO/debug infrastructure if configured and
qualified; neither access to LLVM nor a C API is exclusive to Zig [MP04/MP06].

Class **A** is shared architecture reconstruction; **U** is upstream mechanics
reused after lawful inputs; **Z** is a conditional implementation-language/support
increment; **F** is an optional new feature. A/U are real modernization value,
but do not become Z merely because the selected implementation is Zig. Existing
project support and algorithm reuse are credited. Unknown gains/costs are not
zero; safety/control/root gates cannot be traded for aggregate benefit.

## 2. Fourteen Concrete Leverage Rows

| ID / dimension | Mechanism and architectural leverage | What genuinely changes / retires | Retained/new cost and equal-C control | Future quantitative denominator / positive condition |
| --- | --- | --- | --- | --- |
| LM01 generated C work | A: direct semantic/control products -> LLVM native object | Native-selected Scheme-host C generation, header preprocessing and C parsing are absent from that selected path | New export/verification/lowering/LLVM work; C helper compilation remains; C-full can do the same | Count eliminated source/CPP/C-front invocations and bytes for identical supported change; new total work must be less after all stages |
| LM02 machine backend | U/A: target codegen, register allocation, supported objects/relocations delegated to LLVM | Avoid a project-owned ordinary machine/object emitter for those targets; separate Gambit metadata/fixups | Provider integration, target/ABI/loader qualification; current C/Clang already delegates much of this | Required mechanics maintained locally versus delegated; affected upstream/adapter change events, not a count of LLVM passes |
| LM03 low-level optimization | U: lawful SSA, inlining, scalar/vector optimization and selected profile-guided recipes | Explicit value/effect information can expose opportunities hidden by macro/control barriers | Correct tags/overflow/identity/FP/alias rules and profile instrumentation; generated C/Clang is a strong control | Eligible operations and realized transformations with total cost/size/serial latency; never claim generic -O flags as new Zig value |
| LM04 higher-order functions | A/U: high semantic IR before closure/storage lowering; call-target, environment and escape analysis | Remove proved unnecessary closure/environment allocation, indirect calls or boxes | Binding guards, mutable identity, continuation capture, FFI escapes; custom analyses and verifiers needed in C/Z alike | Remaining closures/captured words/boxes/calls per equivalent semantic program; admitted opportunity census required |
| LM05 regions plus GC | A/F: explicit allocation/lifetime/capture law with hybrid retained GC | Some proved nonescaping objects can avoid general allocation; broader traced regions independently designed | Collector-visible edges, weak/finalization and multi-shot reentry; structural MLIR regions alone are insufficient | Allocated/scanned/copied/retained bytes and region metadata/copies for eligible sites; preserve all traced edges |
| LM06 root/FFI boundary | A: VM-owned retained slots/context carriers and typed effect/update operations | Selected implicit RC/processor rooting and per-wrapper guesses replaced by one contract | Slot/generation/storage/read-barrier or write-barrier requirements, all last uses, legacy adapter; Z types do not supply GC | Root stores/reloads, handle indirections, copies and borrow duration per full boundary; less work only when justified by effects |
| LM07 multicore/VM progress | A/F: execution, root carriers and collective membership separate; acknowledged park/reentry | A retired or parked execution context need not remove its proven root carrier from enumeration | New request/exclusion/weak-memory/cancellation/lifecycle proof; Bmin BW1 and current stealing are credited | Supported blocking/retirement schedules, serial overhead, request-to-service/GC pause tails and parallel throughput separately |
| LM08 target evolution | U/A: one target/profile/layout interface and common physical planner | Reduce duplicated target-specific emission/layout policy on migrated routes | Each target/call cycle/data layout/object/FFI profile remains independently qualified; arm64e not implied | Distinct project decision owners and per-target adapter/change work; new target count alone is not maintenance saving |
| LM09 module/image products | A/U: direct object plus constant graph, fixups, frame/role/debug map and instance plan | Existing native-through-C packaging and selected implicit ordinal/setup rules can leave | Runtime initialization, symbol/global identity, code/map lifetime, rollback/error semantics retained | Zero selected packaging calls through old C dumper; full product/module domain must be covered |
| LM10 LTO and incrementality | U/A: selected ThinLTO/caches inside project semantic artifact dependency graph | Avoid supported repeated provider/backend work and unrelated semantic regeneration on valid hits | Linker/target version, imports/rebinding/runtime ABI/source identity; C-full/Clang can use ThinLTO too | Rebuilt products and total cache-validation/link work per change/upgrade; sound invalidation is a hard condition |
| LM11 debugging/diagnostics | U/A: Scheme origins/PointIds -> LLVM debug products plus retained structured diagnostics | Less ad hoc native-symbol-only diagnosis; provider optimization remarks can be retained | Scheme continuation/variable/GC frame mapping, optimized location loss and native tool support | Covered source/point/root/control cases and actual failure/upgrade diagnosis work; LLVM does not decode Scheme continuations automatically |
| LM12 AOT and distribution | A: reusable semantic/interface-construction programs, native image manifest and fresh instance contract | Repeated immutable construction/code work can be avoided where actual invalidation permits | Dynamic binding, lexical/phase identity, context initialization and native product validation persist | Generation/expansion/instantiation work counted separately; no automatic removal of Darwin interface startup delay |
| LM13 shared native services | Z/A: one coherent planner/provider/FFI-module/product/diagnostic resource subsystem | Selected duplicate native request/custody/error/product support can retire across necessary consumers | Reuse Scheme containers/generated C/libraries; per-consumer semantic protocols and asynchronous last users remain | Union of necessary support bodies/change work actually avoided after reuse, above marginal Zig/bridge/qualification/exit costs |
| LM14 optional JIT/heterogeneous path | F/U: ORC or admitted compute dialect/target providers behind same product/runtime contracts | Opens separately demanded interactive/specialized capability without inventing another whole backend infrastructure | Code/symbol/GC-map reclamation, target memory/copies/cancellation, kernel semantic subset; not mandatory to justify AOT | Independent demanded capability and total support/latency/resource benefit; ORC resource removal is not Scheme quiescence |

Every row is a research target, not a passed benefit. LM01/04/06/09 are core
architecture opportunities; LM02/03/08/10/11 are concrete upstream reuse with
project adaptation; LM07's new detached behavior, LM05's new region representation
and LM14 require independent feature demand and complete costs. No pass count,
source LOC, native target list or weighted score certifies adoption.

## 3. What Must Be Able to Leave the Selected C Path

| ID | Current owner / source seam | Full new owner / product | Retirement condition and retained boundary |
| --- | --- | --- | --- |
| FD01 C procedure text/control emission | _t-c-2 instruction/control/check spelling; _t-c-1 procedure renderer | Scheme completed semantics + Zig physical realization + admitted LLVM lowering | All selected operation/control/root edges covered; no old whole procedure emitter called by native route; legacy BC cohort retained explicitly |
| FD02 renderer-owned layout/label packing | _t-c-1/3 IFD/OFD, frame expansion and label products | One profile-bound FrameLayout/PointLayout product with independent runtime decoder | Actual size/coordinate/root/tail/capture evidence; C and LLVM consumers do not rediscover decisions |
| FD03 ordinal/module setup coupling | setup_kernel_handlers handwritten numeric assignments and native-through-C module products | Semantic runtime-role/PointId manifest and checked image/instance binding | Every required role/entry/signature accounted for; constants/globals/initializers and lifetime still runtime-owned |
| FD04 foreign macro semantic policy | _ptree2 C-oriented conversion records plus SFUN/CFUN macros | Typed ForeignPlan + shared root/control/ownership protocol and generated admitted adapters | Full selected caller/effect/parameter/error/control coverage; raw C/system ABI island remains where demanded |
| FD05 retained-value RC/processor coupling | Per-processor RC managed data and retirement transfer as only carrier in a selected path | VM root domain plus published execution-context carriers; legacy RC bridge | Update/scanner/park/retire/reuse law complete; native-byte RC may remain; existing repairs not deleted indiscriminately |
| FD06 implicit entry/control policy | Configured selector/macros/catcher behavior at managed seams | Explicit execution/return-origin/outcome contract for complete new typed cohort | Preserve continuation/dynamic-environment/foreign abort semantics; arbitrary raw C callbacks not flattened into status |
| FD07 native-through-C packaging | _t-cpu cpu-compile uses C backend to build object | Direct provider object + Gambit metadata/relocation/init product | Native module load/setup semantics complete; no C Scheme-host packaging dependency for selected native product |
| FD08 command/config duplication | _gsclib string transport and selected gambuild template callers | One effective typed profile/request and admitted execution/artifact service | M1-M12 / E01-E32 actual caller/mode closure; no new flag resolver or wrapping all old scripts forever |
| FD09 code/map ownership fragments | Dynamic module, label/frame/foreign return and service-resource lifetime assumptions | One product registration/last-use/retirement protocol with provider adapters | Runtime users, suspended continuations, native returns and collector readers all discharged; ORC/OS unload alone insufficient |

These are nine future responsibility retirements, not nine files to delete now.
A retained portable C backend, raw C ABI or old binary cohort is a real supported
residual with bounded maintenance/exit costs. It must not silently remain the
implementation of every supposedly migrated operation. Internal ABI changes
are allowed for a rebuilt cohort; public semantic preservation and explicit
boundary compatibility still require evidence.

## 4. Quantifying the Leverage Without Inventing Measurements

For a matched native-selected build, partition work before attaching prices:

```text
W_old = W_semantic + W_C_emit + W_CPP + W_C_front
        + W_backend + W_link + W_instance
W_full = W_semantic_export + W_high_analysis + W_lower_verify
         + W_provider_backend + W_link + W_boundary_transport + W_instance'
```

LM01 can remove stages, but the replacement stages are real work. Backend work
cancels only when genuinely matched; target/optimization changes can add work.
Eliminated invocations/tokens are structural gains, not milliseconds or whole-
startup speedup. If removable elapsed fraction is f, ideal speedup from removal
alone is at most 1/(1-f) before replacement costs; no measured f is supplied.
Cache validation, debug/code size, memory, cold tool startup and invalidation
amplification belong in the accounting. Reusing LLVM can add a large dependency
and compile/link/service-memory burden.

For maintenance, use actual demanded native consumers F and change events H:

```text
N_total(Z-full vs B0)
  = valued architecture work/capability avoided or gained
    - shared semantic/runtime/provider reconstruction and migration
    - recurring support/coexistence/regression/exit costs
N_increment(Z-full vs C-full)
  = S_disjoint_private_support(F,H)
    - I_language - I_bridge - I_coexistence - I_qualification - I_exit
```

These are economic accounts over declared units/horizon, not a unitless score.
Performance, correctness, capability and maintenance do not become interchangeable
without explicit justified valuation. For each claimed positive account require
credible lower bounds on avoided work/value above upper bounds on added costs;
unknown remains an interval, not zero. GC/FFI algorithms and LLVM services common
to C-full are excluded from the language-only numerator. C-ZT common tool costs
cancel only if truly shared.

The full portfolio can have useful complementarities: typed semantic export
makes high analyses possible; runtime/root/control contracts make their products
executable; one product/provider boundary permits independent evolution; direct
objects eliminate the old C detour. Removing one seam may enable several rows.
Count that removed support once, and count independently valued capability only
once. Benefits with a required missing seam are conditional, not additive sure
wins. A small local wrapper's S=0 does not constrain the necessary-support union
of a different full topology. A large topology does not guarantee S>0 either.

The selected AOT compiler worker and in-process runtime SDK are separate cost
and invalidation domains. Charge worker transport/startup/RSS/cancellation/reaping
and parent safe-wait work; credit failure/version separation only for the actual
separate deployment. C-full uses the same topology. Isolating the compiler does
not make generated native code safe or permit retry after an unknown publication
outcome. Existing Scheme/NJS execution mechanisms are reuse controls, not work
assumed absent merely to enlarge the Zig saving.

Candidate disjoint Zig mechanisms are typed private product construction,
reusable native session/resource ownership, explicit fallible propagation and
specialized adapters across real planner/provider/image consumers. A single
Scheme schema may generate much of the C/Z record/dispatch support, reducing
that differential; mature C/C++ libraries may remove more. New callbacks, ABI
imports, tool/stdlib upgrades, debugging/training and a viable extraction path
increase it. No positive bound for that union is established in this update.

For two declared semantic producers (high export and completed GVM), P selected
provider routes and T targets, the shared physical protocol aims to keep one
project realization authority plus producer/provider adapters. The source already
shares GVM/target negotiation, so the old cost is not invented as 2*P*T separate
compilers. Semantic/ABI/optimization qualification still spans every supported
producer-provider-target-runtime combination. A small adapter graph reduces some
implementation duplication; it does not collapse that evidence cross-product.
Actual saving requires comparing real old owners and actual future change work.

## 5. Upgrade / Invalidation Matrix

| Change | Reuse candidate | Required invalidation / retained duty |
| --- | --- | --- |
| Source/binding/declaration/effect change | Unrelated stable modules/programs | Semantic product, summaries and all dependent root/control/provider/native products; dynamic rebinding guards/invalidation preserved |
| Runtime root/control/ABI profile change | High semantic product only where representation-independent by contract | Physical plans, wrappers/maps/products and rebuilt cohort; old bytes not admitted by filename or size equality |
| LLVM/MLIR provider/recipe change | Unchanged Scheme semantic export and genuinely separate unchanged runtime | Provider IR/bitcode/caches/objects and provider service; dependent linked/runtime binaries if actually built with that provider |
| Native Zig host-service change | Stable serialized semantics/product meaning where validated | Service binary, affected behavior/transport/ownership and diagnostic qualification; private layout never a wire guarantee |
| Target/CPU/features/object/call convention change | Target-neutral semantic facts only | Native layout/code/object/FFI/control capabilities and link/debug products |
| Code/module retirement | Immutable descriptions with valid identity | Close runtime/continuation/native/collector consumers before maps/code/slots free; cache eviction does not discharge runtime use |

![Leverage and dependency closure](modernization-leverage-boundaries.svg)

## 6. Adoption Gates and Research Sequence

| ID | Gate / required product | Current status |
| --- | --- | --- |
| AG01 demanded modernity | Complete MA objective/caller/capability domain; explicit Bmin/C-full/Z-full comparisons | Full candidate defined; concrete whole-cohort denominator still open |
| AG02 semantic/runtime theory | Root/update/context/member/control/capture/module contracts and all-exit source correspondence | SharedRuntimeContract/CT states proposed; physical protocol/refinement unresolved |
| AG03 provider legality | Per-pass semantic domain/effect/control/relocation preservation and target/tail/object ABI plan | LLVM/MLIR mechanisms identified; no pass/target/runtime capability newly admitted |
| AG04 actual retirement | FD owner/caller/product replacement and bounded legacy support | Nine conditional responsibilities; no implementation retired here |
| AG05 total economics | Positive justified total architecture value versus actual current/repaired baseline | Stage-removal/reuse mechanisms concrete; effort/value bounds unestablished |
| AG06 Zig increment | Same-capability C-full control; support union and conservative marginal costs | Candidate mechanisms specified; positive increment remains open |
| AG07 later native acceptance | Exact-profile independent semantic/root/control/progress and matched performance evidence after authorized implementation | Separate future phase, no tests/implementation authorized by this research |

Next theory work is complete SharedRuntimeContract object/root/participant/control
operations and their cross-backend realization, tied to the necessary service
portfolio/FD retirement graph. It is not another isolated saved0 patch exercise.
Bmin remains a control and source evidence. New architecture may replace that
storage/ABI design rather than inherit every local mechanism as a prerequisite.
No aggregate numerical score or empty provider wrapper can bypass AG01-AG06.
