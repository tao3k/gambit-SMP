# Shared Binding, VM Cells And Collector Ownership

## Why This Join Is Required

The [Stage-One Recipe](stage-one-handoff-recipe.md) preserves VM-local values.
Its existing metadata/constructor model checks binding/range/root coverage, but
does not represent the payload selected by a VM accessor or collector. A shared
canonical identity and an initialized slot are insufficient if either operation
selects another VM's cell. This follow-up extends that existing composition,
not the runtime, collector or host-entry API. It does not claim a reproduced
native wrong-VM access or a complete shared-heap theorem.

## Pinned Source Evidence

The Gambit, Chez and OCaml vendor revisions remain respectively
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`,
`41d5ffca7a07cbfc8807e719dedcc70ed74811cd` and
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`. Baseline line numbers below are
not overlay line numbers or qualification of the native owner's current source.

| Source | What it establishes | Applicability condition / limit |
| --- | --- | --- |
| Gambit `include/gambit.h.in:5953-5958,6755-6772` | `GLOBALVARREF/SET` uses `GLOCELL`; multiple-VM `GLOCELL_IN_VM(vm,x)` resolves through `vm->glos[x]`. `PRMCELL` is a separate direct field operation. | Preserve record/index identity separately from cell ownership. Single-VM direct representation is a compile-time profile, not permission to alias multi-VM cells. Matched rebuilt headers/generator/accessors are required. |
| Gambit `lib/mem.c:1372-1402` | A multi-VM global record stores a global index in `val`; the primitive field is initialized separately. | A shared record is not the mutable Scheme value cell. Publishing a binding does not freeze later payload or establish primitive payload lifetime. |
| Gambit `lib/mem.c:6605-6648` | Single-VM scanning follows global records; multi-VM scanning takes a portion of the current VM's `glos`. | Preserve the current processor-to-VM mapping and actual initialized segment/range correspondence. This baseline snippet does not certify overlay acquire ordering or every GC phase. |
| Chez `c/symbol.c:19-32` | Reading a symbol value and setting its value/code are separate from `S_intern`'s table transaction. | Canonical name lookup is not a theorem about concurrent payload mutation. Do not infer multi-VM cells, whole-runtime data-race freedom or generic external-thread entry from these functions. |
| Chez `c/alloc.c:97-102` | `S_protect` records a root address in process-global protected storage and initializes the cell. | This is not a drop-in nested Gambit root frame or a way to share arbitrary VM heap objects via permanent metadata. Registration lifetime, capacity and collector enumeration remain separate. |
| OCaml `runtime/callback.c:387-431` | Named-value registration roots inputs and updates an existing cell through `caml_modify_generational_global_root`; lookup returns the cell address after unlocking. | Stable storage and table identity do not imply immutable payload. OCaml's shared named-root cell is not Gambit's VM-private global value representation. |
| OCaml `runtime/globroots.c:28-36,45-56,116-178` | Root classification and root-list membership are explicit; modification maintains classification before writing the new value. Its root mutex has an explicit blocking-acquisition requirement because releasing the domain lock is unsafe at some callers. | Learn the requirement that payload mutation and collector discovery agree. Do not import its generational barrier, root registry or wait helper without Gambit's storage/collector/effect contracts. One universally GC-releasing mutex adapter would violate this reference's own premise. |

The OCaml root mutex observation refines the existing wait audit: mutex helpers
are chosen by the caller's runtime contract, not by a universal preference for
releasing execution ownership. Chez's process-global root registration is also
not a replacement for Gambit's generated live-frame maps. No new root registry
is selected for Stage One.

## Existing Composition Extension

`runtime_metadata_vm_publication.qnt` retains its actual imported registration
and constructor transitions. The new `cellsStep` permits payload writes only
after binding discovery and constructor execution admission; these may overlap
the remaining publication observations. Two independent VM owners each write
one local token to the new global slot. After both writes, each VM's root
observer selects its own cell. Wrong policies alias the writes into one VM or
scan VM zero for both VMs. They are controls, not supported runtime modes.

The fixed property conjoins the existing publication safety with VM-cell frame
preservation and collector-source identity. Writer precommit failure remains in
the original projection; this extension retains the imported constructor's real
catchup-failure choice. On success, both VM observations must finish; on failure,
no child execution or scan is admitted. A failed constructor is not an executing
VM. Completion cannot require a payload observation from a nonexistent owner.

Tokens denote VM-owned payload identities, not physical addresses. Initialized
unbound cells, valid independent execution owners, supported same-generation
VMs, atomic abstract cell operations and fair completion are premises. This is
not a moving collector, payload publication memory model, same-VM Scheme race
contract, arbitrary foreign attachment, VM migration or overlapping teardown
proof. Shared immutable/permanent primitive payload has separate eligibility
and mutation obligations. The model does not newly permit movable VM objects
in shared `prm` fields.

Lean's `vmCellWriteFrame` is parameterized by arbitrary VM and value types: a
write through a correctly selected owner cell changes that cell and preserves
every other VM's cell. Actual generated accessors must establish the selector
premise. Neither finite root coverage nor a stable shared record does so alone.

## Transferable Acceptance Recipe

- Retain the existing shared canonical binding/index transaction and constructor
  catchup. Audit every enabled generated/inline/C accessor for the effective
  single-/multiple-VM profile; do not replace index interpretation with a
  process-global Scheme value or retain a stale processor-derived selector.
- For each supported entry, bind the execution owner, processor and VM used by
  value access to the VM whose initialized segments/count the GC scans. Reuse
  the existing host-entry/return and lifecycle contracts; do not add an implicit
  cross-VM entry or teardown capability to make the test possible.
- Classify `val` slots, `prm`, permanent metadata, static module objects and
  mutable Scheme payload separately. A metadata guard does not make a new
  shared movable root legal. Any proposed new root/barrier protocol belongs to
  a separately reviewed design rather than being inferred from OCaml names.
- On the unified rebuilt native candidate, use the same canonical symbol in
  independently owned VMs and store distinct live heap objects. Verify local
  reads, forced collection/relocation in each VM and survival after activity in
  the other VM. Check generated and dynamic access paths, allowed nested FFI,
  configuration branches and constructor overlap with independent oracles.
- Preserve normal resolved-global access cost: no new metadata mutex, per-read
  registry walk or process-global payload serialization is selected. Measure
  any actual selector/barrier changes only after correctness qualifies. Model
  state counts are not speed or scalability evidence.

This adds an explicit join to the handoff, not a fourth native milestone or
proof that all first-stage combinations are closed. Actual C visibility,
collector maps/relocation, payload eligibility and lifecycle interactions remain
source/native obligations. No runtime source or native checkpoint is modified.
