# Allocation Bounds and Scheme-to-Zig: Modernization Report Matrix

Reviewed: 2026-10-20. Theory/design only, without implementation/native tests,
checked proof, accepted theoretical gate or positive economic bound. Read the
[clear backend position](scheme-to-zig-architecture.md),
[bound/metadata design](allocation-check-bound-design.md),
[source/papers](allocation-check-bound-evidence.md) and
[trace map](allocation-check-bound-traceability.json).

## Recommendation and Fair Controls

Recommend a genuine Scheme/GVM semantic-completion -> native Zig product as an
architectural candidate, with the same runtime/service authority used by native
MLIR/LLVM products. It can carry substantive replacement of C generation and
system-service ownership; it is more than build/distribution glue. Require
complete control/root/GC/bound/metadata obligations rather than inferring them
from a generated language or LLVM affiliation.

C-G/C-full is equally modern generated C using the same Scheme descriptions,
typed helpers and mature libraries; C-ZT adds useful Zig tooling to that C route.
Z-full includes Zig native services and, where selected, generated Zig program
code. Compare complete equivalent capabilities and the same maintenance horizon.
Current macro-heavy C is B0 for total modernization, not the ceiling offered to C.

| ID / dimension | Common modernization value | Modern C-G / C-ZT maintenance after reuse | Zig-specific opportunity and added work | Gate / present result |
| --- | --- | --- | --- | --- |
| ABV01 Explicit write/address bounds | Replace scalar-debt assumptions with target/event-bound assurances and pending work [ABR01--06]. | Scheme-generated summaries/checks, checked arithmetic helpers and opaque interval APIs. | Typed records/error cases can simplify local builders; same actual schedule/provenance/loop proof required. | Selected 3-word pair, 2-word box and <=255 small cases are conditional. No universal B or Zig-exclusive correctness benefit. |
| ABV02 Dynamic construction and slow paths | Correct fast/probe/post-return bounds, still dispatch and rooted reload [ABC04--09, ABS01--07]. | Reuse fill/error/save-reload/allocator support; replace whole-section assumptions and finish-capacity paths. | Explicit result variants/allocators can reduce private cleanup plumbing; C/native callback and arbitrary exit bridges remain. | Actual grant, complete frame and remaining-work closure required; no error union supplies contiguous memory. |
| ABV03 Floating materialization | Charge actual dirty versions on the correct side of a check [ABC02/03/08]. | Generate the same F64Box representation/effect cases; reuse cache/liveness algorithms. | Typed planned/actual event distinction may aid support; same NAN/self-tagged/alignment/source invalidation work. | Potential boxes differ from actual boxes. Cache algorithm semantics cannot be counted as removed solely by Zig. |
| ABV04 Sparse completion metadata | One recipe and actual ownership/frontier/exception authority [ABO01--08, ABM01--08]. | Generated dense grammar and explicit sparse exceptions; mature storage/transaction primitives. | Native range/union construction can shrink local support; actual writer/pin/snapshot/retirement remains explicit. | Avoid global percons journaling where qualified. If object-start indexing is needed, count its real space/build/lookup cost. |
| ABV05 Scheme-to-native product generation | Retire old C-only late semantic decisions; share completion/frame/check meaning [ZBD01/02]. | A rewritten typed C emitter can remove macro and duplicated layout support too. C-ZT can reuse useful Zig tools. | A real Zig emitter replaces generated C on its admitted route, with compiler/target/interop/module maintenance of its own. | Qualify complete constructor/primitive/module domain; changing extension or translating old C is not retirement. |
| ABV06 Tail calls and continuation | Explicit selected tail-host or dispatch-host semantics [ZBD05/06]. | C can implement either profile and explicit Scheme frames. Existing trampoline/control algorithms are credited. | Zig switch/loop and requested tail calls express candidate realizations; unsupported edges reject their profile. | Dispatcher overhead/register traffic or tail-ABI target limits remain real costs; never mix profiles silently. |
| ABV07 C FFI, runtime and native lifetime | Reuse sound GC/control algorithms while replacing owner/participant/service coupling [ZBD03/07]. | Mature C libraries/ABI and qualified islands can already support a shared authority. | Zig C integration can host native services; raw Scheme roots, C nonlocal transfers and native effects remain work. | One runtime authority; no duplicated C/Zig quota/layout roots. Unknown writers can retain VM indefinitely. |
| ABV08 MLIR/LLVM high-level leverage | Semantic export and provider isolation enable shared transformations/artifacts [ZBD04, AB-P04/P05]. | Same contracts and C ABI can access provider service; C++ dialect/pass work is common. | Zig can own request/product/lifetime orchestration across services; generated Zig is an optional native product. | High-order semantics must survive before low-level emission. Count common LLVM/provider benefits once. |
| ABV09 Generated-C work and bootstrap | Converted route can remove its old generated-C preprocessing units [ZBD08]. | Modern typed generated C may remove much macro work; C-ZT already receives tooling/cache benefits. | Zig route substitutes Zig parse/semantic/native compilation; possible compiler self-host target requires its full dependency closure. | No total cold/startup/compile speedup inferred. Macro/phase/interface construction work remains separate. |
| ABV10 Shared support and recurring cost | One semantic/metadata/runtime service can replace repeated native scaffolding [ZBD09]. | Credit generated C helpers/generators and existing libraries before comparing remaining support. | Potentially smaller private support plus explicit native products versus migration, tool/stdlib/target/ABI and retained-island costs. | Architectural candidate recommended; positive total and Zig-only economic bounds still unresolved. |

## Quantities and Cost Accounting

Source cases distinguish **word span**, **excess above trigger**, and **physical
native storage**. For the stated profile, pair=3 words, allocated box=2, and a
selected post-check n-element vector with d actual allocated-box events has
bound n+1+2d; the n=10,d=3 case is 17 words. Portable planned pair/flonum costs
are four words. Small dynamic macro extent<=255 is not a bound for literal
groups or slow helpers. The rest/key independent-maxima finish expression gives
25601 words before extras only under its named assumptions; neither reachable
state nor overflow is established.

Each actual interval must satisfy both write and formed-address/lower-bound
conditions. For rebase-free spans h<=L and B=max(0,W,P), require L+B<=b.
On a guarded fast edge, zero excess above L does not mean zero allocation work.
The bound can be rejected or changed by a new boxing representation, helper,
native target, schedule, constructor size or control profile. No native test or
compiler execution was used to establish these cases.

Let K be qualified compact runs, X sparse/partial exceptions and P pending real
users/constructions. A proposed compact service can organize O(K+X+P) records
plus variable payloads only if its grammars and actual lifetimes permit it.
Stronger arbitrary-object-start validation may need additional perobject data.
Neither Zig slices nor generated C types remove those semantic space costs.
Indefinitely unknown effects do not have a proved finite retention bound.

For a fully migrated compilation route, generated-C unit count becomes zero
only if that route no longer invokes the old C emitter/preprocessor. Retained
runtime/FFI C units still count, and Zig semantic/native compilation replaces
the removed work. No time ratio is assigned. Code-generation, request/byte/
lifetime services are shared once; each actual semantic/ABI adapter and old
unretired route adds its own costs.

## Matched Maintenance Events

| ID | Event | Work retained in both / actual language-dependent residual |
| --- | --- | --- |
| ABE01 | New constructor, literal size or runtime helper. | Both update actual events, bound/roots/completion/abort and domain closure. Compare generated C and Zig support after common generator reuse. |
| ABE02 | New FP cache policy/representation. | Both track dirty versions, pre/post-check boxes, alignment and exact roots. Local enum/type savings do not remove materialization algorithm work. |
| ABE03 | New sparse grammar or arbitrary-pointer validation. | Both maintain recipes/actual coverage, diagnostic/scanner consumers, exception retirement and any object-start data. Count real runtime metadata and contention. |
| ABE04 | New host/control/FFI target. | Both cover module/label/frame/tail/dispatch/continuation and callback/native exits. Zig adds actual compiler/language interoperability work; modern C controls get equivalent architecture. |
| ABE05 | New optimizer/provider or LLVM upgrade. | Both invalidate affected schedule/materialization/root/bound contracts; C++ MLIR work is common. Zig-specific tool/API changes are separate from common provider upgrades. |
| ABE06 | Remove an old native path or bootstrap stage. | Both require complete caller/artifact/profile closure. Record actual removed authority, generated work, adapters and permanent islands; do not count a wrapper as retirement. |

## Conditions for Positive Net Benefit

| ID | Condition | Refutation / open boundary |
| --- | --- | --- |
| ABN01 | Complete common semantic plan replaces C-only decisions and redundant native ownership in the chosen cohort. | If old emitter/scalar/list/layout authority remains required on every new route, the design adds orchestration without its claimed decoupling. |
| ABN02 | Useful shared architecture capabilities exceed full migration plus bound/metadata/check/dispatch/retention costs. | Positive theoretical capability is not yet positive aggregate economics; an expensive sparse journal, redundant checks or native stalls can negate it. |
| ABN03 | Residual Zig support avoided after generated modern C/C-ZT reuse exceeds incremental tool/ABI/target/interop/migration cost over the same horizon. | If C generation removes the same boilerplate, the Zig increment may be zero/negative. No positive lower bound is currently established. |
| ABN04 | All required source/target/native/control/root/constructor/helper domains are admitted without dropping semantics. | A selected size equation, explicit dispatcher sketch or source endpoint does not qualify the full runtime/backend. Unclosed helpers and C islands remain actual costs/gates. |
| ABN05 | LLVM/MLIR capability is independently tied to high-level semantic export and runtime contracts; Zig adds a bounded service/product advantage. | If justification is just “Zig uses LLVM” or faster builds without matched work evidence, no Zig-specific leverage has been demonstrated. |

The architecture recommendation is affirmative: design Zig as a real native
backend and system-service carrier, preserving Gambit's Scheme and GC assets.
Modernization is achieved by the explicit contracts and retired responsibilities
that this enables. Language choice and whole-project economic acceptance remain
separate decisions; all five full architecture requirements and AG05/AG06/
future-native AG07 remain unresolved.

## Real Function and Carrier Selection

The [reverse modernization matrix](scheme-function-zig-cost-matrix.md) compares
the same complete control/root/module capability in C-G, C-ZT and Zig. It credits
common restructuring and LLVM value once, records actual old responsibilities
and lifecycle falsifiers, and specifies the modernization program that continues
if Zig's incremental net is not positive. No positive bound is accepted.
