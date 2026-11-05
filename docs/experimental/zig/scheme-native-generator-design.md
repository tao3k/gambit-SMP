# Scheme Generator and Native Product Planning

Design only. All stages and output paths below are proposals; this turn creates
no Scheme generator, C header/body, native executable or minimal prototype.
Read the [contract](generated-c-native-contract.md),
[evidence](generated-c-contract-evidence.md) and
[cost boundary](generated-c-contract-cost-matrix.md).

## Generation Pipeline and Source Authority

| ID / stage | Input / output | Source correspondence and required reconstruction |
| --- | --- | --- |
| SG01 Contract declarations | Authoritative Scheme declarations -> typed schema records | Reuse ordinary Scheme compiler data facilities. GVM operand/frame data is a source model, not a complete runtime contract [CS01/CS02] |
| SG02 Capability negotiation | Effective profile, native provider/access facts and required operations -> realizable capability plan | Existing target begin!/representation/call information supplies a seam [CS01]. Do not let renderer-only decisions change Scheme semantics |
| SG03 Semantic completion | Purified GVM + analysis/role/FFI records -> explicit checks/materialization/transfers/roots/frames | Extract semantic work from targ-check-conditions, targ-update-fr, targ-gen-jump and scanner paths [CS03/CS04]. Recompute affected liveness/slots after expansion |
| SG04 Validate and freeze | Completed graph + schema/profile -> immutable SemanticModule | Resolve normal/error/escape edges, roots, source origins, PointIds and role requirements. Unknown primitive/raw C regions remain unsupported or explicitly fenced |
| SG05 Common native planning | Frozen module + target facts -> ResolvedNativePlan | Scheme resolves shared layouts, host/control dispositions, native operation contracts and module requirements. Provider capabilities were negotiated before freeze |
| SG06 C structural rendering | Plan -> declarations, descriptors, selected host bodies and policy calls | C syntax/field access/call spelling is generated. Semantic decisions are not rediscovered while constructing strings |
| SG07 Provider output/binding | Provider code and maps + common module plan -> NativeModuleProduct | Existing targ-dump consumes/clears C-interface records and emits module counts/constants/procedures [CS10]. New provider does not invoke that whole dumper to recover semantics |
| SG08 Independent admission | Product + source/contract lineage -> future semantic/native acceptance | Independent readers/oracles compare semantics, roots, ABI/control, failures and ownership. Generated metadata checking itself is insufficient |

GVM purification is real [CS02]; the new completion/export is not an existing
public hook. The capability negotiation follows the original Gambit paper's
bidirectional frontend/backend principle [CP05], while preserving current
source/runtime obligations rather than importing the old paper's implementation.

## Generator Modules and Concrete Products

SG09. Conceptual internal modules are schema construction, semantic completion,
common native planning, C product rendering and manifest/source mapping. Keep
them ordinary Scheme procedures with explicit inputs; do not add a new DSL
evaluator or infer layouts from arbitrary C strings. Side-effecting compilation
state may exist inside the current compiler, but the freeze boundary supplies
immutable snapshots to native providers.

The C route emits the following proposed *classes* of products:

| Product class | Generated content | Hand-maintained native counterpart |
| --- | --- | --- |
| Private contract header | Opaque handles, typed records/statuses, service declarations, field/access descriptors and supported-operation tables | Native allocation/synchronization/OS adapters and policy implementation declarations |
| Immutable descriptor C unit | Object trace/weak/init recipes, frame/point/role and service-state metadata, compile-time layout checks | Collector/registry/log/coordinator readers with independent validation |
| Module host C unit | Explicit root materialization/reload, checks, dispatcher transfers and calls to native policies | Admitted Gambit control/trampoline/FFI runtime and selected service bodies |
| Module binding product | Imports/exports, runtime-role references, constants/root registration, init/unwind dependencies and code lifetime | Runtime module binder and per-VM/context instance creation/drain |
| Provider-neutral manifest/data | Source/schema/profile/plan identity and dependency graph | C or LLVM/MLIR provider-specific derived artifacts and evidence |

These names are not new committed .h/.c files. Expensive descriptor/type
definitions should be factored into stable units rather than emitted afresh
inside every hot host or huge macro header. Whether that improves build time is
unmeasured; C parsing, optimization and linking still occur. A descriptor lookup
on every hot operation is not assumed acceptable merely to shrink source text.
Allow a qualified small inline fast path and out-of-line slow policy without
duplicating semantic authority.

## Validation and Limits of Generation

SG10. Validate these properties before rendering:

- Every field has a trace/weak/nonpointer class, access rule and initialization
  completion point; unknown native writes cannot inherit a managed profile.
- Each allocating/polling/blocking/reentrant operation has complete root homes,
  owner state, frame frontier and actual normal/error/escape/reload edges.
- Commit intervals declare native capacity before mutation and prohibit hidden
  allocation, callbacks, parking or epoch change.
- PointIds and role bindings have actual creation/origin and incoming-state
  contracts; physical label numbers are only renderer results.
- Every partial failure names storage/code/root custody and the authorized
  cleanup path; accepted asynchronous tasks do not unwind through caller cleanup.
- Symbolic layout facts resolve for the actual profile, preserving real Scheme
  word/tag/frame meaning. Current source constants are not automatically a
  coherent configured runtime.
- Module imports/exports/init and all code/metadata last users close under the
  admitted cohort. Unknown C-interface text is a declared native island, not
  silently translated to a pure operation.

These checks establish only their local structural premises. Independent root
completeness, primitive semantics, native synchronization, continuation replay
and arbitrary foreign effects are not inferred from a successful freeze.

SG11. If later native lowering needs an allocating spill, extra safe point,
observable poll, resume point or control edge, it sends an AmendmentRequest to
Scheme. Scheme recompletes affected dataflow/frame/root obligations and produces
a new content identity. Ordinary local machine scheduling/noncollecting spills
can remain provider-local only within the frozen effects. Bound negotiation;
exhaustion rejects that provider/cohort instead of adding a late private GC map.

## Data-Only Request Examples

SG12. The [sample ledger](generated-c-contract-samples.json) describes three
real source-backed cases: managed set-cdr!, native C-closure/marker root custody,
and deferred device/TLS release. It is JSON data for documentation, not a
prototype interpreter or an executed generator request. Each sample separates
semantic input, immutable generated recipes, live state and rejection cases.

For set-cdr!, use pair.cdr as a symbolic slot. Scheme supplies the actual
resolved evaluation order and protected receiver/value homes. A slow prepare
can collect only at a declared point; commit uses reloaded current values and a
valid bounded reservation. The generated C operation does not evaluate Scheme
operands again. Language-unspecified evaluation order is not silently turned
into a stronger language rule. The high-level provider needs a compatible order
handoff or an explicitly declared semantic profile [CS11/DR05].

For a C callback/marker, protect proc before any possible managed allocation;
native handle registration does not repair earlier unprotected evaluation.
Preserve the declared native-entry/escape island and owner restoration. The
reviewed dynamic C-closure selector lacks an arm64 template in that block;
required target support remains a separate gate [CS05/DR03].

For foreign release, construct/accept custody before clearing wrapper fields,
then execute staged native close/wait work under explicit owner rules. A TLS
recipe records one context, optional strings and provider lifetime; it does not
serialize SSL_CTX or raw root pointers into an AOT artifact [CS06/CS07].

## Bootstrap, Configuration and Evidence

SG13. Keep configure policy/probes and legacy/typed native outputs at the
existing single-source seam [DR04]. A first bootstrap can consume a maintained
snapshot of generated C contracts with source/generator identity, just as the
project already carries generated C compiler/runtime material. A compatible
host Scheme compiler regenerates them when needed; the generator itself must
not require the new services whose declarations it is creating. Future
reproduction must compare source/model/products and actual compiled layout,
not treat a checked-in hash as a native ABI witness. No snapshot is generated
or accepted by this research turn.

SG14. New artifacts publish atomically as a coherent product set. A missing or
mixed schema/profile/layout/body makes the module unavailable. Exact replacement
of current setup/module/native export tables needs caller closure and provider
admission, not preserved ordinal coincidence [CS08/CS10]. Old C remains a
separate admitted provider until the selected cohort's replacement is complete;
do not keep the old dumper as a permanent hidden semantic oracle behind the new
generator. Cost and retirement must count what actually remains.
