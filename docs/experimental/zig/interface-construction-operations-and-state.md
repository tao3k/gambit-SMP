# Interface Construction Operations and Instance State

Date: 2026-10-19. Design and source review only. No implementation, semantic
test, model execution or performance experiment. Refines the
[construction architecture](interface-construction-aot-design.md) and answers
the separate [Zig adoption question](zig-adoption-decision.md).

## 1. Source Basis and a Lifecycle Correction

This review directly reads the materialized Gerbil tree at
`gerbil-bazel/.data/ci-source-patch-check`, Git HEAD
`1cfb032c7a1612637da6205f5f8a15683eba3ba0`. Its Gambit submodule is
`ea114fc3d2f120abbe20393c1f9aeafdd3f8c89f`. This is a different source identity
from the research repository's vendor Gambit. The tree has local patches:
the inspected `compiler/driver.ss` has 270 added / 43 deleted lines; the other
listed Gerbil files have no tracked diff. Hashes below identify the actual
bytes read. These source observations do not qualify an installed binary or
overwrite the [historical report ledger](interface-construction-evidence.md).

| ID | Directly read source, relative to that tree | Relevant observation |
| --- | --- | --- |
| S1 | `src/gerbil/expander/module.ss:94-225` | Import/eval hooks are parameters; registry HIT precedes source import; normalized path cycle check; parameterized source expansion; path/id registration after expanded code and atomic promise are installed |
| S2 | `src/gerbil/expander/module.ss:541-570,633-718` | Imports resolve current exports and allocate bindings/records; two-stage body expansion; properties and value bindings precede deferred expression/export expansion |
| S3 | `src/gerbil/expander/module.ss:720-890,910-1064` | Import/export phase offsets and user expanders; reverse accumulators; import retention precedes positive-phase dependency evaluation; export resolution updates current context |
| S4 | `src/gerbil/expander/core.ss:13-40,173-181,249-258,281-356,430-622` | Dynamic environment and evaluator hooks; live head dispatch; macro marks; alias/import resolution; rebinding policy and lazy gensym substitution |
| S5 | `src/gerbil/expander/core.ss:624-713,788-836`; `src/gerbil/expander/stx.ss:13-40,109-182` | Identifier keys include marks; phase contexts allocated lazily; sealed syntax retains context/marks; mark cancellation uses identity; existing mark deserialization creates a current-context mark |
| S6 | `src/gerbil/expander/top.ss:273-356` | Runtime references bind before properties; properties may evaluate at the next phase; syntax declarations expand/evaluate at phase +1 before installation; aliases retain quoted lexical references |
| S7 | `src/gerbil/runtime/control.ss:11-28`; `src/gambit/lib/_kernel.scm:1861-1921` | Atomic promise wraps inner force in mutex/dynamic-wind and a continuation-entry guard; underlying force stores a successful result after the thunk returns, not an exception at its throw site |
| S8 | `src/gerbil/compiler/driver.ss:904-909`; `src/gerbil/compiler/compile.ss:1251-1270,1438-1497` | Expanded module code generates interface metadata and separate phase blocks/native loads; runtime declarations, syntax declarations and aliases have distinct producers |

Workspace source links: [module lifecycle](../../../../../.data/ci-source-patch-check/src/gerbil/expander/module.ss),
[bindings and phases](../../../../../.data/ci-source-patch-check/src/gerbil/expander/core.ss),
[atomic promise wrapper](../../../../../.data/ci-source-patch-check/src/gerbil/runtime/control.ss),
[underlying promise force](../../../../../.data/ci-source-patch-check/src/gambit/lib/_kernel.scm).
These materialized-tree links require that local evidence tree; the identities
and hashes are retained below for later reconstruction.

The previous architecture intentionally left publication/cycle details open.
For **this source-import path**, they can now be narrowed: no registry entry
for the new source context is published before module-body expansion completes.
An uncached expansion cycle raises `Cyclic expansion`; it is not serviced by
an initializing placeholder. Other paths, including already cached modules,
submodule lookup and prelude-context caching, have their own behavior [S1].
The model below preserves that distinction instead of adding a universal
in-progress registry or promise-cycle algorithm.

## 2. Operation Inventory

These are semantic operation families, not a bytecode, executable schema or
claims that the current source exposes one function per row. Each instruction
retains source origin, original sequence position, current-context operands and
which stage may execute it. Default execution delegates effectful behavior to
the original Gerbil/Gambit primitives. A factory cannot execute a row twice to
recover from an artifact mismatch.

| Op | Inputs and result | Required behavior / effects | Evidence and repeated-work decision |
| --- | --- | --- | --- |
| C00 Admit artifact | Content/protocol/source manifest -> code or rejection | Native-only validation, before Scheme effects; unsupported input selects ordinary import | New artifact contract; not permission to omit reader/custom-language effects |
| C01 Enter import | Original request, reload/eval flags, current import hook -> context or request | Retain hook and registry lookup order, path normalization, alias/submodule behavior | S1; a code HIT is not an instance HIT |
| C02 Enter source extent | Normalized path and current path stack -> dynamic extent | Original cycle check; root context, empty marks, phi 0 and import/export phi reset; restore parameters on exit | S1, S4; keep path check, do not infer module identity from artifact hash |
| C03 Resolve prelude / allocate module context | Current prelude or dependency context, ID/namespace/path -> fresh context | Existing prelude cache semantics and fresh local table; retain module feature binding before module-head expansion | S1, S2; code/descriptors reusable, live context not globally shared |
| C04 Materialize syntax references | Literal/syntax recipe and current identity map -> syntax graph | Preserve imported context references, marks, mutable aliasing, source locations and fresh uninterned identities where required | S5; remove text decoding only for an admitted representation |
| C05 Resolve and dispatch head | Current form, marks, phi, bindings and live predicates -> original expansion action | Preserve observable resolver/predicate/handler calls, source wrapping and errors | S4, historical E7; no unguarded terminal-binding transfer |
| C06 Resolve import specification | Symbolic path/spec, phase displacement -> current export references | Preserve import/export expanders, rename/weak flags, missing-export errors and nested-module resolution | S2, S3; static shape may be prepared, current export lookup remains |
| C07 Instantiate import records and bindings | Current exports -> fresh required records/bindings | Resolve source binding now; apply rebinding/weak/conflict rules; preserve retained body/import references | S2, S4; do not deduplicate repeated names by spelling |
| C08 Finish import form | Original accumulated import body -> retained body and phase dependency effects | Preserve accumulator/list order, retain module imports, then evaluate required positive-phase dependencies through existing collection traversal | S3; do not sort dependency evaluation for reproducibility |
| C09 Bind runtime/value declarations | Current identifier/key and binding ID -> binding and expanded form | Bind before property processing or later expression expansion; preserve lazy marked-key substitution | S2, S6; descriptor code reusable, binding effects remain |
| C10 Process properties | Current binding and ordered property expressions -> installed properties | Preserve macro/type/property cases, phase +1 evaluation, mutation, exceptions and source context | S6; not a constant-data copy operation |
| C11 Bind syntax or alias | Syntax expression or quoted lexical identifier -> current binding | Syntax expression expands/evaluates at +1 before binding; alias retains lexical reference and resolves under original rules | S4, S6; do not freeze previous transformer values |
| C12 Execute phase body / residual form | Current phase environment and code -> resulting form/effects | Original compile/eval hooks, native phase loads, current parameters, arbitrary Scheme control | S4, S8; compiled code can be reused, effects cannot be pre-run |
| C13 Retain deferred body work | First-stage value/export forms -> original body representation | Preserve original reversal/accumulation and later traversal positions | S2; no eager export resolution |
| C14 Finish module-body stage | Completed first-stage context/body -> expanded expressions and export records | Expand value expressions and resolve exports in original second-stage order; perform live special-form checks | S2, S3; not simply all exports after all expressions |
| C15 Seal code and install delayed evaluation | Current completed body/context -> code plus atomic promise | Quote using current context/marks; install code and original promise; do not evaluate module eagerly | S1, S5, S7 |
| C16 Publish source instance | Completed context -> path/id registry entries | Original two puts after C15; preserve reload/old-entry behavior and library aliases | S1; not a new all-or-nothing registry transaction |
| C17 Demand module evaluation | Existing context -> forced result/effects | Evaluate prelude first, parameterize ctx/phi, use original promise and evaluator hooks | S1, S7; successful value memoization is existing behavior |

C08 and C14 are ordered semantic fragments, not blanket commutative graph nodes.
The source uses reverse lists and a dependency hash table: transport must encode
the same reconstruction and traversal behavior rather than invent a new sorted
order. S3 does not promise a universal deterministic order for independent hash
entries. C12 is an opaque residual capability: arbitrary user code is not made
safe by placing it in an instruction stream.

## 3. Dynamic Bindings: Two Different Kinds

**Expander binding mutation** affects names, aliases, imports, handler objects and
rebinding callbacks. `core-bind!` can keep an existing weak/import binding,
replace one, invoke policy, or raise a conflict. It can also allocate a marked
identifier substitution before the table operation [S4]. Repeated symbol keys
therefore do not imply repeated equivalent operations. A lookup itself can
create phase contexts through `core-context-shift` [S5].

The retained [live-head control](../../../../../patches/gerbil-v19-darwin/receipts/d1510-head-resolution-live-boundary.md)
demonstrates a predicate changing a binding between head resolution and caller
selection. Hence C05 must preserve the intermediate observation. Any optimization
that transfers a binding across that call needs a separate proof of stability;
one guard at constructor entry is insufficient.

**Dynamically scoped parameters** include context, marks, phi, path and evaluator,
compiler/import/eval hooks [S1, S4]. C02 and phase operations must retain original
parameterization boundaries, including restoration during exceptions and
continuation transfers. Do not capture them as code-generation constants or
replace them by a process-global Zig struct. A native compiler service receives
inert code/data, not the authority to execute current expander callbacks.

Two profiles must be distinguished:

| Profile | Permitted elimination | Required compatibility |
| --- | --- | --- |
| Legacy observable profile, selected default | Admitted representation decoding and proven private structural scaffolding; live C05-C12 operations remain | Preserve mutable dispatch and all existing observation points, including native direct-call behavior |
| Future controlled profile, unselected | Could specialize stable handlers and more static import shape | Explicitly specified restrictions, dependency guards and deoptimization semantics; cannot silently claim compatibility with arbitrary legacy mutation |

Thus the default factory may remove much less generic dispatch than an informal
“AOT the interface” claim suggests. No current evidence establishes a large
private, unobservable dispatch budget. A new restricted profile is a language/
environment contract decision, not a performance flag that may be silently enabled.

## 4. Lexical Identity and GC

The recipe uses symbolic references in four categories: `local context`,
`current dependency context`, `fresh mark/uninterned object`, and `immutable
descriptor`. At instantiation, a Scheme-owned identity map reconstructs required
sharing among references. Only identities freshly created by the original path
are freshened; imported contexts/marks intentionally shared remain references
to their current owner. Do not copy all dependency bindings into private cells.

S5's `apply-mark` cancels equal marks using `eq?`; two equal-looking serialized
marks are not automatically the same mark. S4's `core-bind!` lazily creates a
mark substitution table and gensyms; constructing those early can affect
observable identity/allocation/control. Preserve the original creation point.
Alias targets and quoted syntax carry definition contexts, not only names.
`syntax->datum` discards precisely the information needed for this contract.

Existing `core-deserialize-mark` creates a mark in a supplied/current context
and rebuilds substitutions [S5]. It is a reusable primitive, not proof of a
complete graph relocation protocol. Coverage must still specify context/mark
aliasing, cycles, gensym references, source properties and dependency reload.
No general lexical graph serializer is admitted here.

All current contexts, maps, code, promise thunks and retained records remain
GC-visible Scheme objects. A suspension may retain them beyond the native call.
An MLIR region boundary or Zig allocator scope is not a lifetime proof. Native
code may manipulate opaque rooted handles only under the existing runtime
contract; this design introduces no new public rooting or callback API.

## 5. Instance State Machine

![Instance and delayed-evaluation state](interface-instantiation-state.svg)

Artifact availability, source expansion and delayed evaluation are **three
different axes**. State names below describe observations, not new fields.

| Transition | Required source semantics | Exception / cycle consequence |
| --- | --- | --- |
| Request -> cached context | Invoke current import hook; original `reload?` lookup rules and aliases | Existing instance identity preserved; cache lookup can precede source cycle detection |
| Uncached source -> expanding extent | Normalize path; check active expansion path; establish parameters, resolve prelude, allocate context | Repeated active uncached path raises `Cyclic expansion`; no initializing context is returned |
| First stage -> second stage | Retain original work/body order and current bindings | Failure stops at its original effect boundary; no fallback replay |
| Completed expansion -> published interface | Install quoted code and atomic promise, then path and ID entries; add library alias on return | No new context is published by this source-import frame if expansion fails before those writes |
| Published interface -> demand | `eval?` or phase demand invokes current eval hook; prelude evaluation precedes context promise | Expansion success does not imply module evaluation success |
| Promise pending -> forcing -> determined | Original mutex/dynamic-wind and successful-result storage | Other forces use original synchronization; no parallel constructor-owned initializer |
| Forcing -> nonlocal exit | Original dynamic-wind unlock/parameter restoration; propagate original control | Do not add a terminal cached-error state or automatic rollback; inspect underlying promise state on a later ordinary force |

**Reload does not erase the old registry first.** S1 skips HIT reuse when asked
to reload, but overwrites entries only after the new expansion succeeds. A
failed replacement therefore must not delete an existing valid instance as a
cleanup shortcut. A nested import without reload can still hit that old entry;
do not reject every repeated path solely from the new active stack.

The registry itself is keyed by original path/ID/aliases, not by a new
`(module, phi)` tuple. Phase contexts and import displacements are separately
represented. Dependency analysis must track which phase operation demands which
module evaluation, while execution retains the original instance lookup rules.
Replacing this with a generic SCC executor changes semantics [S1, S3, S5].

This machine describes one import attempt, not a new global concurrency control.
The inspected registry path does not itself establish a per-module single-flight
protocol. Artifact construction may deduplicate native work, but deduplicating
concurrent semantic instantiations or adding waits would require a separate
ordering/identity proof. Keep promise synchronization separate from registry
publication and native artifact publication.

There are at least three cycle situations: uncached source/prelude expansion,
current submodule/binding lookup, and demand of already constructed delayed
evaluations. Only the first has the explicit path error above. A runtime demand
cycle must pass through the original promise/mutex behavior; the constructor
must not invent a “cyclic expansion” error or safe fixed point for it.

## 6. Exceptions, Escape and Reentry

Do not equate an exception with permanent constructor poisoning. An expansion
failure occurs before source-context publication, but prior dependency loads,
property callbacks or arbitrary external effects may already have happened.
Their effects remain. Reader errors alone pass through `core-read-module`'s
specific wrapping [S1]; a callback error must not be relabeled as corrupt AOT
data or a reader syntax error.

After publication, a failed module evaluation leaves a context and promise;
it is not an interface-load failure. In S7, a direct thunk raise before return
does not take the successful-result write. Gerbil's dynamic-wind unlocks on
exit. A later ordinary force follows the still-existing promise; the recipe
does not cache the exception, suppress retries or synthesize a fresh initializer.
This is a source-level conclusion for the inspected force path, not a universal
promise theorem after arbitrary user state mutation or nested promise linking.

The atomic block's `once` cell guards continuation **reentry into that dynamic
extent**, producing `Cannot reenter atomic block`. It is not a blanket assertion
that a thunk can never be called again after an exception. Recursive forcing
and thread contention still belong to the original mutex/promise implementation.
Keep that implementation intact instead of translating it into a Zig enum.

For continuation capture outside that protected extent, suspended work retains
its exact current state; a later transfer follows Scheme's dynamic-wind rules.
No native worker may resume it, free its state at an FFI return, or restart the
operation stream from its last numeric offset. C operations describe effect
boundaries, not durable checkpoints. Any future continuation-free constructor
profile needs an explicit restriction and separate admission.

## 7. What Work Can Actually Disappear

| Repeated work | Decision from source/evidence | Benefit boundary |
| --- | --- | --- |
| Text tokenization, reading and generic syntax-container construction | Replace for an admitted standard interface representation, accounting for equivalent metadata reconstruction; custom readers remain residual or unsupported | Historical reader observations are small; no several-fold startup claim |
| Producer-known form arity/layout checks and static list scaffolding | Can stage once only when checks/allocations have no current observable effects and error/source behavior is retained | Requires operation-level proof; not every current handler check qualifies |
| Current head resolution / live predicate / handler invocation | Preserve in legacy profile; E7 defeats unconditional reuse | Source duplication does not prove an eliminable operation |
| Current export lookup, rebinding, mark substitution, phase-context creation | Preserve original effects and allocation identity | Repeated key census is not an omission budget |
| Recompilation of an identical factory or phase code | Reuse compatible AOT code; phase code reuse already exists | New factory producer cost and image/load cost must be charged |
| Import record retention and delayed evaluation state | Preserve required fresh objects and existing same-instance memoization | Mutable public records and promises cannot become global immutable constants |
| Phase init, property expressions, callbacks and deferred exports | Execute at original demand/stage positions | Pre-running them changes semantics; ordinary native compilation may accelerate execution but does not eliminate it |

The defensible structural saving is **avoided interpretation/preparation minus
new representation materialization, loading and validation**. Its exclusive
whole-prefix fraction remains unmeasured. This source refinement establishes
legality boundaries; it establishes no startup improvement and leaves historical
5/50/112 gates and complete-test qualification unchanged.

## 8. Source Snapshot and Remaining Design Work

| File under materialized tree | SHA-256 |
| --- | --- |
| `src/gerbil/expander/module.ss` | `f665ac12169cc60043eb467b203abc27cfc005ace09898cecd56d6aa492b9396` |
| `src/gerbil/expander/core.ss` | `d35243f598aa2f90129eb8af637f61a005652549a9f00ea69aef47e8e500522b` |
| `src/gerbil/expander/stx.ss` | `e67c0cdbee0214b6f28af5a0acaace53c2a0246f91d9a86e9b6e1d05b0c795bb` |
| `src/gerbil/expander/top.ss` | `b58f69720c28bdc463c214bd9b12a10e4adcc97ecfbdeb564edaa46ba48edb2b` |
| `src/gerbil/runtime/control.ss` | `563afc77cc96ed938fda6203c2b39bcba9fe6050ba02055292e0e22622389d9a` |
| `src/gerbil/compiler/driver.ss` (locally patched) | `07a175646c90b16c690cf32d670b8368d534963966bbc84d89896f9bb8e5e300` |
| `src/gerbil/compiler/compile.ss` | `ab7afcabfcf89c8ca635779c200e27edc3abdf18debad3fdec1745c074ac9720` |
| `src/gambit/lib/_kernel.scm` | `9afa811a1c15104b953a10d42cd11bddffbfa0b8684b4f8f8191d848fdb6d9ec` |

The operation families and source-import lifecycle are now selected at design
level. Open obligations are exact syntax-graph relocation, complete generated
form coverage, observable structural checks, current source/reader validation,
exception source maps and a formal correspondence including control effects.
No bytecode encoding or restricted semantic profile is selected. Before any
future implementation proposal, identify an exclusive removable budget using
existing evidence; do not rerun rejected routes or count all allocations as waste.

Documentation verification at this checkpoint: 195 local file links resolve,
86 Markdown tables have consistent widths, both new D2 diagrams render and were
visually inspected, and the earlier code/instance diagram was regenerated after
the publication-rule correction. No Scheme/native/model/performance run was made.
