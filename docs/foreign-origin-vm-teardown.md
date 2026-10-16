# Foreign-Origin VM Teardown

## Source Finding

The source-bound vector-arity candidate checks child VM population equals one
and pending join count equals zero before global cleanup. It then sets
`cleanup_phase`, disables interrupt handling, seals the VM registry, shrinks the
root cohort and destroys root/child VM state. These checks do not establish that
processor zero has no live native C frame. See `lib/setup.c` together with the
patch/revision identity in [the source audit](foreign-origin-source-refinement.md).

The per-removed-origin shrink design must therefore compose with whole-VM
teardown admission. Otherwise it may protect retired processors while allowing
a still-live root or child P0 frame to outlive freed VM state. This is a source
and finite-model finding, not a reproduced native use-after-free.

## Transaction Requirements

1. Close admission for every VM which cleanup will destroy, before disabling
   interrupts, sealing the registry or mutating cleanup state irreversibly.
2. Check all origin leases, including P0, not just origins removed by shrink.
3. On a failed close or a busy lease, roll back only this transaction's acquired
   closures. Preserve a concurrently active publisher and its reservation.
4. Commit teardown only after the entire VM set is closed and quiescent.
5. Block late publication after successful teardown; require a lifetime-safe
   lookup before touching any real VM pointer. The finite model retains a
   tombstone state and does not prove reclamation of a C allocation.

The model includes root P0 busy, child P0 busy, partial-close rollback and
quiescent commit trajectories. Two semantic VMs are a finite abstraction, not
a limit on native CPU count or concurrency. Its counters are abstract integers;
the separately verified word-bounds model supplies saturation obligations, not
an automatic proof that the two models refine a concrete implementation.

## Current Receipt

Recipe `foreign-origin-vm-teardown-model` in
`evidence/research/vm-registry-reader-lease/foreign-origin-vm-teardown.recipe.json`.
Model `models/gambit/foreign_origin_vm_teardown.qnt`.
Local run `.data/fixtures/foreign-origin-vm-teardown/combined-model-run`.

- PASS, 40.196792333 seconds whole, original 300-second budget unchanged.
- Safety and no-stall: 206 distinct / 460 generated states each, zero queued.
- Four trajectories passed, none failed or ignored.
- Population-only and early-commit policies produced real counterexamples.
  Their residual queues are not claimed as exhaustive exploration.
- Engine: `30b196894b2dea5928b8165bf5e40e6012253b20677457790daa93aa4e62f03d`.
- Outer: `415ad41ea3814c73443415d83f477733877256a1934260ed3d5659a742e0a434`.
- Child: `bde6e5c6f612e1cb9e082571348c43111c3e974c5254a3424a2f2f8ad57abd4a`.
- Completed source reused, no new configure/bootstrap or native injection.
- Runtime, source-refinement and release admission remain false.

No-stall means finite deadlock checking, not fair-scheduling liveness or bounded
latency. Memory ordering, pre-catch unwind cleanup, VM lookup/reclamation,
incarnation reuse, ownership of the real cleanup transaction and native
performance still need source-bound verification. Do not implement a global
callback ban or hold a gate across Scheme/GC as a shortcut.

## Evidence Boundary

The unchanged official-FFI roundtrip remains a native DENY. Constructor injection
and private cleanup entry points remain prohibited by the human decision. The
separate framework campaign has 1,087 ordinary tests passing but sealed review
and graph timeouts at the original 60/300-second caps; it is not fully qualified.
SMP acceptance remains 3/12 with nine full gates OPEN.
