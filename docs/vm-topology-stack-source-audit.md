# Topology Stack Source Audit

## Evidence Boundary

This audit follows the owned-child sample recorded in
`smp-threaded-vm-milestone.md`. The resize-grace source lock and completed
producer, not a mutable cache pathname, determine source authority. Reproduce
with `smp-bazel-profile-topology-stack-observation` through the existing sealed
research framework. Original timeout and partial trajectories remain failures.

## Corrections To The Initial Interpretation

- The sampled main-thread `pthread_join` belongs to `fixture_start` in
  `models/gambit/native/registry_topology_latency.scm`. It waits for the VM host
  workers created by the fixture. It is not evidence of a stuck
  `___thread_join` in Gambit's processor-retirement implementation.
- Four sampled OS threads wait in `barrier_sync_op`. That function snapshots
  `processor_count` and coordinates a tree of processor messages. Its presence
  alone does not identify the operation, generation, or missing participant.
- The active Scheme thread samples `___H___thread + 40204/40208`. Subtracting
  the executable load address gives image offsets `0x2ea5a8/0x2ea5ac`.
  Disassembly of the exact retained executable shows `ldaddal` then `ldr`,
  preceded by a `casal` try and followed by another `casal` try. These are
  actual atomic instructions, not proof of the identity or ownership of the
  contended object.
- A DWARF lookup at preferred address `0x1002ea5ac` returns no source mapping.
  Exact generated-C/Scheme call-site attribution is therefore still missing.

## Existing Models Must Be Reused

`scheduler_retry_gc_participation.qnt` already captures retries that release a
processor lock without servicing a pending collective operation.
`scheduler_gc_root_cohort_composition.qnt` already composes processor waits,
thread waits and complete GC-cohort participation. Neither model establishes
that every compiled retry site services synchronization.

The bound `_thread.scm` already defines
`##lock-scheduler-object-with-sync-participation!`, which polls
`___INTR_SYNC_OP` after a failed trylock. Thus proposing that helper again is
not a causal delta. The bound `gambit.h` implements primitive trylocks through
ticket-lock CAS and unlock through atomic increment, consistent with the
instruction family in the sample but not sufficient to name the call site.

## Required Closure Before A Runtime Patch

| Requirement | Missing evidence |
| --- | --- |
| Exact site | Map both sampled offsets to the generated call site using the same source/configuration |
| Lock ownership | Identify object, owner, and held locks at that site |
| Collective generation | Bind waiting participants to the same VM, operation and generation |
| Model refinement | Check that site's retry, release and root relocation against the existing composed model |
| Native recovery | Original-budget repeated topology must finish on the resulting exact producer |

No fresh native retry is justified by this audit alone. A diagnostic source-map
build is distinct from a release/performance producer and cannot replace it.

## Exact Retry Site Located

The existing `gambit.object` capability now accepts a strictly boolean
`debugSymbols` option and the validated completed source-runtime artifact.
It adds only `-g` to the configured command. Recipe
`evidence/research/vm-registry-reader-lease/thread-source-map.recipe.json`
passed through engine
`c3417721becfd49a648ee0a379b9479fc9f9fa0128aa60fc3b7a412259664334`.
Actual object compilation took 4.243 seconds; this is not runtime acceptance.
Thirteen focused diagnostic/executable/stack transport tests passed.

The diagnostic object places `___H___thread` at `0x6e6c`; adding the sampled
function displacement `40208` yields `0x10b7c`. DWARF maps that address to
generated `_thread.c` line 13373, inside
`##thread-lock-remove-btq-toq!`. The local original-executable and debug-object
instruction sequences agree: failed queue trylock, atomic thread unlock,
thread trylock, then reread of the blocked-thread-queue container. This local
match is not a claim that entire object text is identical.

The corresponding `_thread.scm` branch is the mutex/condition-variable blocked
queue path: if `macro-trylock-btq!` fails, it calls `macro-unlock-thread!` and
immediately `try-again`. The processor-container branch already calls the
sync-participating helper. The mutex/condition-variable retry does not. This
binds the existing `scheduler_retry_gc_participation.qnt` abstraction to a
specific additional retry boundary: no locks are held at the retry checkpoint,
so pending collective participation can be checked there without dispatching
ordinary callbacks while locks are held.

Still unproved: the identity/owner of the sampled queue and the operation/VM
generation of the waiting barrier members. A model-guided checkpoint repair
is now a source-supported candidate, not an established unique timeout cause.
It must retain thread/queue ownership, root relocation, original assertions,
all concurrency flags and original native budgets.

## Path Review

This path is worth pursuing because it uses a new captured stack rather than an
unchanged timeout. The general lock/GC interaction has already been explored;
the remaining question is compiled-site coverage of that protocol. Expected
benefit is correctness and sustained progress if an omitted site is confirmed;
no numerical speedup is supported yet. Adding duplicate finite models, changing
retirement based on the host join frame, or rerunning the same stress input
without a causal delta would not resolve the evidence gap.
