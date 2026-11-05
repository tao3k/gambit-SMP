# Canonical Registration: Contenders And Commit Outcomes

## Research Decision

The [Stage-One handoff](stage-one-handoff-recipe.md) already requires canonical
identity and preserves successful insertion when optional growth fails. The
existing metadata/VM composition has one writer; the serial-number transaction
models identity but not symbol insertion or postcommit growth. This follow-up
extends the existing metadata model at their omitted interaction. It neither
introduces a duplicate interner nor changes the selected synchronization shape.
No runtime source or native qualification is changed.

## Pinned Source And Transfer Premises

Use the same Gambit `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, Chez
`41d5ffca7a07cbfc8807e719dedcc70ed74811cd` and OCaml
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91` vendor revisions. Baseline sources
explain the behavior; their lines are not a claim about a newer native candidate.

| Source | Established mechanism | Gambit transfer boundary |
| --- | --- | --- |
| Chez `c/intern.c:155-190,193-228` | Lookup, symbol creation and insertion remain inside the same `tc_mutex` interval; an existing matching symbol is returned. | Preserve whole-operation canonicalization. Do not copy its pre-lock index without its surrounding topology/GC premises. Raw mutex waits and allocating calls still require the existing wait/root/effect audit. |
| OCaml `runtime/callback.c:387-417` | Under `named_value_lock`, registration either modifies the existing rooted cell or allocates/links/registers a new one. | A contender rechecks the current table while owning the transaction. Updating an existing named value is not Gambit interning, immutable value publication or an independent-VM value-cell policy. |
| OCaml `runtime/callback.c:419-444` | Lookup returns a cell pointer after unlocking; iteration invokes a C action while holding the named-value mutex. | Storage stability does not make later payload immutable. This is not a template for allocating/reentrant Scheme callbacks under Gambit's M guard. Existing capture/unlocked-delivery obligations remain. |
| Gambit baseline `lib/mem.c:1936-1989` | `___intern_symkey` links the object and increments membership before allocating an optional larger table. Allocation failure skips rehash and leaves the insertion intact. | Optional capacity failure after structural commit must not erase canonical membership or turn that successful insertion into failure. Actual topology/reader visibility and noncollecting allocation remain separate obligations. |
| Gambit baseline `lib/mem.c:1993-2027` | `___new_symkey` returns an allocation error before insertion, but returns the new object after `___intern_symkey`. | Precommit object-allocation error and postcommit optional-growth failure have different public outcomes. Do not apply one blanket rollback policy to both. |
| Existing selected package | M covers canonical check/create; already-owned helpers avoid nested wrapper acquisition. Global creation uses V -> M -> P and no speculative same-binding allocation. | This projection concerns two creators of one interned key. It does not implement global-variable slot/VM root registration; retain that separate existing composition. |

Chez and OCaml have different allocation and error mechanisms. Neither source
justifies introducing collecting allocation, callbacks or arbitrary foreign
effects while holding Gambit's prospective leaf guard. The useful transfer is
the transaction and commit boundary, not their whole allocator or mutex ABI.

## Existing-Model Extension

`runtime_metadata_allocation.qnt` gains a separate `keyStep` projection. Two
contenders may both observe an initial miss before acquiring exclusive metadata
ownership. The owner rechecks, prepares a typed record, commits membership and
then attempts optional growth. The second creator must reuse the committed
identity. One contender's preparation can fail before commit; growth may fail
after commit. The fixed history preserves successful identity and distinguishes
the two errors. The finite two-contender witness is not a CPU/thread limit.

Three controls omit the owned recheck, report growth failure as insertion
failure, or retract membership after growth failure. The positive contract
requires one canonical live identity, valid returned identities, initialized
publication, no simultaneous success/error result and at most one successful
record preparation for this single-key workload. Failed preparation has no
record in this abstraction. Real partial buffers and permanent arena retention
keep their existing prefix/reservation obligations; this is not an allocator
leak or byte-cost proof.

Acquisition, comparisons, initialization and visibility are abstract atomic
steps. Equality of the name/hash/subtype is a premise, as is a valid enabled
caller and fair completion of the leaf operation. Colliding distinct names,
weak-memory instructions, moving roots, arbitrary allocation sequences and
the full interner/VM lifecycle cross-product are not proved here. This does not
give public `___new_symkey` a new same-name uniqueness contract; the owner must
classify direct creation separately from canonical find-or-create callers.

Lean adds two conditional unbounded results to the existing module:
`canonicalRecheckAgrees` says a committed current binding wins regardless of
either contender's proposed identity; `rehashMembershipPreserved` transports
membership through a genuine permutation of registered identities. Neither
proves that the real C transaction rechecks, or that its rehash is a permutation.
An in-bounds cached index alone establishes neither premise.

## Complete Implementation Handoff

The native owner can incorporate this into the existing coordinated Recipe:

1. Inventory canonical find-or-create, direct new-key, keyword and global-binding
   callers separately. Establish name/hash/subtype comparison and current-table
   selection under the same metadata transaction. A preliminary miss is advisory.
2. Preserve the selected no-speculative-allocation shape. Classify every actual
   preparation failure before structural commit; do not rewind shared permanent
   reservations or destroy another caller's committed record.
3. Identify the actual insertion commit and optional growth boundary. Keep the
   original membership and success result on growth OOM. For successful growth,
   prove every old key survives exactly once and no escaped structural reader
   can observe relinking without the existing protection/capture contract.
4. Bind global-variable publication to the existing constructor/slot/root
   composition, not this key-only model. Do not add a per-value global mutex or
   collapse VM-local cells into the process-global canonical record.
5. On the owner's fully rebuilt repaired candidate, use independent same-name,
   distinct-colliding-name and subtype oracles. Cover both contenders observing
   a miss, preparation OOM, successful insertion followed by forced growth OOM,
   later lookup/reuse and captured/TTY/Geiser readers. Keep original callback,
   continuation, FFI, bootstrap and performance acceptance obligations.

This is a source-bound acceptance specification, not new native code or an
agent-directed sequence. Stage-One feasibility still depends on the actual
wait/effect census, visibility/root-map correspondence and init/retirement joins.
Concurrent reclamation, a new root ABI and restart remain separate Experimental
decisions. No model state count predicts speed or closes a native milestone.
