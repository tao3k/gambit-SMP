# ForeignPlan: Semantic Ownership and Native Adapter Construction

Date: 2026-10-20. Design only. This specifies a proposed contract, not a new
FFI implementation or support claim. Read the [source census](foreign-plan-evidence.md)
and [same-contract engineering comparison](foreign-plan-engineering-comparison.md).
It refines [VQ03-VQ05 and VQ08-VQ12](zig-adoption-value-questions.md).

The selected direction is substantive replacement of generated wrapper and
product decisions. Gambit produces a typed semantic foreign plan; the common
native subsystem constructs C/native adapters and explicit foreign products.
Gambit's runtime owns managed objects, roots, Scheme control and VM entry.
The subsystem could be implemented in modern C or Zig; the comparison must
charge both for the same semantic obligations.

![ForeignPlan production and native/control ownership](foreign-plan-contract.svg)
[D2 source](foreign-plan-contract.d2).

## 1. The Information and Ownership Loss to Remove

Current parsing accumulates types, converters, declaration strings, generated
procedures, initializers and objects. `c-interface-end` preserves only four
lists and clears types/converters. `make-c-proc` retains names, arity and body
text, not the typed signature (FS01, FS07). Consequently a later GVM-only
consumer cannot reconstruct the typed foreign interface without guessing.

There are two further ownership transitions. The frontend replaces elements of
`c-intf-procs` with primitive procedure objects (FS08). The C target consumes
and empties the interface vectors so the frontend will not emit a second file
(FS09). These are actual mutations in the handoff protocol. Merely copying the
four lists later does not recover original types or remove the competing owners.

Capture the resolved type graph and foreign IDs while parsing; keep the parse
environment private. Freeze a pointer-free `ForeignPlan` alongside the semantic
module before the registry is cleared. Bind later procedure objects to those
IDs instead of changing the meaning of a list element. Select exactly one
product owner explicitly; never use an empty mutable vector as an acknowledgement.
GVM export and the high-level export share these IDs but may use different
admitted lowering paths. Exporting the signature does not qualify either path.

## 2. Proposed Logical Data Model

The following is schema notation, not executable Scheme/Zig code or an ABI.
Logical records need canonical serialization and verifiers before use.

```text
ForeignPlan {
  schemaRevision, semanticModuleId, sourceClosure, targetSemanticProfile,
  types: [TypeId -> ResolvedForeignType],
  units: [ForeignUnit], entries: [ForeignEntry],
  conversions: [ConversionProgram], moduleActions: [OrderedModuleAction],
  managedObjects: [ManagedObjectRef], emissionOwner: ProductOwner
}
ResolvedForeignType {
  TypeId, origin, aliasProvenance,
  shape: Scalar | SchemeObject | Pointer | Function | Aggregate | Custom,
  nullPolicy, tagPolicy, converterIds, declaredCleanupPolicy,
  cSpellingDependency?, nativeLayoutAuthority
}
ForeignEntry {
  EntryId, sourceOrigin, schemeProcedureId?, exportedSymbol?, scope,
  direction, logicalSignature, target: Symbol | OpaqueBody(BlobId),
  conversionProgramId, phaseEffects, controlProtocolId,
  lifetimeProtocolId, runtimeEntryId?, foreignUnitId, requiredCapabilities
}
ConversionProgram {
  programRevision, numberedSourceArguments, executionOrder,
  orderedSteps, acquiredResources, successResult, failureContinuations
}
EffectSummary {
  stage, memoryReads, memoryWrites, managedAllocation, mayCollect,
  mayBlock, mayReenter, nonlocalTransfer, retention, synchronization,
  evidence: Unknown | Reviewed(SourceIdentity, ContractRevision)
}
ForeignUnit {
  UnitId, orderedDeclarationBlobs, language, includeAndMacroClosure,
  targetAbiRequest, exportedEntryIds, bodyBlobIds, productDependencies
}
```

An unresolved C aggregate stays dependent on C layout; it is not a guessed Zig
struct. Alias provenance and resolved meaning are both retained. Type syntax
does not prove lifetime, blocking, error, or callback properties. Custom
converters and release functions are executable code with their own dependencies.
Preserve their names and declared cleanup flags without inferring purity.

Semantic argument/root slots come from Scheme completion. Physical frame slots,
symbol names/addresses and target ABI layout come from the common product
planner and configured runtime/provider. An `EntryId`, a Scheme `PointId`, an
external C symbol and a native address are different identities. An exported
callback is an external semantic root even when no Scheme call references it.

## 3. Conversion Order Is Part of the Contract

`c-make-function` partitions parameters into `scheme-object` and other types,
retaining order within each partition, and then constructs nested conversions
(FS05). This is not simply argument-index order. Declaration/macro setup and
runtime conversion effects must be distinguished: direct Scheme-object aliases
can produce no converter call, while other entries execute conversions and
cleanup. Preserve the actual wrapper program, including argument-numbered
errors and which later steps are skipped after failure.

For logical arguments `[a1: custom, a2: scheme-object, a3: char-string]`, the
plan records the stable wrapper setup order `[2,1,3]`, then the invocation and
result conversion. It must also record which steps actually execute, their
nested cleanup obligations and the failure continuation. This is a source
derivation, not an observed execution trace or a claim about arbitrary C
argument-expression evaluation order. Inputs are already Scheme arguments.

`S64/U64_to_SCMOBJ` returns an immediate only within the configured fixnum
range; other branches allocate a bignum (FS12). Pointer results can allocate a
foreign wrapper (FS13). Even if the foreign target is a proven leaf, result
conversion can allocate or fail. A `void` result does not prove that argument
conversion, callbacks or cleanup are leaf operations.

F0-F5 are capability facets, not six mutually exclusive bins. F1 conversion,
F2 blocking, F3 callback and F5 retention may coexist. F4 origin/thread entry is
a separate context constraint. Track effects for entry, each conversion, target,
result and cleanup. A whole boundary earns F0 specialization only when every
reachable stage, including error delivery under its admitted input domain,
meets that policy. A signature or target-only summary cannot supply that proof.

## 4. Control Containment and the Zig Boundary

![Ordinary returns versus nonlocal foreign control](foreign-control-containment.svg)
[D2 source](foreign-control-containment.d2).

FS15 locates configured setjmp/longjmp and C++ exception mechanisms. FS16 and
FS17 locate processor-sensitive markers, matching catches, return errors and
invalidation. The manual describes separate Scheme/C continuations and nested
thread restrictions (FS18). These constrain the current protocol; a new design
must state how any expanded capability changes it.

**A C catcher alone is insufficient.** If its protected call executes
`C catcher -> Zig frame -> C callback -> Scheme` and an escape targets that
outer catcher, the Zig frame can still be skipped. Catching the transfer later
does not make Zig `defer` execute. In the C++ branch, cross-language exception
propagation also requires an admitted unwinding ABI; it is not inferred from
linking. We have not qualified either behavior.

Select these design policies:

- Ordinary-return native services may run in Zig only with an explicit contract
  preventing an escaping Scheme/C transfer across a live Zig frame. Inputs and
  outputs have native/copy ownership or explicit admitted handles.
- Legacy callback/control behavior remains inside a C-controlled dynamic extent
  when that extent can unwind. Any Zig helper used there must return before
  a potentially escaping operation, or independently satisfy a stronger edge
  protocol. Owned resources need explicit cleanup records usable by the real
  C/runtime exit path; lexical Zig cleanup is insufficient.
- A new callback envelope that always returns status is a separate capability.
  It needs callback ABI/error-channel agreement, marker/root correctness and
  proof that no continuation or error can escape through a live Zig frame.
  It must not silently convert a legal Scheme escape into an ordinary error or
  swallow `UNWIND_C_STACK` intended for another activation.
- Unknown callbacks, foreign-origin thread attachment and arbitrary asynchronous
  Scheme entry are unsupported by the selected ordinary-return service profile.
  Preserve their existing C route where independently supported, or reject the
  requested new capability before construction. Do not expand runtime support
  because a C function pointer can be imported into Zig.

This keeps a narrow C control adapter when its semantics require one. It does
not retain the whole old C emitter: Scheme supplies the control plan, the common
subsystem emits the selected adapter, and opaque foreign bodies remain separately
owned foreign units. Generic module/frame/layout decisions move out of the old
macro-emission path in both B1 and Z1.

## 5. Lifetime and Failure State

Model one activation as:

```text
PLANNED -> ADMITTED -> ENTRY_PUBLISHED -> ARGUMENTS_PREPARED
        -> TARGET_ACTIVE -> RESULT_PREPARED -> CLEANED -> DELIVERED
```

Each transition has a failure destination and an acquired-resource set. These
are semantic states, not a prescribed linear implementation. Nested callbacks
create child activations with their own identity and matching control owner.
On collection or stack movement, reload managed locations through the published
runtime state; cached native addresses into moved Scheme storage are invalid.

Conversion failure skips the target and cleans only acquired resources according
to the original program. Target completion does not imply result delivery;
result conversion can still fail. Cancellation of a native job is not completion:
storage survives until the relevant worker/completion/close owner releases it.
F5 needs a separate job lifecycle with generation-safe identity and close/join;
it is not implemented by retaining a Scheme activation's raw pointer.

FS14 supplies a concrete release rule: `release_foreign` clears release/pointer
fields **before** invoking the release function; failure returns an error and
does not restore the old fields. The Scheme wrapper may raise afterward.
Represent invalidation-before-callback and failure explicitly. Do not add
transactional rollback, retry the same release implicitly, or claim arbitrary
parallel releases are safe from this sequential source rule.

The baseline marker constructor still contains a rooting TODO (FS16). Reusing
its name is not a proof that a new root/control path is safe. Keep native marker,
root, helper and mixed-edge requirements open.

## 6. Concrete Design Requests and Rejections

| Proposed request | Plan outcome | Work that remains |
| --- | --- | --- |
| Named bounded scalar function, reviewed target and range-restricted conversions | Candidate ordinary-return adapter; whole-boundary F0 requires all reachable-stage proof | Scheme call/frame correctness, target ABI and guards still need admission; no candidate is implemented here |
| Pure native function returning unrestricted `unsigned-64` | Target may be a leaf; boundary includes allocating result conversion | Preserve bignum/error/root behavior; no F0 inference from signature |
| Long native compiler service, copied byte input, owned byte result, no callback | Candidate F2 with explicit completion and Gambit-owned GC participation | Queue/wait/reacquire/cancel/resource protocol must be designed and qualified independently |
| C++ aggregate or custom converter identified only by spelling | Keep a target-bound C unit or reject direct native lowering | C++ construction/destruction, ABI and executable converter effects cannot be guessed |
| Opaque `c-lambda` body using `___argN`, `___return` or other macro context | Preserve exact body and declared macro/include/configuration closure in a C unit | New emitter supplies qualified envelope; hidden runtime/frame macro use may require rejection or deeper refactor |
| Existing SFUN callback passed through Zig and allowed to escape | Reject ordinary-return Zig route | Preserve suitable C control extent or design a genuinely stronger callback/control capability |
| Arbitrary nonnull C function converted to Scheme procedure | Preserve current conversion error | FS13 shows this baseline conversion is unsupported; callable address is not proof of a bridge |

Illustrative logical request; values are placeholders, not generated artifacts:

```text
request {
  module: M, foreignEntry: E, foreignPlanRevision: FP,
  mode: ordinary-return-native, targetAbiProfile: T,
  runtimeContract: R, semanticFrameSpec: F,
  targetEffects: reviewed(source-id, no-managed-reentry),
  argumentConversion: native-copy(input-bytes),
  resultConversion: owned-buffer-to-Scheme-with-roots,
  capabilityFacets: [F1, F2], emissionOwner: common-product-engine,
  completion: explicit-status-and-owned-result
}
```

Neither `reviewed` nor the names in the example constitute evidence. A real
request must carry validated references and compatible identities. Unknown
effects, missing type graph, duplicate product owner, missing cleanup/exit edge,
unresolved C layout, stale input closure or unsupported callback causes preflight
rejection of the affected capability. Do not reinterpret the source program.

## 7. Replacement Order and Independent Closure

| Stage | Existing path replaced in a selected cohort | Required closure |
| --- | --- | --- |
| FR01 | Type/signature information discarded by `c-interface-end` / body-only c-proc | Parse-time immutable side record, aliases/converters/order captured before reset; old and new logical identities correspond |
| FR02 | `c-intf-procs` element mutation / implicit interface consumption | Explicit procedure-ID binding and single product owner; no duplicate or omitted declarations, inits or managed objects |
| FR03 | `c-make-function` semantic conversion/cleanup decisions embedded in strings | Scheme conversion plan matches setup, result, cleanup and every failure path; opaque C text remains opaque |
| FR04 | `targ-scan-c-procedure` private frame/return construction | Foreign HostGraph/FrameSpec and runtime-role correspondence; independent C/native/mixed control and root admission |
| FR05 | Generic physical wrapper/layout/module emission | Common product engine plus new C/native adapters; correct target ABI and explicit C islands; no whole-old-dumper forwarding |
| FR06 | Raw callback/function-pointer assumptions | Static callback anchor and dynamic closure policies distinguished; qualified lifetime and control containment, or explicit deferred scope |
| FR07 | Hidden release/resource cleanup and service waits | Invalidation/cleanup/error/cancel/close ownership encoded; collector participation and VM/lifecycle constraints preserved |
| FR08 | Old selected callers/emission authority retained after replacement | Caller/artifact inspection plus semantic/native evidence and full-cost decision; M/H retirements stay independently gated |

Stages are dependency order, not permission to implement. FR01-FR03 are useful
under B1 as well. FR04-FR08 can proceed per explicitly scoped capability; no
global FFI success is inferred from one route. The 18 source families below are
a research census of responsibilities, not an application-site denominator.
There are zero newly admitted foreign capabilities in this study.

## 8. Three Existing Kernel Uses as Design Controls

KU01-KU03 in the [evidence ledger](foreign-plan-evidence.md) bind three literal
foreign bodies in the existing kernel, not hypothetical MLIR requests:

- `##foreign-released?` reads the foreign-pointer field and returns a Boolean.
  Its public wrapper still forces/checks its input. A reviewed internal field
  operation may get a precise lowering, while the public call retains its
  applicable effects. Reading lifetime state does not synchronize a concurrent
  release automatically.
- `##foreign-release!` invokes `release_foreign` and may raise a Scheme error.
  Clear-before-release and failure-without-rollback are observable semantics.
  Unknown release function effects prohibit a generic leaf Zig release adapter.
- `##foreign-address` is an actual body-form c-lambda with Scheme-object input
  and `size_t` result. Result conversion delegates to the unsigned integer
  converter with a conditional bignum path. Preserve the address-as-integer
  result; replacing it with an opaque native job handle changes this API.

For these runtime-owned bindings, a deliberate semantic intrinsic/runtime plan
can eventually replace the opaque internal C body after source review. This is
different from inferring semantics from arbitrary user C text. The C/native
emitter then lowers an explicit field/conversion/release operation and no longer
needs that internal C snippet as its semantic authority. Source identification
alone does not admit the replacement; public checks, effects, roots and failure
behavior remain part of the capability. These concrete uses strengthen the
refactoring target without establishing a Zig-specific saving.
