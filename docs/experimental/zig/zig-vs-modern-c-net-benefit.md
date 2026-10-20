# Zig Versus an Equally Modern C Subsystem

Date: 2026-10-20. Theoretical design comparison. No implementation, native
small test, benchmark or research-engine execution. This refines TB06 in the
[theory-first argument](theoretical-net-benefit.md), using the
[source and primary-literature ledger](zig-vs-modern-c-evidence.md).

The strongest defensible Zig-specific case is a reduction in selected **native
implementation obligations**, especially typed private variants, type-dependent
native helpers and ordinary-return resource code. It is not elimination of
Gambit's semantic obligations or exclusive access to LLVM. This is a narrower
and more concrete argument than “Zig modernizes C.” The language mechanisms
support local structural advantages; the aggregate positive cost bound remains
an explicit theoretical gate.

![Equal-capability C and Zig differential argument](zig-vs-modern-c-net-benefit.svg)
[D2 source](zig-vs-modern-c-net-benefit.d2).

## 1. Construct a Serious Modern-C Alternative

Call this alternative B1-C. It uses a C11/C17-capable profile as a proposed
minimum, with C23 or compiler extensions optional and separately qualified.
This is not an assertion about the current configured compiler. Primary C11
materials describe generic selection, static assertions and layout queries;
GCC/Clang offer enum diagnostics. A language comparison must not pretend these
mechanisms are absent (P03-P04).

Both B1-C and Z1 retain the same Gambit Scheme producer and runtime. Both use
the same ForeignPlan, HostGraph/FrameSpec, effective configuration, provider
choices, selected capabilities and supported-profile obligations. Both may use
the existing Scheme frontend to generate native-facing declarations. Both may
retain a narrow C/C++ control/provider unit when the actual ABI requires it.

| Logical component | Concrete B1-C design | Corresponding Z1 design / invariant |
| --- | --- | --- |
| BC01 semantic export and decoding | Scheme-produced versioned schema; generated C declarations/decoder; explicit validation | Same Scheme authority and wire meaning; native typed consumer does not replace wire validation |
| BC02 private native product model | Enum plus payload union or opaque constructors/accessors; generated cases; strict diagnostics | Private tagged values and typed dispatch; public serialized/C representations remain separately validated |
| BC03 frame/layout engine | C structs, checked arithmetic, target descriptors, static layout assertions and algorithms | Native typed algorithms and compile-time parameters where appropriate; identical Scheme root/frame obligations |
| BC04 adapter/product emission | C emitter and native-provider builder from the common plan; generated tables/templates | Same outputs and plan; native helper specialization must not create a second semantic schema |
| BC05 native resources | Allocator context/vtable, existing or selected arena/container library, explicit cleanup labels/records | Standard allocator/container mechanisms and normal-return cleanup; still manual lifetime and close/join protocols |
| BC06 foreign control/provider edge | Generated C catch/marker envelope; C or bounded C++ provider API | Same control extent as needed; no escaping transfer across live Zig frames without a separate contract |
| BC07 construction and distribution | One resolver and artifact owner integrated with the retained build coordinator | Same authority; compiling Zig does not require a second top-level build graph or resolver |
| BC08 diagnostics and retirement | Source maps/manifests, deterministic errors and removal of selected old callers | Same obligations; no retirement is credited to language syntax |

This comparison has **zero logical component owners eliminated solely by the
choice of Zig**. Its possible saving is in support code, independently maintained
type associations, error paths, native generic machinery and repeated integration
inside those components. A shorter language expression is not automatically
less maintained work; generated C is not automatically hand-maintained work.

## 2. The Claim Being Proved Must Be Local Before It Is Global

For each mechanism below, distinguish:

- **Language obligation transfer:** a selected consistency condition is enforced
  by the documented language mechanism instead of a project helper/discipline.
- **Component saving:** enough existing support machinery actually becomes
  unnecessary after the transfer, with all required behavior retained.
- **Net investment benefit:** those savings exceed migration, compiler/service
  ownership, control containment, build and review costs over the chosen scope.

The first can be established theoretically from language rules and a concrete
design. It does not imply the second or third. Relying on the Zig type checker
also adds its implementation/version to the trusted toolchain; that is charged,
not treated as free proof. The compiler does not check a semantically wrong
mapping merely because its payload types match.

## 3. Eight Mechanism Cards

Each card identifies its best B1-C counterdesign, not merely today's macros.
Positive conditions below are obligations to justify, not assumed facts.

### ZC01 — Typed Private Variants and Dispatch

**Concrete mechanism.** Use typed private variants for native products, resource
states and adapter actions; dispatch through payload-capturing exhaustive
branches. The selected representation carries a tag/payload association in its
type rather than asking each native consumer to reconstruct it. This is an
internal design inference from P01, not a wire format or a Scheme runtime type.

**Gambit seam.** G01/G02 expose target/product and interface handoff duties;
G03 shows why checks and resumes need a typed plan. Their semantic meaning
still comes from Scheme, not an enum chosen by the native implementation.

**B1-C counterdesign.** Generated enum/union constructors and visitors, opaque
accessors, and enum diagnostics can enforce much of the same discipline.
`-Wswitch-enum` with a strict policy addresses enum coverage (P04). Therefore
“C cannot check exhaustive dispatch” is rejected. Tag/payload association in
arbitrary C union use still needs the generated/private API discipline; the
variant name alone does not choose a payload type.

**Cost boundary.** Count only support/review obligations for native internal
association and dispatch. Keep serialization, unchecked casts/imports, lifetime,
semantic mapping and compiler-version review in the residual cost. Do not claim
general memory safety or that every field access is checked in every build mode.

**Positive condition.** A named private variant family can retire a real
constructor/accessor/visitor consistency layer or reduce its change-review
obligations enough to pay for Z1's incremental toolchain/control burden. C
generator correctness is charged once and reused; it is not charged afresh for
every emitted line or every variant when no corresponding work occurs.

**Counterexample / reversal.** B1-C already generates a sufficient small visitor
from the shared schema, the data is mostly opaque C objects, or the Zig path
still uses raw tags/casts/default catch-all branches. The saving can then be
zero. Distinct variants with identical payload types still permit semantically
wrong but type-correct dispatch. Status: **local obligation transfer supported;
component/economic saving conditional**.

### ZC02 — Type-Dependent Native Helpers Without a Second Semantic Generator

**Concrete mechanism.** Specialize native private builders/containers/layout
helpers using compile-time types and checked helper instantiation (P01/P05/P11).
The candidate saving is an extra implementation-level generic layer, not the
Scheme semantic exporter. Runtime loops and imported data still need validation.

**Gambit seam.** G03/G04 place materialization/control and conversion order in
Scheme. Physical layout follows the configured representation; it cannot be
guessed from the backend implementation language. G06's structure-size checks
show an existing runtime compatibility boundary which remains required.

**B1-C counterdesign.** Scheme-generated declarations/functions, C macros,
`_Generic`, static assertions and ordinary specialized functions. Since Scheme
generation is already part of B1-C, Z1 must not claim to eliminate an external
generator unless a specific additional native-only generator really disappears.

**Cost boundary.** Charge schema-to-native bindings, compile-time analysis,
specialization/code growth, debugging and upgrades. P11 supplies an actual
standard-helper compilation-cost caveat. Zig reflection describes
Zig types, not Gambit's source semantics or arbitrary C layouts. The old C
target remains a semantic reference; copying its rules into native types is
not semantic extraction.

**Positive condition.** Identify a native-only helper family with a B1-C
generation/instantiation burden that Z1 removes while preserving one schema
authority; its avoided recurring work must exceed new specialization/binding
cost. No credit for the GVM-to-native translation stage shared by both designs.

**Counterexample / reversal.** All necessary helpers are already emitted
correctly from one Scheme schema, the operation set is small/stable, or Z1 adds
another manually synchronized type description. Status: **conditional support
code consolidation, no demonstrated generator retirement**.

### ZC03 — Typed Ordinary Results and Lexical Native Cleanup

**Concrete mechanism.** Express success/failure payloads explicitly and attach
cleanup to acquired native resources along ordinary returns. The potential
benefit is fewer manually connected status/out-parameter and cleanup branches.
P01 describes language mechanisms, not automatic resource lifetime verification.

**Gambit seam.** G05 locates configured nonlocal transfers and release failure;
G07 shows dynamic module handles requiring lifetime ownership. These are real
native-resource cases, but not all of them are eligible for lexical cleanup.

**B1-C counterdesign.** Typed status/result structs, small checked functions,
one cleanup label per acquisition scope, or explicit acquisition ledgers.
The same ordinary-return graph can be correct in C without duplicated error
handling at every exit. Existing helper libraries must be credited.

**Cost boundary.** Eligible scope is ordinary-return compiler/product/service
code whose callbacks cannot escape across a live Zig frame. Charge C envelope
and status mapping at managed/foreign boundaries. Cancellation, close/join,
ownership transfer and asynchronous retention require explicit protocols in
both designs. Zig resources remain copyable unless the project prevents misuse;
no affine ownership guarantee is claimed.

**Positive condition.** In a named ordinary-return component, the maintained
cleanup/result glue and its update obligations are smaller than B1-C's after
including the error/control envelope and migration. Errors must still preserve
their original ordering and meaning, not merely become easier to return.

**Counterexample / reversal.** The component has one trivial C cleanup path,
already uses a proven acquisition ledger, or requires Scheme escapes through
the native dynamic extent. `defer` cannot be credited for a frame skipped by
longjmp; release errors cannot restore already invalidated fields. Status:
**language mechanism supported in a bounded scope; callback-rich scope excluded**.

### ZC04 — Reuse a Native Allocator / Container Ecosystem

**Concrete mechanism.** A shared allocator interface and native generic
components can replace separately selected or maintained native support code.
P02 supplies a concrete standard-library allocator interface. This is library
reuse and consistent conventions, not elimination of an allocator.

**Gambit seam.** Native IR buffers, object-building work and service-owned data
are separate from Scheme managed objects (G02-G04/G07). Collector-visible roots
and foreign wrapper lifetimes are not owned by a native allocator parameter.

**B1-C counterdesign.** Context/vtable allocator API, existing C arenas and
containers, generated typed wrappers, or a small suitable existing library.
Do not assume B1-C starts by writing every vector/hash map from scratch.

**Cost boundary.** Charge library integration/version support, allocation
failure paths, ABI wrapping, container specialization, ownership adaptation and
any replacement of already adequate C libraries. Standard-library use does not
prove the compiler service has no leaks, use-after-free or cross-heap cycles.

**Positive condition.** A named set of otherwise maintained dependencies or
adapters actually retires, and the recurring native support saving exceeds
library/upgrade/migration cost. If the same C support remains linked and used,
credit only the net adapter change.

**Counterexample / reversal.** B1-C's existing library already fits, component
needs are tiny, or custom cross-runtime allocation dominates. Status:
**ecosystem fit conditional; no GC/algorithmic performance dividend inferred**.

### ZC05 — C Import and ABI Access

**Concrete mechanism.** Consume C APIs in a typed native implementation and
construct bounded adapters. That can be convenient for Z1, but B1-C already
speaks the C API directly. C access alone has **zero demonstrated positive
increment** over this comparator.

**Gambit seam.** G04/G05 preserve custom converters, macro context, ABI and
managed control; G06's size checks are not complete ABI validation.

**Cost boundary / positive condition.** Charge C translation, header/macro/flag
identity, unsupported constructs, bindings, layout and toolchain upgrades.
Only a named additional binding generator removed from B1-C could supply a
positive increment; none has been identified here. P06 records actual C-import
API evolution, so bindings are not assumed maintenance-free.

**Counterexample / reversal.** A direct C call in B1-C becomes an imported call
plus adapter/version work in Z1 with no removed responsibility. Status:
**neutral mechanism, potentially negative incremental cost**.

### ZC06 — Build, Cache and Target Integration

**Concrete mechanism.** Native construction can share tool/target/artifact
mechanics (P05). Both alternatives retain one effective configuration and
correct invalidation. A leaf native build component need not introduce a second
coordinator or replace Bazel. The question is which actual helper/resolver it
replaces, not whether a `build.zig` file exists.

**Gambit seam.** G08 constructs operation-specific native requests and shell
commands. M1-M12 already demand a single resolver. Moving those decisions to a
modern C subsystem can achieve the same consolidation.

**Cost boundary / positive condition.** Credit only superseded support surfaces
not already removed by B1-C; charge duplicate graph/caches, provider packaging,
SDK/target differences and diagnostics. Zig compilation/incrementality is not
incremental compilation of unchanged Gambit semantics; P06 bounds LLVM emission.

**Counterexample / reversal.** Z1 retains all existing scripts and adds another
configuration/cache authority, or attributes the Darwin pre-first-compile work
to the later C compiler. Status: **conditional tooling consolidation; no current
Zig-specific cache or startup credit**.

### ZC07 — LLVM / MLIR Engineering Reuse

**Concrete mechanism.** Share upstream backend/pass/object services behind the
common contract. B1-C can use the same C API or bounded C++ service (P07/P09).
Its benefit is primarily the shared architecture/provider choice, not Zig.

**Cost boundary / positive condition.** Zig earns an increment only by reducing
a separately identified provider binding/resource adapter relative to B1-C.
Charge APIs outside the C surface, provider ownership/versioning and all Scheme
effect/root/control qualification. No such net adapter retirement is established.

**Counterexample / reversal.** B1-C and Z1 use identical provider adapters and
Z1 adds a language boundary. A C API with no stability guarantee does not
become stable through Zig. Status: **shared benefit excluded from Zig credit**.

### ZC08 — GC, Multicore VMs and Runtime Modernization

**Concrete mechanism.** Explicit compiler/runtime contracts permit future
protocol changes. Both designs retain Gambit's semantics, collector, memory
ordering and VM ownership. P08 motivates the negotiated contract; it does not
select Zig. G05 retains the marker-root TODO and nonlocal transfer constraints.

**Cost boundary / positive condition.** Any Zig-specific gain must identify a
bounded ordinary-return native runtime component and apply ZC01-ZC04 to it.
Charge all new interfaces and unchanged algorithmic duties. “Zig has no GC”
does not remove Scheme GC, and translating synchronization to another syntax
does not change the required progress or memory model.

**Counterexample / reversal.** The same algorithm/protocol moves languages while
all old owners remain, or an unrelated collector improvement is credited to
Zig. Status: **no independent GC/VM net benefit from language choice**.

## 4. Two Local Deductions and Their Exact Limits

**L1: Typed private dispatch can move an obligation into the language.** In the
selected Z1 style, each branch receives the variant's declared payload and
exhaustive dispatch without a catch-all must cover its domain. In B1-C, a
generated/opaque API or review discipline establishes the tag-to-payload use
association; enum coverage diagnostics alone do not establish that association.
Thus Z1 can replace a project-maintained consistency mechanism in this local
representation. It does not prove less work if the C generator is already small
and reusable, and it cannot catch a wrong operation with a compatible type.

**L2: Ordinary lexical cleanup can reduce explicit exit-edge wiring.** For an
acquired resource that must be released on every ordinary exit, scope cleanup
can express that relation once rather than wire each exit manually. B1-C's
single cleanup label also shares exits, so this is a conditional difference in
support machinery, not a count of all error branches as Zig savings. Neither
mechanism proves asynchronous ownership, and skipped frames invalidate this
local reasoning. No failure-rate or speed claim follows from L1 or L2.

These establish the **kind** of incremental benefit that TB06 can legitimately
contain. They eliminate the need to argue that Zig alone enables native code,
MLIR, managed FFI or multicore execution. They do not establish the sign of the
aggregate investment against a strong B1-C design.

### PC01 — A Concrete Private NativeProduct Family

Consider the proposed internal family `CUnit(declarations, macroClosure)`,
`ObjectImage(bytes, relocations)` and `ProviderRequest(ir, providerIdentity)`.
These three cases are design examples motivated by G02/G06/G08, not a census
of current source objects. Scheme EntryId/PointId and wire validation stay
outside this private representation.

| Obligation | B1-C generated/opaque design | Z1 typed-private design | Differential judgment |
| --- | --- | --- | --- |
| Declare the three alternatives and payload meanings | One shared schema plus generated native declarations | Same shared schema binding plus native variants | Zero semantic-schema saving |
| Construct the matching tag/payload pair | Generated constructors or one checked private API | Selected typed constructors | Candidate local enforcement transfer; generator proof may already be fixed/reusable |
| Dispatch each output to its appropriate handler | Generated/private visitor plus strict enum coverage | Typed payload-capturing exhaustive branches | Candidate field-association support saving, not unique enum coverage |
| Preserve ABI/wire/relocation/resource meaning | Explicit validators and source/profile checks | Same checks | No deletion credit |
| Change a case whose payload type is shared with another | Semantic correspondence review still needed | Same semantic review needed | No type-system proof of the intended handler |

This example identifies the exact support layer to assess: B1-C's private
constructor/visitor field-association machinery. It does not establish that the
best C design needs a costly handwritten layer or that Zig can retire the
shared schema binding. If the C visitor is already generated once and stable,
this family alone may have no positive economic increment.

### PC02 — A Concrete Ordinary-Return Metadata Builder

Consider a native metadata builder with temporary bytes, an index buffer and
an output buffer transferred only on success. Assume no callback, nonlocal
transfer or asynchronous retention. These are explicit design restrictions,
not inferred properties of every existing module loader.

B1-C can use one cleanup path and an acquisition/transfer record. Z1 can use
lexical cleanup for temporaries and error-path cleanup for the output, with an
explicit success transfer. **Both designs still have three resource lifetime
relations.** Do not count all three as removed resources or all failure exits
as eliminated review work. Zig can simplify the code expressing those relations;
only the actual difference in maintained support is credited.

G07's loaded-module handle has a longer lifetime than such a helper invocation.
Closing it at the helper's return would be wrong in either language. If that
lifetime is required, add a module owner and its explicit close/unload protocol,
and charge it to both designs. A leaf cleanup example cannot justify a whole
loader rewrite.

## 5. A Concrete Cost Certificate Instead of Free Coefficients

For each selected component/event, record a paired design certificate:

```text
component + required capabilities + target/runtime/profile set
B1-C mechanism + retained library/generator + project-owned obligations
Z1 mechanism + removed support surface + new residual obligations
changed-owner set + migration + recurring language/provider/build burden
source premises + assumption bounds + reversal evidence
```

Allowed structural units include independent association tables, helper/generator
implementations, separately reviewed cleanup relations, handwritten ABI mappings
and supported version/profile obligations. Count logical rules or actual owners,
not generated LOC. Different units remain separate unless a defensible cost
mapping is supplied. A cast hidden behind a helper is not an eliminated proof
obligation; reliance on a language rule still carries compiler/version support.

Let `n_e` be relevant changes of event kind `e`, `c_e` and `z_e` the compatible
engineering-work bounds for the paired designs, `M` incremental migration,
`U` incremental recurring toolchain/library support, and `X` added control/
provider/unsafe-boundary burden. Then the cost certificate must justify:

```text
Net_Zig(H) = sum_e n_e * (c_e - z_e) - M - U - X

Conservative positive condition:
sum_e n_e_lower * saving_e_lower > M_upper + U_upper + X_upper
```

The conservative expression is valid for credited event kinds only when their
per-event saving bounds are nonnegative; negative event kinds are charged as
cost using their upper frequency bounds. For correlated events, bound the joint
sum rather than multiply independent extrema that cannot occur together.
Do not multiply schema edits by generated variants when one generator edit
already serves them all. Do not credit both library reuse and deletion of the
same support component. Amortization requires a selected horizon/change demand;
language features do not supply `n_e`.

A second legitimate certificate is an explicitly accepted bounded-cost tradeoff:
one required representational/review property improves, semantic/runtime
constraints remain intact, and all extra engineering obligations fit a declared
project budget. It must be labelled a tradeoff, not a proved saving in hours.
No budget, change count, cost rate or claimed lower bound is invented here.

## 6. Narrow the Research Scope and the Gate

The strongest candidate scope is the private native product/layout/resource
subsystem with ordinary returns, shared by the new C and native emitters.
ZC01-ZC04 can apply there without assigning Scheme semantics or general foreign
control to Zig. Bounded C/C++ units remain where actual control or provider APIs
require them. This is substantive C-layer reconstruction, not a build launcher.

The following proposed Zig-specific cases are not accepted: access to a C API
alone; generic LLVM/MLIR reuse; automatic Gambit GC/multicore improvement;
compiler-cache slogans; deletion of all code generation merely because of
comptime; or cheaper arbitrary callback handling.

| Theory gate | Current finding / exact remaining closure |
| --- | --- |
| TG1 equal-capability comparator | B1-C and Z1 now have paired mechanisms for BC01-BC08; neither is an implementation |
| TG2 concrete differential mechanism | ZC01-ZC04 identify bounded candidates; L1/L2 establish local obligation-transfer reasoning |
| TG3 preserved semantic feasibility | Scheme/runtime owners remain explicit; callback-rich/nonlocal scope excluded from the ordinary-return candidate; actual native qualification is later |
| TG4 real support surface retirement | SC-ADT-C is unnecessary in the scoped resident LP-C/LP-Z pair; streaming defeats universal necessity, and no existing support/path is retired; see the follow-through below |
| TG5 positive aggregate bound / accepted tradeoff | Paired cost/change/support bounds or a declared tradeoff budget are still absent; a positive interval cannot be chosen arbitrarily |
| TG6 falsifiable prediction and scope | Can be designed after TG4/TG5; no empirical experiment is used to supply the missing theoretical mechanism |

The gate is now narrowed to TG4/TG5 for this specific candidate, with TG3's
semantic design constraints retained. It is **not passed**. This is stronger
than an unrestricted list of possible benefits: four credible bounded mechanism
families remain, four broad credit claims are neutral/rejected, and the exact
missing theoretical certificate is named. Native tests remain outside this
phase. A claim that Zig is necessary, universally superior or already cheaper
would exceed the evidence.

The [source-grounded support/change certificate](native-support-change-certificate.md)
now distinguishes old-route replacement, prospective support avoidance and
maintenance reduction. It follows actual Scheme label production through C
descriptor macros, names SC-ADT-C and its residual obligations, and compares a
streaming design that may need no native source-product sum in either language.
Nine change events show why stable generated variants and shared C cleanup
cannot be counted as repeated handwritten work. The reviewed consumer demands
do not yet require residency. TG4 has a bounded constructive result for one
pair; neither necessary Zig adoption nor a positive aggregate bound follows.
