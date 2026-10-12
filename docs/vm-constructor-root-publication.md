# VM Constructor Root Publication

## Source Interaction

The pinned submodule plus the `pstate-log-owned-rollback` Fixture establishes:

- `___setup_mem_vmstate` allocates global-root segments under `vm_list_mut`,
  links the VM, then releases the lock before heap and P0 construction finish.
- `___glo_list_add` traverses linked VMs under that lock but calls
  `ensure_glo_segment` only when `processor_count != 0`.
- `___setup_vmstate` currently sets count to one before the fallible constructor.
- The rollback composition assumes a fresh exclusive constructor. It does not
  prove coverage when another VM registers a global during initialization.

Consequently, merely moving the count assignment to the end suppresses root
updates during the constructor. A concurrent registration can leave a ready VM
without a root slot. This is a proposed-fix counterexample, not a claim that the
current native binary has reproduced that exact schedule.

## Checked Protocol

`vm_constructor_root_publication.qnt` checks a fresh VM against a writer that can
register two additional globals at every transition boundary. The proposed
handoff privately prepares P0, then catches up roots, links the VM and sets its
count in a single `vm_list_mut` critical section. Catchup allocation failure
returns to owned rollback instead of publishing partial roots.

Four negative controls are retained: early count publication, count-only
deferral, ignored catchup failure and split catchup/enable locking. All produce
the expected invariant violations. The proposed protocol exhausts 32 distinct
states, with zero queued states, and checks safety plus temporal progress.

The proof is bounded and sequentially consistent. Critical sections and cleanup
return; fresh constructor rollback is abstract. It does not cover arbitrary
writer allocation failure, signal-handler traversal, C atomic publication,
reader drain, retirement or complete GC. Those remain separate obligations.

## Source Repair Requirements

1. Split private root preparation from list publication; no P0 reader may see
   an enabled count before construction succeeds.
2. Catch up to the current global count while holding `vm_list_mut`, then link
   and enable before releasing that same lock.
3. Treat catchup allocation failure as a constructor failure. The already-ready
   P0 must be unwound through its owned cleanup, not a not-ready blanket cleanup.
4. Keep a dedicated VM-memory abort path that neither reads unready P0 memory
   nor removes an unpublished VM from the list.
5. Preserve heap reservation for the intended initial processor count even
   while the published count remains zero.
6. Bind the resulting source overlay to both the root-publication and complete
   constructor rollback models, then validate native controls and bootstrap.

No source repair or runtime admission is claimed by this model receipt. Model
closure must precede implementation, and native failures must refine it again.
