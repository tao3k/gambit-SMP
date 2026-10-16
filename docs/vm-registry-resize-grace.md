# Registry Grace At Processor Count Publication

## Source Obligation

The pinned source plus the owned-retirement overlay protects final VM cleanup,
not processor retirement during `___vm_resize_pstate`. A global interrupt reader
can snapshot the old count in `___raise_interrupt_vmstate`. P0 publishes the
lower count in `barrier_sync_op`, replies to the old cohort, and a retired worker
closes its select-abort pipe in `___cleanup_os_pstate`. The old reader can still
reach that processor. Resetting the descriptor after close is not a reader grace
period. This is a source-derived lifetime obligation, not a reproduced crash.

The resize-grace candidate closes and drains global registry admission only at
P0's count-publication point, after the old cohort has arrived and before its
barrier reply. It then publishes the lower count, opens admission, unlocks the
registry mutex and replays pending interrupts. Only afterward does the existing
tree reply release workers. Growth and single-VM code are unchanged. This short
retirement boundary does not serialize Scheme execution or parallel GC.

## Model And Assumptions

`models/gambit/vm_registry_resize_grace.qnt` composes the old-count snapshot,
registry lease, barrier arrival/reply, slot resources and joining. The model
retains both count-only use-after-retirement and early-close progress controls.
Closing before arrival is not a valid alternative: workers may still need an
interrupt to arrive. The positive finite model checks both safety and enabled
progress; four exact trajectories exercise old readers, late readers and the
two rejected orders. The interpreter cannot evaluate `enabled`; its early-close
trajectory checks the explicit blocked state, while TLC checks `noStall`.

Assumptions remain explicit: sequentially consistent lease operations; bounded
nonblocking global interrupt readers; exclusive runtime lifecycle ownership;
direct VM API callers owned externally; no arbitrary scheduler fairness proof.
Internal `on_all_processors` raises its direct VM interrupt before collecting
the barrier. External direct callers bypassing the registry are not made safe
by this patch. Signal storms, C memory-model refinement, failure injection,
arbitrary processor counts and the complete GC/FFI/native Grid remain required.

## Acceptance Binding

Use `resize-grace-source.lock.json` and `vm-registry-resize-grace.patch`, never
reinterpret the older owned-retirement producer as this candidate. Preserve all
three SMP/multiple-VM switches and the original bootstrap and native budgets.
Models permit source investigation, not runtime or performance admission.
The old locks, bootstrap producer and native entry receipt remain historical
checkpoints. A new completed producer must pass bootstrap, typed handoff and
current causal review before any full Grid or threaded-VM test consumes it.

The initial framework attempt was denied by the sandbox TLC loopback prerequisite
before execution. The first local model run passed positive and negative TLC
checks but failed the interpreter-only `enabled` test. Both failures remain in
their original receipts; neither budget nor safety/progress invariant was relaxed.
