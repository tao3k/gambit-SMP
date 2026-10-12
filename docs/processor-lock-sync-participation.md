# Processor Lock Sync Participation

## Admission Decision

Source audit found four remaining blocking processor acquisitions in SMP idle
enqueue, run-queue removal, interrupt propagation and thread-state snapshots.
The existing ready-processor/GC model already demonstrates that a requester
spinning on a processor lock can prevent its owner's collective from finishing.
This is worth addressing for correctness; no performance multiplier is claimed.
The successful parent helper is generalized by name and used at these sites.
Non-SMP code and queue mutation order are unchanged.

This candidate does not implement the separate retirement/drain/slot-generation
models. Its lock and patch are reproducible from the pinned Gambit submodule;
the cache tree is not source authority.

## Real Denial

GNU GCC incremental core build passed in 10.756 seconds, with host-auto
capacity and the original 180-second budget. The new
`thread_state_gc_lock_paths.scm` coverage fixture then timed out in interpreted
mode after 30.004 seconds, exit -9. It combines migrations, state snapshots and
forced GC on the host-selected processor population. It uses no processor pin
to avoid those paths and propagates worker root exceptions.

The process group was quiescent after termination. Fail-fast stopped before
the compiled coverage runs, strict-interrupt runs and lifecycle runs; they are
**not run**, not passes. The earlier retained parent is not replaced by this
candidate. No bootstrap, sealed producer or runtime admission follows.

Original observations and exact runtime identity are preserved in
`evidence/source-results/fixtures/processor-lock-sync-participation/`.
The unchanged failed native input is not repeated.

## Model Feedback

The first thread lock in `##thread-state` is still a blocking primitive, before
the newly sync-aware processor acquisition. `##thread-migrate-to!` holds its
current thread lock across processor-lock waiting and sync participation.
Consequently, source permits a three-role cycle: A owns a thread lock and waits
for B's processor lock; B requests GC; A can participate, but C blocks on A's
thread lock and cannot participate. This is a source-supported hypothesis,
**not a sampled lock-owner/GC-round diagnosis of the native timeout**.

`thread_processor_lock_gc_cycle.qnt` captures that missing interaction. Its
negative control preserves the processor-wait repair but leaves the thread
wait blocking. The fixed design allows thread-wait participation too. Moving
lock-object roots, register/continuation spilling, synchronous errors, arbitrary
mutex/condvar/timeout locks and resize/join composition remain explicit source
obligations. One additional helper cannot be presumed to fix all of them.

## Controlled Native Follow-Up

The original aggregate timeout is still undiagnosed. A distinct compiled
`thread_processor_gc_wait_cycle.scm` control places three explicit protocol
roles on the host-selected population and forces the source-supported wait
order. On this candidate it reaches the GC-request trace, then times out at
30.004 seconds. A sample of that same process has eleven processors in
`___sync_wait` and one in the internal `##thread-state` lock acquisition.
This confirms the controlled path, not exclusive causation of the aggregate
timeout. The preceding wrong-arity fixture attempt is preserved separately.

An output-wrapped aggregate diagnostic passed; it changed scheduling and is
not acceptance of the original unchanged failing fixture. All controls,
samples and the API error remain in the source-results directory.

See `thread-lock-sync-participation.md` for the next source refinement and
its distinct remaining processor-macro failure.

## Protocol Metadata Audit

Three older registered manifests lacked `composes`. Each actual QNT module
(`pthread_returned_error_identity`, `resize_commit_startup_round`,
`sync_atomic_round_publication`) was inspected: all are standalone transition
models and import no other protocol module. Their explicit empty composition
lists therefore mean **no composed proof**. The atomic-publication manifest's
`dependencies` are context-bound related files copied by the checker, not
imported transitions or checked composition edges. Dependencies were retained,
not silently converted into proved `composes` relationships. Full protocol
composition remains open. Checker logs, model bytes and old receipts were not
changed or rerun to repair this metadata omission.
