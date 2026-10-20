# Host Root Registration And Lifetime Carriers

## Mechanism-Level Scope

The [current Recipe](../host-root-publication-recipe.md) checks an already-owned,
supported host call without changing its root ABI or adding thread attachment.
This separate Experimental question is whether a lifetime-owned registration
could decouple execution ownership, collector-visible roots and reclaimable
storage. Preserving generated C, continuations and FFI is mandatory; an OS TLS
slot or shared-nothing heap is not the selected solution.

OCaml's registered-thread ring and saved states provide a concrete example
(`st_stubs.c`:208-280,294-323). Its teardown replaces the active root owner before
freeing its old info (:441-453,666-702), while domain stop closes registration
under the retained lock after joins (:519-541). Chez's collector enumerates
registered contexts (`gc.c`:1239-1269) and its generator traces context-specific
C-chain, stack-link and stack state (`mkgc.ss`:961-1024). Chez retains a segment
creator carrier, not the freed execution context (`thread.c`:324-335).

The references therefore do not support copying just a host registry, active
counter or TLS lookup. They expose a whole ownership graph and admission protocol.
An inactive registered host may have live stack-allocated root slots; a stable
registration address does not extend those slots or make an old C return valid.

## Decisions Needed Before A Prototype

| Mechanism question | Required design/evidence | Cost or counterevidence |
| --- | --- | --- |
| Who owns registration and execution? | Separate legal attachment, exclusive pstate execution, previous-binding restoration and terminal admission. | Existing Gambit host entry is not arbitrary cross-thread/cross-VM attachment. Rejecting unsupported cases and supporting them are different semantic choices. |
| Where do roots live while execution is inactive? | Enumerate generator maps, saved/stack/C/RC roots, descriptors and collector-specific scan ownership. | No carrier may retain dangling pointers into an ended C activation. Copying stack/continuation state can change the FFI/continuation ABI and needs its own milestone. |
| How is registration published and withdrawn? | Name the actual lock/atomic history, scanner admission and last admitted reader; retain a usable successor for collector traversal. | The OCaml mutex history is not a proposal to make every Gambit field atomic or serialize all Scheme execution. |
| Can slots/VMs be reused? | Match owner incarnation, root layout and collector epoch; prevent new entrants across terminal close. | An address or logical processor ID is not a freshness proof. Source-defined epochs and supported failure rollback are prerequisites, not a new mandatory generation ABI selected here. |
| When can storage be reclaimed? | Discharge returning host, collector, interpretation, work/queue and external borrowers independently, then establish the actual final publication/cleanup edge. | Collector completion and OS join alone each omit consumers. Retaining every record forever is not an acceptable liveness or resource result. |

## Reuse And Deliberately Unmodeled Composition

Reuse `models/experimental/root_registry_callback.qnt` for scanner-owned deletion
and root-slot last use, `participant_exit_publication.qnt` for membership/request
serialization and post-exit writes, and the existing retirement/carrier model
for source versus independent ownership. Their existing Lean companions remain
conditional and their algorithms are unchanged by this audit.

They do not yet compose arbitrary host attachment, a complete physical root graph,
collector epoch/slot reuse, nonlocal C return and bounded carrier reclamation.
The existing Scheme research relations must expose this missing interface rather
than inherit a local deletion or participant-model pass. The current publication/
lifetime composition is useful evidence, not implementation of this redesign.

Before adding such a model, select the actual owner/allocation and root-slot
lifetimes, define failure/retry and terminal admission, and bind the applicable
entry effects. A separately owned uniform-revision/configuration prototype must
then rebuild the affected generated/header-dependent closure and demonstrate
native correctness, resource stability and single-/multicore cost. This thread
does not choose or implement it and does not change the other acceptance lane.
