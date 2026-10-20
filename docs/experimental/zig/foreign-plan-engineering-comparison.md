# Same-Contract Engineering Case: Modern C, Zig and Compiler Services

Date: 2026-10-20. Design accounting, not an effort estimate or a performance
result. [ForeignPlan](foreign-plan-contract.md) / [source ledger](foreign-plan-evidence.md)
/ [adoption questions](zig-adoption-value-questions.md).

## 1. Compare the Same Work, Not Different Architectures

B0 retains today's source-bound paths. B1 extracts ForeignPlan, generates
adapters and explicit artifacts using modern C/existing tools. Z1 implements
the same native responsibilities with Zig. P is an orthogonal provider choice:
direct LLVM service, MLIR service, or no LLVM service for a selected workload.
C++ can be confined to provider features that need it. It is not an exclusive
alternative to using Zig for unrelated native resource/product responsibilities.

All candidates must preserve Gambit's semantic/runtime obligations and support
the same selected capabilities. A smaller capability set can be a valid scope
decision, but it cannot be presented as an implementation-language speedup.

| Task | Common cost under B1 and Z1 | Plausible Zig mechanism / cost still charged | Evidence / measure |
| --- | --- | --- | --- |
| EC01 parse-time information capture | Scheme producer, IDs, resolved types, source/provenance and registry lifecycle refactor | No Zig-specific saving; both need the Scheme change | FS01/FS07/FS08; Q01/Q08 |
| EC02 conversion/effect program | Specify order, failure continuations, resource acquisition and semantic verifier | Typed native consumers may reduce inconsistent adapters; effect laws remain Scheme-owned | FS05/FS11/FS12; Q08/Q10 |
| EC03 physical ABI and adapter emission | Layout/calling/cross-backend entry, debug/source mapping and generated products | Native metaprogramming and C ABI interfaces are candidates; C descriptors/generators are a real comparator | FS10/FS13; Q08/Q16/Q17 |
| EC04 nonlocal control | Matching marker/catcher, callback restrictions and legal C-control extent | Zig frames impose an explicit containment condition; may require a narrow generated C envelope | FS15-FS18; Q10/Q16 |
| EC05 native resources | Acquire/release/ownership/cancel/close and failure records | Explicit allocator/typed resource conventions may simplify normal-return code; no automatic cleanup across foreign escape | FS14-FS16; Q09/Q15/Q16 |
| EC06 opaque C/C++ units | Preserve bodies, include/macro closure, custom converters and target layout | Zig can construct/compile/package units; cannot eliminate opaque dependencies merely by importing headers | FS02/FS04/FS13; Q02/Q04/Q16 |
| EC07 native service boundary | Native-owned requests, completion, diagnostics, GC participation and process/thread owners | Reusable transport/resources across services are candidates; queue/copy/wait overhead remains | FS11/FS17; Q09/Q11/Q14/Q15 |
| EC08 LLVM/MLIR adapter | Provider APIs, dialect/pass legality, handle lifetimes and upgrade invalidation | C access is available to B1 and Z1; C++ service may be needed for missing surfaces | FU02 and existing pass gates; Q05/Q06/Q17 |
| EC09 real retirement | Replace all selected callers and old emission decisions; preserve required C capability via new emitter | No benefit until selected duplicates disappear; coexistence and migration charged | FR01-FR08, M/H plans; Q01/Q16/Q18 |
| EC10 distribution and upgrades | Toolchain/SDK/profile matrix, bootstrap, debugging, incidents and maintainer training | Zig introduces its own version/build/language axis; bundled tools may reduce other packaging work | FU01; Q04/Q05/Q16/Q17 |

These are ten responsibility groups, not ten measured savings. No hour values,
percentages or implemented capabilities are assigned. A failed prototype would
not retroactively prove the contract unnecessary; a good contract does not
retroactively prove Zig pays for itself.

## 2. The Leverage Mechanism and Its Limit

The architectural opportunity is to replace repeated implicit decisions with
one semantic producer and reusable native products. The same plan can feed a
portable C emitter, a low-level native emitter and selected compiler services.
It can expose converter/control obligations before build work and isolate
provider handles from Scheme objects. This reduces the places where a future
representation or provider change must be implemented, if those owners really
are retired. It does not reduce the required semantic qualification by decree.

Zig's candidate increment is concentrated in EC03/EC05/EC06/EC07: typed product
descriptions, explicit native allocation, C interoperability and reusable native
service/resource mechanisms. Its added costs concentrate in EC04/EC08/EC10:
control containment, provider adapter/version work and toolchain/maintainer
ownership. EC01/EC02/EC09 are architecture work, not Zig benefits. C++ provider
services may be useful in either B1 or Z1. Replacing C with Zig solely to reach
MLIR's C API is not a necessary step.

This is a larger role than a build launcher, while remaining subordinate to
Gambit's language and managed-runtime authority. Rewriting the collector or
all C runtime code is not part of this case. Future collector work must specify
an actual algorithm/protocol benefit and be evaluated separately.

## 3. Quantification Without Inventing a Workload

For one selected capability and revision, record these independent denominators:

- **Source families:** the 18 FS responsibilities inspected here. Their mapped
  count says nothing about user call sites or supported signatures.
- **Selected foreign sites:** parser-generated c-lambda/c-define, implicit
  converters, opaque C operations and reachable callbacks in a named input
  closure. The current complete denominator is unknown.
- **Capability cells:** direction, representation/conversion, control, lifetime,
  origin/context, target ABI/runtime revision and output route. Count requested,
  represented, source-reviewed and natively admitted cells separately. Never
  multiply every dimension blindly and call it actual demand.
- **Live authorities and callers:** old/new semantic, layout, wrapper and
  module owners in the selected cohort. A body moved without removing an owner
  is migration work, not demonstrated simplification.
- **Engineering events:** initial implementation/review, changed converter,
  changed runtime representation, new provider release, new target/profile,
  new callback need and a representative lifetime/control defect.

Each event needs B1 and Z1 task records: source inputs, touched owners, generated
and hand-maintained adapter surfaces, tests/qualification work, review/debugging
hours, unresolved defects, and recurring ownership. Record unfamiliarity/training
explicitly rather than assuming equal expertise. Count defects and support costs
as well as code volume. No such time records exist in this study.

For native services, the full cost expression is:

```text
delivered-result cost = Scheme entry/publication
  + argument conversion/copy + native work
  + callback/reentry work + wait/queue/coordination
  + result conversion + cleanup + Scheme reacquisition/error delivery
```

These are accounting terms, not independently summable wall times when stages
overlap. Batching reduces boundary count only if ordering, failure granularity,
latency, cancellation and observation semantics allow it. Unknown foreign effects
prevent a blanket batching rule. Zero-copy additionally needs lifetime/alias
and GC evidence; it is not the default benefit of C ABI compatibility.

Provider leverage is measured by the recurring mechanics actually delegated
upstream and by the adapter/qualification closure left locally. MLIR's useful
interfaces do not eliminate Gambit's effect/control work. An ABI-preserving
library upgrade that changes callbacks, retention or conversion semantics may
invalidate ForeignPlan assumptions even without a changed symbol signature.

## 4. Demand Portfolio and Decision Boundaries

| Prospective demand | Existing evidence | Next missing decision input |
| --- | --- | --- |
| Historical Darwin pre-first-compile work | Source-bound retained patch studies distinguish constructor code from fresh instances | Current selected workload/frequency and exclusive removable budget; no Zig startup attribution |
| Many ordinary foreign kernels | Parser/runtime paths establish a real mechanism and conversion costs | Actual sites and native work distribution; how often boundary cost matters |
| Long LLVM/MLIR service requests | Existing architecture proposes native-owned isolated services | Named user capability, input/result sizes, callbacks, latency and operational budget |
| Callback-rich C libraries | Marker/control/manual sources establish constraints | Actual library callback ABI and required legal Scheme control behavior |
| GC/multicore/VM modernization | Runtime has existing parallel machinery and open integration gates | Concrete algorithm/lifecycle goal, demand and sequential-regression budget |

These are research demand categories, not five observed workloads or an
authorization to run them. No usage frequencies or business priorities are
fabricated. The semantic contract can be designed now while adoption economics
remain unresolved.

There is also a concrete [kernel consumer slice](foreign-plan-evidence.md):
KU01-KU03 bind released-state query, release/error delivery and address query.
These three source occurrences demonstrate actual use of the proposed field,
conversion and lifetime responsibilities. They supply neither operation
frequencies nor a complete reachable-site denominator. Both B1 and Z1 can replace
these runtime-owned snippets with reviewed semantic operations; the benefit of
that extraction belongs to the shared architecture until a Zig increment is
independently demonstrated.

Adopt broader Zig ownership only if the selected portfolio needs it, the native
capabilities are admissible, the same-contract B1 comparison is favorable over
an agreed horizon, and the named old owners can actually retire. Narrow to
ordinary-return services if that is the valuable supportable surface. Keep
control-sensitive paths in generated C where their semantics require it. Choose
B1 or a direct provider service if it meets the need at lower full cost. Reject
unbounded permanent duplication of all old and new routes.

## 5. Reviewed Decision Update

VQ03 now has a more concrete extraction target: parse-time typed capture,
ordered conversion plans and explicit emission ownership. VQ08 now has an
18-family producer/consumer map, stage-specific effects and a control-containment
policy. These close a source-design slice, not the call-site denominator or
native correctness. VQ04 remains conditional: the comparison identifies where
Zig might help and where it adds obligations, without measured preference.
VQ01 and VQ12 remain unresolved because demand and comparative engineering
costs are missing. FR/M/H stages remain proposed; none is retired here.

Continue source research first on the transitive release/custom-converter and
dynamic C-closure ownership paths, and on concrete selected consumers. Preserve
the demand/cost questions alongside that work so a larger semantic map cannot
be mistaken for a stronger economic case.
