# Stage-One Complete Package: Composition And Acceptance

## Scope Decision

Use **one repaired revision, effective build configuration and complete matched
rebuild** of the runtime, generated C, libraries and extensions. Defective SMP
mechanisms are replaced, not supported as fallback modes. Preserve portable C
generation, valid continuation/nested-FFI semantics, interned identity, VM-local
values and ordinary allocation/resolved-global fast paths. Internal generator
or layout changes are allowed when justified and rebuilt throughout.

The earlier documents' version/layout cautions explain why a rebuild is needed;
they are not a requirement to support mixed old/new binaries. Historical failure
receipts remain unchanged. Existing verifier fields named `oldInvariants` or
variants named `old` designate negative controls, **not** a compatibility mode.
There is no reason to modify the shared verifier schema to rename that history.

This completes the discussion-level package boundary, not implementation/native
qualification. Runtime source/patches, TLS, bootstrap, stress tests and the other
lane's checkpoints are untouched. Source authority is still the reviewed Gambit
baseline `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus its existing
[locked overlay](../../evidence/research/processor-interrupt-collective-wait/source.lock.json).
Do not silently treat this overlay as the other lane's latest repaired source.

## Concrete Producer Transaction

The selected first implementation shape avoids speculative same-binding record
allocation: acquire-load an existing binding for the common already-created
case. On a miss, acquire **V -> M**, recheck, then reserve a private record under
P and release P. Initialize record fields, prepare every active VM's cells,
link/register, release-publish count, release-publish binding, then release M/V.
Single-VM profiles omit V, not M/P where same-VM concurrency exists. No Scheme
service, callback, collecting allocation or failure-prone step occurs after
structural commit while these guards are owned. Existing interning uses M -> P;
exported permanent allocation still uses P only.

This chooses one of the earlier preparation alternatives for the first patch:
it avoids duplicate permanent records on competing successful creators at the
cost of raw allocation under the leaf guards. A failed later segment allocation
can still leave an unpublished permanent record until global cleanup, as in
current error behavior. Moving reservation outside V/M, concurrent module load,
nonblocking refill/reclamation and new callback reentry are separate proposals,
not prerequisites silently added to this package.

## Source-Bound Combination Ledger

| Combination | Actual source observation | Required design/acceptance condition |
| --- | --- | --- |
| Existing VM plus newly published global | `mem.c:1435-1499` prepares active VM segments before count; `1611-1644` later initializes `prm` and binds the symbol. | Initialize private record before structural reachability; one canonical check/create under M; count covers initialized slots; binding publication certifies its registered index. A slot count alone does not certify binding/record readiness. |
| Constructing VM plus concurrent global registration | `setup_mem_vmstate:5232-5251` samples roots under V, releases it during private construction; `publish_mem_vmstate:5400-5429` catches up current count and links/enables under V. | Keep the catchup/link/enable transaction indivisible relative to registration. The writer must include every VM that can execute binding reads. An unpublished private VM may lag until catchup, not after enable. |
| Count-zero VM skipped by writer | Registration tests `processor_count != 0`; setup starts at zero. Public `current_vm_resize:1562-1564` rejects targets below one. | Do not treat zero-count construction as an executable VM. A lower-level caller cannot revive execution without the applicable publication/root contract. No general dormant-VM resurrection capability is introduced. |
| GC observes registration during record publication | Multi-VM `mark_globals:7307-7331` acquire-loads count/table/segments; table-root marking at `7334-7346` has a distinct permanent-head observer. | An acquire-visible binding must map to an initialized registered slot for the current VM. GC needs slot coverage, not module/value readiness. Preserve the separate permanent-head publication adaptation; do not guard the full moving scan with M. |
| Global allocation or VM catchup fails | `ensure_glo_segment:1370-1428` can fail before registration commit; constructor publication rejects failed catchup before membership/count. | No new binding/count on writer precommit error; retained safe capacity is allowed. Failed private constructor frees only its owned memory, never process-global records or another VM's cells. Reuse existing constructor rollback models. |
| Reader/callback reentry plus concurrent rehash | TTY C visitor is reviewed leaf code; kernel fold allocates; Geiser also calls `make-global-var` while filtering. | TTY uses its private leaf traversal; allocating readers capture/revalidate under M, release it, then deliver. Preserve nested FFI/continuation behavior outside the guarded interval. A capture freezes membership, not values or newly inserted names. |

The global primitive takes its Scheme identifier directly
(`_kernel.scm:3867-3875`). Do not assume **every** symbol input is permanent
merely because interned table members are. The leaf segment introduces no GC
safepoint/service and must retain valid caller/VM ownership. A moving input at a
new service boundary needs the existing generated storage/map/reload contract;
`interrupts-disabled` or a C-local copy is not a substitute. Borrowing an object
from another VM is not made valid by protecting process metadata.

## Why Separate Local Passes Do Not Compose Automatically

There are three different predicates:

1. The observed record is initialized and visible.
2. The set of committed global indices is covered by a VM's roots.
3. Every visible binding maps into that committed set for that VM.

The first two do not imply the third. That missing correspondence can be exposed
even while both local safety models pass. Conversely, a constructor that catches
up then enables under a separate registry interval can lose a newly registered
slot while its processor count is zero. These are abstract counterexamples, not
attributions of current TFIB/pipe failures.

`runtime_metadata_vm_publication.qnt` imports the **existing actual transitions**
from `runtime_metadata_allocation.qnt` and
`vm_constructor_root_publication.qnt`; it does not rewrite either collector.
The composition binds count publication to `registerGlobal`, excludes constructor
root sampling/publication while the writer owns V, and lets acquire-style readers
observe a binding before the writer returns. It includes writer precommit abort
and constructor/catchup failure. Two negative initializations expose early binding
without range registration and the imported split constructor publication.
The unit indices and single constructor are witnesses, not a CPU/VM limit.

The metadata import starts with a **private initialized record**, matching the
selected producer transaction. Its later phase-advance `initializeRecord`
preserves the already-true readiness bit; it is not a proposed extra C write.
No imported resize/reader/prefix profile is claimed to be fully composed here.
Weak memory, actual root relocation, many writers, allocator OS effects and
unwind/generation protocols remain their separately bound obligations.

Lean's `bindingCoverageComposes` states the general set-correspondence bridge;
`localCoverageWithoutBindingBridge` witnesses why local root coverage alone is
insufficient. These are conditional logical results, not C acquire/release or
source-refinement proofs. Existing order, interval, generated-root, retry and
unwind assets remain dependencies rather than being recreated.

## Chez And OCaml Transfer Decisions

Pinned Chez `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`,
`c/intern.c:155-304`, supplies a whole lookup/create/insertion boundary. Its
collector-driven resize and thread/allocator ordering are not transplanted as
Gambit VM semantics. The local operation boundary must also participate in
Gambit's registry/root publication history.

Pinned OCaml `46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`,
`runtime/callback.c:387-431`, associates named records with registered roots;
stable slot address alone is not root lifetime or immutable payload.
`runtime/unix.c:649-657` releases/reacquires runtime ownership on a contended
wait. That is a reference for explicitly describing effects, not permission to
insert Gambit's broad collective service into a P/M-owned leaf interval.

The low-cost transfer is coherent ownership and observer-specific publication,
not a copied nursery/card-barrier/continuation implementation. Such GC changes
belong to a separate Experimental milestone with generated-C/FFI read/write,
root-map and sequential-cost obligations. The C backend remains the design
substrate, not a defect to remove.

## Whole-Package Implementation Boundary

| Source group | Cohesive responsibility | Evidence required before admission |
| --- | --- | --- |
| `mem.c` central permanent helpers | P reservation/alignment/refill/psection lifecycle for all callers. | Disjoint reservation, overflow/alignment, ordinary/large refill, OOM/cleanup; no movable-allocation hot-path guard. |
| `mem.c` interner/global operations and private `mem.h` helpers | M topology/canonical identity, V -> M -> P nesting, already-owned private helper variants, initialized record/range/binding commit. | Same-name races, collision/rehash, matched discovery macros, constructor/GC interleavings, no hidden V reacquisition. |
| Header plus required generator inputs | Matched publication accessors and generated root/map/RA behavior if affected. | One actual source/compiler/effective-macro identity; regenerate all affected C, rebuild runtime/modules/extensions. No old-inline fallback. |
| `_kernel.scm`, TTY and Geiser | Leaf C traversal versus rooted capture/unlocked Scheme delivery. | Same output/arity/errors, callback insertion, nested/error/continuation folds, retained membership and value-isolation behavior. |
| Global setup/cleanup prefix | Enroll V/interrupt/OS/P/M/memory ownership, handle partial failure and valid drain before reclamation. | Exact-once owned cleanup, original errors, supported prepublication retry; no false full-generation restart claim. |

This is a coordinated small refactor, not one guard added to the interner.
It preserves supported public semantics; rebuilding internal headers or private
helpers is allowed. It adds no second interface, Python workflow or legacy mode.

## Acceptance Contract And Unclosed Work

The **scope decisions above are closed for discussion**. The following remain
explicit implementation/native obligations, not more policy alternatives:

- Produce one repaired source tree and effective configuration; cleanly
  regenerate/recompile the complete runtime and package/extension set once.
  After that, unchanged source-bound stages may use their normal checkpoint;
  a mixed-source artifact cannot inherit the matched rebuild's result.
- Complete actual caller/reader census for that candidate, including enabled
  debug/low-level/C++ branches, ordinary nested FFI and actual callback effects.
  Unsupported new attachment, teardown reentry or module parallelism is not
  quietly introduced by this package.
- Execute same-name and independent permanent allocation, rehash/TTY/Geiser/
  callback capture, global binding/constructor/GC overlap and available typed
  failure cutpoints. A missing supported failure fixture is untested, not green;
  no unapproved injection mechanism or release-only hook is implied.
- Run original interpreted/compiled stresses and required GSI/GSC/Gerbil/FFI
  acceptance for the affected candidate, plus preserved performance gates.
  No serialization of Scheme execution, disabled SMP, wider thresholds or
  synthetic watchdog progress may manufacture a pass.

Only genuine target progress keeps an existing native watchdog alive; logical
model steps are not native progress. This review executes only finite formal
and focused DSL checks. It neither reruns nor invalidates the other lane's
bootstrap/stress results, and awards no native milestone. Exact local evidence
and limitations are recorded in [validation](stage-one-integration-validation.md).
