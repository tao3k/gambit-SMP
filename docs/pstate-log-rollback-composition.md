# Processor And Activity Log Rollback Composition

## Route Review

The processor transaction previously treated memory setup as an atomic callee.
Pinned `lib/mem.c:___setup_mem_pstate` initializes the processor activity log
before returning success; `___cleanup_mem_pstate` does not release those log
buffers. Later synchronization setup failure can therefore require a distinct
log ownership handoff. Existing isolated log and processor models did not
compose this boundary. The intended benefit is correctness, not a claimed
performance improvement or attribution to an old compiler crash.

## Composed Contract

`pstate_log_rollback_composition.qnt` imports both existing protocols and expands
the log allocation actions inside the processor memory stage. It includes VM
array/mutex failures, P0 temporary-allocation failures and later processor
synchronization failures. Fixed rollback releases P0 and VM log ownership,
then the borrowed outer interrupt ownership, without dumping an unready P0.
The explicit VM-only abort control leaves processor buffers live.

The model assumes a fresh exclusive P0, returning successful destructors and a
POSIX boolean mutex initializer; disabled logging is included. It does not model
concurrent readers, general VM-memory construction, slot reuse, failed joins,+C weak memory or full GC. Imported log state was renamed to `logState` because
Quint 0.33's effect checker identifies conflicting updates by variable name.
No protocol transitions changed in that imported model. Original proof receipts
remain historical; a new source031-v3 campaign rechecks all four log controls
and the complete bounded safety/progress result.

## Evidence

The new VM-only control produces an invariant counterexample with actual exit 1.
The original composition finished safety and temporal checking with exit 0:
614 generated states, 430 distinct states, zero queued. Both checks used the
unchanged 90-second budget; inputs remained stable. Portable artifacts are in
`evidence/model-results/pstate-log-rollback-composition/`.

That original proof only constrained final resource emptiness. The owned-log Fixture's
inner failure helper instead releases initialized P0 log buffers before error
handoff. The stronger model now includes this inner cleanup action and a
`returnOwnershipSafe` invariant. A distinct delayed-cleanup control violates it
with processor phase 7, outer phase 2 and both P0 buffers still owned, even
though subsequent outer cleanup would eventually empty resources.

The historical return-handoff campaign checks both negative controls and complete
bounded safety/progress: 617 generated states, 428 distinct states, zero queued.
Inputs stayed stable, the positive parent exit was 0, and both negatives exited
1. Current portable material is in
`evidence/model-results/pstate-log-return-handoff-source032/` (an immutable historical
receipt path, not an active Fixture identity). The active source identity is
`evidence/fixtures/pstate-log-owned-rollback/source.lock.json`. Earlier proofs
remain historical and do not qualify the stronger model. Destructor return,
fresh-slot and exclusive-ownership assumptions remain explicit; this is still
not a C refinement theorem or native lifetime acceptance.

Protocol registration now lives in `evidence/protocol-bundles.json`, with a
generic schema/path/duplicate validator. Adding another proof registration does
not require a Python protocol-specific branch. This removes a registry-only
maintenance issue, not the separate source-preparation architecture gap.

This is a proposed ownership protocol, not an implemented caller repair.
The isolated VM abort C helper cannot discharge the P0/caller obligation alone.
Native source refinement, lifecycle, bootstrap and Gerbil acceptance remain open.
