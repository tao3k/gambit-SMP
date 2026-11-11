# AOT Interface Construction: Shared Programs, Current Instances

Date: 2026-10-19. Architecture proposal only; no implementation, workload,
profile or performance validation. This refines the
[Darwin first-compile boundary](darwin-first-compile-boundary.md), rather than
proposing another Bazel cache or a faster consumer C compiler.

## 1. Selected Structural Change

Compile the **interface-construction program**, while preserving the original
rules for instantiating it in the current module/phase environment. Reuse code;
create live state when the original loader would create a new instance. An
ordinary repeated import that already returns the same cached context must
continue to return that context, not a new one on every request.

The legacy boundary transports interface instructions as textual `.ssi` forms.
At import, a general expander interprets those instructions and constructs live
contexts. Existing native phase artifacts already reuse executable code, but
do not eliminate this interface interpreter. The proposed product makes that
remaining construction program explicit and independently compilable.

This is a fundamental change in representation and staging, not permission to
omit initialization, share mutable import records or freeze an initialized VM.
It removes repeated *interpretation of known construction instructions* where
semantically permitted. It does not remove all construction or all expansion.
Source and cost evidence is collected in the
[evidence ledger](interface-construction-evidence.md).
The follow-up [operation/state design](interface-construction-operations-and-state.md)
directly audits a materialized Gerbil tree and narrows the previously open
cycle/publication rules for its source-import path. The
[Zig adoption review](zig-adoption-decision.md) makes the construction architecture
independent of a mandatory Zig implementation.

![Code and instance ownership](interface-code-instance.svg)

## 2. Producer and Consumer Boundaries

The producer belongs in **Gerbil's interface metadata generation**, where
`generate-meta-code` already consumes expanded module code
(`compiler/driver.ss:904`, retained audit E1). Generate an ordered construction
recipe alongside the existing interface representation, before textualization.
Do not run an interface in a fake context at build time and serialize the
result. The producer records dependencies and effects without executing their
consumer-time callbacks or phase initializers.

On the consumer side, the retained module entry accepts sealed expanded syntax
(`expander/module.ss:633-645`). This is only a possible final handoff boundary:
`sealed-syntax?` recognizes a representation, not proof that binding and import
effects have happened. Quoting raw SSI is incorrect [E1].

The normal module path has two stages: head expansion/resolution and special
handler invocation, then module-body expression expansion and deferred export
resolution. Many handlers already return sealed forms; this is not evidence
that every user macro is expanded twice. The constructor must preserve both
stages and return code/import fields expected by later compiler passes [E1].

This interface export is **upstream of Gambit**. It is separate from the Gambit
resolved-tree export proposed in the [high-level semantics design](zig-high-level-semantics-design.md).
Changing only Gambit's C backend cannot remove Gerbil work that has already
run before Gambit receives a program.

## 3. Product and State Contract

The following names describe responsibilities, not an implemented wire format.

| Component | May be reused | Must be resolved or created for the current instance | Evidence / obligation |
| --- | --- | --- | --- |
| Construction code | Immutable instructions/native code, schema and semantic profile | Invocation state and current environment parameters | E1, E5; compilation and instantiation are distinct |
| Dependencies | Symbolic module IDs, phase offsets, ordered import recipes | Current imported instances and live variable/binding references | E1, E5; do not snapshot previous globals |
| Contexts and bindings | Names and verified immutable descriptors | Parent/phase contexts, binding tables/cells, required identity and rebinding callbacks | E1, E7; retain existing same-instance registry behavior |
| Import/export data | Construction instructions and immutable descriptions | Required mutable records and retained compiler-facing references | E1; final types have setters and records survive import |
| Syntax and literals | Source metadata and reconstruction recipes; proven shareable constants | Context-bearing syntax, marks/stamps and identity-sensitive or mutable literal objects | E1; preserve alias relations, not old heap addresses |
| Syntax/property declarations | Executable initializer code or symbolic factory references | Next-phase evaluation, property effects and installed current values | E1; these are executable declarations |
| Module evaluation | Delayed initializer code | Atomic promise, demand/completion/error state and cycle relationships | E1; no eager evaluation on artifact HIT |
| Expanded body | Code template and symbolic relocations | Current-context syntax and deferred export results | E1; a sealed template alone is insufficient |

Freshness follows the original semantic allocation rules. Imported variables
that are intentionally shared with an existing dependency remain shared;
freshening them would also be wrong. A mark reconstruction map must preserve
required equality/inequality and imported lexical references. A gensym or a
mutable syntax property cannot be declared a shared constant merely because
it occurs in an AOT artifact.

The recipe contains no process-specific Scheme heap address, stale context,
previous phase value or prior handler result. Native addresses need ordinary
compatible-image relocation, not persistence of historical pointer bits.
Context-bearing objects remain under Gambit GC and its rooting protocol;
Zig arenas cannot own their semantic lifetime.

## 4. Ordered Instantiation and Live Dispatch

The constructor has these logical obligations. They are not a newly asserted
transactional lifecycle for the historical loader:

1. Validate artifact compatibility before any semantic effects. Resolve current
   loader identity and select the existing registry result or new-instance path.
2. Establish contexts under the original cycle protocol. The directly audited
   source-import path publishes the new context only after expansion and raises
   on an uncached expansion cycle; do not add an initializing placeholder.
   Preserve distinct prelude-cache and already-cached instance behavior.
3. Execute first-stage instructions in original order: resolve dependencies,
   allocate required import records, install bindings, execute phase/property
   code and retain the expanded-body representation. Preserve dynamic parameters,
   error order and callbacks. Keep initialization delayed where originally delayed.
4. Perform remaining expression expansion and deferred exports against the
   resulting current context, at the original semantic positions. Do not
   resolve every export immediately when reading its declaration.
5. Deliver context-correct expanded syntax and loader state. Retain the original
   atomic evaluation promise and its demand/cycle/concurrency behavior.

The follow-up source audit specifies this source-import publication path and
the atomic-promise exception/reentry distinction. Other loader paths and complete
control correspondence still need coverage before wire-protocol admission. Atomic
artifact publication is not evidence that live instantiation is all-or-nothing:
callbacks can have visible effects before an error, suspension or continuation
capture. Do not invent rollback or replay those effects a second time.

**Dispatch remains an observable operation.** E7's original-native control
replaces the reached `core-expander?` predicate; that predicate mutates the head
binding, and the original caller selects the replacement handler. Therefore
even transferring a seemingly duplicate terminal resolution unguarded is
incorrect. The AOT constructor cannot hardwire a historical handler just because
the original metadata was produced with that handler.

Select a mixed execution policy: compile stable structural scaffolding; retain
live resolver/predicate/handler operations wherever the supported semantic
profile makes them observable. Any stronger specialization must establish an
explicit immutability or dependency-guard contract, preserve the guard's own
effects and invalidate at every relevant mutation. A single entry-time global
pointer comparison does not protect later callbacks that change the context.
No such stronger contract is established by the current evidence.

Unknown forms or incompatible producer semantics choose the ordinary interface
path **before effects begin**. After partial instantiation, never restart the
whole textual interface as fallback. Residual interpreter calls may operate
on the current state only when their exact continuation point is specified;
otherwise reject that recipe at production/admission time. This prevents a
fast path plus fallback from running initialization twice.

## 5. What Must Change, What Can Be Reused

| Owner | Reuse | Required architectural change | Limit |
| --- | --- | --- | --- |
| Gerbil producer | Expanded module metadata, phase compilation and textual interface tooling | Emit typed, ordered construction operations with symbolic relocations, source origins and explicit residual dynamic operations | Main semantic refactor; cannot be delegated to a generic native linker |
| Gerbil expander/loader | Context/binding primitives, registry/cycle protocol, phase evaluator and atomic promises | Add constructor admission and current-instance execution; preserve two-stage behavior and reflection/error observations | Exact semantic coverage remains open |
| Gambit | Scheme compilation, GC, FFI, control and runtime protocol | Compile factory code; expose only required compatible native entry/roots contracts | Does not decide Gerbil phase/import semantics |
| Zig engineering layer | Native compilation, packaging, target compatibility, artifact transport and isolated services | Construct/load a compatible factory bundle with an explicit producer manifest | Must not construct unrooted Scheme graphs or cache live contexts |
| Optional MLIR service | Multi-level lowering and target code generation | Model factory effects/fresh identity; optimize admitted closed portions | Cannot apply generic purity/CSE/LICM to whole instantiation |
| Bazel, where used | Outer dependency/action scheduling | Consume declared constructor artifacts and producer keys | Cannot infer missing semantic dependencies |

A Scheme factory compiled through the existing Gambit native route and a future
MLIR-compiled factory are alternative code-generation choices for the same
semantic contract. Zig is the engineering carrier; MLIR is optional. Neither
is the source of correctness. Their separation allows new targets and compiler
services without moving the language's authority out of its producer/runtime.

MLIR could represent operations such as current import resolution, fresh binding
allocation, phase evaluation and deferred export completion in a custom dialect.
These need ordered semantics including nonlocal control and dynamic dispatch.
Memory-effect annotations alone do not establish termination/speculation or
aliasing correctness [E6]. Only genuinely closed, identity-insensitive code
may enter generic optimization passes under the existing
[pass admission contract](mlir-pass-admission.md). GC and continuation support
remain prerequisites, not benefits conferred by the choice of IR.

## 6. Artifact Keys and Invalidation

Use the existing [artifact envelope](compilation-unit-artifact-contract.md):
request identity, content digest, compatibility and qualification are separate.
An artifact HIT is permission to reuse code, not evidence of a live valid instance.

| Change | Constructor artifact | Live instance |
| --- | --- | --- |
| Expanded interface instructions, source origins or relevant reader/expander semantics | Regenerate affected recipe; rebuild compiled code when its inputs change | Follow existing loader/reload semantics |
| Dependency export/phase contract used for specialization | Invalidate dependent assumptions; symbolic-only code can survive only if its contract proves independence | Resolve current dependency generation |
| Dependency body/init changes with unchanged interface | Reuse code only if no embedded body assumptions; invalidate any recorded phase-execution dependency | Do not reuse old initializer results by content coincidence |
| Current parent, marks, registry or parameter state | Pass as invocation inputs if the recipe is environment-parametric | Create/reuse according to original identity rules |
| Observable handler/predicate or binding mutation | Residual live operations see it; specialized code must deopt under a proved protocol | Preserve mutation visibility and callback order |
| Runtime/GC/native ABI or target changes | Reject incompatible native factory; regenerate as required | Never import old heap objects |

Do not hash an entire mutable environment as a substitute for specifying inputs.
Conversely, do not omit a dependency just because it is inconvenient to key.
Textual interfaces may remain for inspection and unsupported profiles, but a
modified interface and retained factory must not silently describe different
programs. Producer ownership and manifest validation decide which artifact is
authoritative; local ad hoc textual edits require regeneration or ordinary import.

## 7. Quantitative Benefit Boundary

The first genuine compilation log has a historical **5-second ceiling**, not a
fixed cooldown. A decomposition useful for design is reader/preparation,
generic dispatch, required instantiation, phase execution, loading and other
runtime work. Existing nested observations do not provide exclusive values
for all those categories; GC must not be counted twice.

For a matched workload, let `T` be original elapsed time, `f` the *exclusive*
fraction actually eligible for improvement, `s` its acceleration, and `H` added
factory loading/validation/materialization overhead:

`T_new = T * (1 - f + f / s) + H`

Even infinite acceleration leaves `T * (1 - f) + H`. Neither `f` nor `H` is
established for this design. There is no supported seconds or factor forecast.
Removing textual interpretation saves only the work actually replaced; required
fresh allocation, dynamic dispatch effects and phase initialization remain.
An improved equivalent algorithm could reduce their cost later, but freshness
does not license dropping objects from the public contract.

Evidence E2 constrains reader-only proposals to the observed small component;
E1's handler timers omit preceding head resolution and cannot bound its cost.
Binding counts are not time fractions or safe-elimination counts. E3 rejects
assuming another phase serialization layer improves existing native reuse.
E7 prohibits an apparently simple unguarded resolution shortcut. These limits
leave a structural research route, not an admitted major-gain candidate.

Charge producer AOT cost `P` and distribution/image costs as well. With `N`
equivalent future instantiations and net saving `delta` per instantiation, a
simple aggregate break-even condition is `N * delta > P`; it does not prove
each cold build meets its gate. Prepackaging code may move compilation out of
startup, but must not hide it from complete-build accounting or compile the
factory on every fresh launch. More native code can also increase image load
and working-set cost [E5].

## 8. Architectural Closure and Remaining Obligations

Selected: producer-owned construction programs; current-instance semantics;
ordered effects and deferred exports; residual dynamic dispatch by default;
Gambit-managed object lifetime; optional, separately admitted MLIR lowering;
Zig-owned native engineering. This addresses the historical coupling between
interface transport and repeated interpretation without confusing code and state.

Not selected: cached initialized contexts across processes, raw quoted SSI,
shared mutable import records, unguarded resolved-binding transfer, another
native-phase serialization layer, a symbol-only replacement for public context
tables, or reclassification of the full startup interval as removable work.

Before implementation, close the operation inventory, lexical-identity
reconstruction, dynamic-dispatch profile, cycle/error/continuation semantics,
and producer dependency projections. Later equivalence must cover independent
stdlib imports, same-instance identity, mutation and phase/error ordering, then
real complete workloads under their unchanged gates. Those are future admission
obligations; no new experiment is requested or performed here. A persistent
compiler service could amortize more live state, but changes isolation and the
cold-start workload contract and is a separate architectural decision.
